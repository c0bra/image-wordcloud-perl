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
  	  list_words     => 'elements',
      all_words      => 'elements',
      add_word       => 'push',
      count_words    => 'count',
      has_words      => 'count',
      has_no_words   => 'is_empty',
      sorted_words   => 'sort',
  },
);

sub init_field {
	my $self = shift;
	
	$self->recurse_split4();
}

sub find_container {
	my $self = shift;
	my $word = shift;
	
	my $min_container;
	
	if ($self->contains( $word->boundingbox )) {
		$min_container = $self;
		
		# Go through each of this container's children
		foreach my $child ($self->list_children) {
			# And recurse down
			my $found_container = $child->find_container($word);
			
			if ($found_container) {
				$min_container = $found_container;
				last;
			}
		}
	}
	else {
		return;
	}
	
	return $min_container;
}

__PACKAGE__->meta->make_immutable;

1;