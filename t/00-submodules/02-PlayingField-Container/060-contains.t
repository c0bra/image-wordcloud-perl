use strict;
use warnings;

use Test::More tests => 12;

use GD;
use Image::WordCloud;
use Image::WordCloud::Word;
use Image::WordCloud::PlayingField::Container;

# Find the right container to add a word to

my $wc = Image::WordCloud->new();

my $gd = GD::Image->new(800, 800, 1);

my $c = Image::WordCloud::PlayingField::Container->new(
	lefttop => [0, 0],
	width   => 800,
	height  => 800,
);

my $word = Image::WordCloud::Word->new(
	gd       => $gd,
	text     => 'baffle',
	font     => 'AveriaSerif-Regular',
	fontsize => 60,
	x        => 402,
	y        => 80,
	color    => [0,255,0],
);

$c->init_field();

my $minc = $c->find_container( $word );

ok(defined $minc);

isa_ok($minc, 'Image::WordCloud::PlayingField::Container', "find_container() returns a ::PlayingField::Container object");
#printf "Min C: (%s,%s) to (%s,%s)\n", $minc->x, $minc->y, $minc->rightbottom->x, $minc->rightbottom->y;

ok($minc->left <= $word->boundingbox->left, "Container left edge less than or equal to word bottom edge");
ok($minc->top  <= $word->boundingbox->top,  "Container top edge less than or equal to word bottom edge");

ok($minc->right  >= $word->boundingbox->right,  "Container right edge greater than or equal to word right edge");
ok($minc->bottom >= $word->boundingbox->bottom, "Container bottom edge greater than or equal to word bottom edge");

# Add a word and make sure it's there. It should be in the biggest top-right quadrant
$minc->add_word( $word );
my @words = $minc->words();

is($words[0], $word, "words() returns the right word object");

# Add another word

my $word2 = Image::WordCloud::Word->new(
	gd       => $gd,
	text     => 'gordon',
	font     => 'AveriaSerif-Regular',
	fontsize => 60,
	x        => 420,
	y        => 180,
	color    => [0,0,255],
);

my $minc2 = $c->find_container( $word2 );
$minc2->add_word( $word2 );

@words = $minc2->words();

is (scalar @words, 2, "words() returns right number of words in the upper-right quadrant");

is($words[0], $word,  "words() returns the right first word object");
is($words[1], $word2, "words() returns the right second word object");


#=======================#
# Test all_parent_words #
#=======================#

# Add a small word to the same quadrant

my $word3 = Image::WordCloud::Word->new(
	gd       => $gd,
	text     => 'small',
	font     => 'AveriaSerif-Regular',
	fontsize => 15,
	x        => 740,
	y        => 320,
	color    => [0,200,200],
);

my $minc3 = $c->find_container( $word3 );
$minc3->add_word( $word3 );
#@words = $minc3->words();

my @all_words = $minc3->all_parent_words();

is(scalar @all_words, 3, "all_parent_words() returns its words and its parents' words");

# Add a fourth word in a different quadrant

my $word4 = Image::WordCloud::Word->new(
	gd       => $gd,
	text     => 'small2',
	font     => 'AveriaSerif-Regular',
	fontsize => 15,
	x        => 420,
	y        => 330,
	color    => [0,100,200],
);

my $minc4 = $c->find_container( $word4 );
$minc4->add_word( $word4 );
#@words = $minc3->words();

@all_words = $minc4->all_parent_words();

is(scalar @all_words, 3, "all_parent_words() doesn't return words not among its parents' words");



__DATA__

my $red = $gd->colorAllocate(255,0,0);
$gd->rectangle($minc->left, $minc->top, $minc->right, $minc->bottom, $red);
$word->draw();
$word->stroke_bbox_outline();

$gd->rectangle($minc2->left, $minc2->top, $minc2->right, $minc2->bottom, $red);
$word2->draw();
$word2->stroke_bbox_outline();

$gd->rectangle($minc3->left, $minc3->top, $minc3->right, $minc3->bottom, $red);
$word3->draw();
$word3->stroke_bbox_outline();

$gd->rectangle($minc4->left, $minc4->top, $minc4->right, $minc4->bottom, $red);
$word4->draw();
$word4->stroke_bbox_outline();

use File::Slurp;
write_file("/www/vhosts/c0bra.net/htdocs/wordcloud/container.png", {binmode => ':raw'}, $gd->png);

