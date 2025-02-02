#! perl

use Test::More tests => 1;
use App::Music::ChordPro::Config::Properties;
use File::LoadLines;

# Take a big properties file, convert to data and dump.
my $orig = Data::Properties->new;
my $lines = loadlines(\*DATA);
$orig->parse_lines( $lines , '<data>' );
my $sorig = $orig->dump;

# Load the dump into a new properties file.
my $cfg = Data::Properties->new;
$cfg->parse_lines( [ split( /[\r\n]+/, $sorig ) ], '<dump>' );

# Should be identical.
is_deeply( $cfg->data, $orig->data );

__DATA__
# Configuration for ChordPro.

# Includes. These are processed first, before the rest of
# the config file.
#
# "include" takes a list of either filenames or preset names.
include.0 = "guitar"

# General settings, to be changed by legacy configs and
# command line.
settings {
  # Titles flush: default center.
  titles = "center"
  # Columns, default one.
  columns = 1
  # Suppress empty chord lines.
  # Overrides the -a (--single-space) command line options.
  suppress-empty-chords = true
  # Suppress blank lyrics lines.
  suppress-empty-lyrics = true
  # Suppress chords.
  # Overrides --lyrics-only command line option.
  lyrics-only = false
  # Memorize chords in sections, to be recalled by [^].
  memorize = false
  # Chords inline.
  # May be a string containing pretext %s posttext.
  # Defaults to "[%s]" if true.
  inline-chords = false
  # Chords under the lyrics.
  chords-under = false
  # Transcoding.
  transcode = null
  # Always decapoize.
  decapo = false
  # Chords parsing strategy.
  # Strict (only known) or relaxed (anything that looks sane).
  chordnames = "strict"
  # Allow note names in [].
  notenames = false
}

# Metadata.
# For these keys you can use {meta key ...} as well as {key ...}.
# If strict is nonzero, only the keys named here are allowed.
# If strict is zero, {meta ...} will accept any key.
# Important: "title" and "subtitle" must always be in this list.
# The separator is used to concatenate multiple values.
metadata {
  keys = [
	"title" "subtitle" "artist" "composer" "lyricist" "arranger"
	"album" "copyright" "year" "sorttitle"
	"key" "time" "tempo" "capo" "duration"
  ]
  strict = true
  separator = "; "
}

# Printing chord diagrams.
# auto= automatically add unknown chords as empty diagrams.
# show= prints the chords used in the song.
#         all= all chords used.
#         user= only prints user defined chords.
# sorted= order the chords by key.
diagrams {
    auto     =  false
    show     =  "all"
    sorted   =  false
}

# Diagnostig messages.
diagnostics {
    format = "\"%f\", line %n, %m\n\t%l"
}

# Table of contents.
contents = [
  {
    fields   = [ "songindex" ]
    label    = "Table of Contents"
    line     = "%{title}"
    fold     = false
    omit     = false
  }
  {
    fields   = [ "sorttitle" "artist" ]
    label    = "Contents by Title"
    line     = "%{title}%{artist| - %{}}"
    fold     = false
    omit     = false
  }
  {
    fields   = [ "artist" "sorttitle" ]
    label    = "Contents by Artist"
    line     = "%{artist|%{} - }%{title}"
    fold     = false
    omit     = true
  }
]
# Table of contents, old style.
# This will be ignored when new style contents is present.
toc {
    # Title for ToC.
    title = "Table of Contents"
    line = "%{title}"
    # Sorting order.
    # Currently only sorting by page number and alpha is implemented.
    order = "page"
}

# Intrument definitions.

instrument : null
tuning = [ "E2" "A2" "D3" "G3" "B3" "E4" ]

notes {
  flat = [
         "C"
         ["Db" "Des" "D♭"]
         "D"
         ["Eb" "Es" "Ees" "E♭"]
         "E"
         "F"
         ["Gb" "Ges" "G♭"]
         "G"
         ["Ab" "As" "Aes" "A♭"]
         "A"
         ["Bb" "Bes" "B♭"]
         "B"
  ]
  sharp = [
         "C"
         ["C#" "Cis" "C♯"]
         "D"
         ["D#" "Dis" "D♯"]
         "E"
         "F"
         ["F#" "Fis" "F♯"]
         "G"
         ["G#" "Gis" "G♯"]
         "A"
	 ["A#" "Ais" "A♯"]
         "B"
  ]
  system : "common"
  movable : false
}

