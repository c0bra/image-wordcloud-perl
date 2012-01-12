#!/usr/bin/perl

use strict;
use warnings;
use Convert::Color;

my $golden_ratio_conjugate = 0.618033988749895;

my $h = rand();

sub gen_html {
	#my ($r, $g, $b) = @_;
	
	for ('A' .. 'Z') {
		#my ($r, $g, $b) = ( rand(256), rand(256), rand(256) );
		
		#my $h = int(rand(100));
		#my $color = Convert::Color->new( 'hsv:' . $h . ',0.5,0.95' );
		#my $rgb = $color->as_rgb8->hex;
		
		$h += $golden_ratio_conjugate;
  	$h %= 1;
  	
		my ($r, $g, $b) = &hsv_to_rgb(rand(), 0.25, 0.9);
		
		printf qq~<span style="background-color:#%02x%02x%02x; padding:5px; margin: 2px; -moz-border-radius:3px; -webkit-border-radius:3px;">%s</span>~, $r, $g, $b, $_;
		#printf qq~<span style="background-color:#%s; padding:5px; margin: 2px; -moz-border-radius:3px; -webkit-border-radius:3px;">%s</span>~, $rgb, $_;
	}
}

sub hsv_to_rgb {
	my ($h, $s, $v) = @_;
	
	my $h_i = int($h * 6);
	my $f = $h * 6 - $h_i;
	my $p = $v * (1 - $s);
	my $q = $v * (1 - $f * $s);
	my $t = $v * (1 - (1 - $f) * $s);
	
	my ($r, $g, $b);
	
	($r, $g, $b) = ($v, $t, $p) if $h_i == 0;
	($r, $g, $b) = ($q, $v, $p) if $h_i == 1;
	($r, $g, $b) = ($p, $v, $t) if $h_i == 2;
	($r, $g, $b) = ($p, $q, $v) if $h_i == 3;
	($r, $g, $b) = ($t, $p, $v) if $h_i == 4;
	($r, $g, $b) = ($v, $p, $q) if $h_i == 5;
	
	return (
		int($r * 256),
		int($g * 256),
		int($b * 256)
	);
}

gen_html();
