use strict;
use warnings;

use Test::More tests => 4;
use Test::Moose;

BEGIN {
	my $class = 'Image::WordCloud::PlayingField::Container';
	use_ok($class, "Can use '$class'");
}

use Image::WordCloud::Box;

my $class = 'Image::WordCloud::PlayingField::Container';

my $box = Image::WordCloud::PlayingField::Container->new(
	lefttop     => [0, 0],
	rightbottom => [10, 10],
);

isa_ok($box, $class, "::PlayingField::Container->new() returns correct type");

meta_ok($class, "::PlayingField::Container has meta");

has_attribute_ok($class, "words", "::PlayingField::Container has words attr");

#can_ok($class, qw(  ));