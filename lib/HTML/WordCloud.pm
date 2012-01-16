package HTML::WordCloud;

use 5.006;
use strict;
use warnings;

use Carp qw(carp croak confess);
use Params::Validate qw(:all);
use List::Util qw(sum);
use Data::Types qw(:int :float);
use Search::Dict;
use GD;
use GD::Text::Align;
use Color::Scheme;

our $golden_ratio_conjugate = 0.618033988749895;

our $font_path = "./share/fonts/";

our $boring_word_dict_file = "./share/pos/part-of-speech.txt";
our $stop_word_dict_file = "./share/pos/stop_words.txt";

#GeosansLight.ttf
#GeosansLight-Oblique.ttf
our @fonts = qw(
	AveriaSerif-Bold.ttf
);

=head1 NAME

HTML::WordCloud - The great new HTML::WordCloud!

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use HTML::WordCloud;

    my $wc = HTML::WordCloud->new();
    ...

=head1 SUBROUTINES/METHODS

=head2 new

=cut

sub new {
    my $proto = shift;

    my %opts = validate(@_, {
        word_count   => { type => SCALAR, optional => 1 },
        prune_boring => { type => SCALAR, optional => 1, default => 1 },
    });
    
    # ***TODO: Figure out how many words to use based on image size?
    $opts{word_count} ||= 30;

    my $class = ref( $proto ) || $proto;
    my $self = { #Will need to allow for params passed to constructor
			words        => {},
      word_count   => $opts{word_count},
      prune_boring => $opts{prune_boring},
    };
    bless($self, $class);

    return $self;
}

=head2 words(\%words_to_use)

Set up hashref \%words_to_use as the words we build the word cloud from.

Keys are the words, values are their count.

=cut

sub words {
	my $self = shift;
	
	my @opts = validate_pos(@_,
  	{ type => HASHREF | ARRAYREF, optional => 1 }, # \%words
  );
  
  # Return words if no argument is specified
  if (! $opts[0]) { return $self->{words}; }
  
  my %words = ();
  if (ref($opts[0]) eq 'HASH') {
  	%words = %{ $opts[0] };
	}
	elsif (ref($opts[0]) eq 'ARRAY') {
		foreach my $word(map { lc } @{ $opts[0] }) {
			$word =~ s/\W//o;
			$words{ $word }++;
		}
	}
  
  # Blank out the current word list;
  $self->{words} = {};
  
  $self->_prune_stop_words(\%words);
  
  # Sort the words by count and let N number of words through, based on $self->{word_count}
  my $word_count = 1;
  foreach my $word (map { lc } sort { $words{$b} <=> $words{$a} } keys %words) {
  	last if $word_count > $self->{word_count};
  	
  	my $count = $words{$word};
  	
  	if ($word_count == 1) {
  		$self->{max_count} = $count;
  	}
  	
  	# Add this word to our list of words
  	$self->{words}->{$word} = $count;
  	
  	push(@{ $self->{word_list} }, {
  		word  => $word,
  		count => $count
  	});
  	
  	$word_count++;
  }
}

=head2 cloud()

Make the word cloud! Returns an image file location

=cut

