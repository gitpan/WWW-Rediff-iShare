#!/usr/bin/perl

use warnings;
use strict;

use Net::Ping;
use Test::More tests => 1;

use WWW::Rediff::iShare;
my $self = WWW::Rediff::iShare->new();
my $base_url = $self->{'base_url'};

my $reachable = Net::Ping->new('external')->ping($base_url);

my $stream;

SKIP: {
	skip 'ishare.rediff.com is unreachable, is there a connection?', 1 unless $reachable;
	eval {
		$stream = $self->get_stream_url('Karzz','audio');
	};
	is( $@, '', 'construct stream URL' );
}
	
