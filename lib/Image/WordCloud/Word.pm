package Image::WordCloud::Word;

use namespace::autoclean;
use Moose;
use MooseX::Types::Moose qw(Str Int Num);
use Moose::Util::TypeConstraints;
use Math::Trig;
use GD;
use GD::Text::Align;

use Image::WordCloud::Word::BoundingBox;

#==============================================================================#
# Attributes
#==============================================================================#

#=================#
# Text attributes #
#=================#

has 'text' => (
	isa => Str,
	is  => 'ro',
	required => 1,
	trigger => \&_text_set
);
sub _text_set {
	my ($self, $new_text, $old_text) = @_;
	
	$self->gdtext->set_text( $new_text );
}
sub length { length( shift->text ) }

has 'color' => (
	is   => 'rw',
	isa  => 'Image::WordCloud::Color',
	lazy => 1,
	default => sub { [0,0,0] },
	trigger => \&_color_set
);
sub _color_set {
	my ($self, $color) = @_;
	shift->gdtext->set(color => $color);
}

#=================#
# Font attributes #
#=================#

has 'fontsize'	=> (
	isa => Num,
	is => 'rw',
	trigger => \&_fontsize_set
);
sub _fontsize_set {
	my ($self, $fontsize) = @_;
	$self->gdtext->set_font( $self->font, $fontsize );
}

has 'font' => (
	isa => Str,
	is => 'rw',
	trigger => \&_font_set
);
sub _font_set {
	my ($self, $font) = @_;
	$self->gdtext->set_font( $font, $self->fontsize );
}

# Get and set the font+fontsize at the same time
sub font_and_size {
	my ($self, $font, $fontsize) = @_;
	
	if (! defined $font || ! defined $fontsize) {
		return ($self->font, $self->fontsize);
	}
	else {
		$self->font( $font )->size( $fontsize );
	}
}

#===============#
# Inner objects #
#===============#

has 'gd' => (
	isa => 'GD::Image',
	is  => 'ro',
	required => 1,
);

has 'gdtext' => (
	isa => 'GD::Text::Align',
	is  => 'ro',
	init_arg => undef,
	default  => sub { GD::Text::Align->new( shift->gd ) },
);

#=====================#
# Position attributes #
#=====================#

sub width  { return shift->gdtext->get('width') }
sub height { return shift->gdtext->get('height') }

# x,y coordinates
has [ 'x', 'y' ] => ( isa => Num, is => 'rw', default => 0 );
sub xy { my $self = shift; return ($self->x, $self->y); }

# Angle to write the word at
subtype 'Image::WordCloud::Word::Radians',
	as 'Num',
	where { $_ >= 0 && $_ <= 360 };
	
coerce 'Image::WordCloud::Word::Radians',
	from 'Num',
	via { $_ * 180 / pi };

has 'angle' => (
	isa => 'Image::WordCloud::Word::Radians',
	is => 'rw',
	lazy    => 1,
	default => 0,
	coerce  => 1,
);

# Bounding box around this word
has 'boundingbox' => (
	isa => 'Image::WordCloud::Word::BoundingBox',
	is  => 'ro',
	init_arg => undef,
	default => sub { Image::WordCloud::Word::BoundingBox->new(word => shift) }
);

#==============================================================================#
# Methods
#==============================================================================#

#=============#
# Positioning #
#=============#



#============#
# Collisions #
#============#

# Return true if this word collides with another
sub collides {
	my ($self, $word) = @_;
	
	return $self->collides_at($word, $self->xy);
}

# Return true if this word collides with another at specific coordinates
sub collides_at {
	my ($self, $word, $x, $y) = @_;
	
	return $self->boundingbox->collides_at( $word->boundingbox, $x, $y );
}

#=========#
# Drawing #
#=========#

# Draw the word on the given GD::Image object
sub draw {
	my $self   = shift;
	my $gd = shift || $self->gd;
	
	# Make a clone of our GD::Text::Align object so we can draw it on the passed-in GD image
	my $text = GD::Text::Align->new( $gd );
	$text->set_font( $self->font, $self->fontsize );
	$text->set_text( $self->text );
	$text->set(color => $self->color);	
	
	# Draw the text
	$text->draw($self->x, $self->y, $self->angle);
	
	return $self;
}

# Return an image with the bounding boxes stroked
sub boundingbox_image {
	my $self = shift;
	
	return $self->boundingbox->boximage();
}

__PACKAGE__->meta->make_immutable;

1;