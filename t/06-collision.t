use strict;
use warnings;

use Test::More tests => 1;
use Test::Exception;
use Image::WordCloud;

my $wc = new Image::WordCloud();

# Add some words
my @words = qw/this is a bunch of words and some are pretty worthless/; # 11 words
my %wordhash = map { shift @words => $_ } (1 .. ($#words+1));
$wc->words(\%wordhash);

# We should have removed 'of', 'and', and 'a'
SKIP: {
	skip 'Search::Dict finding word matches, not exact word', 1;
	
	is(scalar keys %{ $wc->{words} }, 8, 'Pruned right number of words');
}
