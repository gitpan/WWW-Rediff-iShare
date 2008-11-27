#!/usr/bin/perl 

use CGI;
use WWW::Rediff::iShare;

my $self = WWW::Rediff::iShare->new();

my $music_list = $self->get_stream_url('Karzz','video');

for my $one (@$music_list)
{
   print "Title : ",$one->{'title'},"\n";
   print "Url : ",$one->{'stream_url'},"\n";
   print "File ID : ",$one->{'file_id'},"\n";
   print "\n";
   $i++;
}

#### To download your song

#$self->download('513151','video');
