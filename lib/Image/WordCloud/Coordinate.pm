package Image::WordCloud::Coordinate;

use namespace::autoclean;
use Moose;

#==============================================================================#
# Attributes
#==============================================================================#

has [ 'x', 'y' ] => (
	isa      => 'Num',
	is       => 'rw',
	required => 1,
);

sub xy {
	my $self = shift;
	
	return wantarray ? ($self->x, $self->y) : [$self->x, $self-> y];
}

__PACKAGE__->meta->make_immutable;

1;