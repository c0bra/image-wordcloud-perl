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
use Math::PlanePath::TheodorusSpiral;
use Collision::2D qw(:all);

our $golden_ratio_conjugate = 0.618033988749895;

our $font_path = "./share/fonts/";

our $boring_word_dict_file = "./share/pos/part-of-speech.txt";
our $stop_word_dict_file = "./share/pos/stop_words.txt";

# GeosansLight.ttf
# GeosansLight-Oblique.ttf
# AveriaSerif-Bold.ttf
our @fonts = qw(
	AveriaSerif-Regular.ttf
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
	#my $gd = GD::Image->newTrueColor(800, 600); # Doing truecolor borks the background, it defaults to black.
	my $gd = GD::Image->new(800, 600);
	
	# Center coordinates of this iamge
	my $center_x = $gd->width  / 2;
	my $center_y = $gd->height / 2;
	
	my $gray  = $gd->colorAllocate(40, 40, 40); # background color
	my $white = $gd->colorAllocate(255, 255, 255);
	my $black = $gd->colorAllocate(0, 0, 0);
	
	#my $rand_colors = $self->_random_palette(count => 10);
	my @rand_colors = map { [$self->_hex2rgb($_)] } Color::Scheme->new
		->from_hue(rand(355))
		->scheme('analogic')
		->variation('default')
		->colors();

	my @palette = ();
	foreach my $c (@rand_colors) {
		my $newc = $gd->colorAllocate($c->[0], $c->[1], $c->[2]);
		push @palette, $newc;
	}
	
	# make the background transparent and interlaced  
	#$gd->transparent($white);
  $gd->interlaced('true');
	
	# Array of GD::Text::Align objects that we will move around and then draw
	my @texts = ();
	
	# Max font size in points (40% of image height)
	my $max_points = ($gd->height * 72 / 96) * .25;
	my $min_points = 8;
	
	# Scaling modifier for font sizes
	my $max_count = $self->{max_count};
	my $scaling = $max_points / $max_count;
	
	# For each word we have
	my @areas = ();
	#my @drawn_texts = ();
	my @bboxes = ();
	my $loop = 1;
	foreach my $word (sort { $self->{words}->{$b} <=> $self->{words}->{$a} } keys %{ $self->{words} } ) {
	#foreach my $word (keys %{ $self->{words} } ) {
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
		
		# ***TODO: font scaling needs to be based on word frequency, not loop iteration
		
		$size = $max_points if $size > $max_points;
		$size = $min_points if $size < $min_points;
		
		$text->set_font($font, $size);
		
		# Set the text to this word
		$text->set_text($word);
		
		push(@texts, $text);
		
		my ($w, $h) = $text->get('width', 'height');
		
		push(@areas, $w * $h);
		
		# Position to place the word in
		my ($x, $y);
		
		# Place the first word in the center of the screen
		if ($loop == 1) {
			$x = $center_x - ($w / 2);
			$y = $center_y + ($h / 4); # I haven't done the math see why dividing the height by 4 works, but it does
		}
		else {
			# Get a random place to draw the text
			#   1. The text is drawn starting at its lower left corner
			#	2. So we need to push the y value by the height of the text, but keep it less than the image height
			#   3. Keep a padding of 5px around the edges of the image
			#$y = $self->_random_int_between($h, $gd->height - 5);
			#$x = $self->_random_int_between(5,  $gd->width - $w - 5);
			
			# While this text collides with any of the other placed texts, 
			#   move it in an enlarging spiral around the image 
			
			# Start in the center
			#my $this_x = $gd->width / 2;
			#my $this_y = $gd->height / 2;
			
			# Make a spiral, TODO: probably need to somehow constrain or filter points that are generated outside the image dimensions
			my $path = Math::PlanePath::TheodorusSpiral->new;
			
			my ($this_x, $this_y) = $path->n_to_xy(1);
			$this_x += $center_x;
			$this_y += $center_y;
			
			my $collision = 1;
			my $col_iter = 1;
			while ($collision) {
				foreach my $b (@bboxes) {
					  # (x1,y1) lower left corner
				    # (x2,y2) lower right corner
					  # (x3,y3) upper right corner
				    # (x4,y4) upper left corner
				    
				    #my ($a_x1, $a_y1, $a_x2, $a_y2) = (@$b)[6, 7, 2, 3];
				    my ($a_x, $a_y, $a_w, $a_h) = @$b;
				    
				    #my ($b_x1, $b_y1, $b_x2, $b_y2) = ($this_x, $this_y + $text->get('height'), $this_x + $text->get('width'), $this_y);
				    #my ($b_x, $b_y) = ($this_x, $this_y); # Have to remove the height from the "y" coordinate because Collision::2D draws from the lower left
				    my ($b_x, $b_y, $b_x2, $b_y2) = ( $text->bounding_box($this_x, $this_y) )[6,7,2,3];
				    #my ($b_w, $b_h) = ($text->get('width'), $text->get('height'));
				    
				    #my @bb = $text->bounding_box($this_x, $this_y, 0);
				    my ($b_w, $b_h) = ($b_x2 - $b_x, $b_y2 - $b_y);
				    
				    use Data::Dumper;
				    #warn Dumper([ $a_x1, $a_y1, $a_x2, $a_y2, $b_x1, $b_y1, $b_x2, $b_y2 ]);
#				    warn Dumper({
#				    	 'A-x' => $a_x,
#				    	 'A-y' => $a_y,
#				    	 'A-w' => $a_w,
#				    	 'A-h' => $a_h,
#				    	 'B-x' => $b_x,
#				    	 'B-y' => $b_y,
#				    	 'B-w' => $b_w,
#				    	 'B-h' => $b_h
#				    });
				    
				    # Upper left to lower right
				    if ($self->_detect_collision2(
				    			$a_x, $a_y, $a_w, $a_h,
				    			$b_x, $b_y, $b_w, $b_h)) {
				    	
				    	$collision = 1;
				    	last;
				    }
				    else {
				    	$collision = 0;
				    }
				}
				last if $collision == 0;
				
				# TESTING:
				if ($col_iter % 10 == 0) {
					my $hue = $col_iter;
					while ($hue > 360) {
						$hue = $hue - 360;
					}
					
					my ($r,$g,$b) = $self->_hex2rgb( (Color::Scheme->new->from_hue($hue)->colors())[0] );
					my $c = $gd->colorAllocate($r,$g,$b);
					
					#$gd->filledRectangle($this_x, $this_y, $this_x + 10, $this_y + 10, $c);
					#$gd->string(gdGiantFont, $this_x, $this_y, $col_iter, $c);
					
					#$gd->setPixel($this_x, $this_y, $c);
					
					#my @bo = $text->bounding_box($this_x, $this_y, 0);
					#$self->_stroke_bbox($gd, $c, @bo);
				}
				
				$col_iter++;
				
				# Move text
				my $new_loc = 0;
				while (! $new_loc) {
					($this_x, $this_y) = map { int } $path->n_to_xy($col_iter * 100); # use 'int' because it returns fractional coordinates
					
					# ***Don't do this check right now
					$new_loc = 1;
					last;
					
					if ($this_x < 0 ||
							$this_y < 0) {
								
							#warn "New coordinates outside of image";
							$col_iter++;
							last if $col_iter > 1000;
							next;
					}
					else {
							$new_loc = 1;
					}
				}
				
				# Center the image
				#$this_x -= $text->get('width') / 2;
				#$this_y -= $text->get('height') / 2;
				
				# Center the spiral
				$this_x += $center_x;
				$this_y += $center_y;
				
				#last if $col_iter > 1000;
			}
			
			$x = $this_x;
			$y = $this_y;
		}
		
		my @bounding = $text->draw($x, $y, 0);
		#$gd->string(gdGiantFont, $x, $y, "here", $gd->colorClosest(255,0,0));
		#push(@drawn_texts, $text);
		
		#$self->_stroke_bbox($gd, undef, @bounding);
		
		#my @rect = ($bounding[6], $bounding[7], $text->get('width'), $text->get('height'));
		my @rect = ($bounding[6], $bounding[7], $bounding[2] - $bounding[6], $bounding[3] - $bounding[7]);
		
		#my @rect = ($bounding[0], $bounding[1], $bounding[0] + $bounding[4], $bounding[1] + $bounding[5]);
		
		push(@bboxes, \@rect);
		
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

# Convert a hexadecimal color to a list of rgb values
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

# Detect a collision between two rectangles
#	Returns 1 on a collision and 0 on a miss
sub _detect_collision {
	my $self = shift;
	
	my ($a_x1, $a_y1, $a_w, $a_h, $b_x1, $b_y1, $b_w, $b_h) = @_;
	
	#$a_x1 = $a_x1 - $a_w / 2;
	#$a_y1 = $a_y1 + $a_h / 2;
	#$b_x1 = $b_x1 - $b_w / 2;
	#$b_y1 = $b_y1 + $b_h / 2;
	
	my $rect1 = hash2rect({x => $a_x1, y => $a_y1, w => $a_w, h => $a_h});
	my $rect2 = hash2rect({x => $b_x1, y => $b_y1, w => $b_w, h => $b_h});
	
	return intersection($rect1, $rect2);
}
sub _detect_collision2 {
	my $self = shift;
	
	my ($a_x, $a_y, $a_w, $a_h, $b_x, $b_y, $b_w, $b_h) = @_;
	
#	if (($a_x < $b_x + $b_w) 
#			&& ($a_y < $b_y + $b_h) 
#			&& ($a_x + $a_w > $b_x) 
#			&& ($a_y + $a_h > $b_y)) {
#	    return 1;
#	}
	if (
		#(! ($b_x > $a_x + $a_w) || ($b_x + $b_w < $a_x) ) &&
		#(! ($b_y > $a_y + $a_h) || ($b_y + $b_h < $a_y) )) {
		!( ($b_x > $a_x + $a_w) || ($b_x + $b_w < $a_x) ||
		   ($b_y > $a_y + $a_h) || ($b_y + $b_h < $a_y) )) {
		
		return 1;
	}
	else {
		return 0;
	}
}

sub _stroke_bbox {
	my $self = shift;
	my $gd = shift;
	my $color = shift;
	
	my ($x1, $y1, $x2, $y2, $x3, $y3, $x4, $y4) = @_;
	
	$color ||= $gd->colorClosest(255,0,0);
	
	$gd->line($x1, $y1, $x2, $y2, $color);
	$gd->line($x2, $y2, $x3, $y3, $color);
	$gd->line($x3, $y3, $x4, $y4, $color);
	$gd->line($x4, $y4, $x1, $y1, $color);
}

sub _random_int_between {
	my $self = shift;
	my($min, $max) = @_;
	
	# Assumes that the two arguments are integers themselves!
	return $min if $min == $max;
	($min, $max) = ($max, $min) if $min > $max;
	return $min + int rand(1 + $max - $min);
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
