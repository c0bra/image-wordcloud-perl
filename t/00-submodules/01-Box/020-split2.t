use strict;
use warnings;

use Test::More tests => 24;
use Test::Fatal;

use Image::WordCloud::Box;

## Split a box vertically
my $pbox = Image::WordCloud::Box->new(
	lefttop => [0, 0],
	width   => 400,
	height  => 200,
);

my ($box1, $box2) = $pbox->split2();

# Box1

is($box1->lefttop->x, 0, "Vertical - First child box has right lefttop X coord");
is($box1->lefttop->y, 0, "Vertical - First child box has right lefttop Y coord");

is($box1->width,  200, "Vertical - First child box has right width");
is($box1->height, 200, "Vertical - First child box has right height");

is($box1->rightbottom->x, 200, "Vertical - First child box has right rightbottom X coord");
is($box1->rightbottom->y, 200, "Vertical - First child box has right rightbottom Y coord");

# Box2

is($box2->lefttop->x, 200, "Vertical - Second child box has right lefttop X coord");
is($box2->lefttop->y, 0, "Vertical - Second child box has right lefttop Y coord");

is($box2->width,  200, "Vertical - Second child box has right width");
is($box2->height, 200, "Vertical - Second child box has right height");

is($box2->rightbottom->x, 400, "Vertical - Second child box has right rightbottom X coord");
is($box2->rightbottom->y, 200, "Vertical - Second child box has right rightbottom Y coord");

## Split a box horizontally
$pbox = Image::WordCloud::Box->new(
	lefttop => [0, 0],
	width   => 200,
	height  => 400,
);

($box1, $box2) = $pbox->split2();

# Box1

is($box1->lefttop->x, 0, "Horizontal - First child box has right lefttop X coord");
is($box1->lefttop->y, 0, "Horizontal - First child box has right lefttop Y coord");

is($box1->width,  200, "Horizontal - First child box has right width");
is($box1->height, 200, "Horizontal - First child box has right height");

is($box1->rightbottom->x, 200, "Horizontal - First child box has right rightbottom X coord");
is($box1->rightbottom->y, 200, "Horizontal - First child box has right rightbottom Y coord");

# Box2

is($box2->lefttop->x, 0, "Horizontal - Second child box has right lefttop X coord");
is($box2->lefttop->y, 200, "Horizontal - Second child box has right lefttop Y coord");

is($box2->width,  200, "Horizontal - Second child box has right width");
is($box2->height, 200, "Horizontal - Second child box has right height");

is($box2->rightbottom->x, 200, "Horizontal - Second child box has right rightbottom X coord");
is($box2->rightbottom->y, 400, "Horizontal - Second child box has right rightbottom Y coord");