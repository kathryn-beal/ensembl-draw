package Bio::EnsEMBL::GlyphSet::Ppfam;
use strict;
use vars qw(@ISA);
use Bio::EnsEMBL::GlyphSet;
@ISA = qw(Bio::EnsEMBL::GlyphSet);
use Sanger::Graphics::Glyph::Rect;
use Sanger::Graphics::Glyph::Text;
use Sanger::Graphics::Glyph::Composite;
use Sanger::Graphics::ColourMap;
use  Sanger::Graphics::Bump;
use ExtURL;

sub init_label {
    my ($self) = @_;
	return if( defined $self->{'config'}->{'_no_label'} );
    my $label = new Sanger::Graphics::Glyph::Text({
	'text'      => 'Pfam',
	'font'      => 'Small',
	'absolutey' => 1,
    });
    $self->label($label);
}

sub _init {
    my ($self) = @_;
    my %hash;
    my $caption       = "Pfam";
    my @bitmap        = undef;
    my $protein       = $self->{'container'};
    my $Config        = $self->{'config'};
    my $pix_per_bp    = $Config->transform->{'scalex'};
    my $bitmap_length = int($self->{'container'}->length() * $pix_per_bp);
    my $y             = 0;
    my $h             = 4;
    my $cmap          = new Sanger::Graphics::ColourMap;
    my $black         = $cmap->id_by_name('black');
    my $red           = $cmap->id_by_name('red');
    my $font          = "Small";
    my $colour        = $Config->get('Ppfam','col');
    my ($fontwidth,
	$fontheight)  = $Config->texthelper->px2bp($font);
    my $ext_url = ExtURL->new;

    #foreach my $feat ($protein->each_Protein_feature()) {
       #if ($feat->feature2->seqname =~ /^PF\w+/) {
    my @pf_feat = @{$protein->get_all_PfamFeatures()};
    foreach my $feat(@pf_feat) {
	push(@{$hash{$feat->feature2->seqname}},$feat);
    }
       #}
   #}
    
    foreach my $key (keys %hash) {
	my @row  = @{$hash{$key}};
	my $desc = $row[0]->idesc();
		
	my $Composite = new Sanger::Graphics::Glyph::Composite({
	    'x'     => $row[0]->feature1->start(),
	    'y'     => $y,
	    'zmenu' => {
		'caption' => "Pfam domain",
		$key      => $ext_url->get_url( 'PFAM', $key )
	    },
	});

	my $pfsave;
	my ($minx, $maxx);
		
	foreach my $pf (@row) {
	    my $x  = $pf->feature1->start();
	    $minx  = $x if ($x < $minx || !defined($minx));
	    my $w  = $pf->feature1->end() - $x;
	    $maxx  = $pf->feature1->end() if ($pf->feature1->end() > $maxx || !defined($maxx));
	    my $id = $pf->feature2->seqname();

	    my $rect = new Sanger::Graphics::Glyph::Rect({
		'x'        => $x,
		'y'        => $y,
		'width'    => $w,
		'height'   => $h,
		'colour'   => $colour,
	    });
	    $Composite->push($rect);
	    $pfsave = $pf;
	}

	#########
	# add a domain linker
	#
	my $rect = new Sanger::Graphics::Glyph::Rect({
	    'x'         => $minx,
	    'y'         => $y + 2,
	    'width'     => $maxx - $minx,
	    'height'    => 0,
	    'colour'    => $colour,
	    'absolutey' => 1,
	});
	$Composite->push($rect);

	my $desc = $pfsave->idesc() || $key;

	my $text = new Sanger::Graphics::Glyph::Text({
	    'font'   => $font,
	    'text'   => $desc,
	    'x'      => $row[0]->feature1->start(),
	    'y'      => $h + 1,
	    'height' => $fontheight,
	    'width'  => $fontwidth * length($desc),
	    'colour' => $black,
	});
	$Composite->push($text);

	if ($Config->get('Ppfam', 'dep') > 0){ # we bump
            my $bump_start = int($Composite->x() * $pix_per_bp);
            $bump_start = 0 if ($bump_start < 0);
	    
            my $bump_end = $bump_start + int($Composite->width()*$pix_per_bp);
            if ($bump_end > $bitmap_length){$bump_end = $bitmap_length};
            my $row = & Sanger::Graphics::Bump::bump_row(
				      $bump_start,
				      $bump_end,
				      $bitmap_length,
				      \@bitmap
				      );
            $Composite->y($Composite->y() + (1.5 * $row * ($h + $fontheight)));
        }
	
	$self->push($Composite);
    }

}

1;


