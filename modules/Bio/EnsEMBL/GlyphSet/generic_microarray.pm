package Bio::EnsEMBL::GlyphSet::generic_microarray;
use strict;
use vars qw(@ISA);
use Bio::EnsEMBL::GlyphSet_feature;
@ISA = qw(Bio::EnsEMBL::GlyphSet_feature);

sub my_label { 
  my $self = shift;
  my $key = '_my_label';
  if( ! exists( $self->{$key} ) ){
    my $misc_set_code = $self->my_config('FEATURES') || 
      die( "The FEATURES key of UserConfig must be a misc_set_code" );
    my $db_adaptor = $self->{'container'}->adaptor->db;
    my $msa_adaptor = $db_adaptor->get_MiscSetAdaptor;
    my $misc_set = $msa_adaptor->fetch_by_code( $misc_set_code ) ||
      die( "The misc_set_code $misc_set_code is not found in the DB" );
    $self->{$key} = $misc_set->name;
  }
  return $self->{$key};
}

## Retrieve all MiscFeatures from the misc_set table of the database
## corresponding to the misc_set_code (UserConfig FEATURES key)

sub features {
    my ($self) = @_;
    my $misc_set_code = $self->my_config('FEATURES') || 
      die( "The FEATURES key of UserConfig must be a misc_set_code" );
    return $self->{'container'}->get_all_MiscFeatures( $misc_set_code );
}

## Return the image label and the position of the label
## (overlaid means that it is placed in the centre of the
## feature.

sub image_label {
  my ($self, $f ) = @_;
  return( $f->get_scalar_attribute('name'), 'overlaid' );
}

## Link back to this page centred on the map fragment

sub href {
  my ($self, $f ) = @_;
  return '';
}


## Create the zmenu...
## Include each accession id separately
sub zmenu {
    my ($self, $f ) = @_;
    return undef();
    my $zmenu = { 
        'caption' => $f->get_scalar_attribute('name'),
    };
    return $zmenu;
}

1;