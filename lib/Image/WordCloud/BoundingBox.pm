package Image::WordCloud::BoundingBox;

use strict;
use warnings;

=head1 SYNOPSIS

Not used currently

=head2 new()

Create a bounding box

=cut

sub new {
    my $proto = shift;

    my %opts = validate(@_, {
    });
		
    my $class = ref( $proto ) || $proto;
    my $self = {};
    bless($self, $class);

    return $self;
}

1;