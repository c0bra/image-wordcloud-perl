package Image::WordCloud::BoundingBox;


=head1 SUBROUTINES/METHODS

=head2 new

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