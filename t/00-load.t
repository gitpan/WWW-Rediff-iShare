#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'WWW::Rediff::iShare' );
}

diag( "Testing WWW::Rediff::iShare $WWW::Rediff::iShare::VERSION, Perl $], $^X" );
