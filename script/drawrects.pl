#!/usr/bin/perl

use strict;
use warnings;
use GD;

my $gd = new GD::Image(800, 600);

my $white = $gd->colorAllocate(255,255,255);
my $black = $gd->colorAllocate(0,0,0);

my %blah =  %{
  {
          'A-y' => 218,
          'A-w' => 806,
          'B-y' => 33,
          'B-w' => 1101,
          'B-x' => 440,
          'A-h' => 565,
          'A-x' => 167,
          'B-h' => 180
        }
};

draw($gd, {
	x=> $blah{'A-x'},
	y=> $blah{'A-y'},
	h=> $blah{'A-h'},
	w=> $blah{'A-w'}
});

draw($gd, {
	x=> $blah{'B-x'},
	y=> $blah{'B-y'},
	h=> $blah{'B-h'},
	w=> $blah{'B-w'}
});

#draw($gd, {x=> 167, y=> 218, h=> 176, w=> 472});
#draw($gd, {x=> 384, y=> 401, h=> 154, w=> 221});

print $gd->png();

sub draw {
	my $gd = shift;
	my $rect = shift;
	
	# Top-left to top-right
	$gd->line($rect->{x}, $rect->{y},
					  $rect->{x} + $rect->{w}, $rect->{y}, $black);
					  
	# Top-left to bottom-left
	$gd->line($rect->{x}, $rect->{y},
					  $rect->{x}, $rect->{y} + $rect->{h}, $black);
					  
	$gd->line($rect->{x}, $rect->{y} + $rect->{h},
					  $rect->{x} + $rect->{w}, $rect->{y} + $rect->{h}, $black);
					  
	$gd->line($rect->{x} + $rect->{w} , $rect->{y},
					  $rect->{x} + $rect->{w}, $rect->{y} + $rect->{h}, $black);
}