use strict;
use warnings;

use feature qw(say);
use Test::More tests => 1;
use Test::Moose;
use Benchmark qw(timethese);

use Image::WordCloud::PlayingField::Container;

#timethese(5, {
#	'blah' => sub {
		my $c = Image::WordCloud::PlayingField::Container->new(
			lefttop => [0, 0],
			width   => 800,
			height  => 800,
		);
		
		$c->init_field();
#	}
#});

#use Data::Dumper; print Dumper($c);

#say "Child count: " . $c->count_children;