use strict;
use warnings;

use feature qw(say);
use Test::More tests => 1;
use Test::Fatal;

use Image::WordCloud::PlayingField::Container;

my $c = Image::WordCloud::PlayingField::Container->new(
	lefttop => [0, 0],
	width   => 30,
	height  => 30,
);

is(
	exception { $c->init_field() },
	undef,
	"init_field() doesn't die"
);

# TODO: make sure the number of children matches what we should create based on the min_area attribute