package Bio::EnsEMBL::GlyphSet::gene_legend;
use strict;
use vars qw(@ISA);
use Bio::EnsEMBL::GlyphSet;
@ISA = qw(Bio::EnsEMBL::GlyphSet);
use Bio::EnsEMBL::Glyph::Rect;
use Bio::EnsEMBL::Glyph::Text;
use Bump;
use Bio::EnsEMBL::Utils::Eprof qw(eprof_start eprof_end);

sub init_label {
    my ($self) = @_;
        return if( defined $self->{'config'}->{'_no_label'} );
    my $label = new Bio::EnsEMBL::Glyph::Text({
        'text'      => 'Legend',
        'font'      => 'Small',
        'absolutey' => 1,
    });
    $self->label($label);
}

sub _init {
    my ($self) = @_;

    return unless ($self->strand() == -1);

    my $vc = $self->{'container'};
    my $Config        = $self->{'config'};
    my $y             = 0;
    my $h             = 4;
    my $im_width      = $Config->image_width();
    my $type          = $Config->get('gene_legend', 'src');
    my $NO            = 3;
    my $BOX_WIDTH     = 20;
    my $fontname      = "Tiny";
    # call on ensembl lite to give us the details of all
    # genes in the virtual contig
    my @colours = (
	'Known genes' , $Config->get('gene_legend','known'),
        'EMBL curated genes' , $Config->get('gene_legend','ext'),
        'Sanger curated genes' , $Config->get('gene_legend','sanger'),
        'Unknown genes', $Config->get('gene_legend','unknown'),
        'EMBL pseudogenes' , $Config->get('gene_legend','pseudo'),
        'Sanger pseudogenes' => $Config->get('gene_legend','sangerpseudo')
    );
    my ($x,$y) = (0,0);
     my $rect = new Bio::EnsEMBL::Glyph::Rect({
       'x'         => 0,
       'y'         => 0,
       'width'     => $im_width, 
       'height'    => 0,
       'colour'    => $Config->colourmap->id_by_name('grey3'),
       'absolutey' => 1,
       'absolutex' => 1,
     });
     $self->push($rect);
    while( my ($legend, $colour) = splice @colours, 0, 2 ) {
     ## Draw box
     my $rect = new Bio::EnsEMBL::Glyph::Rect({
       'x'         => $im_width * $x/$NO,
       'y'         => $y * $h * 2 + 6,
       'width'     => $BOX_WIDTH, 
       'height'    => $h,
       'colour'    => $colour,
       'absolutey' => 1,
       'absolutex' => 1,
     });
     my $tglyph = new Bio::EnsEMBL::Glyph::Text({
            'x'         => $im_width * $x/$NO + $BOX_WIDTH,
            'y'         => $y * $h * 2 + 4,
            'height'    => $Config->texthelper->height($fontname),
            'font'      => $fontname,
            'colour'    => $colour,
            'text'      => uc(" $legend"),
            'absolutey' => 1,
            'absolutex' => 1,
     });
     $self->push($rect);
     $self->push($tglyph);
     ## Write text;
     $x++;
     if($x==$NO) { $x=0; $y++ }
    }
}

1;
        
