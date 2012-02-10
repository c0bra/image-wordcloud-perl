package Image::WordCloud::Word::BoundingBox;

use namespace::autoclean;
use Moose;
use Image::WordCloud::Word;
use GD;
use Random::PoissonDisc;

has 'word' => (
	is  => 'ro',
	isa => 'Image::WordCloud::Word',
	required => 1,
);

# Utility GD object for testing
has 'gd' => (
	isa => 'GD::Image',
	is  => 'ro',
	init_arg => undef,
	builder  => '_build_gd',
);
sub _build_gd {
	return GD::Image->new->();
}

# NOTE: GD::Text::Align's boundingbox() method returns 8 elements:
#   (x1,y1) lower left corner
#   (x2,y2) lower right corner
#   (x3,y3) upper right corner
#   (x4,y4) upper left corner

has 'width' => (
	is => 'Num',
	is => 'ro',
	init_arg => undef,
);

has 'height' => (
  is => 'Num',
	is => 'ro',
	init_arg => undef,
);

has 'topleft' => (
	is => 'Num',
	is => 'ro',
	init_arg => undef,
);

has 'topright' => (
	is => 'Num',
	is => 'ro',
	init_arg => undef,
);

has 'bottomleft' => (
	is => 'Num',
	is => 'ro',
	init_arg => undef,
);

has 'bottomleft' => (
	is => 'Num',
	is => 'ro',
	init_arg => undef,
);

#===========================#
# Colors for generating BIH #
#===========================#

has 'forecolor' => (
	isa => 'Image::WordCloud::Color',
	is  => 'ro',
	default => sub { [0,0,0] },
	init_arg => undef,
);

has 'backcolor' => (
	isa => 'Image::WordCloud::Color',
	is  => 'ro',
	default => sub { [255,255,255] },
	init_arg => undef,
);

#============#
# Collisions #
#============#

# Return true if this bounding box collides with another bonding box
sub collides {
	my ($self, $box) = @_;
	
	$self->collides_at($box, $self->word->x, $self->word->y);
}

sub collides_at {
	my ($self, $box, $x, $y) = @_;
	
	
}

#=========#
# Drawing #
#=========#

sub _refresh_gd {
	my $self = shift;
	
	$self->{gd} = GD::Image->new($self->width, $self->height);
	
	$self->gd->fillRectangle($self->width, $self->height, $self->backcolor);
	
	
}

__PACKAGE__->meta->make_immutable;

1;
