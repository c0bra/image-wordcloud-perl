package Image::WordCloud::PlayingField;

use namespace::autoclean;
use Moose;
use MooseX::Types::Moose qw( ArrayRef HashRef Str );
use Moose::Util::TypeConstraints;
use Data::GUID;

use Image::WordCloud::Types qw( PosInt );
use Image::WordCloud::Coordinate;

our $MIN_AREA = 200;

#==============================================================================#
# Attributes
#==============================================================================#

has 'guid' => (
	isa      => Str,
	is       => 'ro',
	init_arg => undef,
	default  => sub { Data::GUID->new->as_string },
);

has 'lefttop' => (
	isa      => 'Image::WordCloud::Coordinate',
	is       => 'ro',
	required => 1,
	handles => {
		left => 'x',
		top  => 'y',
	}
);

has 'rightbottom' => (
	isa      => 'Image::WordCloud::Coordinate',
	is       => 'ro',
	required => 1,
	handles => {
		right  => 'x',
		bottom => 'y',
	}
);

sub width {
	my $self = shift;
	
	return abs($self->right->x - $self->left->x);
}

sub height {
	my $self = shift;
	
	return abs($self->bottom->y - $self->top->y);
}

sub area {
	my $self = shift;
	
	return $self->width * $self->height;
}

# Minimum required area in pixels for a node to be
has 'min_area' => (
	is      => PosInt,
	is      => 'ro',
	default => $MIN_AREA,
);

has 'parent' => (
	isa      => __PACKAGE__,
	is       => 'ro',
	required => 1,
);

has 'children' => (
	traits   => ['Hash'],
	isa      => HashRef[__PACKAGE__],
	is       => 'rw',
	lazy     => 1,
	init_arg => undef,
	default  => sub { {} },
);

# Split this node in four child nodes, and recurse down them
sub recurse {
	my $self = shift;
	
	# Don't splitthis node up if it's below the minimum area threshold
	if ($self->area < $self->min_area) {
		return $self;
	}
	
	# Split this box into four pieces
	#   NOTE: X comes before Y, hence the naming convention
	my $lt = $self->leftop;
	my $rb = $self->rightbottom;
	my $mt = [$self->right / 2, $self->top];    # middle-top
	my $rm = [$self->right, $self->bottom / 2]; # right-middle
	my $mm = [$self->right / 2, $self ];        # middle-middle
	my $lm = [$self->left, $self->bottom / 2];  # left-middle
	my $mb = [$self->right / 2, $self->bottom]; # middle-bottom
	
	foreach my $coord_set (
		[$lt, $mm], # Top-left box
		[$mt, $rm], # Top-right box
		[$lm, $mb], # Bottom-left box
		[$mm, $rb], # Bottom-right box
	) {
		
		my $node = $self->add_node(
			lefttop     => $coord_set->[0],
			rightbottom => $coord_set->[1],
		);
	}
	
	foreach my $child ($self->children->values) {
		$child->recurse();
	}
	
	return $self;
}

# Add a child node with specific coordinates
sub add_node {
	my $self = shift;
	
	my ($tl, $br) = @_;
	
	my $node = __PACKAGE__->new(
		lefttop     => $tl,
		rightbottom => $br,
		parent      => $self,
	);
	
	$self->children->set(
		$node->guid => $node
	);
	
	return $node;
}

sub contains {
	my $self = shift;
	
	# Top-left and bottom-right I::W::Coordinates of the box we're going to look for in this node
	my ($tl, $br) = @_;
	
	# If the box's top-left coordinate is within
	if (
		$tl->x >= $self->left   &&
		$br->x <= $self->right  &&
		$tl->y >= $self->top    &&
		$br->y <= $self->bottom
	) {
		return 1;
	}
	else {
		return 0;
	}
}

__PACKAGE__->meta->make_immutable;

1;