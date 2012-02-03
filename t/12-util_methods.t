use strict;
use warnings;

use Test::More tests => 2;
use Image::WordCloud;

my $wc = Image::WordCloud->new();

# * 96 / 72
is($wc->_points_to_pixels(5), 5 * 96 / 72);

# * 72 / 96
is($wc->_pixels_to_points(5), 5 * 72 / 96);