sub cloud {
	my $self = shift;
	
	# Remove boring words from our wordlist
	#$self->_prune_boring_words() if $self->{prune_boring};
	
	# Create the image object
	my $gd = GD::Image->newTrueColor(800, 600); # 1 = truecolor
	
	my $gray  = $gd->colorAllocate(20, 20, 20);
	my $white = $gd->colorAllocate(255, 255, 255);
	my $black = $gd->colorAllocate(0, 0, 0);
	
	#my $rand_colors = $self->_random_palette(count => 10);
	my @rand_colors = map { [$self->_hex2rgb($_)] } Color::Scheme->new
		->from_hue(rand(355))
		->scheme('analogic')
		->colors();

	my @palette = ();
	foreach my $c (@rand_colors) {
		my $newc = $gd->colorAllocate($c->[0], $c->[1], $c->[2]);
		push @palette, $newc;
	}
	
	# make the background transparent and interlaced  
	$gd->transparent($white);
  	$gd->interlaced('true');
	
	# Array of GD::Text::Align objects that we will move around and then draw
	my @texts = ();
	
	# Max font size in points (40% of image height)
	my $max_points = ($gd->height * 72 / 96) * .30;
	my $min_points = 8;
	
	# Scaling modifier for font sizes
	my $max_count = $self->{max_count};
	my $scaling = $max_points / $max_count;
	
	# For each word we have
	my @areas = ();
	my $loop = 1;
	foreach my $word (sort { $self->{words}->{$b} <=> $self->{words}->{$a} } keys %{ $self->{words} } ) {
		my $count = $self->{words}->{$word};
		
		my $text = new GD::Text::Align($gd);
		
		# Use a random color
		my $color = $palette[ rand @palette ];
		$text->set(color => $color);
		
		# Use a random font
		my $font = $font_path . $fonts[ rand @fonts ];
			unless (-f $font) { carp "Font file '$font' not found"; }
		
		#my $size = $count * $scaling;
		#my $size = ($loop / ($count / $max_count)) * $max_points;
		my $size = (1.75 / $loop) * $max_points;
		$size = $max_points if $size > $max_points;
		$size = $min_points if $size < $min_points;
		
		$text->set_font($font, $size);
		
		# Set the text to this word
		$text->set_text($word);
		
		push(@texts, $text);
		
		my ($w, $h) = $text->get('width', 'height');
		
		push(@areas, $w * $h);

		my $draw_x = $gd->width - $w;
		my $draw_y = $gd->height - $h;

		if ($loop == 1) {
			warn "W: $w - HL $h";
			warn "DX: $draw_x - DY: $draw_y";
			$draw_x = 0;
			$draw_y = 0;
			use Data::Dumper;
			warn Dumper($text->bounding_box(0, 0, 0));
		}
		
		my @bounding = $text->draw(rand $draw_x, rand $draw_y, 0);
		$loop++;
	}
	
	my $total_area = sum @areas;
	
	# Return the image as PNG content
	return $gd;
}

=head2 _random_palette($color_count, [$saturation, $value])

Generate C<$color_count> number of RGB colors. C<$color_count> must be an integer. C<$saturation> and C<$value> are optional floating point values from 0.0 to 1.0.
They default to 0.5 and 0.95 respectively.

Return value: C<\@colors>

=cut

# Stolen from: http://martin.ankerl.com/2009/12/09/how-to-create-random-colors-programmatically/
sub _random_palette {
	my $self = shift;
	
	my %opts = validate(@_, {
  	count			  => { type => SCALAR, optional => 0 },
  	saturation  => { type => SCALAR, optional => 1, default => 0.5 },
  	value       => { type => SCALAR, optional => 1, default => 0.95 },
  });
  
  croak "\$count ($opts{count}) not an integer" 												unless is_int($opts{count});
  croak "\$saturation ($opts{saturation}) not a floating point number"	unless is_float($opts{saturation});
  croak "\$value ($opts{value}) Not a floating point number"						unless is_float($opts{value});
	
	my $h = rand();
	
	my @colors = ();
	for (1 .. $opts{count}) {
		$h += $golden_ratio_conjugate;
  	$h %= 1;
  	
		my ($r, $g, $b) = $self->_hsv_to_rgb(rand(), $opts{saturation}, $opts{value});
		
		push (@colors, [$r, $g, $b]);
	}
	
	return \@colors;
}

# Convert HSV colors to RGB, in a pretty way
# Stolen from: http://martin.ankerl.com/2009/12/09/how-to-create-random-colors-programmatically/
sub _hsv_to_rgb {
	my $self = shift;
	
	my ($h, $s, $v) = @_;
	
	my $h_i = int($h * 6);
	my $f = $h * 6 - $h_i;
	my $p = $v * (1 - $s);
	my $q = $v * (1 - $f * $s);
	my $t = $v * (1 - (1 - $f) * $s);
	
	my ($r, $g, $b);
	
	($r, $g, $b) = ($v, $t, $p) if $h_i == 0;
	($r, $g, $b) = ($q, $v, $p) if $h_i == 1;
	($r, $g, $b) = ($p, $v, $t) if $h_i == 2;
	($r, $g, $b) = ($p, $q, $v) if $h_i == 3;
	($r, $g, $b) = ($t, $p, $v) if $h_i == 4;
	($r, $g, $b) = ($v, $p, $q) if $h_i == 5;
	
	return (
		int($r * 256),
		int($g * 256),
		int($b * 256)
	);
}

