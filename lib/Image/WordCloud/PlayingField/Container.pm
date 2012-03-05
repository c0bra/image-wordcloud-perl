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
	traits     => ['Hash'],
	isa        => 'HashRef[Image::WordCloud::Word]',
	lazy       => 1,
	default    => sub { {} },
  handles => {
		#words          => 'elements',
		#list_words     => 'elements',
    ##add_word       => 'push',
    #push_words     => 'push',
    #count_words    => 'count',
    #has_words      => 'count',
    #has_no_words   => 'is_empty',
    #sorted_words   => 'sort',
    
    words         => 'values',
    list_words    => 'values',
    set_word      => 'set',
	  get_word      => 'get',
	  num_words     => 'count',
	  _delete_word  => 'delete',
	  pairs         => 'kv',
  },
);

sub remove_word {
	my ($self, $word) = @_;
	
	$self->_delete_word($word->text);
}

sub add_word {
	my ($self, $word) = @_;
	
	# Add the word to this container's list of words
	$self->set_word($word->text => $word);
	
	# Set this object as the word's container
	$word->container->remove_word( $word ) if $word->has_container;
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
		printf "	Adding word: %s\n", $word->text;
		$words{ $word->text} = $word;
	}
	
	# Get the parent container's words and IT'S parent's words (and so on)
	if ($self->parent) {
		my $pwords = $self->parent->all_parent_words();
		
		foreach my $word (values %$pwords) {
			printf "	Adding word: %s\n", $word->text;
			$words{ $word->text} = $word;
		}
	}
	
	return wantarray ? values %words : \%words;
}

sub parent_header {
	my $self = shift;
	
	my $header = "";
	
	if ($self->parent) {
		$header = $self->parent->parent_header;
		$header .= "-";
	}
	
	$header .= $self->child_index;
	
	return $header;
}

sub print_all_words {
	my $self = shift;
	
	#if ($self->list_words) {
		print $self->parent_header . "\n";
		
		foreach my $word ($self->list_words) {
			printf "    %s\n", $word->text; 
		}
		
		foreach my $child ($self->list_children) {
			$child->print_all_words;
		}
	#}
}

__PACKAGE__->meta->make_immutable;

1;