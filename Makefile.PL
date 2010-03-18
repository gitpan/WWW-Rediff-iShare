use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'WWW::Rediff::iShare',
    AUTHOR              => 'Rakesh Kumar Shardiwal <rakesh@cpan.org>',
    VERSION_FROM        => 'lib/WWW/Rediff/iShare.pm',
    ABSTRACT_FROM       => 'lib/WWW/Rediff/iShare.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
	'HTML::TagParser' => 0,
	'LWP::Simple' => 0,
	'WWW::Mechanize' => 0,
	'Data::Dumper' => 0
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'WWW-Rediff-iShare-*' },
);