# Layout definitions for PDF output.

pdf {

  # Papersize, 'a4' or [ 595, 842 ] etc.
  papersize = "a4"

  # Space between columns, in pt.
  columnspace  =  20

  # Page margins.
  # Note that top/bottom exclude the head/footspace.
  margintop    =  80
  marginbottom =  40
  marginleft   =  40
  marginright  =  40
  headspace    =  60
  footspace    =  20

  # Special: head on first page only, add the headspace to
  # the other pages so they become larger.
  head-first-only = false

  # Spacings.
  # Baseline distances as a factor of the font size.
  spacing {
      title  = 1.2
      lyrics = 1.2
      chords = 1.2
      grid   = 1.2
      tab    = 1.0
      toc    = 1.4
      empty  = 1.0
  }
  # Note: By setting the font size and spacing for empty lines to
  # smaller values, you get a fine(r)-grained control over the
  # spacing between the various parts of the song.

  # Style of chorus.
  chorus {
      indent     =  0
      # Chorus side bar.
      # Suppress by setting offset and/or width to zero.
      bar {
	  offset =  8
	  width  =  1
	  color  = "black"
      }
      tag = "Chorus"
      # Recall style: Print the tag using the type.
      # Alternatively quote the lines of the preceding chorus.
      recall {
	  tag   = "Chorus"
	  type  = "comment"
	  quote = false
      }
  }

  # This opens a margin for margin labels.
  labels {
      # Margin width. Default is 0 (no margin labels).
      # "auto" will automatically reserve a margin if labels are used.
      width = "auto"
      # Alignment for the labels. Default is left.
      align = "left"
  }

  # Alternative songlines with chords in a side column.
  # Value is the column position.
  # chordscolumn = 400
  chordscolumn =  0
  capoheading = "%{capo|Capo: %{}}"

  # A {titles: left} may conflict with customized formats.
  # Set to non-zero to ignore the directive.
  titles-directive-ignore = false

  # Chord diagrams.
  # A chord diagram consists of a number of cells.
  # Cell dimensions are specified by "width" and "height".
  # The horizontal number of cells depends on the number of strings.
  # The vertical number of cells is "vcells", which should
  # be 4 or larger to accomodate most chords.
  # The horizontal distance between diagrams is "hspace" cells.
  # The vertical distance is "vspace" cells.
  # "linewidth" is the thickness of the lines as a fraction of "width".
  # Diagrams for all chords of the song can be shown at the
  # "top", "bottom" or "right" side of the first page
  # or "below" the last song line.
  diagrams {
      show     =  "bottom"
      width    =  6
      height   =  6
      hspace   =  3.95
      vspace   =  3
      vcells   =  4
      linewidth = 0.1
  }

  # Even/odd pages. A value of -1 denotes odd/even pages.
  even-odd-pages = 1
  # Align songs to even/odd pages.
  pagealign-songs = 1

  # Formats.
  formats {
      # Titles/Footers.

      # Titles/footers have 3 parts, which are printed left
      # centered and right.
      # For even/odd printing, the order is reversed.

      # By default, a page has:
      default {
	  # No title/subtitle.
	  title     = null
	  subtitle  = null
	  # Footer is title -- page number.
	  footer.0  = "%{title}"
	  footer.1  = ""
	  footer.2  = "%{page}"
      }
      # The first page of a song has:
      title {
	  # Title and subtitle.
	  title.0   = ""
	  title.1   = "%{title}"
	  title.2   = ""
	  subtitle.0 = ""
	  subtitle.1 = "%{subtitle}"
	  subtitle.2 = ""
	  # Footer with page number.
	  footer.0  = ""
	  footer.1  = ""
	  footer.2  = "%{page}"
      }
      # The very first output page is slightly different:
      first {
	  # It has title and subtitle, like normal 'first' pages.
	  # But no footer.
	  footer    = null
      }
  }

  # Split marker for syllables that are smaller than chord width.
  # split-marker is a 3-part array: 'start', 'repeat', and 'final'.
  # 'final' is always printed, last.
  # 'start' is printed if there is enough room.
  # 'repeat' is printed repeatedly to fill the rest.
  # If split-marker is a single string, this is 'start'.
  # All elements may be left empty strings.
  split-marker = [ "" "" "" ]

  # Font families and properties.
  # "fontconfig" maps members of font families to physical fonts.
  # Optionally, additional properties of the fonts can be specified.
  # Physical fonts can be the names of TrueType/OpenType fonts
  # or names of built-in fonts (corefonts).
  # Relative filenames are looked up in the fontdir.
  # fontdir = [ "/usr/share/fonts/liberation", "/home/me/fonts" ]

  fontdir = null
  fontconfig {
      # alternatives: regular r normal <empty>
      # alternatives: bold b strong
      # alternatives: italic i oblique o emphasis
      # alternatives: bolditalic bi italicbold ib boldoblique bo obliquebold ob
      times {
	  ''	      = "Times-Roman"
	  bold        = "Times-Bold"
	  italic      = "Times-Italic"
	  bolditalic  = "Times-BoldItalic"
      }
      helvetica {
	  ''	      = "Helvetica"
	  bold        = "Helvetica-Bold"
	  oblique     = "Helvetica-Oblique"
	  boldoblique = "Helvetica-BoldOblique"
      }
      courier {
	  ''	      = "Courier"
	  bold        = "Courier-Bold"
	  italic      = "Courier-Italic"
	  bolditalic  = "Courier-BoldItalic"
      }
      dingbats {
	  ""	      = "ZapfDingbats"
      }
  }

  # "fonts" maps output elements to fonts as defined in "fontconfig".
  # The elements can have a background colour associated.
  # Colours are "#RRGGBB" or predefined names like "black", "white"
  # and lots of others.
  # NOTE: In the built-in config we use only "name" since that can
  # be overruled with user settings.

  fonts {
      title {
	  name = "Times-Bold"
	  size = 14
      }
      text {
	  name = "Times-Roman"
	  size = 12
      }
      chord {
	  name = "Helvetica-Oblique"
	  size = 10
      }
      chordfingers {
	  name = "ZapfDingbats"
	  size = 10
      }
      comment {
	  name = "Helvetica"
	  size = 12
	  background = "#E5E5E5"
      }
      comment_italic {
	  name = "Helvetica-Oblique"
	  size = 12
      }
      comment_box {
	  name = "Helvetica"
	  size = 12
	  frame = 1
      }
      tab {
	  name = "Courier"
	  size = 10
      }
      toc {
	  name = "Times-Roman"
	  size = 11
      }
      grid {
	  name = "Helvetica"
	  size = 10
      }
  }

  # Element mappings that can be specified, but need not since
  # they default to other elements.
  # subtitle       --> text
  # comment        --> text
  # comment_italic --> chord
  # comment_box    --> chord
  # annotation     --> chord
  # toc            --> text
  # grid           --> chord
  # grid_margin    --> comment
  # footer         --> subtitle @ 60%
  # empty          --> text
  # diagram        --> comment
  # diagram_base   --> text (but at a small size)

  # Bookmarks (PDF outlines).
  # fields:   primary and (optional) secondary fields.
  # label:    outline label
  # line:     text of the outline element
  # collapse: initial display is collapsed
  # letter:   sublevel with first letters if more
  # fold:     group by primary (NYI)
  # omit:     ignore this
  outlines = [
    {
      fields   = [ "sorttitle" "artist" ]
      label    = "By Title"
      line     = "%{title}%{artist| - %{}}"
      collapse = false
      letter   = 5
      fold     = false
    }
    {
      fields   = [ "artist" "sorttitle" ]
      label    = "By Artist"
      line     = "%{artist|%{} - }%{title}"
      collapse = false
      letter   = 5
      fold     = false
    }
  ]

  # This will show the page layout if non-zero.
  showlayout = false
}

# Settings for ChordPro backend.
chordpro {
    # Style of chorus.
    chorus {
	# Recall style: Print the tag using the type.
	# Alternatively quote the lines of the preceding chorus.
	# If no tag+type or quote: use {chorus}.
	# Note: Variant 'msp' always uses {chorus}.
	recall {
	     # tag   = "Chorus", type  = "comment"
	     tag   = ""
	     type  = ""
	     # quote = false
	     quote = false
	}
    }
}

# Settings for HTML backend.
html {
    # Stylesheet links.
    styles {
	display = "chordpro.css"
	print   = "chordpro_print.css"
    }
}

# End of config.
