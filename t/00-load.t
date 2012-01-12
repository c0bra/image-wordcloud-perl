#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'HTML::WordCloud' ) || print "Bail out!\n";
}

diag( "Testing HTML::WordCloud $HTML::WordCloud::VERSION, Perl $], $^X" );
