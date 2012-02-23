package Image::WordCloud::PlayingField::Container;

use namespace::autoclean;
use Moose;
use MooseX::Types::Moose qw( ArrayRef HashRef );
use Carp qw(croak);

extends 'Image::WordCloud::Box';

#==============================================================================#
# Attributes
#==============================================================================#

has 'words' => (
	traits     => ['Array'],
	isa        => 'ArrayRef[Image::WordCloud::Word]',
	lazy       => 1,
	default    => sub { [] },
	default => sub { [] },
  handles => {
  	  list_words   => 'elements',
      all_words    => 'elements',
      add_word     => 'push',
      count_words    => 'count',
      has_words      => 'count',
      has_no_words   => 'is_empty',
      sorted_words => 'sort',
  },
);

#has 'parent' => (
#	isa => __PACKAGE__,
#	is  => 'ro',
#);
#
#has 'children' => (
#	traits => ['Hash'],
#	isa    => HashRef[__PACKAGE__],
#	init_arg => undef,
#	default  => sub { {} },
#	handles  => {
#		list_children   => 'values',
#		set_child       => 'set',
#    get_child       => 'get',
#    has_no_children => 'is_empty',
#    num_children    => 'count',
#    delete_child    => 'delete',
#    child_pairs     => 'kv',
#	}
#);

sub init_field {
	my $self = shift;
	
	$self->recurse_split4();
}

__PACKAGE__->meta->make_immutable;

1;