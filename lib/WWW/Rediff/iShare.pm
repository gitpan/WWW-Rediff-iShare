package WWW::Rediff::iShare;

use strict;

our $VERSION = '0.02';

use Data::Dumper; 
use WWW::Mechanize;
use HTML::TagParser;
use LWP::Simple;

use base qw(Exporter);
our @EXPORT = qw(
			new
			get_stream_url
			download
		);

sub new
{
	my ($class, %args) = @_;
	my $query_link = 'http://ishare.rediff.com';
	my $self = {
		base_url => $query_link,
		%args,
	};
	bless $self, $class or die "Can't bless $class: $!";
	return $self;
}

sub get_stream_url
{
	my ($self, $term, $type) = @_;
	
	my $base_url = $self->{'base_url'};
		$type = validate($type);
	
	$term =~ s/ /%20/g; # replacing non-breaking spaces with %20 in search term 
	#Check the number of record
	my $record_found = $self->count_records($term, $type);
	msg("$record_found Record Found");

	my $query_link = $base_url."/searchresult.php?query=$term&type=$type&tag=&page=1&perpage=150";
	my $mech       = WWW::Mechanize->new();
	$mech->get($query_link);

	my $page_contents = $mech->content();
	if ($page_contents =~ /0 results found/ig)
	{
		dienice('No entries found with your query !');
	}

	my @audio_music;
	my $html      = HTML::TagParser->new($page_contents);
	my @tag_lists = $html->getElementsByTagName("a");
	foreach my $each_tag (@tag_lists)
	{
		my $tagname = $each_tag->tagName;
		my $attr    = $each_tag->attributes;
		my $text    = $each_tag->innerText;
		foreach my $key (sort keys %$attr)
		{
			if ($attr->{'title'} =~ m/Add to collection/)
			{
				if ($key ne 'title')
				{
					my $link          = $attr->{$key};
					my $link_text     = substr($link, 25);
					$link_text =~ s/'//g;
					my @link_elements = split(/,/,$link_text);
					
					my $file_id       = $link_elements[0];
					my $title         = $link_elements[1];
					my $video_icon    = $link_elements[2];
					$title =~ s/%20%20//; # Replace %20%20 with spaces in search term
					$title =~ s/%20/-/g; # Replace %20 with - in search term
					
					my $stream_url =
						($type eq 'video')
						? $base_url . '/filevideo-' . $title . '-id-' . $file_id . '.php'
						: $base_url . 'filemusic.php?id=' . $file_id;
						
					my $download_url =
						($type eq 'video')
						? $base_url . 'embedplayer_config.php?content_id=' . $file_id
						: $base_url . 'embedaudio_config.php?audioid=' . $file_id;
						
					push @audio_music,
						{
						  stream_url => $stream_url,
						  file_id    => $file_id,
						  title      => $title,
						  video_icon => $video_icon
						};
				}
			}
		}
	}
	return \@audio_music;
}

sub download
{
	my ($self, $file_no, $type) = @_;
	
	my $base_url = $self->{'base_url'};
	$type = validate($type);

	my $download_url =
		($type eq 'video')
		? $base_url . '/embedplayer_config.php?content_id=' . $file_no
		: $base_url . '/embedaudio_config.php?audioid=' . $file_no;

	my $lookup_key = ($type eq 'video') ? 'video': 'track' ;

	getstore($download_url, $file_no . '.xml');
	my $filesize = -s "$file_no.xml";
	if ($filesize > 0)
	{
		open (FILE, $file_no . '.xml') or die "Can not open temp file !";
		my @config_file = <FILE>;
		close (FILE);
		
		my $config_data = join ('', @config_file);			
		unlink($file_no . '.xml');
	
		$config_data =~ /^.*?$lookup_key\s*path\s*=\s*["'](.*?)["']/xms;
		my $download_this_url = $1;

		$download_this_url eq ''
			? dienice ("Seems some problem ! can not download file") :
			  msg("Downloading... please wait...");
		
		getstore($download_this_url, $file_no.'.flv');
		msg("Download done : $file_no.flv ");
	}
	else
	{
		dienice('oops !! file id seems incorrect ..');
	}
}

sub count_records
{
	my ($self, $term, $type) = @_;
	my $base_url = $self->{'base_url'};
	$term =~ s/%20/ /; # Replace %20 with spaces in search term
	my $query_link = $base_url."/searchresult.php?query=$term&type=$type&tag=&page=1&perpage=150";
	my $mech      = WWW::Mechanize->new();
	$mech->get($query_link);
	my $search_result = $mech->content();

	my $result_found;
	if ($type eq 'music')
	{
		$search_result =~ m/Music \((\d+)\)/ig;
		$result_found = $1;
	}
	elsif ($type eq 'video')
	{
		$search_result =~ m/Video \((\d+)\)/ig;
		$result_found = $1;
	}
	return $result_found;
}

sub validate {
    my($type) = @_;
    $type =~ tr/[A-Z]/[a-z]/; # change to lowercase

    if($type && $type ne 'music' && $type ne 'video' && $type ne 'audio')
    {
	dienice('Not a valid music type');
    }
    if($type eq 'audio')
    {
	$type = 'music';
    }
    return $type;
}

sub dienice {
    my($msg) = @_;
    print "Error\t: $msg \n";
    exit;
}

sub msg {
    my($msg) = @_;
    print "Info\t: $msg \n";
    return;
}

=head1 NAME

WWW::Rediff::iShare - get ishare.rediff.com audio and video stream URL and download it to your system

=head1 SYNOPSIS
    
    ## Stream types are
    ## for audio : audio
    ## for video : video
    
    use WWW::Rediff::iShare;
    
    my $iShare      = WWW::Rediff::iShare->new();
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

    ## to download flv file
    $iShare->download('file_id','stream-type');

=head1 DESCRIPTION

Get Audio and Video Streaming url form Rediff iShare and download it.
Downloaded file is of extension .flv

=head1 SEE ALSO

L<WWW::Live365>, L<WWW::YouTube::VideoURI>, L<FLV::ToMP3>


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
