package Bio::EnsEMBL::GlyphSet::non_hum;
use strict;
use vars qw(@ISA);
use Bio::EnsEMBL::GlyphSet_feature;
@ISA = qw(Bio::EnsEMBL::GlyphSet_feature);

sub my_label { return "SWISSPROT"; }

sub features {
    my ($self) = @_;
    return $self->{'container'}->get_all_ProteinAlignFeatures("BLASTX_SPROT",1);
}

sub href {
    my ( $self, $id ) = @_;
    $id =~ s/(.*)\.\d+/$1/o;
    return $self->{'config'}->{'ext_url'}->get_url( 'SG_NON_HUM', $id );
}

sub zmenu {
    my ($self, $id ) = @_;
    $id =~ s/(.*)\.\d+/$1/o;
    return { 'caption' => "$id", "Protein homology" => $self->href( $id ) };
}

1;
