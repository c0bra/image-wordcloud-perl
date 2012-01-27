#!/usr/bin/perl

use strict;
use warnings;
use File::Find::Rule;

my @fonts = File::Find::Rule->new()
	->extras({ untaint => 1 })
	->file()
	->name('*.ttf')
	->in('/home/c0bra/projects/Image-WordCloud.git/share/fonts');

print join(", ", @fonts) . "\n";
