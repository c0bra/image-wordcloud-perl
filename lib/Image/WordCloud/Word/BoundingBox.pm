package Image::WordCloud::Word::BoundingBox;

use namespace::autoclean;
use Moose;
use Image::WordCloud qw(PosInt Color);
use Image::WordCloud::Word;
use GD;
#use Random::PoissonDisc;
use Data::GUID;

use constant MIN_BOX_SIZE => 144;

our $getpixels = 0;

#===============#
# Inner Objects #
#===============#

has 'word' => (
	is  => 'ro',
	isa => 'Image::WordCloud::Word',
	required => 1,
);

# Utility GD object for testing
has 'gd' => (
	isa => 'GD::Image',
	is  => 'ro',
	required => 1,
	init_arg => undef,
	builder  => '_build_gd',
);
sub _build_gd {
	my $self = shift;
	return GD::Image->new(10, 10, 1);
}

#==============#
# Bounding box #
#==============#

has '_box' => (
	isa => 'ArrayRef',
	is  => 'rw',
	init_arg => undef,
);

# Return the bounding boxes for this image, generating them if necessary
sub box {
	my $self  = shift;
	
	if ($self->_box) {
		return $self->_box;
	}
	else {
		my $boxes = $self->_generate_boxes();
		$self->_box($boxes);
		
		return $self->_box;
	}
}

sub _area {
	my $self = shift;
	
	return $self->gd->width * $self->gd->height;
}

sub _min_box_size {
	my $self = shift;
	
	my $min = $self->_area * .0025;
	$min = MIN_BOX_SIZE if $min < MIN_BOX_SIZE;
	
	return $min;
}

#=========================#
# Dimensions and Position #
#=========================#

# NOTE: GD::Text::Align's boundingbox() method returns 8 elements:
#   (x1,y1) lower left corner
#   (x2,y2) lower right corner
#   (x3,y3) upper right corner
#   (x4,y4) upper left corner

sub width  {
	my $self = shift;
	
	#return $self->word->width();
	
	return $self->coordinate_distance(
		$self->topleft, $self->topright
	);
}

sub height {
	my $self = shift;
	
	#return $self->word->height();
	
	return $self->coordinate_distance(
		$self->topleft, $self->bottomleft
	);
}

sub bottomleft {
	my $self = shift;
	
	return ($self->word->gdtext->bounding_box($self->word->xy, $self->word->angle))[0,1];
}

sub bottomright {
	my $self = shift;
	
	return ($self->word->gdtext->bounding_box($self->word->xy, $self->word->angle))[2,3];
}

sub topright {
	my $self = shift;
	
	return ($self->word->gdtext->bounding_box($self->word->xy, $self->word->angle))[4,5];
}

sub topleft {
	my $self = shift;
	
	return ($self->word->gdtext->bounding_box($self->word->xy, $self->word->angle))[6,7];
}

sub coordinate_distance {
	my ($self, $x1, $y1, $x2, $y2) = @_;
	
	return sqrt( ($x2 - $x1)**2 + ($y2 - $y1)**2 );
}

#===========================#
# Colors for generating BIH #
#===========================#

has 'forecolor' => (
	isa => 'Color',
	is  => 'ro',
	default  => sub { [0,0,0] },
	init_arg => undef,
);

has 'backcolor' => (
	isa => 'Color',
	is  => 'ro',
	default  => sub { [255,255,255] },
	init_arg => undef,
);

has 'highlightcolor' => (
	isa => 'Color',
	is  => 'ro',
	default => sub { [255,0,0] },
	init_arg => undef,
);

has [ qw/gd_forecolor gd_backcolor gd_highlightcolor gd_hightlight_fillcolor/ ] => ( is => 'rw', isa => 'Int', init_arg => undef );

sub colors {
	my $self = shift;
	return ($self->forecolor, $self->backcolor, $self->highlightcolor);
}

#============#
# Collisions #
#============#

