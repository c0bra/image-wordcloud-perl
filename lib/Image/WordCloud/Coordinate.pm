package Image::WordCloud::Coordinate;

use namespace::autoclean;
use Moose;
use Moose::Util::TypeConstraints;

class_type 'Image::WordCloud::Coordinate';
coerce 'Image::WordCloud::Coordinate'
	=> from 'ArrayRef'
	=> via { Image::WordCloud::Coordinate->new( x => $_->[0], y => $_->[1]) };

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