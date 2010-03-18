package WWW::Rediff::iShare;

use strict;

our $VERSION = '0.03';

use Data::Dumper; 
use WWW::Mechanize;
use HTML::TagParser;
use LWP::Simple;

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
		   print Dumper$a;
		}
    }

    ## to download flv file
    $iShare->download('file_id','stream-type');


Output would be like this :
$VAR1 = {
          'stream_url' => 'http://ishare.rediff.com/audio_config_REST.php?audioid=10052411&autoplay=true',
          'video_icon' => 'http://datastore.rediff.com/briefcase/666659675F5C6B27636E645E7064/SHFC_1-2557-11.mp3-0001.png',
          'embedded_code' => '
				<embed
						width="100%"
						height="322"
						wmode="transparent"
						type=\'"application/x-shockwave-flash"
						allowfullscreen="true"
						allowscriptaccess="always"
						name="aplayer"
						flashvars="audioURL=http://ishare.rediff.com/audio_config_REST.php?audioid=10052411&autoplay=true"
						src="http://ishare.rediff.com/images/saplayer2101.swf"/>',
          'download_path' => 'http://datastore.rediff.com/briefcase/666659675F5C6B27636E645E7064/SHFC_1-2557-11.mp3.flv',
          'title' => 'Tu Hi Mera Jaanam Jani Tu Hi Mera Pranam',
          'file_id' => '10052411'
        };

=head2
	my $iShare      = WWW::Rediff::iShare->new();
=cut
sub new
{
	my ($class, %args) = @_;
	my $query_link = 'http://ishare.rediff.com/';
	my $self = {
		base_url => $query_link,
		%args,
	};
	bless $self, $class or die "Can't bless $class: $!";
	return $self;
}

=head2
    my $stream_data = $iShare->get_stream_url('song title','stream_type');
=cut
sub get_stream_url
{
	my ($self, $term, $type) = @_;
	
	my $base_url = $self->{'base_url'};
		$type = validate($type);
	
	$term =~ s/ /%20/g;

	my $query_link = $base_url."$type/$term";
	my $mech       = WWW::Mechanize->new();
	$mech->get($query_link);

	my $page_contents = $mech->content();

	my $audio_music;
	my $html      = HTML::TagParser->new($page_contents);
	my @tag_lists = $html->getElementsByTagName("a");
	foreach my $each_tag (@tag_lists)
	{
		my $tagname = $each_tag->tagName;
		my $attr    = $each_tag->attributes;
		my $text    = $each_tag->innerText;
		foreach my $key (sort keys %$attr)
		{
			my $checkthis = $base_url.$type."/";
			if ($attr->{'href'} =~ m/$checkthis/)
			{
				my $link 	= $attr->{'href'};
				my $title 	= $attr->{'title'};
				$link =~/\/(\d+)$/ig;
				my $file_id = $1;

				my $stream_url =
					($type eq 'video')
					? $base_url."embedplayer_config_REST.php?content_id=$file_id&x=3"
					: $base_url."audio_config_REST.php?audioid=$file_id&autoplay=true";

				my $player_type = ($type eq 'video') ? "splayer": "aplayer";
				my $player_url_type = ($type eq 'video') ? "videoURL": "audioURL";
				my $player_source =
					($type eq 'video')
					? "http://ishare.rediff.com/images/svplayer_ad_20100212_2.swf" :
					"http://ishare.rediff.com/images/saplayer2101.swf";
			
				my $player_html = "
						<embed
							width=\"100%\"
							height=\"322\"
							wmode=\"transparent\"
							type='\"application/x-shockwave-flash\"
							allowfullscreen=\"true\"
							allowscriptaccess=\"always\"
							name=\"$player_type\"
							flashvars=\"$player_url_type=$stream_url\"
							src=\"$player_source\"/>";

				my $file_contents = get($stream_url);
					$file_contents =~  /<(video|track) path=?'(.*.flv)'/ig;

				my $download_path = $2;
				my $video_thumbnail_path = $download_path;
					$video_thumbnail_path =~s/.flv/-0001.png/;

				push @$audio_music,
				{
					stream_url => $stream_url,
					file_id    => $file_id,
					title      => $title,
					video_icon => $video_thumbnail_path,
					download_path => $download_path,
					embedded_code => $player_html,
				}if($file_id && $title);
			}
		}
	}
	return $audio_music;
}

=head2
=cut
sub download
{
	my ($self, $file_id, $type) = @_;
	
	my $base_url = $self->{'base_url'};
	$type = validate($type);

	my $download_url =
		($type eq 'video')
		? $base_url."embedplayer_config_REST.php?content_id=$file_id&x=3"
		: $base_url."audio_config_REST.php?audioid=$file_id&autoplay=true";

	my $file_contents = get($download_url);
		$file_contents =~  /<(video|track) path=?'(.*.flv)'/ig;
	my $download_path = $2;

	if ($download_path)
	{
	    msg("Downloading... please wait...");
		getstore($download_path, $file_id.'.flv');
		msg("Download done : $file_id.flv ");
	}
	else
	{
		dienice('oops !! file id seems incorrect ..');
	}
}

=head2
=cut
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

=head2
=cut
sub dienice {
    my($msg) = @_;
    print "Error\t: $msg \n";
    exit;
}

=head2
=cut
sub msg {
    my($msg) = @_;
    print "Info\t: $msg \n";
    return;
}



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
