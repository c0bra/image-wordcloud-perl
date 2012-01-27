package Image::WordCloud;

use 5.008;

use strict;
use warnings;

use Image::WordCloud::StopWords::EN qw(%STOP_WORDS);
use Carp qw(carp croak confess);
use Params::Validate qw(:all);
use List::Util qw(sum shuffle);
use Data::Types qw(:int :float);
use File::Spec;
use File::ShareDir qw(:ALL);
use File::Find::Rule;
use GD;
use GD::Text::Align;
use Color::Scheme;
use Math::PlanePath::TheodorusSpiral;

our $golden_ratio_conjugate = 0.618033988749895;

our $stop_word_dict_file = "./share/pos/stop_words.txt";

=head1 NAME

Image::WordCloud - Create word cloud images

=head1 VERSION

Version 0.01_01

=cut

our $VERSION = '0.01_01';


=head1 SYNOPSIS

Create "word cloud" images out of a set of specified words. Font size indicates the frequency with which a word is used. Colors are generated randomly. Fonts can be
specified or chosen randomly.

Perhaps a little code snippet.

    use Image::WordCloud;

    my $wc = Image::WordCloud->new();
    
    # Add the Gettysburg Address
    $wc->words([qw/
    		Four score and seven years ago our fathers brought forth on this continent a new nation conceived in Liberty and dedicated to the proposition that all men are created equal
				Now we are engaged in a great civil war testing whether that nation or any nation so conceived and so dedicated can long endure We are met on a great battle field of that
				war We have come to dedicate a portion of that field as a final resting place for those who here gave their lives that that nation might live It is altogether fitting and
				proper that we should do this But in a larger sense we can not dedicate—we can not consecrate—we can not hallow—this ground The brave men living and dead who struggled
				here have consecrated it far above our poor power to add or detract The world will little note nor long remember what we say here but it can never forget what they did here
				It is for us the living rather to be dedicated here to the unfinished work which they who fought here have thus far so nobly advanced It is rather for us to be here dedicated
				to the great task remaining before us—that from these honored dead we take increased devotion to that cause for which they here gave the last full measure of devotion—that we
				here highly resolve that these dead shall not have died in vain—that this nation under God shall have a new birth of freedom—and that government of the people by the people
				for the people shall not perish from the earth
		/]);
		
		# Create the word cloud as a GD image
		my $gd = $wc->cloud();
		
		open(my $fh, '>', 'gettysburg.png');
			binmode $fh;
			print $fh $gd->png();
		close($fh);
		
		# See examples/gettysburg.png for how the created image looks. script/gettysburg.pl will create it

=head1 SUBROUTINES/METHODS

=head2 new()

=cut

sub new {
    my $proto = shift;
		
    my %opts = validate(@_, {
    	  image_size     => { type => ARRAYREF | UNDEF, optional => 1, default => [400, 400] },
        word_count     => { type => SCALAR | UNDEF,   optional => 1 },
        prune_boring   => { type => SCALAR | UNDEF,   optional => 1, default => 1 },
        font           => { type => SCALAR | UNDEF,   optional => 1 },
        font_file      => { type => SCALAR | UNDEF,   optional => 1 },
        font_path      => { type => SCALAR | UNDEF,   optional => 1 },
        stop_word_file => { type => SCALAR | UNDEF,   optional => 1, default => $stop_word_dict_file },
        background     => { type => ARRAYREF,         optional => 1, default => [40, 40, 40] },
    });
    
    # ***TODO: Figure out how many words to use based on image size?
    $opts{'word_count'} ||= 70;
    
    # If a stop word file is specified, make sure it exists
		if ($opts{'stop_word_file'}) {
			unless (-f $opts{'stop_word_file'}) {
				carp sprintf "Stop word file '%s' not found", $opts{'stop_word_file'};
			}
		}
		
		# Make sure the font file exists if it is specified
		if ($opts{'font_file'}) {
			unless (-f $opts{'font_file'}) {
				carp sprintf "Font file '%s' not found", $opts{'font_file'};
			}
		}
		
		# Make sure the font path exists if it is specified
		if ($opts{'font_path'}) {
			unless (-d $opts{'font_path'}) {
				carp sprintf "Specified font path '%s' not found", $opts{'font_path'};
			}
		}
		# Otherwise, find the font path with File::ShareDir
		else {
			my $font_path;
			eval {
				$font_path = File::Spec->catdir(dist_dir('Image-WordCloud'), "fonts");
			};
			if ($@) {
				#carp "Font path for dist 'Image-WordCloud' could not be found";
			}
			else {
				$opts{'font_path'} = $font_path;
			}
		}
		
		# If we still haven't found a font path, try using ./share/fonts
		if (! $opts{'font_path'}) {
			my $local_font_path = File::Spec->catdir(".", "share", "fonts");
			unless (-d $local_font_path) {
				#carp sprintf "Local font path '%s' not found", $local_font_path;
			}
			
			$opts{'font_path'} = $local_font_path;
		}
		
    my $class = ref( $proto ) || $proto;
    my $self = { #Will need to allow for params passed to constructor
			words          => {},
			image_size     => $opts{'image_size'},
      word_count     => $opts{'word_count'},
      prune_boring   => $opts{'prune_boring'},
      font           => $opts{'font'}      || "",
      font_path      => $opts{'font_path'} || "",
      font_file      => $opts{'font_file'} || "",
      stop_word_file => $opts{'stop_word_file'},
      background		 => $opts{'background'},
    };
    bless($self, $class);
    
    # Make sure we have a usable font file or font path
		unless (-f $self->{'font_file'} || -d $self->{'font_path'}) {
			carp sprintf "No usable font path or font file found, only fonts available will be from libgd, which suck";
		}
		# If a font_file is specified, use that as the only font
		elsif (-f $self->{'font_file'}) {
			$self->{fonts} = $self->{'font_file'};
		}
		# Otherwise if no font_file was specified and we have a font path, read in all the fonts from font_path
		elsif (! -f $self->{'font_file'} && -d $self->{'font_path'}) {
				my @fonts = File::Find::Rule->new()
					->extras({ untaint => 1})
					->file()
					->name('*.ttf')
					->in( $self->{'font_path'} );
			$self->{fonts} = \@fonts;
		}

    return $self;
}

