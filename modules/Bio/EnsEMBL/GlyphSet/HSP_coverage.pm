#########
# Author: rmp
# Maintainer: rmp
# Created: 2003-03-05
# Last Modified: 2003-03-05
# Description:
# Colour gradient demonstrating HSP coverage of query-sequence
#
package Bio::EnsEMBL::GlyphSet::HSP_coverage;
use strict;
use vars qw(@ISA);
use Bio::EnsEMBL::GlyphSet;
@ISA = qw(Bio::EnsEMBL::GlyphSet);
use Sanger::Graphics::Bump;

sub init_label {
  my ($self) = @_;
  return if( defined $self->{'config'}->{'_no_label'} );
  my $label = Sanger::Graphics::Glyph::Text->new({
						  'text'      => "coverage",
						  'font'      => 'Small',
						  'absolutey' => 1,
						 });
  $self->label($label);
}

sub _init {
  my ($self)       = @_;
  my $container    = $self->{'container'};
  my $config       = $self->{'config'};
  my $sample_size  = int($container->length() / 1000) || 1;
  my @all_hsps     = $container->hsps;
  my $distribution = {};

  return if(scalar @all_hsps < 2);

  @all_hsps = sort {$a->start() <=> $b->start() || 
                      $a->end() <=> $b->end() } @all_hsps;

  while(my $hsp = shift @all_hsps) {
    my $sample_sskip = $hsp->start() % $sample_size;
    my $sample_start = $hsp->start() - $sample_sskip;
    my $sample_eskip = $hsp->end() % $sample_size;
    my $sample_end   = $hsp->end();
    $sample_end     += $sample_size if($sample_eskip != 0);

    for (my $i = $sample_start; $i <= $sample_end; $i+=$sample_size) {
      for (my $j = $i; $j<$i+$sample_size; $j++) {
	$distribution->{$i}++;
      }
    }
  }
  my $max = (sort {$b <=> $a} values %$distribution)[0];

  return if($max == 0);

  my $smax = 50;

  while(my ($pos, $val) = each %$distribution) {
    my $sval   = $smax * $val / $max;
    my $colour = "black";

    if($sval == $smax) {
      $colour = "red";
    } else {
      my $inv = int(100 - $sval);
      $colour = "grey$inv";
    }

    $self->push(Sanger::Graphics::Glyph::Rect->new({
						    'x'      => $pos,
						    'y'      => $smax/3 - $sval/3,
						    'width'  => $sample_size,
						    'height' => $sval/3,
						    'colour' => $colour,
						   }));
  }

  #########
  # sneakily cover up those annoying rounding errors ;)
  # yeah baby!
  #
  $self->push(Sanger::Graphics::Glyph::Rect->new({
						  'x'      => 0,
						  'y'      => $smax/3,
						  'width'  => $container->length(),
						  'height' => 0,
						  'colour' => "white",
						 }));

}

1;
