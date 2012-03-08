package Image::WordCloud::Word::BoundingBox::Node;

use namespace::autoclean;
use Moose;

extends 'Image::WordCloud::Box';

#===============#
# Inner Objects #
#===============#

# The parent BoundingBox object 
has 'boundingbox' => (
	is         => 'ro',
	isa        => 'Image::WordCloud::Word::BoundingBox',
	required   => 1,
	lazy_build => 1,
);
sub _build_boundingbox {
	my $self = shift;
	if ($self->has_parent) {
		return $self->parent->boundingbox;
	}
}

#===========================#
# Attributes for Collisions #
#===========================#

has ['is_empty', 'is_full', 'is_hit'] => (
	isa => 'Bool',
	is  => 'rw',
	init_arg => undef,
);

#=========================================#
# Method Wrapping for BoundingBox offsets #
#=========================================#

around ['lefttop'] => (
	my $orig = shift;
	my $self = shift;
	
	# ::Coordinate object
	my $coord = $self->$orig(@_);
	
	my $new_coord = $coord->clone();
	$new_coord->x( $new_coord->x + $self->boundingbox->temp_x_offset );
	$new_coord->y( $new_coord->y + $self->boundingbox->temp_y_offset );
	
	return $new_coord;
);

around ['rightbottom'] => (
	my $orig = shift;
	my $self = shift;
	
	# ::Coordinate object
	my $coord = $self->$orig(@_);
	
	my $new_coord = $coord->clone();
	$new_coord->x( $new_coord->x + $self->boundingbox->temp_x_offset );
	$new_coord->y( $new_coord->y + $self->boundingbox->temp_y_offset );
	
	return $new_coord;
);


#===========================#
# Hitbox processing methods #
#===========================#

override 'recurse_split2' => sub {
	my $self = shift;
	
	my ($box1, $box2) = $self->split2();
	
	# Only split if we got two children back from the split
	if ($box1 && $box2) {
		# Scan each box to see if it contains part of the word
		#   Then for each box, if it's empty is empty nor full, continue to split them
		foreach my $box ($box1, $box2) {
			$box->scan_box_for_hits();
			
			if (! $box->is_empty && ! $box->is_full) {
				$box->split2();
			}
		}
	}
	
	return $self;
};

sub scan_box_for_hits {
	my $self = shift;
	
	# Search through the pixels in this box for 
	
	my ($x, $y) = $self->lefttop();
	
	my $empty = undef;
	my $full = undef;
	my $found_fg = 0;
	my $found_bg = 0;
	while ($y <= $self->bottom) {
		my $color = $self->boundingbox->gd->getPixel($x, $y);
		
		# This pixel was a hit!
		if ($color == $self->boundingbox->gd_backcolor) {
			$empty = 1 if ! defined $empty;
			$found_bg = 1;
		}
		else {
			$full = 1 if ! defined $full;
			$found_fg = 1;
		}
		
		# If we already know the box is neither full nor empty
		#		(i.e. it has both back and forecolor) , stop looping over pixels.
		last if $found_fg && $found_bg;
		
		$x++;
		if ($x > $self->right) {
			$x = $self->left;
			$y++;
		}
	}
	
	# Every pixel in this box is the forecolor, no need to process it further
	if (defined $full && $full && ! defined $empty && ! $empty) {
		$self->is_full(1);
		$self->is_hit(1);
		
		$self->boundingbox->add_hitbox($self);
	}
	elsif (defined $empty && $empty && ! defined $full && ! $full) {
		$self->is_empty(1);
		
		# ... don't need to do anything to empty boxes
	}
	# Neither full nor empty, still a hitbox though
	else {
		$self->is_hit(1);
		
		$self->boundingbox->add_hitbox($self);
	}
	
	return $self;
}

__PACKAGE__->meta->make_immutable;

1;