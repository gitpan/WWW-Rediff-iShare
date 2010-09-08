package WWW::Rediff::iShare;

use strict;

use vars qw( $VERSION );
$VERSION = "0.05";

use HTML::TagParser;
use LWP::Simple;
use URI::Encode;
use URI::Fetch;
use XML::Simple;
use Carp qw(cluck);
use String::Random;
use FLV::ToMP3;

sub new {
    my ( $class, %args ) = @_;
    my $query_link = 'http://ishare.rediff.com/';
    my $self       = {
        base_url => $query_link,
        %args,
    };
    bless $self, $class or Carp::croak "Can't bless $class: $!";
    return $self;
}

sub search {
    my ( $self, $term, $stream_type ) = @_;

    $stream_type = $self->_validate($stream_type);
    $self->{stream_type} = $stream_type;

    my $query_link  = $self->{'base_url'} . "$stream_type/$term";
    my $uri         = URI::Encode->new();
    my $encoded_url = $uri->encode($query_link);

    return $self->_get_result($encoded_url);
}

sub get_stream_url {
    my ( $self, $term, $stream_type ) = @_;
    return $self->search( $term, $stream_type );
}

sub _get_result {
    my ( $self, $url ) = @_;

    my $base_url    = $self->{'base_url'};
    my $stream_type = $self->{stream_type};

    my $html      = HTML::TagParser->new($url);
    my @tag_lists = $html->getElementsByTagName("a");

    my $results;
    my $result_found = 0;
    foreach my $each_tag (@tag_lists) {
        my $attr = $each_tag->attributes;
        foreach my $key ( sort keys %$attr ) {
            my $match_this = $base_url . $stream_type . "/";
            if ( $attr->{'href'} =~ m/$match_this/ ) {
                my $link = $attr->{'href'};
                $link =~ /.com\/.*\/.*\/(.*)\/(\d+)$/ig;
                my $title_id = $1;
                my $file_id  = $2;
                if ( !$results->{$file_id} ) {
                    $results->{$file_id} =
                      $self->_get_file_info( $file_id, $title_id )
                      if ( $file_id && $title_id );
                    $result_found = 1;
                }
            }
        }
    }
    if ($result_found) {
        my @result_arr =
          map { $results->{$_} } sort { $a <=> $b } keys %$results;
        return \@result_arr;
    }
    else {
        return "No result found";
    }
}

sub _get_file_info {
    my ( $self, $file_id, $title_id ) = @_;

    my $stream_url         = $self->_get_stream_url($file_id);
    my $stream_xml_url     = URI::Fetch->fetch($stream_url);
    my $stream_xml_content = $stream_xml_url->content();
    my $file_details;

    if ( $stream_xml_content !~ /XML Parsing Error|Servers are busy/ ) {

        my $xmlobj    = new XML::Simple;
        my $file_info = $xmlobj->XMLin($stream_xml_content);

        if ( $file_info->{video} ) {
            my $video_details = $file_info->{video};
            $title_id =~ s/-/ /ig;
            $file_details->{path}    = $video_details->{path};
            $file_details->{time}    = $video_details->{duration};
            $file_details->{comment} = ucfirst($title_id);
        }
        else {
            if ( !$title_id ) {
                foreach my $each_song ( keys %{ $file_info->{track} } ) {
                    if ( $file_info->{track}->{$each_song}->{link} =~
                        /$file_id/ )
                    {
                        $title_id = $each_song;
                    }
                }
            }
            $file_details = $file_info->{track}->{$title_id}
              if ( $file_info->{track}->{$title_id} );
        }
        $file_details->{file_id} = $file_id;
    }

    return $file_details;
}

sub _get_file_stream_type {
    my ( $self, $file_id ) = @_;
    my $rand_pattern = new String::Random;
    my $base_url     = $self->{'base_url'};

    my $file_web_url =
        $base_url 
      . "video/"
      . $rand_pattern->randpattern("cccc") . "/"
      . $rand_pattern->randpattern("cccc") . "/"
      . $file_id;

    my $file_url         = URI::Fetch->fetch($file_web_url);
    my $file_url_content = $file_url->content();
    my $stream_type      = 'music';

    if ( $file_url_content !~ /The video you want to view does not exist./ ) {
        $stream_type = 'video';
    }

    $self->{stream_type} = $stream_type;
    return $stream_type;
}

