package Bio::EnsEMBL::GlyphSet::variation;
use strict;
use vars qw(@ISA);
use Bio::EnsEMBL::GlyphSet_simple;
use Bio::EnsEMBL::Utils::Eprof qw(eprof_start eprof_end eprof_dump);

@ISA = qw(Bio::EnsEMBL::GlyphSet_simple);

sub my_label { return "Variations"; }

sub features {
  my ($self) = @_;
  
  my @vari_features;# = 
             map { $_->[1] } 
             sort { $a->[0] <=> $b->[0] }
             map { [ substr($_->type,0,2) * 1e9 + $_->start, $_ ] }
             grep { $_->score < 4 } @{$self->{'container'}->get_all_VariationFeatures()};

  warn "here are var @vari_features", @{$self->{'container'}->get_all_VariationFeatures};
  if(@vari_features) {
    $self->{'config'}->{'snp_legend_features'}->{'snps'} 
        = { 'priority' => 1000, 'legend' => [] };
  }

  return \@vari_features;
}

sub href {
    my ($self, $f ) = @_;
    my( $chr_start, $chr_end ) = $self->slice2sr( $f->start, $f->end );
    my $snp_id = $f->snpid || $f->id;

    my $source = $f->source_tag;
    my $chr_name = $self->{'container'}->seq_region_name();  # call seq region on slice

    return "/@{[$self->{container}{_config_file_name_}]}/variationview?snp=$snp_id&source=$source&chr=$chr_name&vc_start=$chr_start";
}

sub image_label {
  my ($self, $f) = @_;
  return $f->{'_ambiguity_code'} eq '-' ? undef : ($f->{'_ambiguity_code'},'overlaid');
}

sub tag {
  my ($self, $f) = @_;
   if($f->{'_range_type'} eq 'between' ) {
      my $type = substr($f->type(),3,6);
      return ( { 'style' => 'insertion', 'colour' => $self->{'colours'}{"_$type"} } );
   } else {
      return undef;
   }
}

sub colour {
  my ($self, $f) = @_;

  my $type = substr($f->type(),3,6);
  unless($self->{'config'}->{'snp_types'}{$type}) {
    my %labels = (
	 '_coding' => 'Coding SNPs',
	 '_utr'    => 'UTR SNPs',
	 '_intron' => 'Intronic SNPs',
	 '_local'  => 'Flanking SNPs',
	 '_'       => 'Other SNPs' );
    push @{ $self->{'config'}->{'snp_legend_features'}->{'snps'}->{'legend'}},
           $labels{"_$type"} => $self->{'colours'}{"_$type"};
    $self->{'config'}->{'snp_types'}{$type} = 1;
  }

  return $self->{'colours'}{"_$type"},$self->{'colours'}{"label_$type"}, $f->{'_range_type'} eq 'between' ? 'invisible' : '';
}


sub zmenu {
    my ($self, $f ) = @_;
    my( $chr_start, $chr_end ) = $self->slice2sr( $f->start, $f->end );

    my $allele = $f->alleles;
    my $pos =  $chr_start;
    if($f->{'range_type'} eq 'between' ) {
       $pos = "between&nbsp;$chr_start&nbsp;&amp;&nbsp;$chr_end";
    } elsif($f->{'range_type'} ne 'exact' ) {
       $pos = "$chr_start&nbsp;-&nbsp;$chr_end";
   }
    my %zmenu = ( 
        'caption'           => "SNP: " . ($f->snpid || $f->id),
        '01:SNP properties' => $self->href( $f ),
        "02:bp: $pos" => '',
        "03:class: ".$f->snpclass => '',
        "03:status: ".$f->status => '',
        "06:mapweight: ".$f->{'_mapweight'} => '',
        "07:ambiguity code: ".$f->{'_ambiguity_code'} => '',
        "08:alleles: ".(length($allele)<16 ? $allele : substr($allele,0,14).'..') => ''
   );

    my %links;
    
    my $source = $f->source_tag; 
    foreach my $link ($f->each_DBLink()) {
      my $DB = $link->database;
      if( $DB eq 'TSC-CSHL' || $DB eq 'HGBASE' || ($DB eq 'dbSNP' && $source eq 'dbSNP') || $DB eq 'WI' ) {
        $zmenu{"16:$DB:".$link->primary_id } = $self->ID_URL( $DB, $link->primary_id );
      }
    }
    my $type = substr($f->type(),3);
    $zmenu{"57:Type: $type"} = "" unless $type eq '';  
    return \%zmenu;
}
1;
