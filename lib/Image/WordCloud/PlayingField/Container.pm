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
  handles => {
  		words          => 'elements',
  		list_words     => 'elements',
      #add_word       => 'push',
      push_words     => 'push',
      count_words    => 'count',
      has_words      => 'count',
      has_no_words   => 'is_empty',
      sorted_words   => 'sort',
  },
);

sub add_word {
	my ($self, $word) = @_;
	
	# Add the word to this container's list of words
	$self->push_words($word);
	
	# Set this object as the word's container
	$word->container( $self );
	
	return $self;
}

sub init_field {
	my $self = shift;
	
	$self->recurse_split4();
}

sub find_container {
	my ($self, $word) = @_;
	
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

# Get a list of all the word objects
sub all_parent_words {
	my $self = shift;
	
	my %words = ();
	
	# Add this container's words
	foreach my $word ($self->words) {
		$words{ $word->text} = $word;
	}
	
	# Get the parent container's words and IT'S parent's words (and so on)
	if ($self->parent) {
		my $pwords = $self->parent->all_parent_words();
		
		foreach my $word (values %$pwords) {
			$words{ $word->text} = $word;
		}
	}
	
	return wantarray ? values %words : \%words;
}

sub recurse_words {
	my $self = shift;
	
	my %words = ();
}

__PACKAGE__->meta->make_immutable;

1;