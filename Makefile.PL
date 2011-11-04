use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'      => 'Config::Pit::Qt',
    'VERSION_FROM' => 'lib/Config/Pit/Qt.pm', # finds $VERSION
    'PREREQ_PM' => {
		Config::Pit => 0.04,
		QtGui4 => 4.3,
    },
);
