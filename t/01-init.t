#!perl -T

use Test::More tests => 4;
use Cwd;
use File::Spec;
use Image::WordCloud;

my $wc = new Image::WordCloud();

isa_ok($wc, 'Image::WordCloud', 						"Instantiating right object");

$wc = new Image::WordCloud(
  image_size   => [200, 210],
	word_count   => 25,
	prune_boring => 0,
);

is_deeply($wc->{'image_size'}, [200, 210],	"'image_size' being set right");
is($wc->{'word_count'},   25,								"'word_count' being set right");
is($wc->{'prune_boring'}, 0,								"'prune_boring' being set right");

#my $stop_word_file = File::Spec->catfile('.', 'share', 
#is($wc->{'stop_word_file'}, 0,							"prune_boring being set right");