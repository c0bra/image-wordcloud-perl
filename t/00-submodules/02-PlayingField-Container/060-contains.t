use strict;
use warnings;

use Test::More tests => 7;

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
	#            AveriaSerif-Regular
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

#my $red = $gd->colorAllocate(255,0,0);
#$gd->rectangle($minc->left, $minc->top, $minc->right, $minc->bottom, $red);
#$word->draw();
#$word->stroke_bbox_outline();
#use File::Slurp;
#write_file("/www/vhosts/c0bra.net/htdocs/wordcloud/container.png", {binmode => ':raw'}, $gd->png);

# Add a word and make sure it's there
$minc->add_word( $word );
my @words = $minc->list_words();

is($words[0], $word, "list_words() returns the right word object");