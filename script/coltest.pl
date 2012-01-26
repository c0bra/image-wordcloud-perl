#!/usr/bin/perl

use Collision::2D ':all';

# 'A-y' => 218,
# 'A-w' => 472,
# 'B-y' => '401.316853274719',
# 'B-w' => 221,
# 'B-x' => '384.673707476728',
# 'A-h' => 176,
# 'A-x' => 167,
# 'B-h' => 154



my $rect1   = hash2rect({x=> 167, y=> 218, h=> 176, w=> 472});
my $rect2   = hash2rect({x=> 384, y=> 401, h=> 154, w=> 221});

my $collision = intersection($rect1, $rect2);
print "$collision\n";