# Return true if this bounding box collides with another bonding box
sub collides {
	my ($self, $box) = @_;
	
	$self->collides_at($box, $self->word->x, $self->word->y);
}

# Returns true if this box collides with another box,
#   given that this box is at a specific XY coordinate
sub collides_at {
	my ($self, $otherbox, $x, $y) = @_;
	
	# Get a list of this boundingbox's hitboxes, offset by the word's location
	my $boxlist1 = $self->_offset_boxes( $self->box );
	
	# Get a list of the other boundingbox's hitboxes, offset by the other word's location
	my $boxlist2 = $otherbox->_offset_boxes( $otherbox->box );
	
	# Stash for comparisons
	my $compares = {};
	
	my $collides = 0;
	
	foreach my $box1 (@$boxlist1) {
		foreach my $box2 (@$boxlist2) {
			#next if exists $compares->{ $box1->{guid} }->{ $box2->{guid} };
			
			if ($self->_detect_collision( $box1->{tl}, $box1->{br}, $box2->{tl}, $box2->{br} )) {
				$collides = 1;
				last;
			}
			
			#$compares->{ $box1->{guid} }->{ $box2->{guid} } = 1;
		}
		last if $collides;
	}
	
	return $collides;
}

# Detect a collision between two rectangles, given their
#   top-left and bottom-right corners
sub _detect_collision {
	my $self = shift;
	
	my ($a_tl, $a_br, $b_tl, $b_br) = @_;
	
	# Turn the box coordinates into their x,y position and their dimensions
	my ($a_x, $a_y) = @$a_tl;
	my $a_w = $self->_box_width( $a_tl, $a_br );
	my $a_h = $self->_box_height( $a_tl, $a_br );
	
	my ($b_x, $b_y) = @$b_tl;
	my $b_w = $self->_box_width( $b_tl, $b_br );
	my $b_h = $self->_box_height( $b_tl, $b_br );
	
	# See if they collide!
	if (
		!( ($b_x > $a_x + $a_w) || ($b_x + $b_w < $a_x) ||
		   ($b_y > $a_y + $a_h) || ($b_y + $b_h < $a_y) )) {
	
	 return 1;
	}
	else {
		return 0;
	}
	
	# If the two rectangle collide on the both planes then they intersect
	#if ($self->_detect_x_collision(@_) && $self->_detect_y_collision(@_)) {
	#	return 1;
	#}
	#else {
	#	return 0;
	#}
}

# Detect a collision on the X plane
sub _detect_x_collision {
	my $self = shift;
	
	my ($a_x, $a_y, $a_w, $a_h,
			$b_x, $b_y, $b_w, $b_h) = @_;
			
	if (! (($b_x > $a_x + $a_w) || ($b_x + $b_w < $a_x)) ) {
		return 1;
	}
	else {
		return 0;
	}
}

# Detect a collision on the Y plane
sub _detect_y_collision {
	my $self = shift;
	
	my ($a_x, $a_y, $a_w, $a_h,
			$b_x, $b_y, $b_w, $b_h) = @_;
			
	if (! (($b_y > $a_y + $a_h) || ($b_y + $b_h < $a_y)) ) {
		return 1;
	}
	else {
		return 0;
	}
}

#================#
# Bounding boxes #
#================#

sub _offset_boxes {
	my $self  = shift;
	my $boxes = shift;
	
	# Copy the boxes
	my @newboxes = @$boxes;
	
	# Add the offset of this word's location to the hitboxes
	#
	# ***NOTE: I have NO earthly idea why you have to subtract 75% of the word's height from the Y offset, but it works
	foreach my $box (@newboxes) {
		$box->{br}->[0] += $self->word->x;
		$box->{br}->[1] += $self->word->y - $self->word->height * .75;
		
		$box->{tl}->[0] += $self->word->x;
		$box->{tl}->[1] += $self->word->y - $self->word->height * .75;
	}
	
	return \@newboxes;
}

