#!/usr/bin/perl 

use CGI;
use WWW::Rediff::iShare;

my $iShare = WWW::Rediff::iShare->new();

my $stream_data = $iShare->get_stream_url('Jaane Tu Mera','audio');
if($stream_data)
{
	for my $a (@{$stream_data})
	{
	   print "Title : ", $a->{'title'},"\n";
	   print "Url : ", $a->{'stream_url'},"\n";
	   print "file_id : ", $a->{'file_id'},"\n\n";
	}
}

#### To download your song

#$iShare->download('518188','audio');
