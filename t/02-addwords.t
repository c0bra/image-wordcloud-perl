#!perl -T

use strict;
use Test::More tests => 11;
use Test::Exception;

BEGIN {
    use_ok( 'HTML::WordCloud' ) || print "Bail out!\n";
}

diag( "Testing HTML::WordCloud $HTML::WordCloud::VERSION, Perl $], $^X" );

# Don't prune boring words for this test
my $wc = new HTML::WordCloud(prune_boring => 0);

my @words = qw/this is a bunch of words/;
my %wordhash = map { shift @words => $_ } (1 .. ($#words+1));

is(scalar keys(%wordhash), 6, 'Starting with right number of words');

$wc->words(\%wordhash);
is(scalar keys (%{$wc->{words}}), 6, 'Got right number of words from hash element');

my $get_words = $wc->words();
is(scalar keys %wordhash, scalar keys %$get_words, 'Got right number of words with ->words() method');

is($wc->{words}->{'this'}, 1,  'Right count for first word in list');
is($wc->{words}->{'words'}, 6, 'Right count for last word in list');

# ***TODO: test adding words as an arrayref


$wc = new HTML::WordCloud(word_count => 2);

$wc->words(\%wordhash);

is(scalar keys (%{$wc->{words}}), 2, "Got right number of words with 'word_count' option specified");

my @wordkeys = sort { $wc->{words}->{$b} <=> $wc->{words}->{$a} } keys %{$wc->{words}};

is(@wordkeys[0], 'words', 'Sorting and pruning words right - first word');
is(@wordkeys[1], 'of',    'Sorting and pruning words right - second word');

is($wc->{words}->{'words'}, 6, 'Right count for top word in list');
is($wc->{words}->{'of'},    5, 'Right count for next word in list');