sub _generate_boxes {
	my $self  = shift;
	
	my $gd = $self->_image();
	
	my $pixels = {};
	my $boxes  = {
		hitboxes => [],
		boxtree  => {},
		allboxes => [],
		at_coords => {},
	};
	$self->_recurse_box($gd, $pixels, $boxes, [0,0], [$self->width, $self->height]);
	
	if ($ENV{IWC_DEBUG} == 1) {
		foreach my $box (@{ $boxes->{allboxes} }) {
			if (exists $box->{hit}) {
				$gd->filledRectangle(@{ $box->{tl} }, @{ $box->{br} }, $self->gd_hightlight_fillcolor);
			}
			
			$gd->rectangle(@{ $box->{tl} }, @{ $box->{br} }, $self->gd_highlightcolor);
		}
	}
	
	#print "GETPIXELS: $getpixels\n";
	#my $image_pixels = $self->width * $self->height;
	#print "Image pixels: $image_pixels\n";
	#printf "Call ratio: %s\n", $getpixels / $image_pixels;
	
	#$self->box( $boxes->{hitboxes} );
	
	return $boxes->{hitboxes};
}

sub _recurse_box {
	my ($self, $gd, $pixels, $boxes, $dim_tl, $dim_br) = @_;
	
	return if exists $boxes->{at_coords}->{ join('-', @$dim_tl) }->{ join('-', @$dim_br) };
	
	$boxes->{at_coords}->{ join('-', @$dim_tl) }->{ join('-', @$dim_br) } = 1;
	
	#return if (scalar @{ $boxes->{allboxes} }) >= 192;
	
	# Search through every pixel in the image
	my ($x, $y) = @{$dim_tl}[0, 1];
	
	my $box = {
		tl       => $dim_tl,
		br       => $dim_br,
		#guid     => Data::GUID->new()->as_string,
		#children => [],
	};
	
	my $empty = undef;
	my $full = undef;
	my $found_fg = 0;
	my $found_bg = 0;
	while ($y <= $dim_br->[1]) {
		$getpixels++;
		my $color = $gd->getPixel($x, $y);
		
		# This pixel was a hit!
		if ($color == $self->gd_forecolor) {
			# Save this pixel
			$pixels->{$x}->{$y} = 1;
			
			$full = 1 if ! defined $full;
			$found_fg = 1;
		}
		elsif ($color == $self->gd_backcolor) {
			$empty = 1 if ! defined $empty;
			$found_bg = 1;
		}
		
		# If we already know the box is neither full nor empty
		#		(i.e. it has both back and forecolor) , stop looping over pixels.
		last if $found_fg && $found_bg;
		
		$x++;
		if ($x > $dim_br->[0]) {
			$x = $dim_tl->[0];
			$y++;
		}
	}
	
	# All pixel processing is done
	push @{ $boxes->{allboxes} }, $box;
	
	# Every pixel in this box is the forecolor, no need to process it further
	if (defined $full && $full && ! defined $empty && ! $empty) {
		$box->{full} = 1;
		$box->{hit}  = 1;
		
		push @{ $boxes->{hitboxes} }, $box;
	}
	elsif (defined $empty && $empty && ! defined $full && ! $full) {
		$box->{empty} = 1;
		
		# ... don't need to do anything to empty boxes
	}
	# Neither full nor empty, need to process it further
	else {
		# This box is as small as it can be, make it a hitbox and call it a day
		if ($self->_box_area( $dim_tl, $dim_br ) <= $self->_min_box_size()) {
			$box->{hit} = 1;
			push @{ $boxes->{hitboxes} }, $box;
			
			return $box;
		}
		
		# Coordinates for the first half of the box
		my $box1_tl = $dim_tl; # The top-left of the first box will be the same as the parent box
		my $box1_br = [];
		
		# Coordinates for the second half of the box
		my $box2_tl = [];
		my $box2_br = $dim_br; # The bottom-right of the second box will be the same as the parent box
		
		# Split this box in two on its longest bias
		#   X of bottom-right corner is further away from the top-left, split vertically
		if ($self->_box_width($dim_tl, $dim_br) > $self->_box_height($dim_tl, $dim_br)) {
			$box1_br = [ int( (($dim_br->[0] - $dim_tl->[0]) / 2) + $dim_tl->[0]), @{$dim_br}[1] ];
			
			$box2_tl = [ int( (($dim_br->[0] - $dim_tl->[0]) / 2) + $dim_tl->[0]), @{$dim_tl}[1] ];
		}
		else {
			$box1_br = [ @{$dim_br}[0], int( (($dim_br->[1] - $dim_tl->[1]) / 2) + $dim_tl->[1]) ];
		
			$box2_tl = [ @{$dim_tl}[0], int( (($dim_br->[1] - $dim_tl->[1]) / 2) + $dim_tl->[1]) ];
		}
		
		#printf "  Doing box1 %s,%s to %s,%s\n", @{$box1_tl}[0,1], @{$box1_br}[0,1];
		#printf "  Doing box2 %s,%s to %s,%s\n", @{$box2_tl}[0,1], @{$box2_br}[0,1];
		
		# Recurse the first half box
		my $box1 = $self->_recurse_box($gd, $pixels, $boxes, $box1_tl, $box1_br);
		
		# Recurse the second half box
		my $box2 = $self->_recurse_box($gd, $pixels, $boxes, $box2_tl, $box2_br);
		
		#push @{ $box->{children} }, $box1 if defined $box1;
		#push @{ $box->{children} }, $box2 if defined $box2;
	}
	
	return $box;
}

