package Image::WordCloud::Box;

use namespace::autoclean;
use Moose;
use MooseX::Types::Moose qw( ArrayRef HashRef Str );
use Moose::Util::TypeConstraints;
use Data::GUID;
use Carp qw(croak);

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
	coerce   => 1,
	handles => {
		left => 'x',
		top  => 'y',
		x    => 'x',
	}
);

has 'rightbottom' => (
	isa      => 'Image::WordCloud::Coordinate',
	is       => 'ro',
	coerce   => 1,
	handles => {
		right  => 'x',
		bottom => 'y',
		y      => 'y',
	},
	lazy_build => 1
);

sub _build_rightbottom {
	my $self = shift;
	
	croak "Must specify height and width in order to set rightbottom" unless $self->has_height && $self->has_width;
	
	return [$self->lefttop->x + $self->width, $self->lefttop->y + $self->height];
}

has 'width' => (
	isa        => 'Num',
	is         => 'ro',
	lazy_build => 1
);

sub _build_width {
	my $self = shift;
	
	croak "Must specify rightbottom to set width" unless $self->has_rightbottom;
	
	return $self->rightbottom->x - $self->lefttop->x;
}

has 'height' => (
	isa        => 'Num',
	is         => 'ro',
	lazy_build => 1
);

sub _build_height {
	my $self = shift;
	
	croak "Must specify rightbottom to set height" unless $self->has_rightbottom;
	
	return $self->rightbottom->y - $self->lefttop->y;
}

sub area {
	my $self = shift;
	return $self->width * $self->height;
}

# Minimum required area in pixels for a box to be
has 'min_area' => (
	is      => PosInt,
	is      => 'ro',
	default => $MIN_AREA,
);

has 'parent' => (
	isa       => __PACKAGE__,
	is        => 'ro',
	predicate => 'has_parent',
	weak_ref  => 1,
);

has 'children' => (
	traits   => ['Hash'],
	isa      => HashRef[__PACKAGE__],
	is       => 'rw',
	lazy     => 1,
	init_arg => undef,
	default  => sub { {} },
	handles  => {
		set_child       => 'set',
    get_child       => 'get',
    has_no_children => 'is_empty',
    num_children    => 'count',
    delete_child    => 'delete',
    child_pairs     => 'kv',
	}
);

sub BUILDARGS {
	my $self = shift;
	my %args = @_;
	
	if (exists $args{'rightbottom'} && (exists $args{'height'} || exists $args{'width'})) {
		croak "If you specify 'rightbottom', you must not specify 'height' or 'width', likewise if you specify 'height' and 'width', you must not specify 'rightbottom'";
	}
	
	return \%args;
}

sub BUILD {
	my $self = shift;
	
	# Make sure these get instantiated on build, though they're lazy
	$self->rightbottom;
	$self->height;
	$self->width;
}

#========================#
# Recursive box building #
#========================#

sub split4 {
	my $self = shift;
	
	# Don't split this box up if it's below the minimum area threshold
	if ($self->area < $self->min_area) {
		return;
	}
	
	# Split this box into four pieces
	#   NOTE: X comes before Y, hence the naming convention
	my $lt = [$self->lefttop->x, $self->lefttop->y];
	my $rb = [$self->rightbottom->x, $self->rightbottom->y];
	my $mt = [$self->right / 2, $self->top];    # middle-top
	my $rm = [$self->right, $self->bottom / 2]; # right-middle
	my $mm = [$self->right / 2, $self->bottom /2 ];        # middle-middle
	my $lm = [$self->left, $self->bottom / 2];  # left-middle
	my $mb = [$self->right / 2, $self->bottom]; # middle-bottom
	
	my @children = ();
	
	foreach my $coord_set (
		[$lt, $mm], # Top-left box
		[$mt, $rm], # Top-right box
		[$lm, $mb], # Bottom-left box
		[$mm, $rb], # Bottom-right box
	) {
		
		my $box = $self->add_child_box(
			lefttop     => $coord_set->[0],
			rightbottom => $coord_set->[1],
		);
		
		push @children, $box;
	}
	
	return @children;
}

# Split this box in four child boxes, and recurse down them
sub recurse_split4 {
	my $self = shift;
	
	my @children = $self->split4();
	
	if (@children) {
		foreach my $child (@children) {
			$child->recurse_split4();
		}
	}
	
	return $self;
}

# Split this node into two halves
sub split2 {
	my $self = shift;
	
	# Don't split this box up if it's below the minimum area threshold
	if ($self->area < $self->min_area) {
		return;
	}
	
	my ($box1, $box2);
	
	# Split along the longer edge
	if ($self->height > $self->width) {
		# Add the first box
		$box1 = $self->add_child_box(
			lefttop => [ $self->lefttop->xy ],
			width   => $self->width,
			height  => $self->height / 2,
		);
		
		# Add the second box
		$box2 = $self->add_child_box(
			lefttop => [ $self->left, $self->bottom / 2 ],
			width   => $self->width,
			height  => $self->height / 2,
		);
	}
	else {
		# Add the first box
		$box1 = $self->add_child_box(
			lefttop => [ $self->lefttop->xy ],
			width   => $self->width / 2,
			height  => $self->height,
		);
		
		# Add the second box
		$box2 = $self->add_child_box(
			lefttop => [ $self->right / 2, $self->top ],
			width   => $self->width / 2,
			height  => $self->height,
		);
	}
	
	return ($box1, $box2);
}

sub recurse_split2 {
	my $self = shift;
	
	my ($box1, $box2) = $self->split2();
	
	# Only split if we got children back from the split
	if ($box1 && $box2) {
		$box1->split2();
		$box2->split2();
	}
	
	return $self;
}

# Add a child box with specific coordinates
sub add_child_box {
	my $self = shift;
	
	my @args = @_;
	
	my $box = __PACKAGE__->new(
		parent => $self,
		@_
	);
	
	$self->set_child(
		$box->guid => $box
	);
	
	return $box;
}

#=====================#
# Collision Detection #
#=====================#

sub contains {
	my ($self, $box) = @_;
	
	# If the box's top-left coordinate is within
	if (
		$box->left   >= $self->left   &&
		$box->right  <= $self->right  &&
		$box->top    >= $self->top    &&
		$box->bottom <= $self->bottom
	) {
		return 1;
	}
	else {
		return 0;
	}
}

# Detect a collision between two boxes, given their
#   top-left and bottom-right corners
sub detect_collision {
	my ($self, $otherbox) = @_;
	
	# See if they collide!
	if (
		# !( ($b_x > $a_x + $a_w) || ($b_x + $b_w < $a_x) ||
		#   ($b_y > $a_y + $a_h) || ($b_y + $b_h < $a_y) )) {
		   	
		!( ($otherbox->left > $self->x + $self->width)   || ($otherbox->left + $otherbox->width < $self->left) ||
			 ($otherbox->top > $self->top + $self->height) || ($otherbox->top  + $otherbox->height < $self->top) )) {
	 
	 return 1;
	}
	else {
		return 0;
	}
}

__PACKAGE__->meta->make_immutable;

1;
