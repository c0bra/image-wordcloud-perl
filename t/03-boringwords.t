#!perl -T

use Test::More tests => 2;
use Test::Exception;

BEGIN {
    use_ok( 'HTML::WordCloud' ) || print "Bail out!\n";
}

diag( "Testing HTML::WordCloud $HTML::WordCloud::VERSION, Perl $], $^X" );

my $wc = new HTML::WordCloud();

# Add some words
my @words = qw/this is a bunch of words and some are pretty worthless/; # 11 words
my %wordhash = map { shift @words => $_ } (1 .. ($#words+1));
$wc->words(\%wordhash);

# We should have removed 'of', 'and', and 'a'
SKIP: {
	skip 'Search::Dict finding word matches, not exact word', 1;
	
	is(scalar keys %{ $wc->{words} }, 8, 'Pruned right number of words');
}