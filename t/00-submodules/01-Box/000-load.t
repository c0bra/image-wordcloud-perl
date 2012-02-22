use strict;
use warnings;

use Test::More tests => 10;
use Test::Moose;

BEGIN {
	my $class = 'Image::WordCloud::Box';
	use_ok($class, "Can use '$class'");
}

use Image::WordCloud::Box;

my $class = 'Image::WordCloud::Box';

my $box = Image::WordCloud::Box->new(
	lefttop     => [0, 0],
	rightbottom => [10, 10],
);

isa_ok($box, $class, "::Box->new() returns correct type");

meta_ok($class, "::Box has meta");

has_attribute_ok($class, "guid", "::Box has guid attr");
has_attribute_ok($class, "lefttop", "::Box has lefttop attr");
has_attribute_ok($class, "rightbottom", "::Box has rightbottom attr");
has_attribute_ok($class, "min_area", "::Box has min_area attr");
has_attribute_ok($class, "parent", "::Box has parent attr");
has_attribute_ok($class, "children", "::Box has children attr");

can_ok($class, qw( width height area recurse add_node contains detect_collision ));