sub _get_stream_url {
    my ( $self, $file_id ) = @_;

    my $base_url    = $self->{'base_url'};
    my $stream_type = $self->_get_file_stream_type($file_id);

    return ( $stream_type eq 'video' )
      ? $base_url . "embedplayer_config_REST.php?content_id=$file_id&x=3"
      : $base_url . "audio_config_REST.php?audioid=$file_id&autoplay=true";
}

sub get_player_embedded_code {
    my ( $self, $file_id ) = @_;

    my $base_url    = $self->{'base_url'};
    my $stream_type = $self->_get_file_stream_type($file_id);

    my $player_type = ( $stream_type eq 'video' ) ? "splayer" : "aplayer";

    my $player_url_type = ( $stream_type eq 'video' ) ? "videoURL" : "audioURL";

    my $player_source =
      ( $stream_type eq 'video' )
      ? "http://ishare.rediff.com/images/svplayer_ad_20100212_2.swf"
      : "http://ishare.rediff.com/images/saplayer2101.swf";

    my $stream_url = $self->_get_stream_url($file_id);

    my $embedded_code = "
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

    return $embedded_code;

}

sub download {
    my ( $self, $file_id, $type ) = @_;

    my $file_info     = $self->_get_file_info($file_id);
    my $stream_type   = $self->{stream_type};
    my $download_path = $file_info->{path};

    print "Downloading file ... \n";
    getstore( $download_path, $file_id . '.flv' );

    if ( $stream_type ne 'video' ) {
        my $converter = FLV::ToMP3->new("$file_id.flv");
        print "Converting to MP3 ... \n";
        $converter->parse_flv("$file_id.flv");
        $converter->save("$file_id.mp3");
        unlink("$file_id.flv");
    }
    print "Downloading done ... \n";
}

sub _validate {
    my ( $self, $stream_type ) = @_;
    $stream_type =~ tr/[A-Z]/[a-z]/;
    if ( $stream_type !~ /music|video|audio/ig ) {
        Carp::croak "Not a valid stream type : $stream_type ";
    }
    $stream_type = 'music' if ( $stream_type eq 'audio' );
    return $stream_type;
}

1;

__END__

=head1 NAME

WWW::Rediff::iShare - get ishare.rediff.com audio and video stream URL and download it to your system

=head1 SYNOPSIS

    ## Stream types are
    ## for audio : audio
    ## for video : video
    
	use WWW::Rediff::iShare;
	use Data::Dumper;
	
	my $iShare = WWW::Rediff::iShare->new();
	my $stream_data = $iShare->search( '<SONG NAME>', '<STREAM TYPE>' );
	if ( ref($stream_data) eq 'ARRAY' ) {
		foreach my $song ( @{$stream_data} ) {
			print "Song Title    " . $song->{comment}, "\n";
			print "Song ID 	    " . $song->{file_id},  "\n";
			print "Download path " . $song->{path},    "\n";
		}
	}
	else {
		print $stream_data;
	}

    ## To Download song
    $iShare->download('<song id>');

    ## To Get HTML code to embedded this song to your webpage
    my $html_code = $iShare->get_player_embedded_code('<song id>');


=head1 DESCRIPTION

Get Audio and Video Streaming url form Rediff iShare and download it.
Audio file will be download as .MP3 and Video file will be download as .flv

The following functions are provided by this module:

=over 3

=item new()

Constructor.

=item search($song_name, $stream_type)

The search() function will search the given song based on specified stream type and return you and array of songs found.
It returns C<No result found> if it nothing found.  The $stream_type argument can
be either C<audio> or C<video> .

=item get_stream_url($song_name, $stream_type)

The search() function will search the given song based on specified stream type and return you and array of songs found.
It returns C<No result found> if it nothing found.  The $stream_type argument can
be either C<audio> or C<video> .

=item download($song_id)

Download the given song id. If the song stream is audio it download a mp3 file otherwise it will download .flv file.
Song id can get from Search function.

=item get_player_embedded_code($song_id)

This function will get you html code to embedded this song to you webpage.

=back

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


=head1 COPYRIGHT & LICENSE

Copyright 2008 Rakesh Kumar Shardiwal, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=head1 SEE ALSO

L<WWW::Live365>, L<WWW::YouTube::VideoURI>, L<FLV::ToMP3>


=cut
