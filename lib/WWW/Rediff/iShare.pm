package WWW::Rediff::iShare;

use strict;

our $VERSION = '0.01';

use Data::Dumper; 
use WWW::Mechanize;
use HTML::TagParser;
use LWP::Simple;

use base qw(Exporter);
our @EXPORT = qw(new get_stream_url download);

my $querylink;

sub new
{
	my ($class, %args) = @_;
	$querylink = 'http://ishare.rediff.com/';
	my $self = {
		iShare => $querylink,
		%args,
	};
	bless $self, $class or die "Can't bless $class: $!";
    return $self;
}

sub get_stream_url
{
	my ($self, $term, $type) = @_;
	my $baseurl = 'http://ishare.rediff.com/';
	   $term =~s/ /%20/g;
	   #Check the number of record
	my $record_found = $self->countRecords($term, $type);
	print "$record_found Record Found \n";
	
	my $queryLink = "http://ishare.rediff.com/searchresult.php?query=$term&type=$type&tag=&page=1&perpage=150";
	my $mech = WWW::Mechanize->new();
	   $mech->get( $queryLink);
	
	my $pagecontents = $mech->content();
	if ($pagecontents =~ /0 results found/ig) {
	    print Dumper('No entries found that match '.$term);
	    return 0;
	}
	
	my @audio_music;
	my $html = HTML::TagParser->new($pagecontents);
	my @list = $html->getElementsByTagName( "a" );
	foreach my $elem ( @list ) {
	    my $tagname = $elem->tagName;
	    my $attr = $elem->attributes;
	    my $text = $elem->innerText;
	    foreach my $key ( sort keys %$attr ) {
		if($attr->{'title'} =~ m/Add to collection/)
		 {
		     if($key ne 'title')
		     {
			 my $link = $attr->{$key};
			 my $text = substr($link,25);
			 my @array = split(/,/,$text);
			    $array[1] =~ s/%20%20//;
			    $array[1] =~ s/%20/ /g;
			 my $streamurl = ($type eq 'video')
					   ? $baseurl.'/filevideo-'.$array[1].' -id-'.$array[0].'.php' :
					     $baseurl.'filemusic.php?id='.$array[0];
			 my $downloadurl = ($type eq 'video')
					   ? $baseurl.'embedplayer_config.php?content_id='.$array[0] :
					     $baseurl.'embedaudio_config.php?audioid='.$array[0];			
			 push @audio_music, {
			     stream_url => $streamurl,
			     file_id   => $array[0],
			     title    => $array[1],
			     video_icon => "$array[2]"
			}
		     }
		 }
	    }
	}
	return \@audio_music;
}

sub download
{
	my ($self, $file_no, $type) = @_;
	my $baseurl = 'http://ishare.rediff.com/';
	if(!$type)
	{
		print Dumper("file type require");
		return 0;
	}
	else{
		my $downloadurl = ($type eq 'video')
			? $baseurl.'embedplayer_config.php?content_id='.$file_no :
			  $baseurl.'embedaudio_config.php?audioid='.$file_no;

		getstore($downloadurl, $file_no.'.xml');
		my $filesize = -s "$file_no.xml";
		if($filesize > 0)
		{
			open FILE ,$file_no.'.xml' or die "Can not open file !";
			while (<FILE>) {
				if($_ =~/video path/)
				{
					my $startpos = index $_,'<video path=';
					$_ = substr($_,$startpos);
					my $endpos = index $_,'.flv';
					my $content = substr($_,13,$endpos-9);
					print "Downloading... \n";
					unlink($file_no.'.xml');
					getstore($content, $file_no.'.flv');
					print "Download done : $file_no.flv \n"
				}
			}
		}
		else
		{
			print "oops !! file id seems incorrect ..\n";
			return 0;
		}
	}
}

sub countRecords
{
	my ($self, $term, $type) = @_;
	
	   $term =~s/%20/ /;
	my $queryLink = "http://ishare.rediff.com/searchresult.php?query=$term&type=$type&tag=&page=1&perpage=150";
	my $mech = WWW::Mechanize->new();
	   $mech->get( $queryLink);
	my $searchresult = $mech->content();
	
	my $resultfound ;
	if($type eq 'music')
	{
	    $searchresult =~m/Music \((\d+)\)/ig;
	    $resultfound = $1;
	}
	elsif ($type eq 'video')
	{
	    $searchresult =~m/Video \((\d+)\)/ig;
	    $resultfound = $1;
	}
	return $resultfound;
}

=head1 NAME

WWW::Rediff::iShare - get ishare.rediff.com audio and video stream URLs and download file

=head1 SYNOPSIS
    
    ## Stream types are
    ## for audio : music
    ## for video : video
    
    use WWW::Rediff::iShare;
    
    my $is       = WWW::Rediff::iShare->new();
    my @streamdata = $is->get_stream_url('movie song name','stream-type');
    if(scaler(@streamdata))
    {
	for my $a (@$streamdata)
	{
	   print "Title : ",$a->{'title'},"\n";
	   print "Url : ",$a->{'stream_url'},"\n";
	   print "file_id : ",$a->{'file_id},"\n";
	   print "\n";
	}
    }

## to download flv file

   $is->download('file_id','stream-type');

=head1 DESCRIPTION

Get Audio and Video Streaming url form Rediff iShare and download your favourite music.
I am really wondering how i wrote this module,
actually i used to listen songs from rediff iShare, some of the songs i like very much, but no way to download.
Now cheers....
i wrote this module.
you can search your favourite music or video
my @streamdata = $is->get_stream_url('movie song name','stream-type');
then get your favourite music id and download it
$self->download('music-id','stream-type');


=head1 SEE ALSO

L<WWW::Live365>, L<WWW::YouTube::VideoURI>


=head1 AUTHOR

Rakesh Kumar Shardiwal, C<< <shardiwal at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-www-rediff-ishare at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-Rediff-iShare>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WWW::Rediff::iShare


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-Rediff-iShare>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WWW-Rediff-iShare>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WWW-Rediff-iShare>

=item * Search CPAN

L<http://search.cpan.org/dist/WWW-Rediff-iShare/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2008 Rakesh Kumar Shardiwal, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of WWW::Rediff::iShare
