package Image::WordCloud::Types;

use strict;
use warnings;

use namespace::autoclean;

use MooseX::Types -declare => [qw/
	ArrayRefOfStrs
	PosInt
	PosIntOrZero
	Color
	Percent
	ImageSize
	Radians
	Coordinate
/];

use MooseX::Types::Moose qw( Int ArrayRef Str Num );

use Math::Trig qw(pi);

subtype ArrayRefOfStrs, as ArrayRef[Str];
coerce ArrayRefOfStrs,
	from Str,
	via { [ $_ ] };

subtype PosInt,
	as Int, where { $_ > 0 },
	message { "Int is not greater than 0" };
	
subtype PosIntOrZero,
	as Int, where { $_ >= 0 },
	message { "Int is not greater than or equal 0" };

subtype ImageSize,
	as ArrayRef[PosInt], where { @$_ == 2 },
	message { "Image size must be an arrayref of two greater-than-zero integers" };

subtype Color,
	as ArrayRef[PosIntOrZero], where { @$_ == 3 },
	message { "Must have exactly 3 ints" };

subtype Percent,
	as Str,
	where { /^\d+\%?$/o },
	message { "A percent must be in the format '^\\d+%\$'" };
	
# Angle to write words at
subtype Radians,
	as Num, where { $_ >= 0 && $_ <= 360 };
	#message { "Must be a number between 0 and 360" };
	
coerce Radians,
	from Num,
	via { $_ * 180 / pi };

__PACKAGE__->meta->make_immutable;