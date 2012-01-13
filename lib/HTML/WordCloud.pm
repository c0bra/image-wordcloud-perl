package HTML::WordCloud;

use 5.006;
use strict;
use warnings;

use Carp qw(carp croak confess);
use Params::Validate qw(:all);
use Data::Types qw(:int :float);
use Search::Dict;

our $golden_ratio_conjugate = 0.618033988749895;

our $boring_word_dict_file = "./share/pos/part-of-speech.txt";

=head1 NAME

HTML::WordCloud - The great new HTML::WordCloud!

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use HTML::WordCloud;

    my $wc = HTML::WordCloud->new();
    ...

=head1 SUBROUTINES/METHODS

=head2 new

=cut

sub new {
    my $proto = shift;

    my %opts = validate(@_, {
        word_count   => { type => SCALAR, optional => 1 },
        prune_boring => { type => SCALAR, optional => 1, default => 1 },
    });
    
    # ***TODO: Figure out how many words to use based on image size?
    $opts{word_count} ||= 30;

    my $class = ref( $proto ) || $proto;
    my $self = { #Will need to allow for params passed to constructor
			words        => {},
      word_count   => $opts{word_count},
      prune_boring => $opts{prune_boring},
    };
    bless($self, $class);

    return $self;
}

=head2 words(\%words_to_use)

Set up hashref \%words_to_use as the words we build the word cloud from.

Keys are the words, values are their count.

=cut

sub words {
	my $self = shift;
	
	my @opts = validate_pos(@_,
  	{ type => HASHREF, optional => 0 },
  );
  
  my %words = %{ $opts[0] };
  
  # Blank out the current word list;
  $self->{word} = {};
  
  # Sort the words by count and let N number of words through, based on $self->{word_count}
  my $word_count = 1;
  foreach my $word (sort { $words{$b} <=> $words{$a} } keys %words) {
  	last if $word_count > $self->{word_count};
  	
  	my $count = $words{$word};
  	
  	# Add this word to our list of words
  	$self->{words}->{$word} = $count;
  	
  	$word_count++;
  }
}

=head2 cloud()

Make the word cloud! Returns an image file location

=cut

sub cloud {
	my $self = shift;
	
	self->_prune_boring_words();
	
	return "";
}

=head2 random_palette($color_count, [$saturation, $value])

Generate C<$color_count> number of RGB colors. C<$color_count> must be an integer. C<$saturation> and C<$value> are optional floating point values from 0.0 to 1.0.
They default to 0.5 and 0.95 respectively.

Return value: C<\@colors>

=cut

# Stolen from: http://martin.ankerl.com/2009/12/09/how-to-create-random-colors-programmatically/
sub random_palette {
	my $self = shift;
	
	my %opts = validate(@_, {
  	count			  => { type => SCALAR, optional => 0 },
  	saturation  => { type => SCALAR, optional => 1, default => 0.5 },
  	value       => { type => SCALAR, optional => 1, default => 0.95 },
  });
  
  croak "\$count ($opts{count}) not an integer" 												unless is_int($opts{count});
  croak "\$saturation ($opts{saturation}) not a floating point number"	unless is_float($opts{saturation});
  croak "\$value ($opts{value}) Not a floating point number"						unless is_float($opts{value});
	
	my $h = rand();
	
	my @colors = ();
	for (1 .. $opts{count}) {
		$h += $golden_ratio_conjugate;
  	$h %= 1;
  	
		my ($r, $g, $b) = $self->_hsv_to_rgb(rand(), $opts{saturation}, $opts{value});
		
		push (@colors, [$r, $g, $b]);
	}
	
	return \@colors;
}

# Convert HSV colors to RGB, in a pretty way
# Stolen from: http://martin.ankerl.com/2009/12/09/how-to-create-random-colors-programmatically/
sub _hsv_to_rgb {
	my $self = shift;
	
	my ($h, $s, $v) = @_;
	
	my $h_i = int($h * 6);
	my $f = $h * 6 - $h_i;
	my $p = $v * (1 - $s);
	my $q = $v * (1 - $f * $s);
	my $t = $v * (1 - (1 - $f) * $s);
	
	my ($r, $g, $b);
	
	($r, $g, $b) = ($v, $t, $p) if $h_i == 0;
	($r, $g, $b) = ($q, $v, $p) if $h_i == 1;
	($r, $g, $b) = ($p, $v, $t) if $h_i == 2;
	($r, $g, $b) = ($p, $q, $v) if $h_i == 3;
	($r, $g, $b) = ($t, $p, $v) if $h_i == 4;
	($r, $g, $b) = ($v, $p, $q) if $h_i == 5;
	
	return (
		int($r * 256),
		int($g * 256),
		int($b * 256)
	);
}

# Remove "boring" words from a word list
sub _prune_boring_words {
	my $self = shift;
	
	my @opts = validate_pos(@_, { type => HASHREF, optional => 1 });
	
	# Either use the words supplied to the subroutine or use what we have in the object
	my $words = {};
	if ($opts[0]) {
		$words = $opts[0];
	}
	else {
		$words = $self->{words};
	}
	
	# Open "boring" word dictionary
	open(my $dict, '<', $boring_word_dict_file);
	
	foreach my $word (keys %$words) {
		# Search for the word in the dict file
		#look $dict, $word, 0, 1;
		look $dict, $word, {
			dict => 0,
			fold => 1,
			cmp => sub {
				($a eq $b) ? 0 : 1;
			}
		};
		
		my $found = <$dict>;
		chomp $found; # strip newline
		
		#print "LOOK: '$word' <-> FOUND: '$found'\n";
		
		# If we found a word and it's equal to our word
		if (defined $found && $found) {
			# Strip off the parts of speech bit at the end of the line and capture it
			$found =~ s/\s(.+)$//;
			my ($parts_of_speech) = $1;
			
			$parts_of_speech =~ s/\|//; # strip pipes
			
			$found =~ s/\s*$//; # trim trailing whitespace
			#$found = lc($found); # lower-case the found word, sometimes the first letter is upper (dunno why)
			
			# Turn the parts of speech into a hash
			#my %parts = map { $_ => 1 } split('', $parts_of_speech);
			
			# Skip if we didn't actually find the word
			next if (lc($word) ne lc($found));
			
			#print "WORD: $word : $parts_of_speech\n";
			
			# If this word is a definite article (D), or indefinite article (I), remove it
			#if (exists $parts{'D'} || exists $parts{I}) {
			if ($parts_of_speech =~ /[DI]/o) {
				delete $words->{$word};
			}
		}
	}
}

=head1 AUTHOR

Brian Hann, C<< <brian.hann at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-html-wordcloud at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=HTML-WordCloud>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc HTML::WordCloud


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=HTML-WordCloud>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/HTML-WordCloud>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/HTML-WordCloud>

=item * Search CPAN

L<http://search.cpan.org/dist/HTML-WordCloud/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2012 Brian Hann.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of HTML::WordCloud
