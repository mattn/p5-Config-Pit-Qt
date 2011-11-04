package Config::Pit::Qt::Dialog;
use QtCore4;
use QtGui4;
use QtCore4::isa qw(Qt::Dialog);
use QtCore4::slots ok => [], cancel => [], editUpdate => [];

our $response = 'cancel';

sub NEW {
	shift->SUPER::NEW();
	my ($caption, $setting) = @_;

	this->{response} = 'cancel';
	this->{setting} = $setting;

	setWindowTitle($caption);
	my $vbox = Qt::VBoxLayout();

	my @labels = ();
	my $labels = {};
	for my $label_name (sort keys %{$setting}) {
		my $hbox = Qt::HBoxLayout();
		my $label = Qt::Label($label_name);
		$label->setAlignment(Qt::AlignRight());
		push @labels, $label;
		$hbox->addWidget($label);

		my $edit = Qt::LineEdit();
		$edit->setToolTip($setting->{$label_name});
		if ($label_name =~ /passwd|password/) {
			$edit->setEchoMode(Qt::LineEdit::Password());
		}
		$edits->{$label_name} = $edit;
		$hbox->addWidget($edit);

		$vbox->addLayout($hbox);
	}
	this->{edits} = $edits;

	my $hbox = Qt::HBoxLayout();
	my $ok = Qt::PushButton('&OK');
	this->connect($ok, SIGNAL 'clicked()', SLOT 'ok()');
	$hbox->addWidget($ok);

	my $cancel = Qt::PushButton('&Cancel');
	this->connect($cancel, SIGNAL 'clicked()', SLOT 'cancel()');
	$hbox->addWidget($cancel);

	$vbox->addLayout($hbox);

	this->setLayout($vbox);

	adjustSize();

	my $maxwidth = 0;
	for my $label (@labels) {
		if ($maxwidth < $label->width) {
			$maxwidth = $label->width;
		}
	}
	for my $label (@labels) {
		$label->setMinimumSize($maxwidth, 0);
	}
	adjustSize();
}

sub ok {
	for my $label_name (keys %{this->{edits}}) {
		my $edit = this->{edits}->{$label_name};
		this->{setting}->{$label_name} = $edit->text();
	}
	this->{response} = 'ok';
	qApp->quit();
}

sub cancel {
	this->{response} = 'cancel';
	qApp->quit();
}

sub editUpdate {
	warn shift;
	this->{setting} = 'cancel';
}

package Config::Pit::Qt;

use strict;
use Config::Pit qw();
use Config::Pit::Qt::Dialog;

use YAML::Syck;
use Path::Class;

our $VERSION = '0.01';

unless (grep /^Qt/, keys %INC) {
	require 'Qt.pm';
}

my $orig = Config::Pit->can('set');
*Config::Pit::set = sub {
	my ($name, %opts) = @_;
	my $result = {};
	local $YAML::Syck::ImplicitTyping = 1;
	local $YAML::Syck::SingleQuote    = 1;

	if ($opts{data}) {
		$result = $opts{data};
	} else {
		my $setting = $opts{config} || Config::Pit::get($name);

		my $app = Qt::Application();
		my $dialog = Config::Pit::Qt::Dialog($name, $setting);
		$dialog->show;
		$app->exec;

		if ($dialog->{response} ne 'accept') {
			$result = Config::Pit::get($name);
		} else {
			$result = $orig->($name, data => $setting);
		}
	}
	my $profile = Config::Pit::_load();
	$profile->{$name} = $result;
	YAML::Syck::DumpFile($Config::Pit::profile_file, $profile);
	return $result;
};

1
__END__

=head1 NAME

Config::Pit::Qt - Qt user interface for Config::Pit

=head1 SYNOPSIS

  use Config::Pit;
  use Config::Pit::Qt;

  my $config = pit_get("example.com", require => {
    "username" => "your username on example",
    "password" => "your password on example"
  });

=head1 DESCRIPTION

Config::Pit is account setting management library. In normally, pit_get uses
$EDITOR to editing account information. This library provide GUI instead.

=head1 FUNCTIONS

=head1 AUTHOR

mattn E<lt>mattn.jp@gmail.com<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Config::Pit>

=cut
