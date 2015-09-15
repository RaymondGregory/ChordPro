#!/usr/bin/perl

package Music::ChordPro::Output::PDF;

use strict;
use warnings;
use Data::Dumper;

sub generate_songbook {
    my ($self, $sb, $options) = @_;

    my $ps = page_settings( $options );
    $ps->{pr} = PDFWriter->new( $ps, $options->{output} || "__new__.pdf" );
    my @tm = gmtime(time);
    $ps->{pr}->info( Title => $sb->{songs}->[0]->{title},
		     Creator => "pChord [$options->{_name} $options->{_version}]",
		     CreationDate =>
		     sprintf("D:%04d%02d%02d%02d%02d%02d+00'00'",
			     1900+$tm[5], 1+$tm[4], @tm[3,2,1,0]),
		   );

    my @book;
    foreach my $song ( @{$sb->{songs}} ) {
	if ( @book ) {
	    $ps->{pr}->newpage;
	    push(@book, "{new_song}");
	}
	showlayout($ps);
	generate_song( $song, { ps => $ps, $options ? %$options : () } );
    }
    $ps->{pr}->finish;
    []
}

my $single_space = 0;		# suppress chords line when empty
my $lyrics_only = 0;		# suppress all chord lines

sub generate_song {
    my ($s, $options) = @_;

    my $ps = $options->{ps};
    my $x = $ps->{marginleft} + $ps->{offsets}->[0];
    my $y = $ps->{papersize}->[1] - $ps->{margintop};
    $s->structurize
      if ( $options->{'backend-option'}->{structure} // '' ) eq 'structured';

    my $sb = $s->{body};
    $ps->{column} = 0;
    $ps->{columns} = $s->{settings}->{columns} || 1;
    my $st = $s->{settings}->{titles} || "left";

    $single_space = $options->{'single-space'};
    $lyrics_only = 2 * $options->{'lyrics-only'};

    for ( $options->{'text-font'} ) {
	next unless $_ && m;/;;
	$ps->{fonts}->{text}->{file} = $_;
    }
    for ( $options->{'text-size'} ) {
	next unless $_;
	$ps->{fonts}->{text}->{size} = $_;
    }
    for ( $options->{'chord-font'} ) {
	next unless $_ && m;/;;
	$ps->{fonts}->{chord}->{file} = $_;
    }
    for ( $options->{'chord-size'} ) {
	next unless $_;
	$ps->{fonts}->{chord}->{size} = $_;
    }
    $ps->{lineheight} = $ps->{fonts}->{text}->{size} - 1; # chordii
    $ps->{chordheight} = $ps->{fonts}->{chord}->{size};
    $ps->{'vertical-space'} = $options->{'vertical-space'};

    my $show = sub {
	my ( $text, $font ) = @_;
	my $x = $x;
	if ( $st eq "right" ) {
	    $ps->{pr}->setfont($font);
	    $x = $ps->{papersize}->[0]
		 - $ps->{marginright}
		 - $ps->{pr}->strwidth($text);
	}
	elsif ( $st eq "center" || $st eq "centre" ) {
	    $ps->{pr}->setfont($font);
	    $x = $ps->{marginleft} +
	         ( $ps->{papersize}->[0]
		   - $ps->{marginright}
		   - $ps->{marginleft}
		   - $ps->{pr}->strwidth($text) ) / 2;
	}
	$ps->{pr}->text( $text, $x, $y, $font );
	$y -= $font->{size};
    };

    if ( $s->{title} ) {
	$show->( $s->{title}, $ps->{fonts}->{title} );
    }

    if ( $s->{subtitle} ) {
	for ( @{$s->{subtitle}} ) {
	    $show->( $_, $ps->{fonts}->{subtitle} );
	}
    }

    if ( $s->{title} or $s->{subtitle} ) {
	$y -= $ps->{headspace};
    }

    my $y0 = $y;
    my $cskip = 0;

    foreach my $elt ( @{$sb} ) {

	$cskip = 0 unless $elt->{type} =~ /^comment/;

	if ( $elt->{type} eq "newpage" ) {
	    $ps->{pr}->newpage;
	    showlayout($ps);
	    $x = $ps->{marginleft} + $ps->{offsets}->[$ps->{column} = 0];
	    $y0 = $y = $ps->{papersize}->[1] - $ps->{margintop} - $ps->{headspace};
	    next;
	}

	if ( $elt->{type} eq "colb" ) {
	    if ( ++$ps->{column} >= $ps->{columns}) {
		$ps->{pr}->newpage;
		showlayout($ps);
		$x = $ps->{marginleft} + $ps->{offsets}->[$ps->{column} = 0];
		$y = $ps->{papersize}->[1] - $ps->{margintop};
	    }
	    else {
		$x = $ps->{marginleft} + $ps->{offsets}->[$ps->{column}];
		$y = $y0;
	    }
	    next;
	}

	if ( $elt->{type} eq "empty" ) {
	    my $y0 = $y;
	    warn("***SHOULD NOT HAPPEN1***")
	      if $s->{structure} eq "structured";
	    $y -= $ps->{lineheight} + 4 + $ps->{'vertical-space'}; # chordii
	    next;
	}

	if ( $elt->{type} eq "songline" ) {
	    if ( $elt->{context} eq "chorus" ) {
		my $cy = $y + $ps->{lineheight} - 2 + $ps->{'vertical-space'};
		$y = songline( $elt, $x, $y, $ps );
		my $cx = $ps->{marginleft} + $ps->{offsets}->[0] - 10;
		$ps->{pr}->{pdfgfx}
		  ->move( $cx, $cy+1 )
		  ->linewidth(1)
		  ->vline( $y - 2 + $ps->{lineheight} + $ps->{'vertical-space'} )
		  ->stroke;
	    }
	    else {
		$y = songline( $elt, $x, $y, $ps );
	    }
	    next;
	}

	if ( $elt->{type} eq "chorus" ) {
	    my $cy = $y + $ps->{lineheight} - 2 + $ps->{'vertical-space'};
	    foreach my $e ( @{$elt->{body}} ) {
		if ( $e->{type} eq "songline" ) {
		    $y = songline( $e, $x, $y, $ps );
		    next;
		}
		elsif ( $e->{type} eq "empty" ) {
		    warn("***SHOULD NOT HAPPEN2***");
		    $y -= $ps->{lineheight} + $ps->{'vertical-space'};
		    next;
		}
	    }
	    my $cx = $ps->{marginleft} + $ps->{offsets}->[0] - 10;
#	    sprintf( "%d %d m %d %d l S",
#		     $cx, $cy, $cx, $y+$ps->{lineheight} )
	    $ps->{pr}->{pdfgfx}
	      ->move( $cx, $cy )
	      ->linewidth(1)
	      ->vline( $y + $ps->{lineheight} + $ps->{'vertical-space'} )
	      ->stroke;
	    $y -= $ps->{lineheight} + 4 + $ps->{'vertical-space'}; # chordii
	    next;
	}

	if ( $elt->{type} eq "verse" ) {
	    foreach my $e ( @{$elt->{body}} ) {
		if ( $e->{type} eq "songline" ) {
		    $y = songline( $e, $x, $y, $ps );
		    next;
		}
		elsif ( $e->{type} eq "empty" ) {
		    warn("***SHOULD NOT HAPPEN2***");
		    $y -= $ps->{lineheight} + $ps->{'vertical-space'};
		    next;
		}
	    }
	    $y -= $ps->{lineheight} + 4 + $ps->{'vertical-space'}; # chordii
	    next;
	}

	if ( $elt->{type} eq "tab" ) {
	    $ps->{pr}->setfont( $ps->{fonts}->{tab} );
	    my $dy = $ps->{fonts}->{tab}->{size};
	    foreach my $e ( @{$elt->{body}} ) {
		next unless $e->{type} eq "tabline";
		$ps->{pr}->text( $e->{text}, $x, $y );
		$y -= $dy;
	    }
	    next;
	}

	if ( $elt->{type} eq "tabline" ) {
	    $ps->{pr}->setfont( $ps->{fonts}->{tab} );
	    my $dy = $ps->{fonts}->{tab}->{size};
	    $ps->{pr}->text( $elt->{text}, $x, $y );
	    $y -= $dy;
	    next;
	}

	if ( $elt->{type} eq "comment" ) {
	    $y += $ps->{'vertical-space'} if $cskip++;
	    my $font = $ps->{fonts}->{comment} || $ps->{fonts}->{text};
	    $ps->{pr}->setfont( $font );
	    my $text = $elt->{text};
	    my $w = $ps->{pr}->strwidth( $text );
	    my $y0 = $y;
	    my $y1 = $y0 + 0.8*($font->{size});
	    $y0 -= 0.2*($font->{size});
	    my $grey = "0.9";
	    my $x1 = $x + $w;
	    if ( 0 ) {
		# This causes the text to be hidden behind the grey.
		$ps->{pr}->{pdftext}->fillcolor("#E5E5E5");
		$ps->{pr}->{pdftext}->strokecolor("#E5E5E5");
		$ps->{pr}->{pdftext}
		  ->rectxy( $x, $y, $x1, $y1 )
		  ->linewidth(3)
		  ->fillstroke;
	    }
	    else {
		# This works, but is too lowlevel.
		$ps->{pr}->{pdftext}->add
		  ("q",
		   "$grey $grey $grey rg $grey $grey $grey RG",
		   "3 w",
		   "$x $y0 m $x $y1 l $x1 $y1 l $x1 $y0 l b",
		   "Q");
	    }
	    $ps->{pr}->text( $text, $x, $y );
	    $y -= $ps->{lineheight} + $ps->{'vertical-space'};
	    next;
	}

	if ( $elt->{type} eq "comment_italic" ) {
	    my $font = $ps->{fonts}->{comment_italic} || $ps->{fonts}->{chord};
	    $ps->{pr}->setfont( $font );
	    $ps->{pr}->text( $elt->{text}, $x, $y );
	    $y -= $ps->{lineheight} + $ps->{'vertical-space'};
	    next;
	}

	if ( $elt->{type} eq "control" ) {
	    if ( $elt->{name} eq "lyrics-only" ) {
		$lyrics_only = $elt->{value}
		  unless $lyrics_only > 1;
	    }
	}
    }
}

sub songline {
    my ( $elt, $x, $y, $ps ) = @_;
    my $ftext = $ps->{fonts}->{text};

    if ( $lyrics_only
	 or
	 $single_space && ! ( $elt->{chords} && join( "", @{ $elt->{chords} } ) =~ /\S/ )
       ) {
	$ps->{pr}->text( join( "", @{ $elt->{phrases} } ), $x, $y+2, $ftext );
	return $y - ($ps->{lineheight} + $ps->{'vertical-space'});
    }

    $elt->{chords} //= [ '' ];

    my $fchord = $ps->{fonts}->{chord};
    foreach ( 0..$#{$elt->{chords}} ) {
	my $chord = $elt->{chords}->[$_];
	my $phrase = $elt->{phrases}->[$_];
	my $xt0 = $ps->{pr}->text( $chord." ", $x, $y, $fchord );
	my $xt1 = $ps->{pr}->text( $phrase, $x, $y-$ps->{lineheight}, $ftext );
	$x = $xt0 > $xt1 ? $xt0 : $xt1;
    }
    return $y - ($ps->{lineheight} + $ps->{'vertical-space'}) - $ps->{chordheight};
}

sub page_settings {
  # Pretty hardwired for now.

  # Add font dirs.
  PDF::API2::addFontDirs( $ENV{HOME} . "/.fonts" );

  my $ret =
  { papersize     => [ 595, 842 ],	# A4, portrait
    marginleft    => 130,
    margintop     => 66,
    marginbottom  => 40,
    marginright   => 40,
    headspace     => 20,
    offsets       => [ 0, 250 ],	# col 1, col 2
    xxfonts      => {
	title   => { name => 'Times-Bold',
		     size => 14 },
	subtitle=> { name => 'Times-Bold',
		     size => 12 },
	text    => { name => 'Garamond-Light',
		     size => 14 },
        chord   => { name => 'Helvetica-LightOblique',
		     size => 10 },
        comment => { name => 'Times-Roman',
		     size => 12 },
    },
    fonts         => {
	title   => { file => 'ITCGaramond-Light.ttf',
		     size => 14 },
	subtitle=> { file => 'ITCGaramond-Light.ttf',
		     size => 12 },
        text =>  { file => 'ITCGaramond-Light.ttf',
		   size => 14 },
        xxchord => { file    => 'Helvetica-LightOblique.pfb',
		   metrics => 'Helvetica-LightOblique.afm',
		   size    => 10 },
        chord => { file => 'Myriad-CnSemibold.ttf',
		   size => 14 },
        tab => { name => 'Courier',
		   size => 10 },
        comment => { file => 'GillSans.ttf',
		     size => 12 },
        comment_italic => { file => 'GillSans-Italic.ttf',
		     size => 12 },
    },
  };

    # Sanitize.
    $ret->{fonts}->{subtitle}       ||= $ret->{fonts}->{text};
    $ret->{fonts}->{comment_italic} ||= $ret->{fonts}->{chord};
    $ret->{fonts}->{comment}        ||= $ret->{fonts}->{text};

    return $ret;
}

sub showlayout {
    my ( $ps ) = @_;
    $ps->{pr}->{pdfgfx}
      ->linewidth(0.5)
      ->rectxy( $ps->{marginleft},
		$ps->{marginbottom},
		$ps->{papersize}->[0]-$ps->{marginright},
		$ps->{papersize}->[1]-$ps->{margintop} )
      ->stroke;
    $ps->{pr}->{pdfgfx}
      ->linewidth(0.25)
      ->move( $ps->{marginleft}+$ps->{offsets}->[1],
	      $ps->{marginbottom} )
      ->vline( $ps->{papersize}->[1]-$ps->{margintop} )
      ->stroke;
}

package PDFWriter;

use strict;
use warnings;
use PDF::API2;
use Encode;

my %fonts;

sub new {
    my ( $pkg, $ps, @file ) = @_;
    my $self = bless { ps => $ps }, $pkg;
    $self->{pdf} = PDF::API2->new( -file => $file[0] );
    $self->{pdf}->{forcecompress} = 0;
    $self->newpage;
    $self;
}

sub info {
    my ( $self, %info ) = @_;
    $self->{pdf}->info( %info );
}

sub text {
    my ( $self, $text, $x, $y, $font, $size ) = @_;
    $font ||= $self->{font};
    $size ||= $font->{size};

    $self->setfont($font, $size);

    $text = encode( "cp1250", $text ) unless $font->{file};
    $self->{pdftext}->translate( $x, $y );
    return $x + $self->{pdftext}->text($text);
}

sub setfont {
    my ( $self, $font, $size ) = @_;
    $self->{font} = $font;
    $self->{fontsize} = $size ||= $font->{size};
    $self->{pdftext}->font( $self->_getfont($font), $size );
}

sub _getfont {
    my ( $self, $font ) = @_;
    $self->{font} = $font;
    if ( $font->{file} ) {
	if ( $font->{file} =~ /\.[ot]tf$/ ) {
	    return $fonts{$font->{file}} ||=
	      $self->{pdf}->ttfont( $font->{file},
				    -dokern => 1 );
	}
	elsif ( $font->{file} =~ /\.pf[ab]$/ ) {
	    return $fonts{$font->{file}} ||=
	      $self->{pdf}->psfont( $font->{file},
				    -afmfile => $font->{metrics},
				    -dokern  => 1 );
	}
	else {
	    return $self->{pdf}->corefont( 'Courier' );
	}
    }
    else {
	return $fonts{$font->{name}} ||=
	  $self->{pdf}->corefont( $font->{name} );
    }
}

sub strwidth {
    my ( $self, $text, $font, $size ) = @_;
    $font ||= $self->{font};
    $size ||= $font->{size};
    $self->setfont( $font, $size );
    $self->{pdftext}->advancewidth($text);
}

sub newpage {
    my ( $self ) = @_;
    #$self->{pdftext}->textend if $self->{pdftext};
    $self->{pdfpage} = $self->{pdf}->page;
    $self->{pdfpage}->mediabox('A4');
    $self->{pdftext} = $self->{pdfpage}->text;
    $self->{pdfgfx}  = $self->{pdfpage}->gfx;
}

sub add {
    my ( $self, @text ) = @_;
#    prAdd( "@text" );
}

sub finish {
    my $self = shift;
    #$self->{pdftext}->textend if $self->{pdftext};
    $self->{pdf}->save;
}

1;
