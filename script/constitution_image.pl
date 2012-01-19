#!/usr/bin/perl

use strict;
use warnings;

use HTML::WordCloud;
use File::Slurp;
use Data::Dumper;

my $text = read_file('./script/constitution.txt');

#my @words = qw/this is a bunch of words/;
my @words = split /\s+/, $text;

#my %wordhash = map { shift @words => $_ } (1 .. ($#words+1));

my $wc = new HTML::WordCloud(prune_boring => 1, word_count => 70);

$wc->words(\@words);

#print Dumper($wc->words);

binmode STDOUT;

my $img = $wc->cloud();

#print $img->png;

write_file('/www/vhosts/c0bra.net/htdocs/wordcloud/constitution.png', {binmode => ':raw'}, $img->png);