#!perl -T

use Test::More tests => 1;
use Test::Exception;
use Image::WordCloud;

my $wc = new Image::WordCloud();

my $num_fonts = scalar(@{ $wc->{'fonts'} });

ok($num_fonts > 0,		'Found font or fonts to use');

diag('Found ' . $num_fonts . ' fonts to use');
