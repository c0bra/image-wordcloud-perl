use strict;
use warnings;

use Test::More tests => 10;
use Test::Fatal;

BEGIN {
	use_ok('Image::WordCloud::Coordinate', "Can use 'Image::WordCloud::Coordinate'");
}

BEGIN {

can_ok('Image::WordCloud::Coordinate', 'new');

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

can_ok('Image::WordCloud::Coordinate', 'x');
can_ok('Image::WordCloud::Coordinate', 'y');

is($c->x, 5,  "X coordinate set correctly");
is($c->y, 20, "Y coordinate set correctly");

}
