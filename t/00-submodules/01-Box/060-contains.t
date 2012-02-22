use strict;
use warnings;

use Test::More tests => 5;
use Test::Moose;

use Image::WordCloud::Coordinate;
use Image::WordCloud::Box;

my $box1 = Image::WordCloud::Box->new(
	lefttop => [100, 100],
	width   => 100,
	height  => 100,
);

my $box2 = Image::WordCloud::Box->new(
	lefttop => [105, 105],
	width   => 10,
	height  => 3,
);

is($box1->contains( $box2 ), 1, "Box contains a box inside of it");

is($box2->contains( $box1 ), 0, "Box doesn't contain a box bigger than it");

$box2 = Image::WordCloud::Box->new(
	lefttop => [201, 100],
	width   => 10,
	height  => 3,
);

is($box1->contains( $box2 ), 0, "Box doesn't contain a box next to it");

$box2 = Image::WordCloud::Box->new(
	lefttop => [100, 100],
	width   => 100,
	height  => 100,
);

is($box1->contains( $box2 ), 1, "Box contains an identical box");

$box2 = Image::WordCloud::Box->new(
	lefttop => [100, 100],
	width   => 101,
	height  => 100,
);

is($box1->contains( $box2 ), 0, "Box doesn't contain a box that's identical but 1 value bigger");