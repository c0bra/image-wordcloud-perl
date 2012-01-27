#!/usr/bin/perl

use strict;
use warnings;

use Image::WordCloud;
use File::Slurp;
use Data::Dumper;

my $text = read_file('./script/constitution.txt');

my @words = split /\s+/, $text;

my $wc = new Image::WordCloud(word_count => 70);

$wc->words(\@words);

my $img = $wc->cloud();

write_file('/www/vhosts/c0bra.net/htdocs/wordcloud/constitution.png', {binmode => ':raw'}, $img->png);
