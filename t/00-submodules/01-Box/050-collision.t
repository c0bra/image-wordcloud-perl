use strict;
use warnings;

use Test::More tests => 3;
use Test::Moose;

use Image::WordCloud::Coordinate;
use Image::WordCloud::Box;

my $box1 = Image::WordCloud::Box->new(
	lefttop     => [0, 0],
	rightbottom => [50, 50],
);

my $box2 = Image::WordCloud::Box->new(
	lefttop     => [20, 20],
	rightbottom => [30, 30],
);

is($box1->detect_collision( $box2 ), 1, "Two boxes collide");

$box1 = Image::WordCloud::Box->new(
	lefttop     => [0, 0],
	rightbottom => [50, 50],
);

$box2 = Image::WordCloud::Box->new(
	lefttop     => [100, 100],
	rightbottom => [150, 150],
);

is($box1->detect_collision( $box2 ), 0, "Two boxes don't collide");

$box2 = Image::WordCloud::Box->new(
	lefttop     => [150, 0],
	rightbottom => [250, 150],
);

is($box1->detect_collision( $box2 ), 0, "Boxes next to each other don't collide");