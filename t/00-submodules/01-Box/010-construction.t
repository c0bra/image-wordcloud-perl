use strict;
use warnings;

use Test::More tests => 9;
use Test::Fatal;

use Image::WordCloud::Box;

my $box = Image::WordCloud::Box->new(
	lefttop     => [0, 0],
	rightbottom => [50, 40],
);

is($box->width,  50, "Width set correctly using rightbottom");
is($box->height, 40, "Height set correctly using rightbottom");

$box = Image::WordCloud::Box->new(
	lefttop => [0, 0],
	height  => 20,
	width   => 30, 
);

is($box->rightbottom->x, 30, "Bottomright X value set correctly with width attr");
is($box->rightbottom->y, 20, "Bottomright Y value set correctly with height attr");

# Now try a box floating in space

$box = Image::WordCloud::Box->new(
	lefttop     => [100, 120],
	rightbottom => [130, 160],
);

is($box->width,  30, "Width set correctly using rightbottom");
is($box->height, 40, "Height set correctly using rightbottom");

$box = Image::WordCloud::Box->new(
	lefttop => [100, 120],
	width   => 30, 
	height  => 40,
);

is($box->rightbottom->x, 130, "Bottomright X value set correctly with width attr");
is($box->rightbottom->y, 160, "Bottomright Y value set correctly with height attr");

# What happens if all 3 attrs are set?

like(
	exception {
		$box = Image::WordCloud::Box->new(
			lefttop     => [100, 120],
			rightbottom => [110, 130],
			width       => 30, 
			height      => 40,
		);
	},
	qr/If you specify 'rightbottom', you must not specify 'height' or 'width', likewise if you specify 'height' and 'width', you must not specify 'rightbottom'/,
	"Must declare EITHER rightbottom OR height and width, but not both"
);