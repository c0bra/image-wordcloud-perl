use strict;
use warnings;

use Test::More tests => 4;
use Image::WordCloud;

my $wc = Image::WordCloud->new();

# Detect a collision
is(
	$wc->_detect_collision(
		0, 0, 5, 5, # Box at 0,0 that is 5px wide and high
		2, 2, 3, 3, # Box at 2x2 that is 5px wide and high
	),
	1
);

# Detect a non-collision
is(
	$wc->_detect_collision(
		0,   0, 5, 5,   # Box at 0,0 that is 5px wide and high
		20, 20, 5, 5, # Box at 20x20 that is 5px wide and high
	),
	0
);

# Boxes right next to each other don't collide
is(
	$wc->_detect_collision(
		0, 0, 5, 5,   # Box at 0,0 that is 5px wide and high
		0, 6, 5, 5, # Box at 20x20 that is 5px wide and high
	),
	0
);

# Dimensionless boxes collide
is(
	$wc->_detect_collision(
		0, 0, 0, 0, # Box at 0,0 that is 5px wide and high
		0, 0, 0, 0, # Box at 20x20 that is 5px wide and high
	),
	1
);