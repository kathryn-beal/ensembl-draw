package Bio::EnsEMBL::GlyphSetManager;
use strict;
use vars qw(@ISA);
@ISA = qw(Sanger::Graphics::GlyphSetManager);

sub species_defs { return $_[0]->{'config'}->{'species_defs'}; }

1;
