package Bio::EnsEMBL::GlyphSet::das;
use strict;
use vars qw(@ISA);
use Bio::EnsEMBL::GlyphSet;
@ISA = qw(Bio::EnsEMBL::GlyphSet);
use Bio::EnsEMBL::Glyph::Composite;
use Bio::EnsEMBL::Glyph::Rect;
use Bio::EnsEMBL::Glyph::Text;
use ExtURL;
use SiteDefs;

sub init_label {
    my ($self) = @_;
    return if( defined $self->{'config'}->{'_no_label'} );

    my $label = new Bio::EnsEMBL::Glyph::Text({
	'text'      => $self->{'extras'}->{'caption'},
	'font'      => 'Small',
    'colour'    => $self->{'config'}->colourmap()->id_by_name('contigblue2'),
	'absolutey' => 1,
        'href'      => qq[javascript:X=window.open(\'/$ENV{'ENSEMBL_SPECIES'}/helpview?se=1&kw=$ENV{'ENSEMBL_SCRIPT'}#das\',\'helpview\',\'height=400,width=500,left=100,screenX=100,top=100,screenY=100,resizable,scrollbars=yes\');X.focus();void(0)],


    'zmenu'     => {
            'caption'                     => 'HELP',
            "01:Track information..."     =>
qq[javascript:X=window.open(\\\'/$ENV{'ENSEMBL_SPECIES'}/helpview?se=1&kw=$ENV{'ENSEMBL_SCRIPT'}#das\\\',\\\'helpview\\\',\\\'height=400,width=500,left=100,screenX=100,top=100,screenY=100,resizable,scrollbars=yes\\\');X.focus();void(0)]
        }
    });
    $self->label($label);
}

sub _init {
    my ($self) = @_;

    my $Config         	= $self->{'config'};
    my $das_name        = $self->das_name();
	my $strand          = $Config->get($das_name, 'str');
# If strand is 'r' or 'f' then we display everything on one strand (either
# at the top or at the bottom!

    return if( $strand eq 'r' && $self->strand() != -1 || $strand eq 'f' && $self->strand() != 1 );

    $self->{'bitmap'} = [];	
    my $tstrand = $self->strand;
    my $cmap            = $Config->colourmap();
    my $feature_colour 	= $Config->get($das_name, 'col') || $Config->colourmap()->id_by_name('contigblue1');
	my $dep             = $Config->get($das_name, 'dep');
	my $group           = $Config->get($das_name, 'group');
    my $vc 		        = $self->{'container'};
    my $border          = $Config->colourmap()->id_by_name('black');
    my $red             = $Config->colourmap()->id_by_name('red');
    my ($w,$h)          = $Config->texthelper()->real_px2bp('Tiny');
    my $length          = $vc->length() +1;

    $self->{'pix_per_bp'} = $Config->transform->{'scalex'};
    $self->{'bitmap_length'} = int(($length+1) * $self->{'pix_per_bp'});

    $w *= ($length+1)/$length;
    
    my @features;
    eval{
        @features = grep { ($_->das_dsn() eq $self->{'extras'}->{'dsn'}) && ($_->das_type_id() !~ /(contig|component|karyotype)/i) }$vc->get_all_DASFeatures();
    };
#    print STDERR map { "DAS: ". $_->das_dsn. ": ". $_->das_start."-".$_->das_end."|\n"}  @features;
    if($@) {
        print STDERR "----------\n",$@,"---------\n";
        return;
    }
    $self->{'link_text'}  = $self->{'extras'}->{'linktext'} || 'Additional info';
	if( $self->{'extras'}->{'linkURL'} ) {
        $self->{'ext_url'} =  $self->{'extras'}->{'name'} =~ /^extdas_/ ? 
			ExtURL->new( $self->{'extras'}->{'linkURL'} => $self->{'extras'}->{'linkURL'} ) :
			ExtURL->new();		
	}
	
    my $empty_flag  = 1;

    my $STRAND = $self->strand();
    if($group==1) {
	    my %grouped;
	    foreach my $f(@features){
            if($f->das_type_id() eq '__ERROR__') {
                $self->errorTrack( 'Error retrieving '.$self->{'extras'}->{'caption'}.' features ('.$f->id.')' );
		    	return;
            }
    		next if $strand eq 'b' && ( $f->strand() !=1 && $STRAND==1 || $f->strand() ==1 && $STRAND==-1);
    	    my $fid = $f->das_id;
		    next unless $fid;
		             $fid  = "G:".$f->das_group_id if $f->das_group_id;
		    $grouped{$fid} = [] unless(exists $grouped{$fid});
	   	    push @{$grouped{$fid}}, $f;
            $empty_flag = 0; # We have a feature (its on one of the strands!)
	    }

        if($empty_flag) {
			$self->errorTrack( 'No '.$self->{'extras'}->{'caption'}.' features in this region' );
		    return;
        }	
        
		foreach my $value (values %grouped) {
			my $f = $value->[0];
		## Display if not stranded OR
			my @features = sort { $a->das_start <=> $b->das_start } @$value;
			my $start = $features[0]->das_start;
			my $START = $start < 1 ? 1 : $start;
			my $end   = $features[-1]->das_end;
        ### A general list of features we don't want to draw via DAS ###
       
            my ($href, $zmenu ) = $self->zmenu( $f );
			my $Composite = new Bio::EnsEMBL::Glyph::Composite({
				'y'            => 0,
				'x'            => $START,
				'absolutey'    => 1,
            	'zmenu'        => $zmenu,
			});
			$Composite->{'href'} = $href if $href;
            
            ## if we are dealing with a transcript (CDS/transcript/exon) then join with introns...
            
            if( $f->das_type_id() =~ /(CDS|translation|transcript|exon)/i ) { ## TRANSCRIPT!
                my $f     = shift @features;
                my $START = $f->das_start() < 1        ? 1       : $f->das_start();
                my $END   = $f->das_end()   > $length  ? $length : $f->das_end();
                my $old_end = $END;
    			my $glyph = new Bio::EnsEMBL::Glyph::Rect({
        	        'x'      	=> $START,
    	    		'y'      	=> 0,
    	    		'width'  	=> $END-$START,
    		    	'height' 	=> 8,
    		    	'colour' 	=> $feature_colour,
    	    		'absolutey' => 1,
                	'zmenu'     => $zmenu
                });
                $end = $old_end if $end <= $old_end;
                $Composite->push($glyph);
    			foreach(@features) {
                    my $START = $f->das_start() <  1       ? 1 : $f->das_start();
    				$glyph = new Bio::EnsEMBL::Glyph::Intron({
                        'x'         => $old_end,
                        'y'         => 0,
                        'width'     => $_->das_start()-$old_end,
                        'height'    => 8,
                        'colour'    => $feature_colour,
                        'absolutey' => 1,
                        'strand'    => $STRAND,
                    });
    				$Composite->push($glyph);
                    my $END   = $_->das_end()   > $length  ? $length : $_->das_end();
                    $old_end = $END;
    				$glyph = new Bio::EnsEMBL::Glyph::Rect({
        	        	'x'      	=> $_->das_start(),
    	    			'y'      	=> 0,
    	    			'width'  	=> $END-$_->das_start(),
    		    		'height' 	=> 8,
    		    		'colour' 	=> $feature_colour,
    	    			'absolutey' => 1,
                		'zmenu'     => $zmenu
    				});
    				$Composite->push($glyph);
                    $end = $old_end if $end <= $old_end;
                }
            } else { ## GENERAL GROUPED FEATURE!
    			$Composite->bordercolour($feature_colour);
    			foreach(@features) {
                    my $START = $_->das_start() <  1       ? 1 : $_->das_start();
                    my $END   = $_->das_end()   > $length  ? $length : $_->das_end();
    				my $glyph = new Bio::EnsEMBL::Glyph::Rect({
        	        	'x'      	=> $START,
    	    			'y'      	=> 0,
    	    			'width'  	=> $END-$START,
    		    		'height' 	=> 8,
    		    		'colour' 	=> $feature_colour,
    	    			'absolutey' => 1,
                		'zmenu'     => $zmenu
    				});
    				$Composite->push($glyph);
                }
			}
            # DONT DISPLAY IF BUMPING AND BUMP HEIGHT TOO GREAT
            $self->push($Composite) unless( $dep>0 && $self->bump($Composite, $dep, $tstrand, $h ) );
    	}
  	} else {
		foreach my $f(@features){
        	if($f->das_type_id() eq '__ERROR__') {
				$self->errorTrack(
					'Error retrieving '.$self->{'extras'}->{'caption'}.
					' features ('.$f->id.')'
				);
		    	return;
        	}
	        $empty_flag = 0; # We have a feature (its on one of the strands!)
    		next if $strand eq 'b' && ( $f->strand() !=1 && $STRAND==1 || $f->strand() ==1 && $STRAND==-1);
                
			my ($href, $zmenu ) = $self->zmenu( $f );
            my $START = $f->das_start() <  1       ? 1       : $f->das_start();
            my $END   = $f->das_end()   > $length  ? $length : $f->das_end();
			my $Composite = new Bio::EnsEMBL::Glyph::Composite({
				'y'            => 0,
				'x'            => $START,
				'absolutey'    => 1,
            	'zmenu'        => $zmenu,
			});
			$Composite->{'href'} = $href if $href;
		
			my $glyph = new Bio::EnsEMBL::Glyph::Rect({
    	        'x'      	=> $START,
		    	'y'      	=> 0,
	    		'width'  	=> $END-$START,
		    	'height' 	=> 8,
	    		'colour' 	=> $feature_colour,
		    	'absolutey' => 1,
    	        'zmenu'     => $zmenu,
			});
			$Composite->push($glyph);
            # DONT DISPLAY IF BUMPING AND BUMP HEIGHT TOO GREAT
            $self->push($Composite) unless( $dep>0 && $self->bump($Composite, $dep, $tstrand, $h ) );
	    }
    
		$self->errorTrack( 'No '.$self->{'extras'}->{'caption'}.' features in this region' ) if $empty_flag;
    }   
}

sub bump{
    my ($self, $Composite, $dep, $tstrand, $h ) = @_;
    my $bump_start = int($Composite->x() * $self->{'pix_per_bp'} );
       $bump_start = 0 if ($bump_start < 0);

	my $bump_end = $bump_start + int($Composite->width() * $self->{'pix_per_bp'});
       $bump_end = $self->{'bitmap_length'} if ($bump_end > $self->{'bitmap_length'});
    my $row = &Bump::bump_row(
	    $bump_start,    $bump_end,   $self->{'bitmap_length'}, $self->{'bitmap'}
    );
    return 1 if ($row > $dep); ## DON'T DISPLAY!
    $Composite->y($Composite->y() - $tstrand * 1.4 * $row * $h);
    return 0;
}

sub zmenu {
        my( $self, $f ) = @_;
		my $href=undef;
        my $id = $f->das_id;
        my $zmenu = {
            'caption'         => $self->{'extras'}->{'label'},
#                "DAS source info" => $self->{'extras'}->{'url'},
        };
		$zmenu->{"TYPE: ". $f->das_type_id()           } = '' if $f->das_type_id() && uc($f->das_type_id()) ne 'NULL';
		$zmenu->{"SCORE: ". $f->das_score()            } = '' if $f->das_score() && uc($f->das_score()) ne 'NULL';
		$zmenu->{"GROUP: ". $f->das_group_id()         } = '' if $f->das_group_id() && uc($f->das_group_id()) ne 'NULL' && $f->das_group_id ne $id;

		$zmenu->{"METHOD: ". $f->das_method_id()       } = '' if $f->das_method_id() && uc($f->das_method_id()) ne 'NULL';
		$zmenu->{"CATEGORY: ". $f->das_type_category() } = '' if $f->das_type_category() && uc($f->das_type_category()) ne 'NULL';
		$zmenu->{"DAS LINK: ".$f->das_link_label()     } = $f->das_link() if $f->das_link() && uc($f->das_link()) ne 'NULL';
		if($id && uc($id) ne 'NULL') {
		    if($self->{'extras'}->{'linkURL'}){
			    $zmenu->{$self->{'link_text'}} = $href = $self->{'ext_url'}->get_url( $self->{'extras'}->{'linkURL'}, $id );
	        }
            $zmenu->{"ID: $id"} = '';
        }
        return( $href, $zmenu );
}


sub das_name {
    my ($self) = @_;
    return $self->{'extras'}->{'name'};
}

1;
