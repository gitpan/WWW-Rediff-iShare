#!/usr/bin/perl

use warnings;
use strict;

use Net::Ping;
use Test::More tests => 1;

use lib '../lib/';

use WWW::Rediff::iShare;
my $self = WWW::Rediff::iShare->new();
my $baseurl = 'http://ishare.rediff.com/';

my $reachable = Net::Ping->new('external')->ping($baseurl);

my $stream;

SKIP: {
	skip 'ishare.rediff.com is unreachable, is there a connection?', 1 unless $reachable;
	eval {
		$stream = $self->get_stream_url('Karzz','music');
	};
	is( $@, '', 'construct stream URL' );
}
	