# Get a file from the dist share location
sub _get_dist_file_option {
	my ($opts, $option, $file) = @_;
	
	return;
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
  
  $self->_prune_stop_words(\%words) if $self->{prune_boring};
  
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
  
  return $self;
}

=head2 cloud()

Make the word cloud. Returns a L<GD> image object

=cut

sub cloud {
	my $self = shift;
	
	# Set the font path for GD::Text::* objects, if we have one to use
	if (-d $self->{'font_path'}) {
		GD::Text->font_path( $self->{'font_path'} );
	}
	
	# Create the image object 
	my $gd = GD::Image->new($self->{image_size}->[0], $self->{image_size}->[1]); # Adding the 3rd argument (for truecolor) borks the background, it defaults to black.
	
	# Center coordinates of this iamge
	my $center_x = $gd->width  / 2;
	my $center_y = $gd->height / 2;
	
	my $gray  = $gd->colorAllocate( @{$self->{background}}[0,1,2] ); # Background color, gray
	my $white = $gd->colorAllocate(255, 255, 255);
	my $black = $gd->colorAllocate(0, 0, 0);
	
	my @rand_colors = $self->_random_colors();

	my @palette = ();
	foreach my $c (@rand_colors) {
		my $newc = $gd->colorAllocate($c->[0], $c->[1], $c->[2]);
		push @palette, $newc;
	}
	
	# make the background interlaced  
  $gd->interlaced('true');
	
	# Array of GD::Text::Align objects that we will move around and then draw
	my @texts = ();
	
	# Max font size in points (25% of image height)
	my $max_points = ($gd->height * 72 / 96) * .25; # Convert height in pixels to points, then take 25% of that number
	my $min_points = ($gd->height * 72 / 96) * 0.0175; # 0.02625; 
	
	# Scaling modifier for font sizes
	my $max_count = $self->{max_count};
	my $scaling = $max_points / $max_count;
	
	# For each word we have
	my @areas = ();
	#my @drawn_texts = ();
	my @bboxes = ();
	my $loop = 1;
	
	my @word_keys = sort { $self->{words}->{$b} <=> $self->{words}->{$a} } keys %{ $self->{words} };
	
	# Get the font size for each word using the Fibonacci sequence
#	my %word_sizes = ();
#	my $sloop = 0;
#	my $fib_counter = 1;
#	my $cur_size;
#	foreach my $word (@word_keys) {
#		if ($sloop == 0) {
#			my $term = Math::Fibonacci::term($fib_counter);
#			
#			$cur_size = (1 / $fib_counter * $max_points);
#			
#			$sloop = $term;
#			
#			$fib_counter++;
#		}
#		
#		$word_sizes{ $word } = $cur_size;
#		
#		$sloop--;
#	}
	my $sloop = 0;
	my %word_sizes = map { $sloop++; $_ => (1.75 / $sloop * $max_points) } @word_keys;
	
	foreach my $word ( shift @word_keys, shuffle @word_keys ) {
		my $count = $self->{words}->{$word};
		
		my $text = GD::Text::Align->new($gd);
		
		# Use a random color
		my $color = $palette[ rand @palette ];
		$text->set(color => $color);
		
		# Either use the specified font file...
		my $font = "";
		if ($self->{'font_file'}) {
			$font = $self->{'font_file'};
		}
		# Or the specified font
		elsif ($self->{'font'} && -d $self->{'font_path'}) {
			$font = $self->{'font'};
		}
		# ...or use a random font
		elsif (scalar @{$self->{'fonts'}} > 0) {
			$font = $self->{'fonts'}->[ rand @{$self->{'fonts'}} ];
				unless (-f $font) { carp "Font file '$font' not found"; }
		}
		
		my $size = $word_sizes{ $word };
		
		#my $size = $count * $scaling;
		#my $size = (1.75 / $loop) * $max_points;
		
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
			
			# Move the image center around a little
			$x += $self->_random_int_between($gd->width * .1 * -1, $gd->width * .1 );
			$y += $self->_random_int_between($gd->height * .1 * -1, $gd->height * .1);
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
			
			# Get the initial starting point
			my ($rand_bound_w, $rand_bound_h) = @{$bboxes[0]}[2,3];
			#my ($this_x, $this_y) = $path->n_to_xy(1);
			my ($this_x, $this_y) = $self->_new_coordinates($gd, $path, 1, $rand_bound_w, $rand_bound_h);
			
			# Put the spiral in the center of the image
			#$this_x += $center_x;
		  #$this_y += $center_y;
			
			my $collision = 1;
			my $col_iter = 1;
			while ($collision) {
				# New text's coords and width/height
				# (x1,y1) lower left corner
		    # (x2,y2) lower right corner
			  # (x3,y3) upper right corner
		    # (x4,y4) upper left corner
				my ($b_x, $b_y, $b_x2, $b_y2) = ( $text->bounding_box($this_x, $this_y) )[6,7,2,3];
				my ($b_w, $b_h) = ($b_x2 - $b_x, $b_y2 - $b_y);
				
				foreach my $b (@bboxes) {
				    my ($a_x, $a_y, $a_w, $a_h) = @$b;
				    
				    # Upper left to lower right
				    if ($self->_detect_collision(
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
					
					#my ($r,$g,$b) = $self->_hex2rgb( (Color::Scheme->new->from_hue($hue)->colors())[0] );
					#my $c = $gd->colorAllocate($r,$g,$b);
					
					#$gd->filledRectangle($this_x, $this_y, $this_x + 10, $this_y + 10, $c);
					#$gd->string(gdGiantFont, $this_x, $this_y, $col_iter, $c);
					
					#$gd->setPixel($this_x, $this_y, $c);
					
					#my @bo = $text->bounding_box($this_x, $this_y, 0);
					#$self->_stroke_bbox($gd, $c, @bo);
				}
				
				$col_iter++;
				
				# Move text
				my $new_loc  = 0;
				while (! $new_loc) {
					($this_x, $this_y) = $self->_new_coordinates($gd, $path, $col_iter, $rand_bound_w, $rand_bound_h);
					
					# ***Don't do this check right now
					#$new_loc = 1;
					#last;
					
					my ($newx, $newy, $newx2, $newy2) = ( $text->bounding_box($this_x, $this_y) )[6,7,2,3];
					
					if ($newx < 0 || $newx2 > $gd->width ||
							$newy < 0 || $newy2 > $gd->height) {
								
							#carp sprintf "New coordinates outside of image: (%s, %s), (%s, %s)", $newx, $newy, $newx2, $newy2;
							$col_iter++;
							last if $col_iter > 10_000;
					}
					else {
							$new_loc = 1;
					}
				}
				
				# Center the image
				#$this_x -= $text->get('width') / 2;
				#$this_y -= $text->get('height') / 2;
				
				# Center the spiral
				#if (! $centered) {
				#	$this_x += $center_x;
				#	$this_y += $center_y;
				#}
			}
			
			$x = $this_x;
			$y = $this_y;
		}
		
		my @bounding = $text->draw($x, $y, 0);		
		#$self->_stroke_bbox($gd, undef, @bounding);
		
		my @rect = ($bounding[6], $bounding[7], $bounding[2] - $bounding[6], $bounding[3] - $bounding[7]);
		push(@bboxes, \@rect);
		
		$loop++;
	}
	
	my $total_area = sum @areas;
	
	# Return the image as PNG content
	return $gd;
}

# Return new coordinates ($x, $y) that are no more than $bound_x or $bound_y digits away from the center of GD image $gd
sub _new_coordinates {
	my $self = shift;
	
	my ($gd, $path, $iteration, $bound_x, $bound_y) = @_;
	
	my ($x, $y) = map { int } $path->n_to_xy($iteration * 100); # use 'int' because it returns fractional coordinates
					
	# Move the center of this word within 50% of the area of the first word's bounding box
	$x += $self->_random_int_between($bound_x * -1 * .25, $bound_x * .25);
	$y += $self->_random_int_between($bound_y * -1 * .25, $bound_y * .25);
					
	$x += $gd->width / 2;
	$y += $gd->height / 2;
	
	return ($x, $y);
}

sub _exp2 {
	my $n = shift;
	return exp($n) / exp(2);
}

sub _log2 {
	my $n = shift;
	return log($n) / log(2);
}

sub _normalize_num {
	my $self = shift;
	my ($num, $max, $min) = @_;
	
	return ($num - $min) / ($max - $min);
}

# Return a list of random colors as an array of RGB arrayrefs
# ( [25,30,60], [2,204,300] ), etc.
sub _random_colors {
	my $self = shift;
	
	my %opts = validate(@_, {
    	  hue       => { type => SCALAR, optional => 1, default => rand(359)  },
    	  scheme    => { type => SCALAR, optional => 1, default => 'analogic' },
    	  variation => { type => SCALAR, optional => 1, default => 'default'  },
  });
	
	my @rand_colors = map { [$self->_hex2rgb($_)] } Color::Scheme->new
		->from_hue( $opts{'hue'} )
		->scheme( $opts{'scheme'} )
		->variation( $opts{'variation'} )
		->colors();
		
	return @rand_colors;
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

sub _prune_stop_words {
	my $self = shift;
	
	my @opts = validate_pos(@_, { type => HASHREF, optional => 1 });
	
	# Either use the words supplied to the subroutine or use what we have in the object
	my $words = {};
	if ($opts[0]) {
		$words = $opts[0];
	}
	else {
		$words = $self->{words};
	}
	
	# Read in the stop word file if we haven't already
	#if (! $self->{read_stop_file}) { $self->_read_stop_file(); }
	
	foreach my $word (keys %$words) {
			#delete $words->{$word} if exists $self->{stop_words}->{ $word };
			#delete $words->{$word} if exists $STOP_WORDS{ $word };
			delete $words->{$word} if exists $STOP_WORDS{ $word };
	}
	
	return 1;
}

sub _read_stop_file {
	my $self = shift;
	
	my $stop_word_file = $self->{'stop_word_file'};
	if (! -f $stop_word_file) {
		carp "Stop word file '$stop_word_file' not found, not pruning any words";
		return;
	}
	
	#$self->{stop_words} = {};
	
	open(my $dict, '<', $stop_word_file);
	while (my $line = <$dict>) {
		chomp $line;
		$self->{stop_words}->{ $line } = 1;
	}
	close($dict);
	
	$self->{'read_stop_file'} = 1;
	
	return 1;
}

=head2 add_stop_words(@words)

Add new stop words onto the list. Automatically puts words in lowercase.

=cut

sub add_stop_words {
	my $self = shift;
	my @words = @_;
	
	foreach my $word (@words) {
		$self->{stop_words}->{ lc($word) } = 1;
	}
		
	return $self;
}

# Detect a collision between two rectangles
sub _detect_collision {
	my $self = shift;
	
	my ($a_x, $a_y, $a_w, $a_h,
			$b_x, $b_y, $b_w, $b_h) = @_;
	
	if (
		!( ($b_x > $a_x + $a_w) || ($b_x + $b_w < $a_x) ||
		   ($b_y > $a_y + $a_h) || ($b_y + $b_h < $a_y) )) {
		
		return 1;
	}
	else {
		return 0;
	}
}

# Stroke the outline of a bounding box
sub _stroke_bbox {
	my $self  = shift;
	my $gd    = shift;
	my $color = shift;
	
	my ($x1, $y1, $x2, $y2, $x3, $y3, $x4, $y4) = @_;
	
	$color ||= $gd->colorClosest(255,0,0);
	
	$gd->line($x1, $y1, $x2, $y2, $color);
	$gd->line($x2, $y2, $x3, $y3, $color);
	$gd->line($x3, $y3, $x4, $y4, $color);
	$gd->line($x4, $y4, $x1, $y1, $color);
}

# Return a random ingeger between two numbers
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
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Image-WordCloud>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Image::WordCloud


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Image-WordCloud>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Image-WordCloud>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Image-WordCloud>

=item * Search CPAN

L<http://search.cpan.org/dist/Image-WordCloud/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2012 Brian Hann.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Image::WordCloud