sub _hex2rgb {
	my $self = shift;
	my $hex = shift;

	my @rgb = map {hex($_) } unpack 'a2a2a2', $hex;
	return @rgb;
}

# Remove "boring" words from a word list
sub _prune_boring_words {
	my $self = shift;
	
	my @opts = validate_pos(@_, { type => HASHREF, optional => 1 });
	
	if (! -f $boring_word_dict_file) {
		carp "Boring word file '$boring_word_dict_file' not found, not pruning any words";
		return;
	}
	
	# Either use the words supplied to the subroutine or use what we have in the object
	my $words = {};
	if ($opts[0]) {
		$words = $opts[0];
	}
	else {
		$words = $self->{words};
	}
	
	# Open "boring" word dictionary
	open(my $dict, '<', $boring_word_dict_file);
	
	foreach my $word (keys %$words) {
		# Search for the word in the dict file
		#look $dict, $word, 0, 1;
		look $dict, $word, {
			dict => 0,
			fold => 1,
			cmp => sub {
				($a eq $b) ? 0 : 1;
			}
		};
		
		my $found = <$dict>;
		chomp $found; # strip newline
		
		#print "LOOK: '$word' <-> FOUND: '$found'\n";
		
		# If we found a word and it's equal to our word
		if (defined $found && $found) {
			# Strip off the parts of speech bit at the end of the line and capture it
			$found =~ s/\s(.+)$//;
			my ($parts_of_speech) = $1;
			
			$parts_of_speech =~ s/\|//; # strip pipes
			
			$found =~ s/\s*$//; # trim trailing whitespace
			#$found = lc($found); # lower-case the found word, sometimes the first letter is upper (dunno why)
			
			# Turn the parts of speech into a hash
			#my %parts = map { $_ => 1 } split('', $parts_of_speech);
			
			# Skip if we didn't actually find the word
			next if (lc($word) ne lc($found));
			
			#print "WORD: $word : $parts_of_speech\n";
			
			# If this word is a definite article (D), or indefinite article (I), remove it
			#if (exists $parts{'D'} || exists $parts{I}) {
			if ($parts_of_speech =~ /[DI]/o) {
				delete $words->{$word};
			}
		}
	}
}

sub _prune_stop_words {
	my $self = shift;
	
	my @opts = validate_pos(@_, { type => HASHREF, optional => 1 });
	
	if (! -f $stop_word_dict_file) {
		carp "Stop word file '$stop_word_dict_file' not found, not pruning any words";
		return;
	}
	
	# Either use the words supplied to the subroutine or use what we have in the object
	my $words = {};
	if ($opts[0]) {
		$words = $opts[0];
	}
	else {
		$words = $self->{words};
	}
	
	# Open "boring" word dictionary
	open(my $dict, '<', $stop_word_dict_file);
	
	foreach my $word (keys %$words) {
		# Search for the word in the dict file
		#look $dict, $word, 0, 1;
		look $dict, $word, {
			dict => 0,
			fold => 1,
		};
		
		my $found = <$dict>;
		
		# If we found a word and it's equal to our word
		if (defined $found && $found) {
			chomp $found; # strip newline
			next if $found ne $word;
			
			#warn "LOOK: '$word' <-> FOUND: '$found'\n";
			
			# Strip off the parts of speech bit at the end of the line and capture it
			#$found =~ s/\s(.+)$//;
			
			#$found =~ s/\s*$//; # trim trailing whitespace
			
			# Skip if we didn't actually find the word
			#next if (lc($word) ne lc($found));
			
			delete $words->{$word};
		}
	}
}

=head1 AUTHOR

Brian Hann, C<< <brian.hann at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-html-wordcloud at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=HTML-WordCloud>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc HTML::WordCloud


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=HTML-WordCloud>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/HTML-WordCloud>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/HTML-WordCloud>

=item * Search CPAN

L<http://search.cpan.org/dist/HTML-WordCloud/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2012 Brian Hann.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of HTML::WordCloud
