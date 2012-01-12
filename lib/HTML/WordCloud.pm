package HTML::WordCloud;

use 5.006;
use strict;
use warnings;

use Carp qw(carp croak confess);
use Params::Validate qw(:all);
use Data::Types qw(:int :float);

our $golden_ratio_conjugate = 0.618033988749895;

=head1 NAME

HTML::WordCloud - The great new HTML::WordCloud!

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use HTML::WordCloud;

    my $wc = HTML::WordCloud->new();
    ...

=head1 SUBROUTINES/METHODS

=head2 new

=cut

sub new {
    my $proto = shift;

    my %opts = validate(@_, {
        dates       => { type => ARRAYREF,                  optional => 1 },
        profile     => { type => SCALAR | OBJECT | HASHREF, optional => 1 },
        clustering  => { type => SCALAR | HASHREF,          optional => 1, },
    });

    my $class = ref( $proto ) || $proto;
    my $self = { #Will need to allow for params passed to constructor
        
    };
    bless($self, $class);

    return $self;
}

=head2 random_palette($color_count, [$saturation, $value])

Generate C<$color_count> number of RGB colors. C<$color_count> must be an integer. C<$saturation> and C<$value> are optional floating point values from 0.0 to 1.0.
They default to 0.5 and 0.95 respectively.

Return value: C<\@colors>

=cut

sub random_palette {
	my $self = shift;
	
	my %opts = validate(@_, {
  	count			  => { type => SCALAR, optional => 0 },
  	saturation  => { type => SCALAR, optional => 1, default => 0.5 },
  	value       => { type => SCALAR, optional => 1, default => 0.95 },
  });
  
  croak "\$count ($opts{count}) not an integer" 												unless is_int($opts{count});
  croak "\$saturation ($opts{saturation}) not a floating point number"	unless is_float($opts{saturation});
  croak "\$value ($opts{value}) Not a floating point number"						unless is_float($opts{value});
	
	my $h = rand();
	
	my @colors = ();
	for (1 .. $opts{count}) {
		$h += $golden_ratio_conjugate;
  	$h %= 1;
  	
		my ($r, $g, $b) = &hsv_to_rgb(rand(), $opts{saturation}, $opts{value});
		
		push (@colors, [$r, $g, $b]);
	}
	
	return \@colors;
}

=head2 hsv_to_rgb

Convert na HSV color to RGB, nicely.

=cut 
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


=head2 function2

=cut

sub function2 {
}

=head1 AUTHOR

Brian Hann, C<< <brian.hann at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-html-wordcloud at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=HTML-WordCloud>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc HTML::WordCloud


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=HTML-WordCloud>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/HTML-WordCloud>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/HTML-WordCloud>

=item * Search CPAN

L<http://search.cpan.org/dist/HTML-WordCloud/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2012 Brian Hann.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of HTML::WordCloud