sub _box_area {
	my $self = shift;
	my ($tl, $br) = @_;
	
	my $w = abs($br->[0] - $tl->[0]);
	my $h = abs($br->[1] - $tl->[1]);
	
	return $w * $h;
}

sub _box_width {
	my $self = shift;
	my ($tl, $br) = @_;
	
	my $w = abs($br->[0] - $tl->[0]);
	
	return $w;
}

sub _box_height {
	my $self = shift;
	my ($tl, $br) = @_;
	
	my $h = abs($br->[1] - $tl->[1]);
	
	return $h;
}

#=========#
# Drawing #
#=========#

# Clear out any drawing on this GD object
sub _refresh_gd {
	my $self = shift;
	
	$self->{gd} = GD::Image->new($self->width + 1, $self->height + 1, 1);
	
	$self->_allocateColors();
	
	$self->_refresh_gd_background();
}

sub _refresh_gd_background {
	my $self = shift;
	
	$self->gd->filledRectangle(0, 0, $self->width, $self->height, $self->gd_backcolor);
}

sub _allocateColors {
	my $self = shift;
	
	$self->gd_backcolor( $self->gd->colorAllocate(@{ $self->backcolor }) );
	$self->gd_forecolor( $self->gd->colorAllocate(@{ $self->forecolor }) );
	$self->gd_highlightcolor( $self->gd->colorAllocate(@{ $self->highlightcolor }) );
	
	$self->gd_hightlight_fillcolor( $self->gd->colorAllocateAlpha(@{ $self->highlightcolor }, 110) );
}

# Return an image with the bounding box dimensions stroked
sub _image {
	my $self = shift;
	
	$self->_refresh_gd();
		
	my $newtext = $self->word->gdtext;
	
	$newtext->{gd} = $self->gd;
	$newtext->set('color' => $self->gd_forecolor);
	$newtext->set(valign => 'top');
	
	$newtext->draw(0,0);
	
	return $self->gd;
}

sub boximage {
	my $self = shift;
	
	$ENV{IWC_DEBUG} = 1;
	$self->_generate_boxes();
	$ENV{IWC_DEBUG} = 0;
	
	return $self->gd;
}

__PACKAGE__->meta->make_immutable;

1;
