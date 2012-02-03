use strict;
use warnings;

use Test::More tests => 3;
use Test::Exception;
use Image::WordCloud;

BEGIN {
	use_ok( 'Image::WordCloud::StopWords::EN', qw(%STOP_WORDS) );
}

BEGIN {
	use Image::WordCloud::StopWords::EN qw(%STOP_WORDS);
	ok(scalar(keys %STOP_WORDS) > 0,		"Got more than 0 stop words from StopWords:: module");
}

my $wc = Image::WordCloud->new();

# Add some words
my @words = qw/this is a bunch of words and some are pretty worthless/; # 11 words
my %wordhash = map { shift @words => $_ } (1 .. ($#words+1));
$wc->words(\%wordhash);

# We should have removed 'this', 'is', 'a', 'of', 'and', and 'are' (7 words, leaving 4)
is(scalar keys %{ $wc->{words} }, 4, 'Pruned right number of words');


$wc = Image::WordCloud->new()->;
$wc
$wc->_prune_stop_words