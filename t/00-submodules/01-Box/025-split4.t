use strict;
use warnings;

use Test::More tests => 24;
use Test::Fatal;

use Image::WordCloud::Box;

## Split a box vertically
my $pbox = Image::WordCloud::Box->new(
	lefttop => [0, 0],
	width   => 800,
	height  => 800,
);

my ($box_tl, # top-left
		$box_tr, # top-right
		$box_bl, # bottom-left
		$box_br) # bottom-right
	= $pbox->split4();

my @quads = qw/topleft topright bottomleft bottomright/;
my %boxhash = map { shift @quads => $_ } ($box_tl, $box_tr, $box_bl, $box_br);

# Make sure the boxes have the right dimensions (8 tests)
foreach my $boxname(keys %boxhash) {
	my $box = $boxhash{ $boxname };
	is($box->width,  400, "Box $boxname has right width");
	is($box->height, 400, "Box $boxname has right height");
}

# Top-left box
is($box_tl->lefttop->x, 0, "Top-left box has right lefttop X coord");
is($box_tl->lefttop->y, 0, "Top-left box has right lefttop Y coord");

is($box_tl->rightbottom->x, 400, "Top-left box has right rightbottom X coord");
is($box_tl->rightbottom->y, 400, "Top-left box has right rightbottom Y coord");

# Top-right box
is($box_tr->lefttop->x, 400, "Top-right box has right lefttop X coord");
is($box_tr->lefttop->y, 0, "Top-right box has right lefttop Y coord");

is($box_tr->rightbottom->x, 800, "Top-right box has right rightbottom X coord");
is($box_tr->rightbottom->y, 400, "Top-right box has right rightbottom Y coord");

# Bottom-left box
is($box_bl->lefttop->x, 0, "Bottom-left box has right lefttop X coord");
is($box_bl->lefttop->y, 400, "Bottom-left box has right lefttop Y coord");

is($box_bl->rightbottom->x, 400, "Bottom-left box has right rightbottom X coord");
is($box_bl->rightbottom->y, 800, "Bottom-left box has right rightbottom Y coord");

# Bottom-right box
is($box_br->lefttop->x, 400, "Bottom-right box has right lefttop X coord");
is($box_br->lefttop->y, 400, "Bottom-right box has right lefttop Y coord");

is($box_br->rightbottom->x, 800, "Bottom-right box has right rightbottom X coord");
is($box_br->rightbottom->y, 800, "Bottom-right box has right rightbottom Y coord");