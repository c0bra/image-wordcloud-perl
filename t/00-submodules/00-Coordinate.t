use strict;
use warnings;

use Test::More tests => 16;
use Test::Moose;
use Test::Fatal;

BEGIN {
	use_ok('Image::WordCloud::Coordinate', "Can use 'Image::WordCloud::Coordinate'");
}

use Image::WordCloud::Coordinate;

#=============#
# Moose tests #
#=============#

my $class = 'Image::WordCloud::Coordinate';

my $tc = Image::WordCloud::Coordinate->new(x => 0, y => 0);
isa_ok($tc, $class, "new() returns the right type");

meta_ok($class, "I::W::Coordinate has meta");

has_attribute_ok($class, 'x', "I::W::Coordinate has y attribute");
has_attribute_ok($class, 'x', "I::W::Coordinate has x attribute");

can_ok($class, 'xy');

#=============#
# Usage tests #
#=============#

like(
	exception { my $c = Image::WordCloud::Coordinate->new() },
	qr/Attribute .+? is required/,
	"Must declare x and y coordinates upon instantiation"
);

like(
	exception { my $c = Image::WordCloud::Coordinate->new( y => 2 ) },
	qr/Attribute \(x\) is required/,
	"Must declare x coordinate upon instantiation"
);
like(
	exception { my $c = Image::WordCloud::Coordinate->new( x => 2 ) },
	qr/Attribute \(y\) is required/,
	"Must declare y coordinate upon instantiation"
);

my $c = Image::WordCloud::Coordinate->new(x => 5, y => 20);
isa_ok($c, 'Image::WordCloud::Coordinate');

is($c->x, 5,  "X coordinate set correctly");
is($c->y, 20, "Y coordinate set correctly");

my ($x, $y) = $c->xy;

is($x, 5,  "xy() returns proper X value");
is($y, 20, "xy() returns proper Y value");

my $xy = $c->xy;

is($xy->[0], 5,  "xy() returns proper X value in an arrayref");
is($xy->[1], 20, "xy() returns proper Y value in an arrayref");