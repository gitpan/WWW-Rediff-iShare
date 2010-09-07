use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'WWW::Rediff::iShare',
    AUTHOR        => 'Rakesh Kumar Shardiwal <rakesh@cpan.org>',
    VERSION_FROM  => 'lib/WWW/Rediff/iShare.pm',
    ABSTRACT_FROM => 'lib/WWW/Rediff/iShare.pm',
    ( $ExtUtils::MakeMaker::VERSION >= 6.3002
        ? ( 'LICENSE' => 'perl' )
        : () ),
    PL_FILES  => {},
    PREREQ_PM => {
        'Test::More'          => 0.96,
        'HTML::TagParser'     => 0.16,
        'Data::Dumper'        => 2.126,
        'LWP::Simple'         => 5.835,
        'URI::Encode'         => 0.02,
        'URI::Fetch'          => 0.08,
        'XML::Simple'         => 2.18,
        'String::Random'      => 0.22,
        'FLV::ToMP3'          => 0.24,
        'Test::Pod::Coverage' => 1.08
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES    => 'WWW-Rediff-iShare-*' },
);
