#!perl -T

use Test::More;
use Test::Exception;
use Image::WordCloud;

plan skip_all => "No palette tests at this time";

my $wc = new Image::WordCloud;

#isa_ok( $wc, 'Image::WordCloud' );
#
#dies_ok( sub { my $colors = $wc->random_palette(); }, "Dies when no 'count' is provided");
#
#$colors = $wc->_random_palette(count => 10);
#is( scalar @$colors, 10, 'Right number of colors with count' );
#
#$colors = $wc->_random_palette(count => 10, saturation => 0.8);
#is( scalar @$colors, 10, 'Right number of colors with saturation' );
#
#$colors = $wc->_random_palette(count => 10, value => 0.8);
#is( scalar @$colors, 10, 'Right number of colors with value' );
#
#$colors = $wc->_random_palette(count => 10, saturation => 0.8, value => 0.2);
#is( scalar @$colors, 10, 'Right number of colors with saturation and value' );
#
## Check for death with bad parameters
#dies_ok( sub { $wc->_random_palette(count => 'flurb') }, 									'Dies on non-integer number of colors' );
#dies_ok( sub { $wc->_random_palette(count => 10, saturation => 'flurb') }, 'Dies on non-integer saturation' );
#dies_ok( sub { $wc->_random_palette(count => 10, value => 'flurb') }, 			'Dies on non-integer value' );
