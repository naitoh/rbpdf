# coding: ASCII-8BIT
#============================================================+
# File name   : rbpdf.rb
# Begin       : 2002-08-03
# Last Update : 2010-06-02
# Author      : Nicola Asuni
# Version     : 5.2.000
# License     : GNU LGPL (http://www.gnu.org/copyleft/lesser.html)
#  ----------------------------------------------------------------------------
#      This program is free software: you can redistribute it and/or modify
#      it under the terms of the GNU Lesser General Public License as published by
#      the Free Software Foundation, either version 2.1 of the License, or
#      (at your option) any later version.
#
#      This program is distributed in the hope that it will be useful,
#      but WITHOUT ANY WARRANTY; without even the implied warranty of
#      MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#      GNU Lesser General Public License for more details.
#
#      You should have received a copy of the GNU Lesser General Public License
#      along with this program.  If not, see <http://www.gnu.org/licenses/>.
#  ----------------------------------------------------------------------------
#
# Description : This is a Ruby class for generating PDF files
#               on-the-fly without requiring external
#               extensions.
#
# IMPORTANT:
# This class is an extension and improvement of the Public Domain
# FPDF class by Olivier Plathey (http://www.fpdf.org).
#
# Main changes by Nicola Asuni:
#    Ruby porting;
#    UTF-8 Unicode support;
#    code refactoring;
#    source code clean up;
#    code style and formatting;
#    source code documentation using phpDocumentor (www.phpdoc.org);
#    All ISO page formats were included;
#    image scale factor;
#    includes methods to parse and printsome XHTML code, supporting the following elements: h1, h2, h3, h4, h5, h6, b, u, i, a, img, p, br, strong, em, font, blockquote, li, ul, ol, hr, td, th, tr, table, sup, sub, small;
#    includes a method to print various barcode formats using an improved version of "Generic Barcode Render Class" by Karim Mribti (http://www.mribti.com/barcode/) (require GD library: http://www.boutell.com/gd/);
#    defines standard Header() and Footer() methods.
#
#   Ported to Ruby by Ed Moss 2007-08-06
#
#============================================================+

require "rbpdf/version"

require 'htmlentities'
require 'rbpdf-font'
require 'erb'

begin
  require 'mini_magick' unless Object.const_defined?(:MiniMagick)
  require 'core/mini_magick'
rescue LoadError
  # MiniMagick is not available
end

unless Object.const_defined?(:MiniMagick)
  begin
    # RMagick 2.14.0
    # [DEPRECATION] requiring "RMagick" is deprecated. Use "rmagick" instead
    # https://github.com/gemhome/rmagick/pull/141
    require 'rmagick' unless Object.const_defined?(:Magick)
  rescue LoadError
    # RMagick is not available
  end

  begin
    require 'RMagick' unless Object.const_defined?(:Magick)
  rescue LoadError
    # RMagick is not available
  end
  require 'core/rmagick'
end

# Needed to run the test suite outside of a Rails environment.
require 'rubygems' if RUBY_VERSION < '1.9' # Ruby 1.8.7
require 'action_view'
require 'tempfile'
require 'uri'
require 'net/http'

#
# RBPDF Class.
#


PDF_PRODUCER = "RBPDF #{Rbpdf::VERSION}"

# == This is a Ruby class for generating PDF files on-the-fly without requiring external extensions.
# * This class is a Ruby port of the TCPDF class by Nicola Asuni (http://www.tcpdf.org).
# * This class is an extension and improvement of the FPDF class by Olivier Plathey (http://www.fpdf.org).
# * This version contains some changes: [porting to Ruby, support for UTF-8 Unicode, code style and formatting, php documentation (www.phpdoc.org), ISO page formats, minor improvements, image scale factor]
# * TCPDF project (http://www.tcpdf.org) has been originally derived in 2002 from the Public Domain FPDF class by Olivier Plathey (http://www.fpdf.org), but now is almost entirely rewritten.
# * To add your own TTF fonts please read /fonts/README.TXT
# @name:: RBPDF
# @@version:: 5.1.002
# @author:: Nicola Asuni
# @license:: http://www.gnu.org/copyleft/lesser.html LGPL 2.1
#

class RBPDFError < StandardError
end

class RBPDF
  include ActionView::Helpers
  include Rbpdf
  require 'unicode_data.rb'
  require 'htmlcolors.rb'
  include Unicode_data
  include Html_colors

  def logger
    if defined? Rails.logger
      Rails.logger
    else
      # This particular error will occur when the test suite is run from outside a Rails environment.
      # We use the standard Ruby stdout logger in that case.
      require 'logger'
      return Logger.new(STDOUT)
    end
  end

  @@version = "5.1.002"
  @@fpdf_charwidths = {}

  cattr_accessor :k_cell_height_ratio
  @@k_cell_height_ratio = 1.25

  cattr_accessor :k_blank_image
  @@k_blank_image = ""

  cattr_accessor :k_small_ratio
  @@k_small_ratio = 2/3.0

  cattr_accessor :k_path_cache

  cattr_accessor :k_path_main

  cattr_accessor :k_path_url

  @@k_path_images = ""
  @@k_thai_topchars = nil

  cattr_accessor :decoder

  attr_accessor :barcode

  attr_accessor :buffer

  attr_accessor :diffs

  attr_accessor :color_flag

  attr_accessor :default_font

  attr_accessor :draw_color

  attr_accessor :encoding

  attr_accessor :fill_color

  attr_accessor :fonts

  attr_accessor :font_family

  attr_accessor :font_files

  cattr_accessor :k_path_fonts

  attr_accessor :font_style

  attr_accessor :font_size_pt

  attr_accessor :header_width

  attr_accessor :header_logo

  attr_accessor :header_logo_width

  attr_accessor :header_title

  attr_accessor :header_string

  attr_accessor :images

  attr_accessor :img_scale

  attr_accessor :in_footer

  attr_accessor :is_unicode

  attr_accessor :lasth

  attr_accessor :links

  attr_accessor :listordered

  attr_accessor :listcount

  attr_accessor :lispacer

  attr_accessor :n

  attr_accessor :offsets

  attr_accessor :page

  attr_accessor :pages

  attr_accessor :pdf_version

  attr_accessor :print_header

  attr_accessor :print_footer

  attr_accessor :state

  attr_accessor :text_color

  attr_accessor :underline

  attr_accessor :diskcache

  attr_accessor :cache_file_length

  attr_accessor :prev_pages

  #
  # This is the class constructor.
  # It allows to set up the page format, the orientation and
  # the measure unit used in all the methods (except for the font sizes).
  # [@since 1.0]
  # [@param string :orientation]
  #   page orientation. Possible values are (case insensitive):
  #   * P or Portrait (default)
  #   * L or Landscape
  # [@param string :unit]
  #   User measure unit. Possible values are:
  #   * pt: point
  #   * mm: millimeter (default)
  #   * cm: centimeter
  #   * in: inch
  #   A point equals 1/72 of inch, that is to say about 0.35 mm (an inch being 2.54 cm). This is a very common unit in typography; font sizes are expressed in that unit.
  # [@param mixed :format]
  #   The format used for pages. It can be either: <b>A string indicating the page format:</b>
  #   * 4A0,2A0,A0,A1,A2,A3,A4 (default),A5,A6,A7,A8,A9,A10
  #   * B0,B1,B2,B3,B4,B5,B6,B7,B8,B9,B10
  #   * C0,C1,C2,C3,C4,C5,C6,C7,C8,C9,C10
  #   * RA0,RA1,RA2,RA3,RA4
  #   * SRA0,SRA1,SRA2,SRA3,SRA4
  #   * LETTER,LEGAL,EXECUTIVE,FOLIO
  #   <b>An array containing page measures and advanced options:</b> see setPageFormat()
  # [@param boolean :unicode] TRUE means that the input text is unicode (default = true)
  # [@param String :encoding] charset encoding; default is UTF-8
  # [@param boolean :diskcache] if TRUE reduce the RAM memory usage by caching temporary data on filesystem (slower).
  # [@access public]
  #
  def initialize(orientation = 'P',  unit = 'mm', format = 'A4', unicode = true, encoding = "UTF-8", diskcache = false)

    # Set internal character encoding to ASCII#
    #FIXME 2007-05-25 (EJM) Level=0 -
    # if (respond_to?("mb_internal_encoding") and mb_internal_encoding())
    #   @internal_encoding = mb_internal_encoding();
    #   mb_internal_encoding("ASCII");
    # }

    if defined? Rails.root
      @@k_path_cache = Rails.root.join('tmp').to_s
      @@k_path_main = Rails.root.join('tmp').to_s
      @@k_path_url = Rails.root.join('tmp').to_s
    else
      # This particular error will occur when the test suite is run from outside a Rails environment.
      # We want to use the system's temp directory in that case.
      require 'tmpdir'
      @@k_path_cache = Dir.tmpdir
      @@k_path_main = Dir.tmpdir
      @@k_path_url = Dir.tmpdir
    end

    @@k_path_fonts = RBPDFFontDescriptor.getfontpath

    # set disk caching
    @diskcache = diskcache ? true : false

    # set language direction
    @rtl = false
    @tmprtl = false

    @x ||= 0
    @y ||= 0

    #######################
    @offsets ||= []

    @alias_nb_pages = '{nb}'
    @alias_num_page = '{pnb}'
    @img_scale ||= 1
    @r_margin ||= 0
    @l_margin ||= 0
    @original_r_margin ||= nil
    @original_l_margin ||= nil
    @t_margin ||= nil
    @b_margin ||= nil
    @auto_page_break ||= nil
    @page_annots ||= []

    @header_font ||= ['', '', 10]
    @footer_font ||= ['', '', 8]
    @l ||= {}

    @header_margin ||= 10
    @footer_margin ||= 10

    @barcode ||= false
    @print_header ||= true
    @print_footer ||= true
    @header_width ||= 0
    @header_logo ||= ""
    @header_logo_width ||= 30
    @header_title ||= ""
    @header_string ||= ""
    @listordered ||= []
    @listcount ||= []
    @listnum ||= 0
    @listindent ||= 0
    @listindentlevel ||= 0
    @lispacer ||= ""
    @li_position_x = nil

    # bookmark
    @outlines ||= []

    # --- javascript and form ---
    @javascript ||= ''
    @js_objects ||= {}
    @js_start_obj_id ||= 300000
    @js_obj_id ||= 300000

    @dpi = 72.0
    @newpagegroup ||= []
    @pagegroups ||= {}
    @currpagegroup ||= nil
    @visibility ||= 'all'
    @cell_height_ratio = @@k_cell_height_ratio
    @viewer_preferences ||= {}

    @intmrk ||= []
    @cntmrk ||= []
    @footerpos ||= []
    @footerlen ||= []
    @newline ||= true
    @endlinex ||= 0

    @open_marked_content ||= false
    @htmlvspace ||= 0
    @spot_colors ||= {}
    @lisymbol ||= ''
    @epsmarker ||= 'x#!#EPS#!#x'
    @transfmatrix ||= []
    @transfmatrix_key ||= 0
    @booklet ||= false
    @feps ||= 0.005
    @tagvspaces ||= {}
    @customlistindent ||= -1
    @opencell = true
    @embeddedfiles ||= {}

    @html_link_color_array ||= [0, 0, 255]
    @html_link_font_style ||= 'U'
    @numpages ||= 0
    @pagelen ||= []
    @numimages ||= 0
    @imagekeys ||= []
    @bufferlen ||= 0

    @numfonts ||= 0
    @fontkeys ||= []
    @font_obj_ids ||= {}
    @pageopen ||= [] # Store the fage status (true when opened, false when closed).
    @default_monospaced_font = 'courier'


    @cache_file_length = {}
    @thead ||= ''
    @thead_margins ||= {}
    @cache_utf8_string_to_array = {}
    @cache_maxsize_utf8_string_to_array = 8
    @cache_size_utf8_string_to_array = 0

    @signature_data ||= {}
    @sig_annot_ref ||= '***SIGANNREF*** 0 R'
    @page_obj_id ||= []
    @embedded_start_obj_id ||= 100000
    @form_obj_id ||= []
    @default_form_prop ||= {'lineWidth'=>1, 'borderStyle'=>'solid', 'fillColor'=>[255, 255, 255], 'strokeColor'=>[128, 128, 128]}
    @apxo_start_obj_id ||= 400000
    @apxo_obj_id ||= 400000
    @annotation_fonts ||= {}
    @radiobutton_groups ||= []
    @radio_groups ||= []
    @textindent ||= 0

    @start_transaction_y ||= 0
    @in_thead ||= false
    @columns ||= []
    @num_columns ||= 0
    @current_column ||= 0
    @column_start_page ||= 0
    @cur_orientation ||= nil

    # Text rendering mode:
    # 0 = Fill text;
    # 1 =            Stroke text;
    # 2 = Fill, then stroke text;
    # 3 = Neither fill nor stroke text (invisible);
    # 4 =              Fill text and add to path for clipping;
    # 5 =            Stroke text and add to path for clipping;
    # 6 = Fill, then stroke text and add to path for clipping;
    # 7 = Add text to path for clipping.
    @textrendermode ||= 0
    @textstrokewidth ||= 0

    @pdfunit ||= 'mm'
    @tocpage ||= false

    #######################

    #Some checks
    dochecks();

    begin
      @@decoder = HTMLEntities.new
    rescue
      @@decoder = nil
    end

    #Initialization of properties
    @is_unicode = unicode
    @page ||= 0
    @transfmrk ||= []
    @pagedim ||= []
    @n ||= 2
    if @diskcache
      @buffer ||= nil
    else
      @buffer ||= ''
    end
    @tmp_buffer = nil
    @pages ||= []
    @prev_pages ||= []
    @state ||= 0
    @fonts ||= {}
    @font_files ||= {}
    @diffs ||= []
    @images ||= {}
    @links ||= [] # array of internal links
    @html_anchor ||= nil
    @html_anchors ||= {}
    @html_anchor_links ||= {}
    @gradients ||= []
    @in_footer ||= false
    @lasth ||= 0
    @font_family ||= 'helvetica'
    @font_style ||= ''
    @font_size_pt ||= 12
    @font_subsetting ||= true
    @underline ||= false
    @overline ||= false
    @linethrough ||= false
    @draw_color ||= '0 G'
    @fill_color ||= '0 g'
    @text_color ||= '0 g'
    @color_flag ||= false
    @title ||= nil
    @author ||= nil
    @subject ||= nil
    @keywords ||= nil
    @creator ||= nil

    # encryption values
    @encrypted ||= false
    @last_enc_key ||= ''

    # Standard Unicode fonts
    @core_fonts = {
    'courier'=>'Courier',
    'courierB'=>'Courier-Bold',
    'courierI'=>'Courier-Oblique',
    'courierBI'=>'Courier-BoldOblique',
    'helvetica'=>'Helvetica',
    'helveticaB'=>'Helvetica-Bold',
    'helveticaI'=>'Helvetica-Oblique',
    'helveticaBI'=>'Helvetica-BoldOblique',
    'times'=>'Times-Roman',
    'timesB'=>'Times-Bold',
    'timesI'=>'Times-Italic',
    'timesBI'=>'Times-BoldItalic',
    'symbol'=>'Symbol',
    'zapfdingbats'=>'ZapfDingbats'}

    # Set scale factor
    setPageUnit(unit)
    # set page format and orientation
    setPageFormat(format, orientation)
    # Page margins (1 cm)
    margin = 28.35/@k
    SetMargins(margin, margin)
    #Interior cell margin (1 mm)
    @c_margin = margin / 10
    #Line width (0.2 mm)
    @line_width = 0.57 / @k
    @linestyle_width ||= sprintf('%.2f w', (@line_width * @k))
    @linestyle_cap ||= '0 J'
    @linestyle_join ||= '0 j'
    @linestyle_dash ||= '[] 0 d'
    #Automatic page break
    SetAutoPageBreak(true, 2 * margin)
    #Full width display mode
    SetDisplayMode('fullwidth')
    #Compression
    SetCompression(true)
    #Set default PDF version number
    @pdf_version ||= "1.7"
    @encoding = encoding
    @href ||= {}
    @fontlist ||= []
    getFontsList()
    @fgcolor = ActiveSupport::OrderedHash.new
    @fgcolor['R'] = 0
    @fgcolor['G'] = 0
    @fgcolor['B'] = 0
    @strokecolor = ActiveSupport::OrderedHash.new
    @strokecolor['R'] = 0
    @strokecolor['G'] = 0
    @strokecolor['B'] = 0
    @bgcolor = ActiveSupport::OrderedHash.new
    @bgcolor['R'] = 255
    @bgcolor['G'] = 255
    @bgcolor['B'] = 255
    @extgstates ||= []

    # user's rights
    @sign ||= false
    @ur = false
    @ur_document = "/FullSave"
    @ur_annots = "/Create/Delete/Modify/Copy/Import/Export"
    @ur_form = "/Add/Delete/FillIn/Import/Export/SubmitStandalone/SpawnTemplate"
    @ur_signature = "/Modify"

    # set default JPEG quality
    @jpeg_quality ||= 75

    # initialize some settings
#    utf8Bidi([''], '')
    # set default font
    SetFont(@font_family, @font_style, @font_size_pt)

    @annots_start_obj_id ||= 200000
    @annot_obj_id ||= @annots_start_obj_id
    @curr_annot_obj_id ||= @annots_start_obj_id
    @apxo_obj_id ||= @apxo_start_obj_id
    @objcopy ||= nil
  end

  #
  # Set the units of measure for the document.
  # [@param string :unit]
  #   User measure unit. Possible values are:
  #   * pt: point
  #   * mm: millimeter (default)
  #   * cm: centimeter
  #   * in: inch
  #   A point equals 1/72 of inch, that is to say about 0.35 mm (an inch being 2.54 cm). This is a very common unit in typography; font sizes are expressed in that unit.
  # [@access public]
  # [@since 3.0.015 (2008-06-06)]
  #
  def setPageUnit(unit)
    unit = unit.downcase
    # Set scale factor
    case unit
    when 'px', 'pt'; @k=1.0     # points
    when 'mm'; @k = @dpi / 25.4 # millimeters
    when 'cm'; @k = @dpi / 2.54 # centimeters
    when 'in'; @k = @dpi        # inches
    # unsupported unit
    else Error("Incorrect unit: #{unit}")
    end
    @pdfunit = unit
    unless @cur_orientation.nil?
      setPageOrientation(@cur_orientation)
    end
  end
  alias_method :set_page_unit, :setPageUnit

  #
  # Get page dimensions from fromat name.
  # [@param mixed :format]
  #   The format name. It can be:
  #   * 4A0,2A0,A0,A1,A2,A3,A4 (default),A5,A6,A7,A8,A9,A10
  #   * B0,B1,B2,B3,B4,B5,B6,B7,B8,B9,B10
  #   * C0,C1,C2,C3,C4,C5,C6,C7,C8,C9,C10
  #   * RA0,RA1,RA2,RA3,RA4
  #   * SRA0,SRA1,SRA2,SRA3,SRA4
  #   * LETTER,LEGAL,EXECUTIVE,FOLIO
  # [@return array] containing page width and height in points
  # [@access public]
  # [@since 5.0.010 (2010-05-17)]
  #
  def getPageSizeFromFormat(format)
    # Page formats (45 standard ISO paper formats and 4 american common formats).
    # Paper cordinates are calculated in this way: (inches * 72) where (1 inch = 2.54 cm)
    case format.upcase
    when '4A0'; pf = [4767.87,6740.79]
    when '2A0'; pf = [3370.39,4767.87]
    when 'A0'; pf = [2383.94,3370.39]
    when 'A1'; pf = [1683.78,2383.94]
    when 'A2'; pf = [1190.55,1683.78]
    when 'A3'; pf = [841.89,1190.55]
    when 'A4'; pf = [595.28,841.89]
    when 'A5'; pf = [419.53,595.28]
    when 'A6'; pf = [297.64,419.53]
    when 'A7'; pf = [209.76,297.64]
    when 'A8'; pf = [147.40,209.76]
    when 'A9'; pf = [104.88,147.40]
    when 'A10'; pf = [73.70,104.88]
    when 'B0'; pf = [2834.65,4008.19]
    when 'B1'; pf = [2004.09,2834.65]
    when 'B2'; pf = [1417.32,2004.09]
    when 'B3'; pf = [1000.63,1417.32]
    when 'B4'; pf = [708.66,1000.63]
    when 'B5'; pf = [498.90,708.66]
    when 'B6'; pf = [354.33,498.90]
    when 'B7'; pf = [249.45,354.33]
    when 'B8'; pf = [175.75,249.45]
    when 'B9'; pf = [124.72,175.75]
    when 'B10'; pf = [87.87,124.72]
    when 'C0'; pf = [2599.37,3676.54]
    when 'C1'; pf = [1836.85,2599.37]
    when 'C2'; pf = [1298.27,1836.85]
    when 'C3'; pf = [918.43,1298.27]
    when 'C4'; pf = [649.13,918.43]
    when 'C5'; pf = [459.21,649.13]
    when 'C6'; pf = [323.15,459.21]
    when 'C7'; pf = [229.61,323.15]
    when 'C8'; pf = [161.57,229.61]
    when 'C9'; pf = [113.39,161.57]
    when 'C10'; pf = [79.37,113.39]
    when 'RA0'; pf = [2437.80,3458.27]
    when 'RA1'; pf = [1729.13,2437.80]
    when 'RA2'; pf = [1218.90,1729.13]
    when 'RA3'; pf = [864.57,1218.90]
    when 'RA4'; pf = [609.45,864.57]
    when 'SRA0'; pf = [2551.18,3628.35]
    when 'SRA1'; pf = [1814.17,2551.18]
    when 'SRA2'; pf = [1275.59,1814.17]
    when 'SRA3'; pf = [907.09,1275.59]
    when 'SRA4'; pf = [637.80,907.09]
    when 'LETTER'; pf = [612.00,792.00]
    when 'LEGAL'; pf = [612.00,1008.00]
    when 'EXECUTIVE'; pf = [521.86,756.00]
    when 'FOLIO'; pf = [612.00,936.00]
    else
      pf = [595.28,841.89] # DEFAULT A4
    end
    return pf
  end
  alias_method :get_page_size_from_format, :getPageSizeFromFormat

  #
  # Change the format of the current page
  # [@param mixed :format]
  #   The format used for pages. It can be either: <b>A string indicating the page format:</b>
  #   * 4A0,2A0,A0,A1,A2,A3,A4 (default),A5,A6,A7,A8,A9,A10
  #   * B0,B1,B2,B3,B4,B5,B6,B7,B8,B9,B10
  #   * C0,C1,C2,C3,C4,C5,C6,C7,C8,C9,C10
  #   * RA0,RA1,RA2,RA3,RA4
  #   * SRA0,SRA1,SRA2,SRA3,SRA4
  #   * LETTER,LEGAL,EXECUTIVE,FOLIO
  #   <b>An array containing page measures and advanced options:</b>
  #     ['format'] = page format name (one of the above)
  #     ['Rotate'] : The number of degrees by which the page shall be rotated clockwise when displayed or printed. The value shall be a multiple of 90.
  #     ['PZ'] : The page's preferred zoom (magnification) factor.
  #     ['MediaBox'] : the boundaries of the physical medium on which the page shall be displayed or printed:
  #     ['MediaBox']['llx'] : lower-left x coordinate in points
  #     ['MediaBox']['lly'] : lower-left y coordinate in points
  #     ['MediaBox']['urx'] : upper-right x coordinate in points
  #     ['MediaBox']['ury'] : upper-right y coordinate in points
  #     ['CropBox'] : the visible region of default user space:
  #     ['CropBox']['llx'] : lower-left x coordinate in points
  #     ['CropBox']['lly'] : lower-left y coordinate in points
  #     ['CropBox']['urx'] : upper-right x coordinate in points
  #     ['CropBox']['ury'] : upper-right y coordinate in points
  #     ['BleedBox'] : the region to which the contents of the page shall be clipped when output in a production environment:
  #     ['BleedBox']['llx'] : lower-left x coordinate in points
  #     ['BleedBox']['lly'] : lower-left y coordinate in points
  #     ['BleedBox']['urx'] : upper-right x coordinate in points
  #     ['BleedBox']['ury'] : upper-right y coordinate in points
  #     ['TrimBox'] : the intended dimensions of the finished page after trimming:
  #     ['TrimBox']['llx'] : lower-left x coordinate in points
  #     ['TrimBox']['lly'] : lower-left y coordinate in points
  #     ['TrimBox']['urx'] : upper-right x coordinate in points
  #     ['TrimBox']['ury'] : upper-right y coordinate in points
  #     ['ArtBox'] : the extent of the page's meaningful content:
  #     ['ArtBox']['llx'] : lower-left x coordinate in points
  #     ['ArtBox']['lly'] : lower-left y coordinate in points
  #     ['ArtBox']['urx'] : upper-right x coordinate in points
  #     ['ArtBox']['ury'] : upper-right y coordinate in points
  #     ['BoxColorInfo'] :specify the colours and other visual characteristics that should be used in displaying guidelines on the screen for each of the possible page boundaries other than the MediaBox:
  #     ['BoxColorInfo'][BOXTYPE]['C'] : an array of three numbers in the range 0-255, representing the components in the DeviceRGB colour space.
  #     ['BoxColorInfo'][BOXTYPE]['W'] : the guideline width in default user units
  #     ['BoxColorInfo'][BOXTYPE]['S'] : the guideline style: S = Solid; D = Dashed
  #     ['BoxColorInfo'][BOXTYPE]['D'] : dash array defining a pattern of dashes and gaps to be used in drawing dashed guidelines
  #     ['trans'] : the style and duration of the visual transition to use when moving from another page to the given page during a presentation
  #     ['trans']['Dur'] : The page's display duration (also called its advance timing): the maximum length of time, in seconds, that the page shall be displayed during presentations before the viewer application shall automatically advance to the next page.
  #     ['trans']['S'] : transition style : Split, Blinds, Box, Wipe, Dissolve, Glitter, R, Fly, Push, Cover, Uncover, Fade
  #     ['trans']['D'] : The duration of the transition effect, in seconds.
  #     ['trans']['Dm'] : (Split and Blinds transition styles only) The dimension in which the specified transition effect shall occur: H = Horizontal, V = Vertical. Default value: H.
  #     ['trans']['M'] : (Split, Box and Fly transition styles only) The direction of motion for the specified transition effect: I = Inward from the edges of the page, O = Outward from the center of the pageDefault value: I.
  #     ['trans']['Di'] : (Wipe, Glitter, Fly, Cover, Uncover and Push transition styles only) The direction in which the specified transition effect shall moves, expressed in degrees counterclockwise starting from a left-to-right direction. If the value is a number, it shall be one of: 0 = Left to right, 90 = Bottom to top (Wipe only), 180 = Right to left (Wipe only), 270 = Top to bottom, 315 = Top-left to bottom-right (Glitter only). If the value is a name, it shall be None, which is relevant only for the Fly transition when the value of SS is not 1.0. Default value: 0.
  #     ['trans']['SS'] : (Fly transition style only) The starting or ending scale at which the changes shall be drawn. If M specifies an inward transition, the scale of the changes drawn shall progress from SS to 1.0 over the course of the transition. If M specifies an outward transition, the scale of the changes drawn shall progress from 1.0 to SS over the course of the transition. Default: 1.0.
  #     ['trans']['B'] : (Fly transition style only) If true, the area that shall be flown in is rectangular and opaque. Default: false.
  # [@param string :orientation]
  #   page orientation. Possible values are (case insensitive):
  #   * P or PORTRAIT (default)
  #   * L or LANDSCAPE
  # [@access protected]
  # [@since 3.0.015 (2008-06-06)]
  #
  def setPageFormat(format, orientation="P")
    if !format.empty? and @pagedim[@page]
      # remove inherited values
      @pagedim[@page] = nil
    end
    if format.is_a?(String)
      # get page measures from format name
      pf = getPageSizeFromFormat(format)
      @fw_pt = pf[0]
      @fh_pt = pf[1]
    else
      # the boundaries of the physical medium on which the page shall be displayed or printed
      if format['MediaBox']
        setPageBoxes(@page, 'MediaBox', format['MediaBox']['llx'], format['MediaBox']['lly'], format['MediaBox']['urx'], format['MediaBox']['ury'])
        @fw_pt = (format['MediaBox']['urx'] - format['MediaBox']['llx']) * @k
        @fh_pt = (format['MediaBox']['ury'] - format['MediaBox']['lly']) * @k
      else
        if format[0] and format[0].is_a?(Numeric) and format[1] and format[1].is_a?(Numeric)
          pf = [format[0], format[1]]
        else
          if format['format'].nil?
            # default value
            format['format'] = 'A4'
          end
          pf = getPageSizeFromFormat(format['format'])
        end
        @fw_pt = pf[0]
        @fh_pt = pf[1]
        setPageBoxes(@page, 'MediaBox', 0, 0, @fw_pt, @fh_pt, true)
      end
      # the visible region of default user space
      if format['CropBox']
        setPageBoxes(@page, 'CropBox', format['CropBox']['llx'], format['CropBox']['lly'], format['CropBox']['urx'], format['CropBox']['ury'])
      end
      # the region to which the contents of the page shall be clipped when output in a production environment
      if format['BleedBox']
        setPageBoxes(@page, 'BleedBox', format['BleedBox']['llx'], format['BleedBox']['lly'], format['BleedBox']['urx'], format['BleedBox']['ury'])
      end
      # the intended dimensions of the finished page after trimming
      if format['TrimBox']
        setPageBoxes(@page, 'TrimBox', format['TrimBox']['llx'], format['TrimBox']['lly'], format['TrimBox']['urx'], format['TrimBox']['ury'])
      end
      # the page's meaningful content (including potential white space)
      if format['ArtBox']
        setPageBoxes(@page, 'ArtBox', format['ArtBox']['llx'], format['ArtBox']['lly'], format['ArtBox']['urx'], format['ArtBox']['ury'])
      end
      # specify the colours and other visual characteristics that should be used in displaying guidelines on the screen for the various page boundaries
      if format['BoxColorInfo']
        @pagedim[@page]['BoxColorInfo'] = format['BoxColorInfo']
      end
      if format['Rotate'] and ((format['Rotate'] % 90) == 0)
        # The number of degrees by which the page shall be rotated clockwise when displayed or printed. The value shall be a multiple of 90.
        @pagedim[@page]['Rotate'] = format['Rotate'].to_i
      end
      if format['PZ']
        # The page's preferred zoom (magnification) factor
        @pagedim[@page]['PZ'] = format['PZ'].to_f
      end
      if format['trans']
        @pagedim[@page]['trans'] = {}
        # The style and duration of the visual transition to use when moving from another page to the given page during a presentation
        if format['trans']['Dur']
          # The page's display duration
          @pagedim[@page]['trans']['Dur'] = format['trans']['Dur'].to_f
        end
        stansition_styles = ['Split', 'Blinds', 'Box', 'Wipe', 'Dissolve', 'Glitter', 'R', 'Fly', 'Push', 'Cover', 'Uncover', 'Fade']
        if format['trans']['S'] and stansition_styles.include?(format['trans']['S'])
          # The transition style that shall be used when moving to this page from another during a presentation
          @pagedim[@page]['trans']['S'] = format['trans']['S']
          valid_effect = ['Split', 'Blinds']
          valid_vals = ['H', 'V']
          if format['trans']['Dm'] and valid_effect.include?(format['trans']['S']) and valid_vals.include?(format['trans']['Dm'])
            @pagedim[@page]['trans']['Dm'] = format['trans']['Dm']
          end
          valid_effect = ['Split', 'Box', 'Fly']
          valid_vals = ['I', 'O']
          if format['trans']['M'] and valid_effect.include?(format['trans']['S']) and valid_vals.include?(format['trans']['M'])
            @pagedim[@page]['trans']['M'] = format['trans']['M']
          end
          valid_effect = ['Wipe', 'Glitter', 'Fly', 'Cover', 'Uncover', 'Push']
          if format['trans']['Di'] and valid_effect.include?(format['trans']['S'])
            if (((format['trans']['Di'] == 90) or (format['trans']['Di'] == 180)) and (format['trans']['S'] == 'Wipe')) or ((format['trans']['Di'] == 315) and (format['trans']['S'] == 'Glitter')) or ((format['trans']['Di'] == 0) or (format['trans']['Di'] == 270))
              @pagedim[@page]['trans']['Di'] = format['trans']['Di'].to_i
            end
          end
          if format['trans']['SS'] and (format['trans']['S'] == 'Fly')
            @pagedim[@page]['trans']['SS'] = format['trans']['SS'].to_f
          end
          if format['trans']['B'] and (format['trans']['B'] === true) and (format['trans']['S'] == 'Fly')
            @pagedim[@page]['trans']['B'] = 'true'
          end
        else
          @pagedim[@page]['trans']['S'] = 'R'
        end
        if format['trans']['D']
          # The duration of the transition effect, in seconds
          @pagedim[@page]['trans']['D'] = format['trans']['D'].to_f
        else
          @pagedim[@page]['trans']['D'] = 1
        end
      end
    end
    setPageOrientation(orientation)
  end
  protected :setPageFormat

  #
  # Set page boundaries.
  # [@param int :page] page number
  # [@param string :type]
  #   valid values are:
  #   * 'MediaBox' : the boundaries of the physical medium on which the page shall be displayed or printed
  #   * 'CropBox' : the visible region of default user space
  #   * 'BleedBox' : the region to which the contents of the page shall be clipped when output in a production environment
  #   * 'TrimBox' : the intended dimensions of the finished page after trimming
  #   * 'ArtBox' : the page's meaningful content (including potential white space).
  # [@param float :llx] lower-left x coordinate in user units
  # [@param float :lly] lower-left y coordinate in user units
  # [@param float :urx] upper-right x coordinate in user units
  # [@param float :ury] upper-right y coordinate in user units
  # [@param boolean :points] if true uses user units as unit of measure, if false uses PDF points
  # [@access public]
  # [@since 5.0.010 (2010-05-17)]
  #
  def setPageBoxes(page, type, llx, lly, urx, ury, points=false)
    pageboxes = ['MediaBox', 'CropBox', 'BleedBox', 'TrimBox', 'ArtBox']
    unless pageboxes.include?(type)
      return
    end
    if @pagedim[page].nil?
      # initialize array
      @pagedim[page] = {}
    end

    points ? k = 1 : k = @k
    @pagedim[page][type] = {}
    @pagedim[page][type]['llx'] = llx * k
    @pagedim[page][type]['lly'] = lly * k
    @pagedim[page][type]['urx'] = urx * k
    @pagedim[page][type]['ury'] = ury * k
  end
  alias_method :set_page_boxes, :setPageBoxes

  #
  # Swap X and Y coordinates of page boxes (change page boxes orientation).
  # [@param int :page] page number
  # [@access protected]
  # [@since 5.0.010 (2010-05-17)]
  #
  def swapPageBoxCoordinates(page)
    pageboxes = ['MediaBox', 'CropBox', 'BleedBox', 'TrimBox', 'ArtBox']
    pageboxes.each {|type|
      # swap X and Y coordinates
      if @pagedim[page][type]
        tmp = @pagedim[page][type]['llx']
        @pagedim[page][type]['llx'] = @pagedim[page][type]['lly']
        @pagedim[page][type]['lly'] = tmp
        tmp = @pagedim[page][type]['urx']
        @pagedim[page][type]['urx'] = @pagedim[page][type]['ury']
        @pagedim[page][type]['ury'] = tmp
      end
    }
  end
  protected :swapPageBoxCoordinates

  #
  # Set page orientation.
  # [@param string :orientation]
  #   page orientation. Possible values are (case insensitive):
  #   * P or PORTRAIT (default)
  #   * L or LANDSCAPE
  # [@param boolean :autopagebreak] Boolean indicating if auto-page-break mode should be on or off.
  # [@param float :bottommargin] bottom margin of the page.
  # [@access public]
  # [@since 3.0.015 (2008-06-06)]
  #
  def setPageOrientation(orientation, autopagebreak='', bottommargin='')
    if @pagedim[@page].nil? or @pagedim[@page]['MediaBox'].nil?
      # the boundaries of the physical medium on which the page shall be displayed or printed
      setPageBoxes(@page, 'MediaBox', 0, 0, @fw_pt, @fh_pt, true)
    end
    if @pagedim[@page]['CropBox'].nil?
      # the visible region of default user space
      setPageBoxes(@page, 'CropBox', @pagedim[@page]['MediaBox']['llx'], @pagedim[@page]['MediaBox']['lly'], @pagedim[@page]['MediaBox']['urx'], @pagedim[@page]['MediaBox']['ury'], true)
    end
    if @pagedim[@page]['BleedBox'].nil?
      # the region to which the contents of the page shall be clipped when output in a production environment
      setPageBoxes(@page, 'BleedBox', @pagedim[@page]['CropBox']['llx'], @pagedim[@page]['CropBox']['lly'], @pagedim[@page]['CropBox']['urx'], @pagedim[@page]['CropBox']['ury'], true)
    end
    if @pagedim[@page]['TrimBox'].nil?
      # the intended dimensions of the finished page after trimming
      setPageBoxes(@page, 'TrimBox', @pagedim[@page]['CropBox']['llx'], @pagedim[@page]['CropBox']['lly'], @pagedim[@page]['CropBox']['urx'], @pagedim[@page]['CropBox']['ury'], true)
    end
    if @pagedim[@page]['ArtBox'].nil?
      # the page's meaningful content (including potential white space)
      setPageBoxes(@page, 'ArtBox', @pagedim[@page]['CropBox']['llx'], @pagedim[@page]['CropBox']['lly'], @pagedim[@page]['CropBox']['urx'], @pagedim[@page]['CropBox']['ury'], true)
    end
    if @pagedim[@page]['Rotate'].nil?
      # The number of degrees by which the page shall be rotated clockwise when displayed or printed. The value shall be a multiple of 90.
      @pagedim[@page]['Rotate'] = 0
    end
    if @pagedim[@page]['PZ'].nil?
      # The page's preferred zoom (magnification) factor
      @pagedim[@page]['PZ'] = 1
    end
    if @fw_pt > @fh_pt
      # landscape
      default_orientation = 'L'
    else
      # portrait
      default_orientation = 'P'
    end
    valid_orientations = ['P', 'L']
    if orientation.empty?
      orientation = default_orientation
    else
      orientation = orientation[0, 1].upcase
    end
    if valid_orientations.include?(orientation) and (orientation != default_orientation)
      @cur_orientation = orientation
      @w_pt = @fh_pt
      @h_pt = @fw_pt
    else
      @cur_orientation = default_orientation
      @w_pt = @fw_pt
      @h_pt = @fh_pt
    end
    if ((@pagedim[@page]['MediaBox']['urx'] - @h_pt).abs < @feps) and ((@pagedim[@page]['MediaBox']['ury'] - @w_pt).abs < @feps)
      # swap X and Y coordinates (change page orientatio
      swapPageBoxCoordinates(@page)
    end
    @w = @w_pt / @k
    @h = @h_pt / @k
    if empty_string(autopagebreak)
      unless @auto_page_break.nil?
        autopagebreak = @auto_page_break
      else
        autopagebreak = true
      end
    end
    if empty_string(bottommargin)
      unless @b_margin.nil?
        bottommargin = @b_margin
      else
        # default value = 2 cm
        bottommargin = 2 * 28.35 / @k
      end
    end
    SetAutoPageBreak(autopagebreak, bottommargin)
    # store page dimensions
    @pagedim[@page]['w'] = @w_pt
    @pagedim[@page]['h'] = @h_pt
    @pagedim[@page]['wk'] = @w
    @pagedim[@page]['hk'] = @h
    @pagedim[@page]['tm'] = @t_margin
    @pagedim[@page]['bm'] = bottommargin
    @pagedim[@page]['lm'] = @l_margin
    @pagedim[@page]['rm'] = @r_margin
    @pagedim[@page]['pb'] = autopagebreak
    @pagedim[@page]['or'] = @cur_orientation
    @pagedim[@page]['olm'] = @original_l_margin
    @pagedim[@page]['orm'] = @original_r_margin
    @pagedim[@page]
  end
  alias_method :set_page_orientation, :setPageOrientation

  #
  # Enable or disable Right-To-Left language mode
  # [@param Boolean :enable] if true enable Right-To-Left language mode.
  # [@param Boolean :resetx] if true reset the X position on direction change.
  # [@access public]
  # [@since 2.0.000 (2008-01-03)]
  #
  def setRTL(enable, resetx=true)
    enable = enable ? true : false
    resetx = resetx and (enable != @rtl)
    @rtl = enable
    @tmprtl = false
    Ln(0) if resetx
  end
  alias_method :set_rtl, :setRTL

  #
  # Return the RTL status
  # [@return boolean]
  # [@access public]
  # [@since 4.0.012 (2008-07-24)]
  #
  def getRTL()
    return @rtl
  end
  alias_method :get_rtl, :getRTL

  #
  # Force temporary RTL language direction
  # [@param mixed :mode] can be false, 'L' for LTR or 'R' for RTL
  # [@access public]
  # [@since 2.1.000 (2008-01-09)]
  #
  def setTempRTL(mode)
    newmode = false
    case mode
    when 'ltr', 'LTR', 'L'
      newmode = 'L' if @rtl
    when 'rtl', 'RTL', 'R'
      newmode = 'R' if !@rtl
    end
    @tmprtl = newmode
  end
  alias_method :set_temp_rtl, :setTempRTL

  #
  # Return the current temporary RTL status
  # [@return boolean] true: RTL, false: LTR
  # [@access public]
  # [@since 4.8.014 (2009-11-04)]
  #
  def isRTLTextDir()
    if @tmprtl != false
      return @tmprtl == 'R'
    else
      return @rtl
    end
  end
  alias_method :is_rtl_text_dir, :isRTLTextDir

  #
  # Return the current text RTL status
  # [@return direction] 'R' : RTL, 'L' LTR
  # [@access protected]
  #
  def rtl_text_dir()
    if @tmprtl != false
      return @tmprtl # 'R' or 'L'
    else
      return @rtl ? 'R' : 'L'
    end
  end
  protected :rtl_text_dir

  #
  # Set the last cell height.
  # [@param float :h] cell height.
  # [@author] Nicola Asuni
  # [@access public]
  # [@since 1.53.0.TC034]
  #
  def setLastH(h)
    @lasth = h
  end
  alias_method :set_last_h, :setLastH

  #
  # Get the last cell height.
  # [@return] last cell height
  # [@access public]
  # [@since 4.0.017 (2008-08-05)]
  #
  def getLastH()
    return @lasth
  end
  alias_method :get_last_h, :getLastH

  #
  # Set the adjusting factor to convert pixels to user units.
  # [@param float :scale] adjusting factor to convert pixels to user units.
  # [@author] Nicola Asuni
  # [@access public]
  # [@since 1.5.2]
  #
  def setImageScale(scale)
    @img_scale = scale;
  end
  alias_method :set_image_scale, :setImageScale

  def SetImageScale(scale)
    warn "[DEPRECATION] 'SetImageScale' is deprecated. Please use 'set_image_scale' instead."
    setImageScale(scale)
  end

  #
  # Returns the adjusting factor to convert pixels to user units.
  # [@return float] adjusting factor to convert pixels to user units.
  # [@author] Nicola Asuni
  # [@access public]
  # [@since 1.5.2]
  #
  def getImageScale()
    return @img_scale;
  end
  alias_method :get_image_scale, :getImageScale

  def GetImageScale()
    warn "[DEPRECATION] 'GetImageScale' is deprecated. Please use 'get_image_scale' instead."
    getImageScale()
  end

  #
  # Returns an array of page dimensions:
  #   @pagedim[@page]['w'] = page width in points
  #   @pagedim[@page]['h'] = height in points
  #   @pagedim[@page]['wk'] = page width in user units
  #   @pagedim[@page]['hk'] = page height in user units
  #   @pagedim[@page]['tm'] = top margin
  #   @pagedim[@page]['bm'] = bottom margin
  #   @pagedim[@page]['lm'] = left margin
  #   @pagedim[@page]['rm'] = right margin
  #   @pagedim[@page]['pb'] = auto page break
  #   @pagedim[@page]['or'] = page orientation
  #   @pagedim[@page]['olm'] = original left margin
  #   @pagedim[@page]['orm'] = original right margin
  #   @pagedim[@page]['Rotate'] = The number of degrees by which the page shall be rotated clockwise when displayed or printed. The value shall be a multiple of 90.
  #   @pagedim[@page]['PZ'] = The page's preferred zoom (magnification) factor.
  #   @pagedim[@page]['trans'] : the style and duration of the visual transition to use when moving from another page to the given page during a presentation
  #     @pagedim[@page]['trans']['Dur'] = The page's display duration (also called its advance timing): the maximum length of time, in seconds, that the page shall be displayed during presentations before the viewer application shall automatically advance to the next page.
  #     @pagedim[@page]['trans']['S'] = transition style : Split, Blinds, Box, Wipe, Dissolve, Glitter, R, Fly, Push, Cover, Uncover, Fade
  #     @pagedim[@page]['trans']['D'] = The duration of the transition effect, in seconds.
  #     @pagedim[@page]['trans']['Dm'] = (Split and Blinds transition styles only) The dimension in which the specified transition effect shall occur: H = Horizontal, V = Vertical. Default value: H.
  #     @pagedim[@page]['trans']['M'] = (Split, Box and Fly transition styles only) The direction of motion for the specified transition effect: I = Inward from the edges of the page, O = Outward from the center of the pageDefault value: I.
  #     @pagedim[@page]['trans']['Di'] = (Wipe, Glitter, Fly, Cover, Uncover and Push transition styles only) The direction in which the specified transition effect shall moves, expressed in degrees counterclockwise starting from a left-to-right direction. If the value is a number, it shall be one of: 0 = Left to right, 90 = Bottom to top (Wipe only), 180 = Right to left (Wipe only), 270 = Top to bottom, 315 = Top-left to bottom-right (Glitter only). If the value is a name, it shall be None, which is relevant only for the Fly transition when the value of SS is not 1.0. Default value: 0.
  #     @pagedim[@page]['trans']['SS'] = (Fly transition style only) The starting or ending scale at which the changes shall be drawn. If M specifies an inward transition, the scale of the changes drawn shall progress from SS to 1.0 over the course of the transition. If M specifies an outward transition, the scale of the changes drawn shall progress from 1.0 to SS over the course of the transition. Default: 1.0.
  #     @pagedim[@page]['trans']['B'] = (Fly transition style only) If true, the area that shall be flown in is rectangular and opaque. Default: false.
  #   @pagedim[@page]['MediaBox'] : the boundaries of the physical medium on which the page shall be displayed or printed
  #     @pagedim[@page]['MediaBox']['llx'] = lower-left x coordinate in points
  #     @pagedim[@page]['MediaBox']['lly'] = lower-left y coordinate in points
  #     @pagedim[@page]['MediaBox']['urx'] = upper-right x coordinate in points
  #     @pagedim[@page]['MediaBox']['ury'] = upper-right y coordinate in points
  #   @pagedim[@page]['CropBox'] : the visible region of default user space
  #     @pagedim[@page]['CropBox']['llx'] = lower-left x coordinate in points
  #     @pagedim[@page]['CropBox']['lly'] = lower-left y coordinate in points
  #     @pagedim[@page]['CropBox']['urx'] = upper-right x coordinate in points
  #     @pagedim[@page]['CropBox']['ury'] = upper-right y coordinate in points
  #   @pagedim[@page]['BleedBox'] : the region to which the contents of the page shall be clipped when output in a production environment
  #     @pagedim[@page]['BleedBox']['llx'] = lower-left x coordinate in points
  #     @pagedim[@page]['BleedBox']['lly'] = lower-left y coordinate in points
  #     @pagedim[@page]['BleedBox']['urx'] = upper-right x coordinate in points
  #     @pagedim[@page]['BleedBox']['ury'] = upper-right y coordinate in points
  #   @pagedim[@page]['TrimBox'] : the intended dimensions of the finished page after trimming
  #     @pagedim[@page]['TrimBox']['llx'] = lower-left x coordinate in points
  #     @pagedim[@page]['TrimBox']['lly'] = lower-left y coordinate in points
  #     @pagedim[@page]['TrimBox']['urx'] = upper-right x coordinate in points
  #     @pagedim[@page]['TrimBox']['ury'] = upper-right y coordinate in points
  #   @pagedim[@page]['ArtBox'] : the extent of the page's meaningful content
  #     @pagedim[@page]['ArtBox']['llx'] = lower-left x coordinate in points
  #     @pagedim[@page]['ArtBox']['lly'] = lower-left y coordinate in points
  #     @pagedim[@page]['ArtBox']['urx'] = upper-right x coordinate in points
  #     @pagedim[@page]['ArtBox']['ury'] = upper-right y coordinate in points
  # [@param int :pagenum] page number (empty = current page)
  # [@return] array of page dimensions.
  # [@author] Nicola Asuni
  # [@access public]
  # [@since 4.5.027 (2009-03-16)]
  #
  def getPageDimensions(pagenum=0)
    if !pagenum.is_a? Integer or pagenum.zero?
      pagenum = @page
    end
    return @pagedim[pagenum]
  end
  alias_method :get_page_dimensions, :getPageDimensions

  #
  # Returns the page width in units.
  # [@return int] page width.
  # [@author] Nicola Asuni
  # [@access public]
  # [@since 1.5.2]
  #
  def getPageWidth()
    return @w;
  end
  alias_method :get_page_width, :getPageWidth

  def GetPageWidth()
    warn "[DEPRECATION] 'GetPageWidth' is deprecated. Please use 'get_page_width' instead."
    getPageWidth()
  end

  #
  # Returns the page height in units.
  # [@return int] page height.
  # [@author] Nicola Asuni
  # [@access public]
  # [@since 1.5.2]
  #
  def getPageHeight()
    return @h;
  end
  alias_method :get_page_height, :getPageHeight

  def GetPageHeight()
    warn "[DEPRECATION] 'GetPageHeight' is deprecated. Please use 'get_page_height' instead."
    getPageHeight()
  end

  #
  # Returns the page break margin.
  # [@param int :pagenum] page number (empty = current page)
  # [@return int page] break margin.
  # [@author] Nicola Asuni
  # [@access publi]c
  # [@since 1.5.2]
  # [@see] getPageDimensions()
  #
  def getBreakMargin(pagenum=0)
    if !pagenum.is_a? Integer or pagenum.zero?
      return @b_margin
    end
    return @pagedim[pagenum]['bm']
  end
  alias_method :get_break_margin, :getBreakMargin

  def GetBreakMargin(pagenum=0)
    warn "[DEPRECATION] 'GetBreakMargin' is deprecated. Please use 'get_break_margin' instead."
    getBreakMargin(pagenum)
  end

  #
  # Returns the scale factor (number of points in user unit).
  # [@return int] scale factor.
  # [@author] Nicola Asuni
  # [@access public]
  # [@since 1.5.2]
  #
  def getScaleFactor()
    return @k;
  end
  alias_method :get_scale_factor, :getScaleFactor

  def GetScaleFactor()
    warn "[DEPRECATION] 'GetScaleFactor' is deprecated. Please use 'get_scale_factor' instead."
    getScaleFactor()
  end

  #
  # Defines the left, top and right margins.
  # [@param float :left] Left margin.
  # [@param float :top] Top margin.
  # [@param float :right] Right margin. Default value is the left one.
  # [@param boolean :keepmargins] if true overwrites the default page margins
  # [@access public]
  # [@since 1.0]
  # [@see] SetLeftMargin(), SetTopMargin(), SetRightMargin(), SetAutoPageBreak()
  #
  def SetMargins(left, top, right=-1, keepmargins=false)
    #Set left, top and right margins
    @l_margin = left
    @t_margin = top
    if (right == -1)
      right = left
    end
    @r_margin = right
    if keepmargins
      # overwrite original values
      @original_l_margin = @l_margin
      @original_r_margin = @r_margin
    end
  end
  alias_method :set_margins, :SetMargins

  #
  # Defines the left margin. The method can be called before creating the first page. If the current abscissa gets out of page, it is brought back to the margin.
  # [@param float :margin] The margin.
  # [@access public]
  # [@since 1.4]
  # [@see] SetTopMargin(), SetRightMargin(), SetAutoPageBreak(), SetMargins()
  #
  def SetLeftMargin(margin)
    #Set left margin
    @l_margin = margin
    if (@page > 0) and (@x < margin)
      @x = margin
    end
  end
  alias_method :set_left_margin, :SetLeftMargin

  #
  # Defines the top margin. The method can be called before creating the first page.
  # [@param float :margin] The margin.
  # [@access public]
  # [@since 1.5]
  # [@see] SetLeftMargin(), SetRightMargin(), SetAutoPageBreak(), SetMargins()
  #
  def SetTopMargin(margin)
    #Set top margin
    @t_margin = margin
    if (@page > 0) and (@y < margin)
      @y = margin
    end
  end
  alias_method :set_top_margin, :SetTopMargin

  #
  # Defines the right margin. The method can be called before creating the first page.
  # [@param float :margin] The margin.
  # [@access public]
  # [@since 1.5]
  # [@see] SetLeftMargin(), SetTopMargin(), SetAutoPageBreak(), SetMargins()
  #
  def SetRightMargin(margin)
    @r_margin = margin
    if (@page > 0) and (@x > (@w - margin))
      @x = @w - margin
    end
  end
  alias_method :set_right_margin, :SetRightMargin

  #
  # Set the internal Cell padding.
  # [@param float :pad] internal padding.
  # [@access public]
  # [@since 2.1.000 (2008-01-09)]
  # [@see] Cell(), SetLeftMargin(), SetTopMargin(), SetAutoPageBreak(), SetMargins()
  #
  def SetCellPadding(pad)
    @c_margin = pad
  end
  alias_method :set_cell_padding, :SetCellPadding

  #
  # Enables or disables the automatic page breaking mode. When enabling, the second parameter is the distance from the bottom of the page that defines the triggering limit. By default, the mode is on and the margin is 2 cm.
  # [@param boolean :auto] Boolean indicating if mode should be on or off.
  # [@param float :margin] Distance from the bottom of the page.
  # [@access public]
  # [@since 1.0]
  # [@see] Cell(), MultiCell(), AcceptPageBreak()
  #
  def SetAutoPageBreak(auto, margin=0)
    #Set auto page break mode and triggering margin
    @auto_page_break = auto
    @b_margin = margin
    @page_break_trigger = @h - margin
  end
  alias_method :set_auto_page_break, :SetAutoPageBreak

  #
  # Defines the way the document is to be displayed by the viewer.
  # [@param mixed :zoom]
  #   The zoom to use. It can be one of the following string values or a number indicating the zooming factor to use.
  #   * fullpage: displays the entire page on screen
  #   * fullwidth: uses maximum width of window
  #   * real: uses real size (equivalent to 100% zoom)
  #   * default: uses viewer default mode
  # [@param string :layout]
  #   The page layout. Possible values are:
  #   * SinglePage Display one page at a time
  #   * OneColumn Display the pages in one column
  #   * TwoColumnLeft Display the pages in two columns, with odd-numbered pages on the left
  #   * TwoColumnRight Display the pages in two columns, with odd-numbered pages on the right
  #   * TwoPageLeft (PDF 1.5) Display the pages two at a time, with odd-numbered pages on the left
  #   * TwoPageRight (PDF 1.5) Display the pages two at a time, with odd-numbered pages on the right
  # [@param string :mode]
  #   A name object specifying how the document should be displayed when opened:
  #   * UseNone Neither document outline nor thumbnail images visible
  #   * UseOutlines Document outline visible
  #   * UseThumbs Thumbnail images visible
  #   * FullScreen Full-screen mode, with no menu bar, window controls, or any other window visible
  #   * UseOC (PDF 1.5) Optional content group panel visible
  #   * UseAttachments (PDF 1.6) Attachments panel visible
  # [@access public]
  # [@since 1.2]
  #
  def SetDisplayMode(zoom, layout='SinglePage', mode='UseNone')
    #Set display mode in viewer
    if (zoom == 'fullpage' or zoom == 'fullwidth' or zoom == 'real' or zoom == 'default' or zoom.is_a?(Numeric))
      @zoom_mode = zoom
    else
      Error('Incorrect zoom display mode: ' + zoom)
    end

    case layout
    when 'default', 'single', 'SinglePage'
      @layout_mode = 'SinglePage'
    when 'continuous', 'OneColumn'
      @layout_mode = 'OneColumn'
    when 'two', 'TwoColumnLeft'
      @layout_mode = 'TwoColumnLeft'
    when 'TwoColumnRight'
      @layout_mode = 'TwoColumnRight'
    when 'TwoPageLeft'
      @layout_mode = 'TwoPageLeft'
    when 'TwoPageRight'
      @layout_mode = 'TwoPageRight'
    else
      @layout_mode = 'SinglePage'
    end

    case mode
    when 'UseNone'
      @page_mode = 'UseNone'
    when 'UseOutlines'
      @page_mode = 'UseOutlines'
    when 'UseThumbs'
      @page_mode = 'UseThumbs'
    when 'FullScreen'
      @page_mode = 'FullScreen'
    when 'UseOC'
      @page_mode = 'UseOC'
    when ''
      @page_mode = 'UseAttachments'
    else
      @page_mode = 'UseNone'
    end
  end
  alias_method :set_display_mode, :SetDisplayMode

  #
  # Activates or deactivates page compression. When activated, the internal representation of each page is compressed, which leads to a compression ratio of about 2 for the resulting document. Compression is on by default.
  # * Note: the Zlib extension is required for this feature. If not present, compression will be turned off.
  # [@param boolean :compress] Boolean indicating if compression must be enabled.
  # [@access public]
  # [@since 1.4]
  #
  def SetCompression(compress)
    #Set page compression
    if Object.const_defined?(:Zlib)
      @compress = compress
    else
      @compress = false
    end
  end
  alias_method :set_compression, :SetCompression

  #
  # Defines the title of the document.
  # [@param string :title] The title.
  # [@access public$
  # [@since 1.2]
  # [@see] SetAuthor(), SetCreator(), SetKeywords(), SetSubject()
  #
  def SetTitle(title)
    #Title of document
    @title = title
  end
  alias_method :set_title, :SetTitle

  #
  # Defines the subject of the document.
  # [@param string :subject] The subject.
  # [@access public]
  # [@since 1.2]
  # [@see] SetAuthor(), SetCreator(), SetKeywords(), SetTitle()
  #
  def SetSubject(subject)
    #Subject of document
    @subject = subject
  end
  alias_method :set_subject, :SetSubject

  #
  # Defines the author of the document.
  # [@param string :author] The name of the author.
  # [@access public]
  # [@since 1.2]
  # [@see] SetCreator(), SetKeywords(), SetSubject(), SetTitle()
  #
  def SetAuthor(author)
    #Author of document
    @author = author
  end
  alias_method :set_author, :SetAuthor

  #
  # Associates keywords with the document, generally in the form 'keyword1 keyword2 ...'.
  # [@param string :keywords] The list of keywords.
  # [@access public]
  # [@since 1.2]
  # [@see] SetAuthor(), SetCreator(), SetSubject(), SetTitle()
  #
  def SetKeywords(keywords)
    #Keywords of document
    @keywords = keywords
  end
  alias_method :set_keywords, :SetKeywords

  #
  # Defines the creator of the document. This is typically the name of the application that generates the PDF.
  # [@param string :creator] The name of the creator.
  # [@access public]
  # [@since 1.2]
  # [@see] SetAuthor(), SetKeywords(), SetSubject(), SetTitle()
  #
  def SetCreator(creator)
    #Creator of document
    @creator = creator
  end
  alias_method :set_creator, :SetCreator

  #
  # This method is automatically called in case of fatal error; it simply outputs the message and halts the execution. An inherited class may override it to customize the error handling but should always halt the script, or the resulting document would probably be invalid.
  # * 2004-06-11 :: Nicola Asuni : changed bold tag with strong
  # [@param string :msg] The error message
  # [@param string :err] Exception object
  # [@access public]
  # [@since 1.0]
  #
  def Error(msg, err = nil)
    if /^.+?:\d+(?::in `(.*)')?/ =~ caller(2).first
      method = $1
    end
    if err and err.class != RBPDFError
      logger.error "pdf: #{method}: #{err.message}"
      err.backtrace.each{|trace|
        logger.error trace
      }
    end
    raise RBPDFError, "RBPDF error: #{msg}"
  end
  alias_method :error, :Error

  #
  # This method begins the generation of the PDF document. It is not necessary to call it explicitly because AddPage() does it automatically.
  # * Note: no page is created by this method
  # [@access public]
  # [@since 1.0]
  # [@see] AddPage(), Close()
  #
  def Open()
    #Begin document
    @state = 1
  end
  # alias_method :open, :Open

  #
  # Terminates the PDF document. It is not necessary to call this method explicitly because Output() does it automatically. If the document contains no page, AddPage() is called to prevent from getting an invalid document.
  # [@since 1.0]
  # [@see] Open(), Output()
  #
  def Close()
    #Terminate document
    if (@state==3)
      return;
    end
    if (@page==0)
      AddPage();
    end
    # close page
    endPage()
    lastPage()
    resetLinksAfterCurrentPage()

    @state = 2
    SetAutoPageBreak(false)
    @y = @h - (1 / @k)
    @r_margin = 0
    out('q')
    setVisibility('screen')
    SetFont('helvetica', '', 1)
    SetTextColor(127,127,127)
    setAlpha(0)
    msg = "\x50\x6f\x77\x65\x72\x65\x64\x20\x62\x79\x20\x54\x43\x50\x44\x46\x20\x28\x77\x77\x77\x2e\x74\x63\x70\x64\x66\x2e\x6f\x72\x67\x29"
    lnk = "\x68\x74\x74\x70\x3a\x2f\x2f\x77\x77\x77\x2e\x74\x63\x70\x64\x66\x2e\x6f\x72\x67"
    Cell(0, 0, msg, 0, 0, 'R', 0, lnk, 0, false, 'D', 'B')
    out('Q')
    setVisibility('all')
    @state = 1
    # close document
    enddoc();
  end
  # alias_method :close, :Close

  #
  # Move pointer at the specified document page and update page dimensions.
  # [@param int :pnum] page number (1 ... numpages)
  # [@param boolean :resetmargins] if true reset left, right, top margins and Y position.
  # [@access public]
  # [@since 2.1.000 (2008-01-07)]
  # [@see] getPage(), lastPage(), getNumPages()
  #
  def setPage(pnum, resetmargins=false)
    if pnum == @page
      return
    end
    if (pnum > 0) and (pnum <= @numpages)
      @state = 2
      # save current graphic settings
      # gvars = getGraphicVars()
      oldpage = @page
      @page = pnum
      @w_pt = @pagedim[@page]['w']
      @h_pt = @pagedim[@page]['h']
      @w = @pagedim[@page]['wk']
      @h = @pagedim[@page]['hk']
      @t_margin = @pagedim[@page]['tm']
      @b_margin = @pagedim[@page]['bm']
      @original_l_margin = @pagedim[@page]['olm']
      @original_r_margin = @pagedim[@page]['orm']
      @auto_page_break = @pagedim[@page]['pb']
      @cur_orientation = @pagedim[@page]['or']
      SetAutoPageBreak(@auto_page_break, @b_margin)
      # restore graphic settings
      # setGraphicVars(gvars)
      if resetmargins
        @l_margin = @pagedim[@page]['olm']
        @r_margin = @pagedim[@page]['orm']
        SetY(@t_margin)
      else
        # account for booklet mode
        if @pagedim[@page]['olm'] != @pagedim[oldpage]['olm']
          deltam = @pagedim[@page]['olm'] - @pagedim[@page]['orm']
          @l_margin += deltam
          @r_margin -= deltam
        end
      end
    else
      Error('Wrong page number on setPage() function.')
    end
  end
  alias_method :set_page, :setPage

  #
  # Reset pointer to the last document page.
  # [@param boolean :resetmargins] if true reset left, right, top margins and Y position.
  # [@access public]
  # [@since 2.0.000 (2008-01-04)]
  # [@see] setPage(), getPage(), getNumPages()
  #
  def lastPage(resetmargins=false)
    setPage(getNumPages(), resetmargins)
  end
  alias_method :last_page, :lastPage

  #
  # Get current document page number.
  # [@return int] page number
  # [@access public]
  # [@since 2.1.000 (2008-01-07)]
  # [@see] setPage(), lastPage(), getNumPages()
  #
  def getPage()
    return @page
  end
  alias_method :get_page, :getPage

  #
  # Get the total number of insered pages.
  # [@return int] number of pages
  # [@access public]
  # [@since 2.1.000 (2008-01-07)]
  # [@see] setPage(), getPage(), lastPage()
  #
  def getNumPages()
    return @numpages
  end
  alias_method :get_num_pages, :getNumPages

  #
  # Adds a new TOC (Table Of Content) page to the document.
  # [@param string :orientation] page orientation.
  # [@param boolean :keepmargins] if true overwrites the default page margins with the current margins
  # [@access public]
  # [@since 5.0.001 (2010-05-06)]
  # [@see] AddPage(), startPage(), endPage(), endTOCPage()
  #
  def addTOCPage(orientation='', format='', keepmargins=false)
    AddPage(orientation, format, keepmargins, true)
  end
  alias_method :add_toc_page, :addTOCPage

  #
  # Terminate the current TOC (Table Of Content) page
  # [@access public]
  # [@since 5.0.001 (2010-05-06)]
  # [@see] AddPage(), startPage(), endPage(), addTOCPage()
  #
  def endTOCPage()
    endPage(true)
  end
  alias_method :end_toc_page, :endTOCPage

  #
  # Adds a new page to the document. If a page is already present, the Footer() method is called first to output the footer (if enabled). Then the page is added, the current position set to the top-left corner according to the left and top margins (or top-right if in RTL mode), and Header() is called to display the header (if enabled).
  # The origin of the coordinate system is at the top-left corner (or top-right for RTL) and increasing ordinates go downwards.
  # [@param string :orientation]
  #   page orientation. Possible values are (case insensitive):
  #   * P or PORTRAIT (default)
  #   * L or LANDSCAPE
  # [@param mixed :format]
  #   The format used for pages. It can be either: <b>A string indicating the page format:</b>
  #   * 4A0,2A0,A0,A1,A2,A3,A4 (default),A5,A6,A7,A8,A9,A10
  #   * B0,B1,B2,B3,B4,B5,B6,B7,B8,B9,B10
  #   * C0,C1,C2,C3,C4,C5,C6,C7,C8,C9,C10
  #   * RA0,RA1,RA2,RA3,RA4
  #   * SRA0,SRA1,SRA2,SRA3,SRA4
  #   * LETTER,LEGAL,EXECUTIVE,FOLIO
  #   <b>An array containing page measures and advanced options:</b> see setPageFormat()
  # [@param boolean :keepmargins] if true overwrites the default page margins with the current margin
  # [@param boolean :tocpage] if true set the tocpage state to true (the added page will be used to display Table Of Content).
  # [@access public]
  # [@since 1.0]
  # [@see] startPage, endPage(), addTOCPage(), endTOCPage()
  #
  def AddPage(orientation='', format='', keepmargins=false, tocpage=false)
    if @original_l_margin.nil? or keepmargins
      @original_l_margin = @l_margin
    end
    if @original_r_margin.nil? or keepmargins
      @original_r_margin = @r_margin
    end
    # terminate previous page
    endPage()
    # start new page
    startPage(orientation, format, tocpage)
  end
  alias_method :add_page, :AddPage

  #
  # Terminate the current page
  # [@param boolean :tocpage] if true set the tocpage state to false (end the page used to display Table Of Content).
  # [@access public]
  # [@since 4.2.010 (2008-11-14)]
  # [@see] AddPage(), startPage(), addTOCPage(), endTOCPage()
  #
  def endPage(tocpage=false)
    # check if page is already closed
    if (@page == 0) or (@numpages > @page) or !@pageopen[@page]
      return
    end
    @in_footer = true
    # print page footer
    setFooter()
    # close page
    endpage()
    # mark page as closed
    @pageopen[@page] = false
    @in_footer = false
    if tocpage
      @tocpage = false
    end
  end
  alias_method :end_page, :endPage

  #
  # Starts a new page to the document. The page must be closed using the endPage() function.
  # The origin of the coordinate system is at the top-left corner and increasing ordinates go downwards.
  # [@param string :orientation]
  #   page orientation. Possible values are (case insensitive):
  #   * P or PORTRAIT (default)
  #   * L or LANDSCAPE
  # [@param mixed :format]
  #   The format used for pages. It can be either: <b>A string indicating the page format:</b>
  #   * 4A0,2A0,A0,A1,A2,A3,A4 (default),A5,A6,A7,A8,A9,A10
  #   * B0,B1,B2,B3,B4,B5,B6,B7,B8,B9,B10
  #   * C0,C1,C2,C3,C4,C5,C6,C7,C8,C9,C10
  #   * RA0,RA1,RA2,RA3,RA4
  #   * SRA0,SRA1,SRA2,SRA3,SRA4
  #   * LETTER,LEGAL,EXECUTIVE,FOLIO
  #   <b>An array containing page measures and advanced options:</b> see setPageFormat()
  # [@param boolean :tocpage] if true set the tocpage state to true (the added page will be used to display Table of Content).
  # [@access public]
  # [@since 4.2.010 (2008-11-14)]
  # [@see] AddPage(), endPage(), addTOCPage(), endTOCPage()
  #
  def startPage(orientation='', format='', tocpage=false)
    if tocpage
      @tocpage = true
    end
    if @numpages > @page
      # this page has been already added
      setPage(@page + 1)
      SetY(@t_margin)
      return
    end
    # start a new page
    if @state == 0
      Open()
    end
    @numpages += 1
    swapMargins(@booklet)
    # save current graphic settings
    gvars = getGraphicVars()
    # start new page
    beginpage(orientation, format)
    # mark page as open
    @pageopen[@page] = true
    # restore graphic settings
    setGraphicVars(gvars)
    # mark this point
    setPageMark()
    # print page header
    setHeader()
    # restore graphic settings
    setGraphicVars(gvars)
    # mark this point
    setPageMark()
    # print table header (if any)
    setTableHeader()
  end
  alias_method :start_page, :startPage

  #
  # Set start-writing mark on current page stream used to put borders and fills.
  # Borders and fills are always created after content and inserted on the position marked by this method.
  # This function must be called after calling Image() function for a background image.
  # Background images must be always inserted before calling Multicell() or WriteHTMLCell() or WriteHTML() functions.
  # [@access public]
  # [@since 4.0.016 (2008-07-30)]
  #
  def setPageMark()
    @intmrk[@page] = @pagelen[@page]
    setContentMark()
  end
  alias_method :set_page_mark, :setPageMark

  #
  # Set start-writing mark on selected page.
  # Borders and fills are always created after content and inserted on the position marked by this method.
  # [@param int :page] page number (default is the current page)
  # [@access protected]
  # [@since 4.6.021 (2009-07-20)]
  #
  def setContentMark(page=0)
    if page <= 0
      page = @page
    end
    if @footerlen[page]
      @cntmrk[page] = @pagelen[page] - @footerlen[page]
    else
      @cntmrk[page] = @pagelen[page]
    end
  end
  protected :setContentMark

  #
  # Set header data.
  # [@param string :ln] header image logo
  # [@param string :lw] header image logo width in mm
  # [@param string :ht] string to print as title on document header
  # [@param string :hs] string to print on document header
  # [@access public]
  #
  def setHeaderData(ln="", lw=0, ht="", hs="")
    @header_logo = ln || ""
    @header_logo_width = lw || 0
    @header_title = ht || ""
    @header_string = hs || ""
  end
  alias_method :set_header_data, :setHeaderData

  def SetHeaderData(ln="", lw=0, ht="", hs="")
    warn "[DEPRECATION] 'SetHeaderData' is deprecated. Please use 'set_header_data' instead."
    setHeaderData(ln, lw, ht, hs)
  end

  #
  # Returns header data:
  #   ret['logo'] = logo image
  #   ret['logo_width'] = width of the image logo in user units
  #   ret['title'] = header title
  #   ret['string'] = header description string
  # [@return hash]
  # [@access public]
  # [@since 4.0.012 (2008-07-24)]
  #
  def getHeaderData()
    ret = {}
    ret['logo'] = @header_logo
    ret['logo_width'] = @header_logo_width
    ret['title'] = @header_title
    ret['string'] = @header_string
    return ret
  end
  alias_method :get_header_data, :getHeaderData

  #
  # Set header margin.
  # (minimum distance between header and top page margin)
  # [@param int :hm] distance in user units
  # [@access public]
  #
  def setHeaderMargin(hm=10)
    @header_margin = hm;
  end
  alias_method :set_header_margin, :setHeaderMargin

  def SetHeaderMargin(hm=10)
    warn "[DEPRECATION] 'SetHeaderMargin' is deprecated. Please use 'set_header_margin' instead."
    setHeaderMargin(hm)
  end

  #
  # Returns header margin in user units.
  # [@return float]
  # [@since 4.0.012 (2008-07-24)]
  # [@access public]
  #
  def getHeaderMargin()
    return @header_margin
  end
  alias_method :get_header_margin, :getHeaderMargin

  #
  # Set footer margin.
  # (minimum distance between footer and bottom page margin)
  # [@param int :fm] distance in millimeters
  # [@access public]
  #
  def setFooterMargin(fm=10)
    @footer_margin = fm;
  end
  alias_method :set_footer_margin, :setFooterMargin

  def SetFooterMargin(fm=10)
    warn "[DEPRECATION] 'SetFooterMargin' is deprecated. Please use 'set_footer_margin' instead."
    setFooterMargin(fm)
  end

  #
  # Returns footer margin in user units.
  # [@return float]
  # [@since 4.0.012 (2008-07-24)]
  # [@access public]
  #
  def getFooterMargin()
    return @footer_margin
  end
  alias_method :get_footer_margin, :getFooterMargin

  #
  # Set a flag to print page header.
  # [@param boolean :val] set to true to print the page header (default), false otherwise.
  # [@access public]
  #
  def setPrintHeader(val=true)
    @print_header = val;
  end
  alias_method :set_print_header, :setPrintHeader

  def SetPrintHeader(val=true)
    warn "[DEPRECATION] 'SetPrintHeader' is deprecated. Please use 'set_print_header' instead."
    setPrintHeader(val)
  end

  #
  # Set a flag to print page footer.
  # [@param boolean :value] set to true to print the page footer (default), false otherwise.
  # [@access public]
  #
  def setPrintFooter(val=true)
    @print_footer = val;
  end
  alias_method :set_print_footer, :setPrintFooter

  def SetPrintFooter(val=true)
    warn "[DEPRECATION] 'SetPrintFooter' is deprecated. Please use 'set_print_footer' instead."
    setPrintFooter(val)
  end

  #
  # Return the right-bottom (or left-bottom for RTL) corner X coordinate of last inserted image
  # [@return float]
  # [@access public]
  #
  def getImageRBX()
    return @img_rb_x
  end
  alias_method :get_image_rbx, :getImageRBX

  #
  # Return the right-bottom (or left-bottom for RTL) corner Y coordinate of last inserted image
  # [@return float]
  # [@access public]
  #
  def getImageRBY()
    return @img_rb_y
  end
  alias_method :get_image_rby, :getImageRBY

  #
  # This method is used to render the page header.
  # It is automatically called by AddPage() and could be overwritten in your own inherited class.
  # [@access public]
  #
  def Header()
    ormargins = getOriginalMargins()
    headerfont = getHeaderFont()
    headerdata = getHeaderData()
    if headerdata['logo'] and (headerdata['logo'] != @@k_blank_image)
      result_img = Image(@@k_path_images + headerdata['logo'], '', '', headerdata['logo_width'])
      if result_img != false
        imgy = getImageRBY()
      else
        Write(@lasth, File.basename(headerdata['logo']), '', false, '', false, 0, false)
        imgy = GetY()
      end
    else
      imgy = GetY()
    end
    cell_height = ((getCellHeightRatio() * headerfont[2]) / getScaleFactor()).round(2)

    # set starting margin for text data cell
    if getRTL()
      header_x = ormargins['right'] + (headerdata['logo_width'] * 1.1)
    else
      header_x = ormargins['left'] + (headerdata['logo_width'] * 1.1)
    end
    SetTextColor(0, 0, 0)
    # header title
    SetFont(headerfont[0], 'B', headerfont[2] + 1)
    SetX(header_x)
    Cell(0, cell_height, headerdata['title'], 0, 1, '', 0, '', 0)
    # header string
    SetFont(headerfont[0], headerfont[1], headerfont[2])
    SetX(header_x)
    MultiCell(0, cell_height, headerdata['string'], 0, '', 0, 1, '', '', true, 0, false)

    # print an ending header line
    SetLineStyle({'width' => 0.85 / getScaleFactor(), 'cap' => 'butt', 'join' => 'miter', 'dash' => 0, 'color' => [0, 0, 0]})
    SetY((2.835 / getScaleFactor()) + (imgy > GetY() ? imgy : GetY()))

    if getRTL()
      SetX(ormargins['right'])
    else
      SetX(ormargins['left'])
    end
    Cell(0, 0, '', 'T', 0, 'C')
  end
  alias_method :header, :Header

  #
  # This method is used to render the page footer.
  # It is automatically called by AddPage() and could be overwritten in your own inherited class.
  # [@access public]
  #
  def Footer()
    cur_y = GetY()
    ormargins = getOriginalMargins()
    SetTextColor(0, 0, 0)
    # set style for cell border
    line_width = 0.85 / getScaleFactor()
    SetLineStyle({'width' => line_width, 'cap' => 'butt', 'join' => 'miter', 'dash' => 0, 'color' => [0, 0, 0]})
    # print document barcode
    #barcode = getBarcode()
    #if !barcode.empty?
    #  Ln(line_width)
    #  barcode_width = ((getPageWidth() - ormargins['left'] - ormargins['right']) / 3.0).round
    #  write1DBarcode(barcode, 'C128B', GetX(), cur_y + line_width, barcode_width, ((getFooterMargin() / 3.0) - line_width), 0.3, '', '')
    #end
    w_page = (@l.nil? or @l['w_page'].nil?) ? '' : @l['w_page']
    if @pagegroups.empty?
      pagenumtxt = w_page + ' ' + getAliasNumPage() + ' / ' + getAliasNbPages()
    else
      pagenumtxt = w_page + ' ' + getPageNumGroupAlias() + ' / ' + getPageGroupAlias()
    end
    SetY(cur_y)
    # Print page number
    if getRTL()
      SetX(ormargins['right'])
      Cell(0, 0, pagenumtxt, 'T', 0, 'L')
    else
      SetX(ormargins['left'])
      Cell(0, 0, pagenumtxt, 'T', 0, 'R')
    end
  end
  alias_method :footer, :Footer

  #
  # This method is used to render the page header.
  # [@access protected]
  # [@since 4.0.012 (2008-07-24)]
  #
  def setHeader()
    if @print_header
      temp_thead = @thead
      temp_theadMargins = @thead_margins
      lasth = @lasth
      out('q')
      @r_margin = @original_r_margin
      @l_margin = @original_l_margin
      @c_margin = 0
      # set current position
      if @rtl
        SetXY(@original_r_margin, @header_margin)
      else
        SetXY(@original_l_margin, @header_margin)
      end
      SetFont(@header_font[0], @header_font[1], @header_font[2])
      Header()
      # restore position
      if @rtl
        SetXY(@original_r_margin, @t_margin)
      else
        SetXY(@original_l_margin, @t_margin)
      end
      out('Q')
      @lasth = lasth
      @thead = temp_thead
      @thead_margins = temp_theadMargins
      @newline = false
    end
  end
  protected :setHeader

  #
  # This method is used to render the page footer.
  # [@access protected]
  # [@since 4.0.012 (2008-07-24)]
  #
  def setFooter()
    # Page footer
    # save current graphic settings
    gvars = getGraphicVars()
    # mark this point
    @footerpos[@page] = @pagelen[@page]
    out("\n")
    if @print_footer
      temp_thead = @thead
      temp_theadMargins = @thead_margins
      lasth = @lasth
      out('q')
      @r_margin = @original_r_margin
      @l_margin = @original_l_margin
      @c_margin = 0
      # set current position
      footer_y = @h - @footer_margin
      if @rtl
        SetXY(@original_r_margin, footer_y)
      else
        SetXY(@original_l_margin, footer_y)
      end
      SetFont(@footer_font[0], @footer_font[1] , @footer_font[2])
      Footer()
      # restore position
      if @rtl
        SetXY(@original_r_margin, @t_margin)
      else
        SetXY(@original_l_margin, @t_margin)
      end
      out('Q')
      @lasth = lasth
      @thead = temp_thead
      @thead_margins = temp_theadMargins
    end
    # restore graphic settings
    setGraphicVars(gvars)
    # calculate footer length
    @footerlen[@page] = @pagelen[@page] - @footerpos[@page] + 1
  end
  protected :setFooter

  #
  # This method is used to render the table header on new page (if any).
  # [@access protected]
  # [@since 4.5.030 (2009-03-25)]
  #
  def setTableHeader()
    if @num_columns > 1
      # multi column mode
      return
    end
    if !@thead_margins['top'].nil?
      # restore the original top-margin
      @t_margin = @thead_margins['top']
      @pagedim[@page]['tm'] = @t_margin
      @y = @t_margin
    end
    if !empty_string(@thead) and !@in_thead
      # set margins
      prev_lMargin = @l_margin
      prev_rMargin = @r_margin
      prev_cMargin = @c_margin
      @l_margin = @thead_margins['lmargin']
      @r_margin = @thead_margins['rmargin']
      @c_margin = @thead_margins['cmargin']
      if @rtl
        @x = @w - @r_margin
      else
        @x = @l_margin
      end
      # print table header
      writeHTML(@thead, false, false, false, false, '')
      # set new top margin to skip the table headers
      if @thead_margins['top'].nil?
        @thead_margins['top'] = @t_margin
      end
      @t_margin = @y
      @pagedim[@page]['tm'] = @t_margin
      @lasth = 0
      @l_margin = prev_lMargin
      @r_margin = prev_rMargin
      @c_margin = prev_cMargin
    end
  end
  protected :setTableHeader

  #
  # Returns the current page number.
  # [@return int] page number
  # [@access public]
  # [@since 1.0]
  # [@see] alias_nb_pages()
  #
  def PageNo()
    #Get current page number
    return @page;
  end
  alias_method :page_no, :PageNo

  #
  # Defines a new spot color.
  # It can be expressed in RGB components or gray scale.
  # The method can be called before the first page is created and the value is retained from page to page.
  # [@param int :c] Cyan color for CMYK. Value between 0 and 255
  # [@param int :m] Magenta color for CMYK. Value between 0 and 255
  # [@param int :y] Yellow color for CMYK. Value between 0 and 255
  # [@param int :k] Key (Black) color for CMYK. Value between 0 and 255
  # [@access public]
  # [@since 4.0.024 (2008-09-12)]
  # [@see] SetDrawSpotColor(), SetFillSpotColor(), SetTextSpotColor()
  #
  def AddSpotColor(name, c, m, y, k)
    if @spot_colors[name].nil?
      i = 1 + @spot_colors.length
      @spot_colors[name] = {'i' => i, 'c' => c, 'm' => m, 'y' => y, 'k' => k}
    end
  end
  alias_method :add_spot_color, :AddSpotColor

  #
  # Defines the color used for all drawing operations (lines, rectangles and cell borders).
  # It can be expressed in RGB components or gray scale.
  # The method can be called before the first page is created and the value is retained from page to page.
  # [@param array or ordered hash :color] array(or ordered hash) of colors
  # [@access public]
  # [@since 3.1.000 (2008-6-11)]
  # [@see] SetDrawColor()
  #
  def SetDrawColorArray(color)
    if !color.nil?
      color = color.values if color.is_a? Hash
      r = !color[0].nil? ? color[0] : -1
      g = !color[1].nil? ? color[1] : -1
      b = !color[2].nil? ? color[2] : -1
      k = !color[3].nil? ? color[3] : -1
      if r >= 0
        SetDrawColor(r, g, b, k)
      end
    end
  end
  alias_method :set_draw_color_array, :SetDrawColorArray

  #
  # Defines the color used for all drawing operations (lines, rectangles and cell borders). It can be expressed in RGB components or gray scale. The method can be called before the first page is created and the value is retained from page to page.
  # [@param int :col1] Gray level for single color, or Red color for RGB, or Cyan color for CMYK. Value between 0 and 255
  # [@param int :col2] Green color for RGB, or Magenta color for CMYK. Value between 0 and 255
  # [@param int :col3] Blue color for RGB, or Yellow color for CMYK. Value between 0 and 255
  # [@param int :col4] Key (Black) color for CMYK. Value between 0 and 255
  # [@access public]
  # [@since 1.3]
  # [@see] SetFillColor(), SetTextColor(), Line(), Rect(), Cell(), MultiCell()
  #
  def SetDrawColor(col1=0, col2=-1, col3=-1, col4=-1)
    # set default values
    unless col1.is_a?(Numeric)
      col1 = 0
    end
    unless col2.is_a?(Numeric)
      col2 = 0
    end
    unless col3.is_a?(Numeric)
      col3 = 0
    end
    unless col4.is_a?(Numeric)
      col4 = 0
    end
    #Set color for all stroking operations
    if (col2 == -1) and (col3 == -1) and (col4 == -1)
      # Grey scale
      @draw_color = sprintf('%.3f G', col1 / 255.0)
      @strokecolor['G'] = col1
    elsif col4 == -1
      # RGB
      @draw_color = sprintf('%.3f %.3f %.3f RG', col1 / 255.0, col2 / 255.0, col3 / 255.0)
      @strokecolor['R'] = col1
      @strokecolor['G'] = col2
      @strokecolor['B'] = col3
    else
      # CMYK
      @draw_color = sprintf('%.3f %.3f %.3f %.3f K', col1 / 100.0, col2 / 100.0, col3 / 100.0, col4 / 100.0)
      @strokecolor['C'] = col1
      @strokecolor['M'] = col2
      @strokecolor['Y'] = col3
      @strokecolor['K'] = col4
    end
    if (@page>0)
      out(@draw_color + ' ')
    end
  end
  alias_method :set_draw_color, :SetDrawColor

  #
  # Defines the color used for all filling operations (filled rectangles and cell backgrounds).
  # It can be expressed in RGB components or gray scale.
  # The method can be called before the first page is created and the value is retained from page to page.
  # [@param array or ordered hash :color] array(or ordered hash) of colors
  # [@access public]
  # [@since 3.1.000 (2008-6-11)]
  # [@see] SetFillColor()
  #
  def SetFillColorArray(color)
    if !color.nil?
      color = color.values if color.is_a? Hash
      r = !color[0].nil? ? color[0] : -1
      g = !color[1].nil? ? color[1] : -1
      b = !color[2].nil? ? color[2] : -1
      k = !color[3].nil? ? color[3] : -1
      if r >= 0
        SetFillColor(r, g, b, k)
      end
    end
  end
  alias_method :set_fill_color_array, :SetFillColorArray

  #
  # Defines the color used for all filling operations (filled rectangles and cell backgrounds). It can be expressed in RGB components or gray scale. The method can be called before the first page is created and the value is retained from page to page.
  # [@param int :col1] Gray level for single color, or Red color for RGB, or Cyan color for CMYK. Value between 0 and 255
  # [@param int :col2] Green color for RGB, or Magenta color for CMYK. Value between 0 and 255
  # [@param int :col3] Blue color for RGB, or Yellow color for CMYK. Value between 0 and 255
  # [@param int :col4] Key (Black) color for CMYK. Value between 0 and 255
  # [@access public]
  # [@since 1.3]
  # [@see] SetDrawColor(), SetTextColor(), Rect(), Cell(), MultiCell()
  #
  def SetFillColor(col1=0, col2=-1, col3=-1, col4=-1)
    # set default values
    unless col1.is_a?(Numeric)
      col1 = 0
    end
    unless col2.is_a?(Numeric)
      col2 = -1
    end
    unless col3.is_a?(Numeric)
      col3 = -1
    end
    unless col4.is_a?(Numeric)
      col4 = -1
    end

    # Set color for all filling operations
    if (col2 == -1) and (col3 == -1) and (col4 == -1)
      # Grey scale
      @fill_color = sprintf('%.3f g', col1 / 255.0)
      @bgcolor['G'] = col1
    elsif col4 == -1
      # RGB
      @fill_color = sprintf('%.3f %.3f %.3f rg', col1 / 255.0, col2 / 255.0, col3 / 255.0)
      @bgcolor['R'] = col1
      @bgcolor['G'] = col2
      @bgcolor['B'] = col3
    else
      # CMYK
      @fill_color = sprintf('%.3f %.3f %.3f %.3f k', col1 / 100.0, col2 / 100.0, col3 / 100.0, col4 / 100.0)
      @bgcolor['C'] = col1
      @bgcolor['M'] = col2
      @bgcolor['Y'] = col3
      @bgcolor['K'] = col4
    end

    @color_flag = (@fill_color != @text_color)
    if @page > 0
      out(@fill_color)
    end
  end
  alias_method :set_fill_color, :SetFillColor

=begin
  # This hasn't been ported from tcpdf, it's a variation on SetTextColor for setting cmyk colors
  def SetCmykFillColor(c, m, y, k, storeprev=false)
    #Set color for all filling operations
    @fill_color=sprintf('%.3f %.3f %.3f %.3f k', c, m, y, k);
    @color_flag=(@fill_color!=@text_color);
    if (storeprev)
      # store color as previous value
      @prevtext_color = [c, m, y, k]
    end
    if (@page>0)
      out(@fill_color);
    end
  end
  alias_method :set_cmyk_fill_color, :SetCmykFillColor
=end
  #
  # Defines the color used for text. It can be expressed in RGB components or gray scale.
  # The method can be called before the first page is created and the value is retained from page to page.
  # [@param array or ordered hash :color] array(or ordered hash) of colors
  # [@access public]
  # [@since 3.1.000 (2008-6-11)]
  # [@see] SetFillColor()
  #
  def SetTextColorArray(color)
    unless color.nil?
      color = color.values if color.is_a? Hash
      r = !color[0].nil? ? color[0] : -1
      g = !color[1].nil? ? color[1] : -1
      b = !color[2].nil? ? color[2] : -1
      k = !color[3].nil? ? color[3] : -1
      if r >= 0
        SetTextColor(r, g, b, k)
      end
    end
  end
  alias_method :set_text_color_array, :SetTextColorArray

  #
  # Defines the color used for text. It can be expressed in RGB components or gray scale. The method can be called before the first page is created and the value is retained from page to page.
  # [@param int :col1] Gray level for single color, or Red color for RGB, or Cyan color for CMYK. Value between 0 and 255
  # [@param int :col2] Green color for RGB, or Magenta color for CMYK. Value between 0 and 255
  # [@param int :col3] Blue color for RGB, or Yellow color for CMYK. Value between 0 and 255
  # [@param int :col4] Key (Black) color for CMYK. Value between 0 and 255
  # [@access public]
  # [@since 1.3]
  # [@see] SetDrawColor(), SetFillColor(), Text(), Cell(), MultiCell()
  #
  def SetTextColor(col1=0, col2=-1, col3=-1, col4=-1)
    # set default values
    unless col1.is_a?(Numeric)
      col1 = 0
    end
    unless col2.is_a?(Numeric)
      col2 = -1
    end
    unless col3.is_a?(Numeric)
      col3 = -1
    end
    unless col4.is_a?(Numeric)
      col4 = -1
    end

    # Set color for text
    if (col2 == -1) and (col3 == -1) and (col4 == -1)
      # Grey scale
      @text_color = sprintf('%.3f g', col1 / 255.0)
      @fgcolor['G'] = col1
    elsif col4 == -1
      # RGB
      @text_color = sprintf('%.3f %.3f %.3f rg', col1 / 255.0, col2 / 255.0, col3 / 255.0)
      @fgcolor['R'] = col1
      @fgcolor['G'] = col2
      @fgcolor['B'] = col3
    else
      # CMYK
      @text_color = sprintf('%.3f %.3f %.3f %.3f k', col1 / 100.0, col2 / 100.0, col3 / 100.0, col4 / 100.0)
      @fgcolor['C'] = col1
      @fgcolor['M'] = col2
      @fgcolor['Y'] = col3
      @fgcolor['K'] = col4
    end
    @color_flag = (@fill_color != @text_color)
  end
  alias_method :set_text_color, :SetTextColor

=begin
  # This hasn't been ported from tcpdf, it's a variation on SetTextColor for setting cmyk colors
  def SetCmykTextColor(c, m, y, k, storeprev=false)
    #Set color for text
    @text_color=sprintf('%.3f %.3f %.3f %.3f k', c, m, y, k);
    @color_flag=(@fill_color!=@text_color);
    if (storeprev)
      # store color as previous value
      @prevtext_color = [c, m, y, k]
    end
  end
  alias_method :set_cmyk_text_color, :SetCmykTextColor
=end

  #
  # Returns the length of a string in user unit. A font must be selected.
  # [@param string :s] The string whose length is to be computed
  # [@param string :fontname] Family font. It can be either a name defined by AddFont() or one of the standard families. It is also possible to pass an empty string, in that case, the current family is retained.
  # [@param string :fontstyle]
  #   Font style. Possible values are (case insensitive):
  #   * empty string: regular
  #   * B: bold
  #   * I: italic
  #   * U: underline
  #   * D: line trough
  #   * O: overline
  #   or any combination. The default value is regular.
  # [@param float :fontsize] Font size in points. The default value is the current size.
  # [@param boolean :getarray] if true returns an array of characters widths, if false returns the total length.
  # [@return mixed int] total string length or array of characted widths
  # [@author] Nicola Asuni
  # [@access public]
  # [@since 1.2]
  #
  def GetStringWidth(s, fontname='', fontstyle='', fontsize=0, getarray=false)
    return GetArrStringWidth(utf8Bidi(UTF8StringToArray(s), s, rtl_text_dir), fontname, fontstyle, fontsize, getarray)
  end
  alias_method :get_string_width, :GetStringWidth

  #
  # Returns the string length of an array of chars in user unit or an array of characters widths. A font must be selected.
  # [@param string :sa] The array of chars whose total length is to be computed
  # [@param string :fontname] Family font. It can be either a name defined by AddFont() or one of the standard families. It is also possible to pass an empty string, in that case, the current family is retained.
  # [@param string :fontstyle]
  #   Font style. Possible values are (case insensitive):
  #   * empty string: regular
  #   * B: bold
  #   * I: italic
  #   * U: underline
  #   * D: line trough
  #   * O: overline
  #   or any combination. The default value is regular.
  # [@param float :fontsize] Font size in points. The default value is the current size.
  # [@param boolean :getarray] if true returns an array of characters widths, if false returns the total length.
  # [@return mixed int] total string length or array of characted widths
  # [@author] Nicola Asuni
  # [@access public]
  # [@since 2.4.000 (2008-03-06)]
  #
  def GetArrStringWidth(sa, fontname='', fontstyle='', fontsize=0, getarray=false)
    # store current values
    if !empty_string(fontname)
      prev_FontFamily = @font_family
      prev_FontStyle = @font_style
      prev_FontSizePt = @font_size_pt
      SetFont(fontname, fontstyle, fontsize)
    end
    # convert UTF-8 array to Latin1 if required
    sa = UTF8ArrToLatin1(sa)
    w = 0 # total width
    wa = [] # array of characters widths
    sa.each do |char|
      # character width
      cw = GetCharWidth(char)
      wa.push cw
      w += cw
    end
    # restore previous values
    if !empty_string(fontname)
      SetFont(prev_FontFamily, prev_FontStyle, prev_FontSizePt)
    end
    if getarray
      return wa
    end
    return w
  end
  alias_method :get_arr_string_width, :GetArrStringWidth

  #
  # Returns the length of the char in user unit for the current font.
  # [@param int :char] The char code whose length is to be returned
  # [@return int] char width
  # [@author] Nicola Asuni
  # [@access public]
  # [@since 2.4.000 (2008-03-06)]
  #
  def GetCharWidth(char)
    if char == 173
      # SHY character will not be printed
      return 0
    end
    cw = @current_font['cw']
    if !cw[char].nil?
      w = cw[char]
    elsif !@current_font['dw'].nil?
      # default width
      w = @current_font['dw']
    elsif !cw[32].nil?
      # default width
      w = cw[32]
    else
      w = 600
    end
    return (w * @font_size / 1000.0)
  end
  alias_method :get_char_width, :GetCharWidth

  #
  # Returns the numbero of characters in a string.
  # [@param string :s] The input string.
  # [@return int] number of characters
  # [@access public]
  # [@since 2.0.0001 (2008-01-07)]
  #
  def GetNumChars(s)
    if (@current_font['type'] == 'TrueTypeUnicode') or (@current_font['type'] == 'cidfont0')
      return UTF8StringToArray(s).length
    end
    return s.length
  end
  alias_method :get_num_chars, :GetNumChars

  #
  # Fill the list of available fonts (@fontlist).
  # [@access protected]
  # [@since 4.0.013 (2008-07-28)]
  #
  def getFontsList()
      Dir.glob(File.join getfontpath(), '*.rb').each {|file| @fontlist.push File.basename(file, '.rb').downcase }
  end
  protected :getFontsList

  #
  # Imports a TrueType, Type1, core, or CID0 font and makes it available.
  # It is necessary to generate a font definition file first with the makefont.rb utility.
  # The definition file (and the font file itself when embedding) must be present either in the current directory or in the one indicated by FPDF_FONTPATH if the constant is defined. If it could not be found, the error "Could not include font definition file" is generated.
  #
  # === Example
  #
  #   :pdf.add_font('Comic','I')
  #   # is equivalent to:
  #   :pdf.add_font('Comic','I','comici.rb')
  #
  # [@param string :family] Font family. The name can be chosen arbitrarily. If it is a standard family name, it will override the corresponding font.
  # [@param string :style]
  #   Font style. Possible values are (case insensitive):
  #   * empty string: regular (default)
  #   * B: bold
  #   * I: italic
  #   * BI or IB: bold italic
  # [@param string :fontfile] The font definition file. By default, the name is built from the family and style, in lower case with no space.
  # [@return array] containing the font data, or false in case of error.
  # [@param boolean :subset] if true embedd only a subset of the font (stores only the information related to the used characters); this option is valid only for TrueTypeUnicode fonts. If you want to enable users to change the document, set this parameter to false. If you subset the font, the person who receives your PDF would need to have your same font in order to make changes to your PDF. The file size of the PDF would also be smaller because you are embedding only part of a font.
  # [@access public]
  # [@since 1.5]
  # [@see] SetFont()
  #
  def AddFont(family, style='', fontfile='', subset=nil)
    if empty_string(family)
      if !empty_string(@font_family)
        family = @font_family
      else
        Error('Empty font family')
      end
    end
    subset = @font_subsetting if subset.nil?

    family = family.downcase
    if ((!@is_unicode) and (family == 'arial'))
      family = 'helvetica';
    end
    if (family == "symbol") or (family == "zapfdingbats")
      style = ''
    end

    tempstyle = style.upcase
    style = ''
    # underline
    if tempstyle.index('U') != nil
      @underline = true
    else
      @underline = false
    end
    # line-through (deleted)
    if tempstyle.index('D') != nil
      @linethrough = true
    else
      @linethrough = false
    end
    # overline
    if tempstyle.index('O') != nil
      @overline = true
    else
      @overline = false
    end
    # bold
    if tempstyle.index('B') != nil
      style << 'B';
    end
    # oblique
    if tempstyle.index('I') != nil
      style << 'I';
    end
    bistyle = style
    fontkey = family + style;
    font_style = style + (@underline ? 'U' : '') + (@linethrough ? 'D' : '') + (@overline ? 'O' : '')
    fontdata = {'fontkey' => fontkey, 'family' => family, 'style' => font_style}
    # check if the font has been already added
    if getFontBuffer(fontkey) != false
      return fontdata
    end

    # get specified font directory (if any)
    fontdir = false
    if !empty_string(fontfile)
      fontdir = File.dirname(fontfile)
      if empty_string(fontdir) or (fontdir == '.')
        fontdir = ''
      else
        fontdir << '/'
      end
    end

    fontname = family.gsub(' ', '') + style.downcase

    # search and include font file
    if empty_string(fontfile)
      # build a standard filenames for specified font
      fontfile1 = fontname + '.rb'
      fontfile2 = family.gsub(' ', '') + '.rb'
      # search files on various directories
      if (fontdir != false) and File.exist?(fontdir + fontfile1)
        fontfile = fontdir + fontfile1
        fontname = fontfile1
      elsif fontfile = getfontpath(fontfile1)
        fontname = fontfile1
      elsif File.exist?(fontfile1)
        fontfile = fontfile1
        fontname = fontfile1
      elsif (fontdir != false) and File.exist?(fontdir + fontfile2)
        fontfile = fontdir + fontfile2
        fontname = fontfile2
      elsif fontfile = getfontpath(fontfile2)
        fontname = fontfile2
      else
        fontfile = fontfile2
        fontname = fontfile2
      end
    end

    # include font file
    if File.exist?(fontfile)
      require(fontfile)
    else
      Error('Could not include font definition file: ' + family + '')
    end

    font_desc = RBPDFFontDescriptor.font(fontname).dup
    if font_desc[:desc].nil?
      desc = {}
    else
      desc = font_desc[:desc].dup
    end

    # check font parameters
    if font_desc[:type].nil? or font_desc[:cw].nil?
      Error('The font definition file has a bad format: ' + fontfile + '')
    end

    # SET default parameters
    font_desc[:file] ||= ''
    font_desc[:enc] ||= ''
    if font_desc[:cidinfo].nil?
      font_desc[:cidinfo] = {'Registry'=>'Adobe', 'Ordering'=>'Identity', 'Supplement'=>0}
      font_desc[:cidinfo]['uni2cid'] = {}
    end
    font_desc[:ctg] ||= ''
    font_desc[:up] ||= -100
    font_desc[:ut] ||= 50
    font_desc[:cw] ||= {}

    if empty_string(font_desc[:dw])
      # set default width
      if !desc['MissingWidth'].nil? and (desc['MissingWidth'] > 0)
        font_desc[:dw] = desc['MissingWidth']
      elsif font_desc[:cw][32]
        font_desc[:dw] = font_desc[:cw][32]
      else
        font_desc[:dw] = 600
      end
    end

    @numfonts += 1
    if font_desc[:type] == 'cidfont0'
      #  register CID font (all styles at once)
      styles = {'' => '', 'B' => ',Bold', 'I' => ',Italic', 'BI' => ',BoldItalic'}
      font_desc[:name] = font_desc[:name] + styles[bistyle]
      # artificial bold
      if bistyle.index('B') != nil
        if desc['StemV']
          desc['StemV'] *= 2
        else
          desc['StemV'] = 120
        end
      end
      # artificial italic
      if bistyle.index('I') != nil
        if desc['ItalicAngle']
          desc['ItalicAngle'] -= 11
        else
          desc['ItalicAngle'] = -11
        end
      end
    elsif font_desc[:type] == 'core'
      font_desc[:name] = @core_fonts[fontkey]
      subset = false
    elsif (font_desc[:type] == 'TrueType') or (font_desc[:type] == 'Type1')
      # ...
      subset = false
    elsif font_desc[:type] == 'TrueTypeUnicode'
      font_desc[:enc] = 'Identity-H'
    else
      Error('Unknow font type: ' + font_desc[:type] + '')
    end
    # initialize subsetchars to contain default ASCII values (0-255)
    subsetchars = Array.new(256, true)

    setFontBuffer(fontkey, {'fontkey' => fontkey, 'i' => @numfonts, 'type' => font_desc[:type], 'name' => font_desc[:name], 'desc' => desc, 'up' => font_desc[:up], 'ut' => font_desc[:ut], 'cw' => font_desc[:cw], 'dw' => font_desc[:dw], 'enc' => font_desc[:enc], 'cidinfo' => font_desc[:cidinfo], 'file' => font_desc[:file], 'ctg' => font_desc[:ctg], 'subset' => subset, 'subsetchars' => subsetchars})

    if (!font_desc[:diff].nil? and (!font_desc[:diff].empty?))
      #Search existing encodings
      d=0;
      nb=@diffs.length;
      1.upto(nb) do |i|
        if (@diffs[i]== font_desc[:diff])
          d = i;
          break;
        end
      end
      if (d==0)
        d = nb+1;
        @diffs[d] = font_desc[:diff];
      end
      setFontSubBuffer(fontkey, 'diff', d)
    end
    if !empty_string(font_desc[:file])
      if @font_files[font_desc[:file]].nil?
        if (font_desc[:type] == 'TrueType') or (font_desc[:type] == 'TrueTypeUnicode')
          @font_files[font_desc[:file]] = {'length1' => font_desc[:originalsize], 'fontdir' => fontdir, 'subset' => subset, 'fontkeys' => [fontkey]}
        elsif font_desc[:type] != 'core'
          @font_files[font_desc[:file]] = {'length1' => font_desc[:size1], 'length2' => font_desc[:size2], 'fontdir' => fontdir, 'subset' => subset, 'fontkeys' => [fontkey]}
        end
      else
        # update fontkeys that are sharing this font file
        @font_files[font_desc[:file]]['subset'] = (@font_files[font_desc[:file]]['subset'] and subset)
        unless @font_files[font_desc[:file]]['fontkeys'].include? fontkey
          @font_files[font_desc[:file]]['fontkeys'] ||= []
          @font_files[font_desc[:file]]['fontkeys'].push fontkey
        end
      end
    end
    return fontdata
  end
  alias_method :add_font, :AddFont

  #
  # Sets the font used to print character strings.
  # The font can be either a standard one or a font added via the AddFont() method. Standard fonts use Windows encoding cp1252 (Western Europe).
  # The method can be called before the first page is created and the font is retained from page to page.
  # If you just wish to change the current font size, it is simpler to call SetFontSize().
  # * Note: for the standard fonts, the font metric files must be accessible. There are three possibilities for this:
  #   * They are in the current directory (the one where the running script lies)
  #   * They are in one of the directories defined by the include_path parameter
  #   * They are in the directory defined by the FPDF_FONTPATH constant
  # [@param string :family]
  #   Family font. It can be either a name defined by AddFont() or one of the standard Type1 families (case insensitive):
  #   * times (Times-Roman)
  #   * timesb (Times-Bold)
  #   * timesi (Times-Italic)
  #   * timesbi (Times-BoldItalic)
  #   * helvetica (Helvetica)
  #   * helveticab (Helvetica-Bold)
  #   * helveticai (Helvetica-Oblique)
  #   * helveticabi (Helvetica-BoldOblique)
  #   * courier (Courier)
  #   * courierb (Courier-Bold)
  #   * courieri (Courier-Oblique)
  #   * courierbi (Courier-BoldOblique)
  #   * symbol (Symbol)
  #   * zapfdingbats (ZapfDingbats)
  #   It is also possible to pass an empty string. In that case, the current family is retained.
  # [@param string :style]
  #   Font style. Possible values are (case insensitive):
  #   * empty string: regular
  #   * B: bold
  #   * I: italic
  #   * U: underline
  #   * D: line trough
  #   * O: overline
  #   or any combination. The default value is regular. Bold and italic styles do not apply to Symbol and ZapfDingbats basic fonts or other fonts when not defined.
  # [@param float :size] Font size in points. The default value is the current size. If no size has been specified since the beginning of the document, the value taken is 12
  # [@param string :fontfile] The font definition file. By default, the name is built from the family and style, in lower case with no spaces.
  # [@param boolean :subset] if true embedd only a subset of the font (stores only the information related to the used characters); this option is valid only for TrueTypeUnicode fonts. If you want to enable users to change the document, set this parameter to false. If you subset the font, the person who receives your PDF would need to have your same font in order to make changes to your PDF. The file size of the PDF would also be smaller because you are embedding only part of a font.
  # [@author Nicola Asuni]
  # [@access public]
  # [@since 1.0]
  # [@see] AddFont(), SetFontSize()
  #
  def SetFont(family, style='', size=0, fontfile='', subset=nil)
    # Select a font; size given in points
    if size == 0
      size = @font_size_pt
    end
    # try to add font (if not already added)
    fontdata =  AddFont(family, style, fontfile, subset)
    @font_family = fontdata['family']
    @font_style = fontdata['style']
    @current_font = getFontBuffer(fontdata['fontkey'])
    SetFontSize(size)
  end
  alias_method :set_font, :SetFont

  #
  # Defines the size of the current font.
  # [@param float :size] The size (in points)
  # [@access public]
  # [@since 1.0]
  # [@see] SetFont()
  #
  def SetFontSize(size)
    #Set font size in points
    @font_size_pt = size;
    @font_size = size.to_f / @k;
    if !@current_font['desc'].nil? and !@current_font['desc']['Ascent'].nil? and (@current_font['desc']['Ascent'] > 0)
      @font_ascent = @current_font['desc']['Ascent'] * @font_size / 1000.0
    else
      @font_ascent = 0.85 * @font_size
    end
    if !@current_font['desc'].nil? and !@current_font['desc']['Descent'].nil? and (@current_font['desc']['Descent'] <= 0)
      @font_descent = - @current_font['desc']['Descent'] * @font_size / 1000.0
    else
      @font_descent = 0.15 * @font_size
    end
    if (@page > 0) and !@current_font['i'].nil?
      out(sprintf('BT /F%d %.2f Tf ET ', @current_font['i'], @font_size_pt));
    end
  end
  alias_method :set_font_size, :SetFontSize

  #
  # Return the font descent value
  # [@param string :font] font name
  # [@param string :style] font style
  # [@param float :size] The size (in points)
  # [@return int] font descent
  # [@access public]
  # [@since 4.9.003 (2010-03-30)]
  #
  def getFontDescent(font, style='', size=0)
    # Set font size in points
    sizek = size / @k
    fontdata = AddFont(font, style)
    font = getFontBuffer(fontdata['fontkey'])
    if font['desc'] and font['desc']['Descent'] and (font['desc']['Descent'] <= 0)
      descent = - font['desc']['Descent'] * sizek / 1000.0
    else
      descent = 0.15 * sizek
    end
    return descent
  end
  alias_method :get_font_descent, :getFontDescent

  #
  # Return the font ascent value
  # [@param string :font] font name
  # [@param string :style] font style
  # [@param float :size] The size (in points)
  # [@return int] font ascent
  # [@access public]
  # [@since 4.9.003 (2010-03-30)]
  #
  def getFontAscent(font, style='', size=0)
    # Set font size in points
    sizek = size / @k
    fontdata = AddFont(font, style)
    font = getFontBuffer(fontdata['fontkey'])
    if font['desc'] and font['desc']['Ascent'] and (font['desc']['Ascent'] > 0)
      ascent = font['desc']['Ascent'] * sizek / 1000.0
    else
      ascent = 0.85 * sizek
    end
    return ascent
  end
  alias_method :get_font_ascent, :getFontAscent

  #
  # Defines the default monospaced font.
  # [@param string :font] Font name.
  # [@access public]
  # [@since 4.5.025]
  #
  def SetDefaultMonospacedFont(font)
    @default_monospaced_font = font
  end
  alias_method :set_default_monospaced_font, :SetDefaultMonospacedFont

  #
  # Creates a new internal link and returns its identifier. An internal link is a clickable area which directs to another place within the document.
  # The identifier can then be passed to Cell(), Write(), Image() or Link(). The destination is defined with SetLink().
  # [@access public]
  # [@since 1.5]
  # [@see] Cell(), Write(), Image(), Link(), SetLink()
  #
  def AddLink()
    #Create a new internal link
    n = @links.length + 1
    @links[n]=[0,0];
    return n;
  end
  alias_method :add_link, :AddLink

  #
  # Defines the page and position a link points to
  # [@param int :link] The link identifier returned by AddLink()
  # [@param float :y] Ordinate of target position; -1 indicates the current position. The default value is 0 (top of page)
  # [@param int :page] Number of target page; -1 indicates the current page. This is the default value
  # [@since 1.5]
  # [@see] AddLink()
  #
  def SetLink(link, y=0, page=-1)
    #Set destination of internal link
    if (y==-1)
      y=@y;
    end
    if (page==-1)
      page=@page;
    end
    @links[link] = [page, y]
  end
  alias_method :set_link, :SetLink

  #
  # Puts a link on a rectangular area of the page.
  # Text or image links are generally put via Cell(), Write() or Image(), but this method can be useful for instance to define a clickable area inside an image.
  # [@param float :x] Abscissa of the upper-left corner of the rectangle
  # [@param float :y] Ordinate of the upper-left corner of the rectangle
  # [@param float :w] Width of the rectangle
  # [@param float :h] Height of the rectangle
  # [@param mixed :link] URL or identifier returned by AddLink()
  # [@param int :spaces] number of spaces on the text to link
  # [@access public]
  # [@since 1.5]
  # [@see] AddLink(), Annotation(), Cell(), Write(), Image()
  #
  def Link(x, y, w, h, link, spaces=0)
    Annotation(x, y, w, h, link, {'Subtype'=>'Link'}, spaces)
  end
  alias_method :link, :Link

  #
  # Puts a markup annotation on a rectangular area of the page.
  # * !!!!THE ANNOTATION SUPPORT IS NOT YET FULLY IMPLEMENTED !!!!
  # [@param float :x] Abscissa of the upper-left corner of the rectangle
  # [@param float :y] Ordinate of the upper-left corner of the rectangle
  # [@param float :w] Width of the rectangle
  # [@param float :h] Height of the rectangle
  # [@param mixed :text] annotation text or alternate content
  # [@param array :opt] array of options (see section 8.4 of PDF reference 1.7).
  # [@param int :spaces] number of spaces on the text to link
  # [@access public]
  # [@since 4.0.018 (2008-08-06)]
  #
  def Annotation(x, y, w, h, text, opt={'Subtype'=>'Text'}, spaces=0)
    x = @x if x == ''
    y = @y if y == ''

    # recalculate coordinates to account for graphic transformations
    if !@transfmatrix.nil?
      @transfmatrix_key.downto(1) do |i|
        maxid = @transfmatrix[i].length - 1
        maxid.downto(0) do |j|
          ctm = @transfmatrix[i][j]
          if !ctm['a'].nil?
            x = x * @k
            y = (@h - y) * @k
            w = w * @k
            h = h * @k
            # top left
            xt = x
            yt = y
            x1 = (ctm['a'] * xt) + (ctm['c'] * yt) + ctm['e']
            y1 = (ctm['b'] * xt) + (ctm['d'] * yt) + ctm['f']
            # top right
            xt = x + w
            yt = y
            x2 = (ctm['a'] * xt) + (ctm['c'] * yt) + ctm['e']
            y2 = (ctm['b'] * xt) + (ctm['d'] * yt) + ctm['f']
            # bottom left
            xt = x
            yt = y - h
            x3 = (ctm['a'] * xt) + (ctm['c'] * yt) + ctm['e']
            y3 = (ctm['b'] * xt) + (ctm['d'] * yt) + ctm['f']
            # bottom right
            xt = x + w
            yt = y - h
            x4 = (ctm['a'] * xt) + (ctm['c'] * yt) + ctm['e']
            y4 = (ctm['b'] * xt) + (ctm['d'] * yt) + ctm['f']
            # new coordinates (rectangle area)
            x = [x1, x2, x3, x4].min
            y = [y1, y2, y3, y4].max
            w = ([x1, x2, x3, x4].max - x) / @k
            h = (y - [y1, y2, y3, y4].min) / @k
            x = x / @k
            y = @h - (y / @k)
          end
        end
      end
    end
    if @page <= 0
      page = 1
    else
      page = @page
    end
    @page_annots[page] ||= []
    @page_annots[page].push 'x' => x, 'y' => y, 'w' => w, 'h' => h, 'txt' => text, 'opt' => opt, 'numspaces' => spaces
    if ((opt['Subtype'] == 'FileAttachment') or (opt['Subtype'] == 'Sound')) and !empty_string(opt['FS']) and File.exist?(opt['FS']) and @embeddedfiles[File.basename(opt['FS'])].nil?
      @embeddedfiles[File.basename(opt['FS'])] = {'file' => opt['FS'], 'n' => (@embeddedfiles.length + @embedded_start_obj_id)}
    end
    # Add widgets annotation's icons
    if opt['mk'] and opt['mk']['i'] and File.exist?(opt['mk']['i'])
      Image(opt['mk']['i'], '', '', 10, 10, '', '', '', false, 300, '', false, false, 0, false, true)
    end
    if opt['mk'] and opt['mk']['ri'] and File.exist?(opt['mk']['ri'])
      Image(opt['mk']['ri'], '', '', 0, 0, '', '', '', false, 300, '', false, false, 0, false, true)
    end
    if opt['mk'] and opt['mk']['ix'] and File.exist?(opt['mk']['ix'])
      Image(opt['mk']['ix'], '', '', 0, 0, '', '', '', false, 300, '', false, false, 0, false, true)
    end
    @annot_obj_id += 1
  end
  alias_method :annotation, :Annotation

  #
  # Embedd the attached files.
  # [@since 4.4.000 (2008-12-07)]
  # [@access protected]
  # [@see] Annotation()
  #
  def putEmbeddedFiles()
    # reset(@embeddedfiles)
    @embeddedfiles.each { |filename, filedata|
      data = ''
      open(filedata['file'],'rb') do |f|
        data = f.read()
      end
      filter = ''
      if @compress
        data = Zlib::Deflate.deflate(data)
        filter = ' /Filter /FlateDecode'
      end
      @offsets[filedata['n']] = @bufferlen
      out = filedata['n'].to_s + ' 0 obj'
      out << '<</Type /EmbeddedFile' + filter + ' /Length ' + data.length.to_s + ' >>'
      out << ' ' + getstream(data, filedata['n'])
      out << ' endobj'
      out(out)
    }
  end
  protected :putEmbeddedFiles

  #
  # Prints a text cell at the specified position.
  # The origin is on the left of the first charcter, on the baseline.
  # This method allows to place a string precisely on the page.
  # [@param float :x] Abscissa of the cell origin
  # [@param float :y] Ordinate of the cell origin
  # [@param string :txt] String to print
  # [@param int :fstroke] outline size in user units (false = disable)
  # [@param boolean :fclip] if true activate clipping mode (you must call StartTransform() before this function and StopTransform() to stop the clipping tranformation).
  # [@param boolean :ffill] if true fills the text
  # [@param mixed :border]
  #   Indicates if borders must be drawn around the cell. The value can be either a number:
  #   * 0: no border (default)
  #   * 1: frame
  #   or a string containing some or all of the following characters (in any order):
  #   * L: left
  #   * T: top
  #   * R: right
  #   * B: bottom
  # [@param int :ln]
  #   Indicates where the current position should go after the call. Possible values are:
  #   * 0: to the right (or left for RTL languages)
  #   * 1: to the beginning of the next line
  #   * 2: below
  #   Putting 1 is equivalent to putting 0 and calling Ln() just after. Default value: 0.
  # [@param string :align]
  #   Allows to center or align the text. Possible values are:
  #   * L or empty string: left align (default value)
  #   * C: center
  #   * R: right align
  #   * J: justify
  # [@param int :fill] Indicates if the cell background must be painted (1) or transparent (0). Default value: 0.
  # [@param mixed :link] URL or identifier returned by AddLink().
  # [@param int :stretch]
  #   stretch carachter mode:
  #   * 0 = disabled
  #   * 1 = horizontal scaling only if necessary
  #   * 2 = forced horizontal scaling
  #   * 3 = character spacing only if necessary
  #   * 4 = forced character spacing
  # [@param boolean :ignore_min_height] if true ignore automatic minimum height value.
  # [@param string :calign]
  #   cell vertical alignment relative to the specified Y value. Possible values are:
  #   * T : cell top
  #   * A : font top
  #   * L : font baseline
  #   * D : font bottom
  #   * B : cell bottom
  # [@param string :valign]
  #   text vertical alignment inside the cell. Possible values are:
  #   * T : top
  #   * C : center
  #   * B : bottom
  # [@param boolean :rtloff] if true uses the page top-left corner as origin of axis for :x and :y initial position.
  # [@access public]
  # [@since 1.0]
  # [@see] SetFont(), SetTextColor(), Cell(), MultiCell(), Write()
  #
  def Text(x, y, txt, fstroke=false, fclip=false, ffill=true, border=0, ln=0, align='', fill=0, link='', stretch=0, ignore_min_height=false, calign='T', valign='M', rtloff=false)
    fstroke = 0 if fstroke == false

    textrendermode = @textrendermode
    textstrokewidth = @textstrokewidth
    setTextRenderingMode(fstroke, ffill, fclip)
    SetXY(x, y, rtloff)
    Cell(0, 0, txt, border, ln, align, fill, link, stretch, ignore_min_height, calign, valign)
    # restore previous rendering mode
    @textrendermode = textrendermode
    @textstrokewidth = textstrokewidth
  end
  alias_method :text, :Text

  #
  # Whenever a page break condition is met, the method is called, and the break is issued or not depending on the returned value.
  # The default implementation returns a value according to the mode selected by SetAutoPageBreak().
  # This method is called automatically and should not be called directly by the application.
  # [@return boolean]
  # [@access public]
  # [@since 1.4]
  # [@see] SetAutoPageBreak()
  #
  def AcceptPageBreak()
    #if @num_columns > 1
    #  # multi column mode
    #  if @current_column < (@num_columns - 1)
    #    # go to next column
    #    selectColumn(@current_column + 1)
    #  else
    #    # add a new page
    #    AddPage()
    #    # set first column
    #    selectColumn(0)
    #  end
    #  # avoid page breaking from checkPageBreak()
    #  return false
    #end
    return @auto_page_break;
  end
  alias_method :accept_page_break, :AcceptPageBreak

  #
  # Add page if needed.
  # [@param float :h] Cell height. Default value: 0.
  # [@param mixed :y] starting y position, leave empty for current position.
  # [@param boolean :addpage] if true add a page, otherwise only return the true/false state
  # [@return boolean] true in case of page break, false otherwise.
  # [@since 3.2.000 (2008-07-01)]
  # [@access protected]
  #
  def checkPageBreak(h=0, y='', addpage=true)
    if empty_string(y)
      y = @y
    end
    current_page = @page
    if (y + h > @page_break_trigger) and !@in_footer and AcceptPageBreak()
      if addpage
        # Automatic page break
        x = @x
        AddPage(@cur_orientation)
        @y = @t_margin
        oldpage = @page - 1
        if @rtl
          if @pagedim[@page]['orm'] != @pagedim[oldpage]['orm']
            @x = x - (@pagedim[@page]['orm'] - @pagedim[oldpage]['orm'])
          else
            @x = x
          end
        else
          if @pagedim[@page]['olm'] != @pagedim[oldpage]['olm']
            @x = x + (@pagedim[@page]['olm'] - @pagedim[oldpage]['olm'])
          else
            @x = x
          end
        end
      end
      @newline = true
      return true
    end
    if current_page != @page
      # account for columns mode
      @newline = true
      return true
    end
    return false
  end
  protected :checkPageBreak

  def BreakThePage?(h)
    warn "[DEPRECATION] 'BreakThePage/break_the_page' is deprecated. Please don't Use."
    if ((@y + h) > @page_break_trigger and !@in_footer and AcceptPageBreak())
      true
    else
      false
    end
  end
  alias_method :break_the_page?, :BreakThePage?

  #
  # Removes SHY characters from text.
  # Unicode Data:
  #   * Name : SOFT HYPHEN, commonly abbreviated as SHY
  #   * HTML Entity (decimal): &#173;
  #   * HTML Entity (hex): &#xad;
  #   * HTML Entity (named): &shy;
  #   * How to type in Microsoft Windows: [Alt +00AD] or [Alt 0173]
  #   * UTF-8 (hex): 0xC2 0xAD (c2ad)
  #   * UTF-8 character: chr(194).chr(173)
  # [@param string :txt] input string
  # [@return string] without SHY characters.
  # [@access public]
  # [@since (4.5.019) 2009-02-28]
  #
  def removeSHY(txt='')
    txt = txt.dup
    txt.force_encoding('ASCII-8BIT') if txt.respond_to?(:force_encoding)
    txt.gsub!(/([\xc2]{1}[\xad]{1})/, '')
    if !@is_unicode
      txt.gsub!(/([\xad]{1})/, '')
      return txt
    end
    txt.force_encoding('UTF-8') if txt.respond_to?(:force_encoding)
    return txt
  end
  alias_method :remove_shy, :removeSHY

  #
  # Prints a cell (rectangular area) with optional borders, background color and character string. The upper-left corner of the cell corresponds to the current position. The text can be aligned or centered. After the call, the current position moves to the right or to the next line. It is possible to put a link on the text.
  # If automatic page breaking is enabled and the cell goes beyond the limit, a page break is done before outputting.
  # [@param float :w] Cell width. If 0, the cell extends up to the right margin.
  # [@param float :h] Cell height. Default value: 0.
  # [@param string :txt] String to print. Default value: empty string.
  # [@param mixed :border]
  #   Indicates if borders must be drawn around the cell. The value can be either a number:
  #   * 0: no border (default)
  #   * 1: frame
  #   or a string containing some or all of the following characters (in any order):
  #   * L: left
  #   * T: top
  #   * R: right
  #   * B: bottom
  # [@param int :ln]
  #   Indicates where the current position should go after the call. Possible values are:
  #   * 0: to the right
  #   * 1: to the beginning of the next line
  #   * 2: below
  #   Putting 1 is equivalent to putting 0 and calling Ln() just after. Default value: 0.
  # [@param string :align]
  #   Allows to center or align the text. Possible values are:
  #   * L or empty string: left align (default value)
  #   * C: center
  #   * R: right align
  # [@param int :fill] Indicates if the cell background must be painted (1) or transparent (0). Default value: 0.
  # [@param mixed :link] URL or identifier returned by AddLink().
  # [@param int :stretch]
  #   stretch carachter mode:
  #   * 0 = disabled
  #   * 1 = horizontal scaling only if necessary
  #   * 2 = forced horizontal scaling
  #   * 3 = character spacing only if necessary
  #   * 4 = forced character spacing
  # [@param boolean :ignore_min_height] if true ignore automatic minimum height value.
  # [@param string :calign]
  #   cell vertical alignment relative to the specified Y value. Possible values are:
  #   * T : cell top
  #   * C : center
  #   * B : cell bottom
  #   * A : font top
  #   * L : font baseline
  #   * D : font bottom
  # [@param string :valign]
  #   text vertical alignment inside the cell. Possible values are:
  #   * T : top
  #   * M : middle
  #   * B : bottom
  # [@access public]
  # [@since 1.0]
  # [@see] SetFont(), SetDrawColor(), SetFillColor(), SetTextColor(), SetLineWidth(), AddLink(), Ln(), MultiCell(), Write(), SetAutoPageBreak()
  #
  def Cell(w, h=0, txt='', border=0, ln=0, align='', fill=0, link=nil, stretch=0, ignore_min_height=false, calign='T', valign='M')
    if !ignore_min_height
      min_cell_height = @font_size * @cell_height_ratio
      if h < min_cell_height
        h = min_cell_height
      end
    end
    checkPageBreak(h)
    out(getCellCode(w, h, txt, border, ln, align, fill, link, stretch, ignore_min_height, calign, valign))
  rescue => err
    Error('Cell Error.', err)
  end
  alias_method :cell, :Cell

  #
  # Returns the PDF string code to print a cell (rectangular area) with optional borders, background color and character string. The upper-left corner of the cell corresponds to the current position. The text can be aligned or centered. After the call, the current position moves to the right or to the next line. It is possible to put a link on the text.
  # If automatic page breaking is enabled and the cell goes beyond the limit, a page break is done before outputting.
  # [@param float :w] Cell width. If 0, the cell extends up to the right margin.
  # [@param float :h] Cell height. Default value: 0.
  # [@param string :txt] String to print. Default value: empty string.
  # [@param mixed :border]
  #   Indicates if borders must be drawn around the cell. The value can be either a number:
  #   * 0: no border (default)
  #   * 1: frame
  #   or a string containing some or all of the following characters (in any order):
  #   * L: left
  #   * T: top
  #   * R: right
  #   * B: bottom
  # [@param int :ln]
  #   Indicates where the current position should go after the call. Possible values are:
  #   * 0: to the right (or left for RTL languages)
  #   * 1: to the beginning of the next line
  #   * 2: below
  #   Putting 1 is equivalent to putting 0 and calling Ln() just after. Default value: 0.
  # [@param string :align]
  #   Allows to center or align the text. Possible values are:
  #   * L or empty string: left align (default value)
  #   * C: center
  #   * R: right align
  #   * J: justify
  # [@param int :fill] Indicates if the cell background must be painted (1) or transparent (0). Default value: 0.
  # [@param mixed :link] URL or identifier returned by AddLink().
  # [@param int :stretch]
  #   stretch carachter mode:
  #   * 0 = disabled
  #   * 1 = horizontal scaling only if necessary
  #   * 2 = forced horizontal scaling
  #   * 3 = character spacing only if necessary
  #   * 4 = forced character spacing
  # [@param boolean :ignore_min_height] if true ignore automatic minimum height value.
  # [@param string :calign]
  #   cell vertical alignment relative to the specified Y value. Possible values are:
  #   * T : cell top
  #   * C : center
  #   * B : cell bottom
  #   * A : font top
  #   * L : font baseline
  #   * D : font bottom
  # [@param string :valign]
  #   text vertical alignment inside the cell. Possible values are:
  #   * T : top
  #   * M : middle
  #   * B : bottom
  # [@access protected]
  # [@since 1.0]
  # [@see] Cell()
  #
  def getCellCode(w, h=0, txt='', border=0, ln=0, align='', fill=0, link=nil, stretch=0, ignore_min_height=false, calign='T', valign='M')
    txt = '' if txt.nil?
    rs = "" # string to be returned
    txt = removeSHY(txt)
    if !ignore_min_height
      min_cell_height = @font_size * @cell_height_ratio
      if h < min_cell_height
        h = min_cell_height
      end
    end
    k = @k
    x = @x
    y = @y
    # cell vertical alignment
    case calign
    when 'A'
      # font top
      case valign
      when 'T'
        # top
        y -= @line_width / 2.0
      when 'B'
        # bottom
        y -= (h - @font_ascent - @font_descent - @line_width / 2.0)
      else # 'M'
        # center
        y -= (h - @font_ascent - @font_descent) / 2.0
      end
    when 'L'
      # font baseline
      case valign
      when 'T'
        # top
        y -= (@font_ascent + @line_width / 2.0)
      when 'B'
        # bottom
        y -= (h - @font_descent - @line_width / 2.0)
      else # 'M'
        # center
        y -= (h + @font_ascent - @font_descent) / 2.0
      end
    when 'D'
      # font bottom
      case valign
      when 'T'
        # top
        y -= (@font_ascent + @font_descent + @line_width / 2.0)
      when 'B'
        # bottom
        y -= (h - @line_width / 2.0)
      else # 'M'
        # center
        y -= (h + @font_ascent + @font_descent) / 2.0
      end
    when 'B'
      # cell bottom
      y -= h
    when 'C'
      # cell center
      y -= h / 2.0
    else # 'T'
      # cell top
    end

    # text vertical alignment
    case valign
    when 'T'
      # top
      basefonty = y + @font_ascent + @line_width / 2.0
    when 'B'
      # bottom
      basefonty = y + h - @font_descent - @line_width / 2.0
    else # 'M'
      # center
      basefonty = y + (h + @font_ascent - @font_descent) / 2.0
    end

    if empty_string(w) or (w <= 0)
      if @rtl
        w = x - @l_margin
      else
        w = @w - @r_margin - x
      end
    end
    s = '';
    # fill and borders
    if (fill == 1) or (border.to_i == 1)
      if (fill == 1)
        op = (border.to_i == 1) ? 'B' : 'f';
      else
        op = 'S';
      end

      if @rtl
        xk = (@x - w) * k
      else
        xk = @x * k
      end
      s << sprintf('%.2f %.2f %.2f %.2f re %s ', xk, (@h - y) * k, w * k, -h * k, op)
    end
    if (border.is_a?(String))
      lm = @line_width / 2.0
      if (border.include?('L'))
        if @rtl
          xk = (x - w) * k
        else
          xk = x * k
        end
        s << sprintf('%.2f %.2f m %.2f %.2f l S ', xk, (@h - y + lm) * k, xk, (@h - (y + h + lm)) * k)
      end
      if (border.include?('T'))
        if @rtl
          xk = (x - w + lm) * k
          xwk = (x - lm) * k
        else
          xk = (x - lm) * k
          xwk = (x + w + lm) * k
        end
        s << sprintf('%.2f %.2f m %.2f %.2f l S ', xk,(@h-y)*k,xwk,(@h-y)*k)
      end
      if (border.include?('R'))
        if @rtl
          xk = x * k
        else
          xk = (x + w) * k
        end
        s << sprintf('%.2f %.2f m %.2f %.2f l S ', xk, (@h - y + lm) * k, xk, (@h - (y + h + lm)) * k)
      end
      if (border.include?('B'))
        if @rtl
          xk = (x - w + lm) * k
          xwk = (x - lm) * k
        else
          xk = (x - lm) * k
          xwk = (x + w + lm) * k
        end
        s << sprintf('%.2f %.2f m %.2f %.2f l S ', xk,(@h-(y+h))*k,xwk,(@h-(y+h))*k)
      end
    end
    if (txt != '')
      txt2 = txt
      if @is_unicode
        if (@current_font['type'] == 'core') or (@current_font['type'] == 'TrueType') or (@current_font['type'] == 'Type1')
          txt2 = UTF8ToLatin1(txt2)
        else
          unicode = UTF8StringToArray(txt) # array of UTF-8 unicode values
          unicode = utf8Bidi(unicode, '', rtl_text_dir)
          if @@k_thai_topchars and @@k_thai_topchars == true
            # ---- Fix for bug #2977340 "Incorrect Thai characters position arrangement" ----
            # NOTE: this doesn't work with HTML justification
            # Symbols that could overlap on the font top (only works in LTR)
            topchar = [3611, 3613, 3615, 3650, 3651, 3652] # chars that extends on top
            topsym = [3633, 3636, 3637, 3638, 3639, 3655, 3656, 3657, 3658, 3659, 3660, 3661, 3662] # symbols with top positi
            numchars = unicode.length # number of chars
            unik = 0;
            uniblock = []
            uniblock[unik] = []
            uniblock[unik].push unicode[0]
            # resolve overlapping conflicts by splitting the string in several parts
            1.upto(numchars - 1) do |i|
              # check if symbols overlaps at top
              if topsym.include?(unicode[i]) and (topsym.include?(unicode[i - 1]) or topchar.inclue?(unicode[i - 1]))
                # move symbols to another array
                unik += 1
                uniblock[unik] = []
                uniblock[unik].push unicode[i]
                unik += 1
                uniblock[unik] = []
                unicode[i] = 8203 # Unicode Character 'ZERO WIDTH SPACE' (U+200B)
              else
                uniblock[unik].push unicode[i]
              end
            end
            # ---- END OF Fix for bug #2977340
          end
          txt2 = arrUTF8ToUTF16BE(unicode, false)
        end
      end
      txt2 = escape(txt2)
      # text length
      width = txwidth = GetStringWidth(txt)
      # ratio between cell length and text length
      if width <= 0
        ratio = 1
      else
        ratio = (w - (2 * @c_margin)) / width
      end
      # stretch text if required
      if (stretch > 0) and ((ratio < 1) or ((ratio > 1) and ((stretch % 2) == 0)))
        if stretch > 2
          # spacing
          # Calculate character spacing in points
          txt_length =  GetNumChars(txt) - 1
          char_space = ((w - width - (2 * @c_margin)) * @k) / (txt_length > 1 ? txt_length : 1)
          # Set character spacing
          rs << sprintf('BT %.2f Tc ET ', char_space)
        else
          # scaling
          # Calculate horizontal scaling
          horiz_scale = ratio * 100.0
          # Set horizontal scaling
          rs << sprintf('BT %.2f Tz ET ', horiz_scale)
        end
        align = ''
        width = w - (2 * @c_margin)
      else
        stretch == 0
      end

      if (@color_flag)
        s << 'q ' + @text_color + ' ';
      end
      # rendering mode
      # s << sprintf('BT %d Tr %.2f w ET ', @textrendermode, @textstrokewidth)
      opt = sprintf('%d Tr %.2f w ', @textrendermode, @textstrokewidth) # fix for compatibility
      # count number of spaces
      ns = txt.count(' ')
      # Justification
      spacewidth = 0
      if (align == 'J') and (ns > 0)
        if (@current_font['type'] == "TrueTypeUnicode") or (@current_font['type'] == "cidfont0")
          # get string width without spaces
          width = GetStringWidth(txt.gsub(' ', ''))
          # calculate average space width
          spacewidth = -1000 * (w - width - (2 * @c_margin)) / (ns ? ns : 1) / @font_size
          # set word position to be used with TJ operator
          txt2 = txt2.gsub(0.chr + 32.chr, ') ' + sprintf('%.3f', spacewidth) + ' (')
          unicode_justification = true
        else
          # get string width
          width = txwidth
          spacewidth = ((w - width - (2 * @c_margin)) / (ns ? ns : 1)) * @k
          # set word spacing
          rs << sprintf('BT %.3f Tw ET ', spacewidth)
        end
        width = w - (2 * @c_margin)
      end
      # replace carriage return characters
      txt2 = txt2.gsub("\r", ' ')
      case align
      when 'C'
        dx = (w - width) / 2.0
      when 'R'
        if @rtl
          dx = @c_margin
        else
          dx = w - width - @c_margin
        end
      when 'L'
        if @rtl
          dx = w - width - @c_margin
        else
          dx = @c_margin
        end
      else # 'J'
        dx = @c_margin
      end

      if @rtl
        xdx = @x - dx - width
      else
        xdx = @x + dx
      end
      xdk = xdx * k

      # print text
      # s << sprintf('BT %.2f %.2f Td [(%s)] TJ ET', xdk, (@h - basefonty) * k, txt2)
      s << sprintf('BT %.2f %.2f Td %s[(%s)] TJ ET', xdk, (@h - basefonty) * k, opt, txt2) # fix for compatibility

      if !uniblock.nil?
        # print overlapping characters as separate string
        xshift = 0 # horizontal shift
        ty = (@h - basefonty + (0.2 * @font_size)) * k
        spw = (w - txwidth - (2 * @c_margin)) / (ns ? ns : 1)
        uniblock.each_with_index {|uniarr, uk|
          if (uk % 2) == 0
            # x space to skip
            if spacewidth != 0
              # justification shift
              xshift += uniarr.select {|item| item == 32 }.length * spw
            end
            xshift += GetArrStringWidth(uniarr) # + shift justification
          else
            # character to print
            topchr = arrUTF8ToUTF16BE(uniarr, false)
            topchr = escape(topchr)
            s << sprintf(' BT %.2f %.2f Td [(%s)] TJ ET', xdk + (xshift * k), ty, topchr)
          end
        }
      end
      if @underline
        s << ' ' + dounderlinew(xdx, basefonty, width)
      end
      if @linethrough
        s << ' ' + dolinethroughw(xdx, basefonty, width)
      end
      if @overline
        s << ' ' + dooverlinew(xdx, basefonty, width)
      end
      if (@color_flag)
        s<<' Q';
      end
      if link && ((link.is_a?(String) and !link.empty?) or (link.is_a?(Integer) and link != 0)) # Integer is PDF file Page No.
        Link(xdx, y + ((h - @font_size) / 2.0), width, @font_size, link, ns)
      end
    end

    # output cell
    if (s)
      # output cell
      rs << s
      # reset text stretching
      if stretch > 2
        # Reset character horizontal spacing
        rs << ' BT 0 Tc ET'
      elsif stretch > 0
        # Reset character horizontal scaling
        rs << ' BT 100 Tz ET'
      end
    end

    # reset word spacing
    if !((@current_font['type'] == 'TrueTypeUnicode') or (@current_font['type'] == 'cidfont0')) and (align == 'J')
      rs << ' BT 0 Tw ET'
    end

    @lasth = h;

    if (ln.to_i>0)
      # Go to the beginning of the next line
      @y = y + h
      if (ln == 1)
        if @rtl
          @x = @w - @r_margin
        else
          @x = @l_margin
        end
      end
    else
      # go left or right by case
      if @rtl
        @x -= w
      else
        @x += w
      end
    end
    gstyles = '' + @linestyle_width + ' ' + @linestyle_cap + ' ' + @linestyle_join + ' ' + @linestyle_dash + ' ' + @draw_color + ' ' + @fill_color + "\n"
    rs = gstyles + rs
    return rs
  end
  protected :getCellCode

  #
  # This method allows printing text with line breaks.
  # They can be automatic (as soon as the text reaches the right border of the cell) or explicit (via the \n character). As many cells as necessary are output, one below the other.
  # Text can be aligned, centered or justified. The cell block can be framed and the background painted.
  #
  # [@param float :w] Width of cells. If 0, they extend up to the right margin of the page.
  # [@param float :h] Cell minimum height. The cell extends automatically if needed.
  # [@param string :txt] String to print
  # [@param mixed :border]
  #   Indicates if borders must be drawn around the cell block. The value can be either a number:
  #   * 0: no border (default)
  #   * 1: frame
  #   or a string containing some or all of the following characters (in any order):
  #   * L: left
  #   * T: top
  #   * R: right
  #   * B: bottom
  # [@param string :align]
  #   Allows to center or align the text. Possible values are:
  #   * L or empty string: left align
  #   * C: center
  #   * R: right align
  #   * J: justification (default value when :ishtml=false)
  # [@param int :fill] Indicates if the cell background must be painted (1) or transparent (0). Default value: 0.
  # [@param int :ln]
  #   Indicates where the current position should go after the call. Possible values are:
  #   * 0: to the right
  #   * 1: to the beginning of the next line [DEFAULT]
  #   * 2: below
  # [@param float :x] x position in user units
  # [@param float :y] y position in user units
  # [@param boolean :reseth] if true reset the last cell height (default true).
  # [@param int :stretch]
  #   stretch carachter mode:
  #   * 0 = disabled
  #   * 1 = horizontal scaling only if necessary
  #   * 2 = forced horizontal scaling
  #   * 3 = character spacing only if necessary
  #   * 4 = forced character spacing
  # [@param boolean :ishtml] set to true if :txt is HTML content (default = false).
  # [@param boolean :autopadding] if true, uses internal padding and automatically adjust it to account for line width.
  # [@param float :maxh] maximum height. It should be >= :h and less then remaining space to the bottom of the page, or 0 for disable this feature. This feature works only when :ishtml=false.
  # [@return int] Rerurn the number of cells or 1 for html mode.
  # [@access public]
  # [@since 1.3]
  # [@see]
  #   SetFont(), SetDrawColor(), SetFillColor(), SetTextColor(), SetLineWidth(), Cell(), Write(), SetAutoPageBreak()
  #
  def MultiCell(w, h, txt, border=0, align='J', fill=0, ln=1, x='', y='', reseth=true, stretch=0, ishtml=false, autopadding=true, maxh=0)

    @x ||= 0

    w = 0 unless w.is_a?(Numeric)
    h = 0 unless h.is_a?(Numeric)

    if empty_string(@lasth) or reseth
      # set row height
      @lasth = @font_size * @cell_height_ratio
    end

    if !empty_string(y)
      SetY(y)
    else
      y = GetY()
    end
    resth = 0
    if !@in_footer and (y + h > @page_break_trigger)
      # spit cell in two pages
      newh = @page_break_trigger - y
      resth = h - newh # cell to be printed on the next page
      h = newh
    end
    # get current page number
    startpage = @page

    if !empty_string(x)
      SetX(x)
    else
      x = GetX()
    end

    if empty_string(w) or (w <= 0)
      if @rtl
        w = @x - @l_margin
      else
        w = @w - @r_margin - @x
      end
    end

    # store original margin values
    l_margin = @l_margin
    r_margin = @r_margin

    if @rtl
      SetRightMargin(@w - @x)
      SetLeftMargin(@x - w)
    else
      SetLeftMargin(@x)
      SetRightMargin(@w - @x - w)
    end

    starty = @y
    if autopadding
      # Adjust internal padding
      if @c_margin < (@line_width / 2.0)
        @c_margin = @line_width / 2.0
      end
      # Add top space if needed
      if (@lasth - @font_size) < @line_width
        @y += @line_width / 2.0
      end
      # add top padding
      @y += @c_margin
    end

    if ishtml
      # ******* Write HTML text
      writeHTML(txt, true, false, reseth, true, align)
      nl = 1
    else
      # ******* Write text
      nl = Write(@lasth, txt, '', 0, align, true, stretch, false, true, maxh)
    end

    if autopadding
      # add bottom padding
      @y += @c_margin
      # Add bottom space if needed
      if (@lasth - @font_size) < @line_width
        @y += @line_width / 2.0
      end
    end

    # Get end-of-text Y position
    currentY = @y
    # get latest page number
    end_page = @page
    if resth > 0
      skip = end_page - startpage
      tmpresth = resth
      while tmpresth > 0
        if skip <= 0
          # add a page (or trig AcceptPageBreak() for multicolumn mode)
          checkPageBreak(@page_break_trigger + 1)
        end
        tmpresth -= (@h - @t_margin - @b_margin)
        skip -= 1
      end
      currentY = @y
      end_page = @page
    end

    # check if a new page has been created
    if end_page > startpage
      # design borders around HTML cells.
      for page in startpage..end_page
        setPage(page)
        if page == startpage
          # first page
          @y = starty # put cursor at the beginning of cell on the first page
          h = @h - starty - @b_margin
          cborder = getBorderMode(border, position='start')
        elsif page == end_page
          # last page
          @y = @t_margin # put cursor at the beginning of last page
          h = currentY - @t_margin
          if resth > h
            h = resth
          end
          cborder = getBorderMode(border, position='end')
        else
          @y = @t_margin # put cursor at the beginning of the current page
          h = @h - @t_margin - @b_margin
          resth -= h
          cborder = getBorderMode(border, position='middle')
        end
        nx = x
        # account for margin changes
        if page > startpage
          if @rtl and (@pagedim[page]['orm'] != @pagedim[startpage]['orm'])
            nx = x + (@pagedim[page]['orm'] - @pagedim[startpage]['orm'])
          elsif !@rtl and (@pagedim[page]['olm'] != @pagedim[startpage]['olm'])
            nx = x + (@pagedim[page]['olm'] - @pagedim[startpage]['olm'])
          end
        end
        SetX(nx)

        prevLastH = @lasth
        ccode = getCellCode(w, h, '', cborder, 1, '', fill, '', 0, false)
        @lasth = prevLastH

        if (cborder != 0) or (fill == 1)
          pagebuff = getPageBuffer(@page)
          pstart = pagebuff[0, @intmrk[@page]]
          pend = pagebuff[@intmrk[@page]..-1]
          setPageBuffer(@page, pstart + ccode + "\n" + pend)
          @intmrk[@page] += (ccode + "\n").length
        end
      end
    else
      h = [h, currentY - y].max
      # put cursor at the beginning of text
      SetY(y)
      SetX(x)

      prevLastH = @lasth
      # design a cell around the text
      ccode = getCellCode(w, h, '', border, 1, '', fill, '', 0, true)
      @lasth = prevLastH

      if @tmp_buffer
        @tmp_buffer = "#{ccode}\n#{@tmp_buffer}"
      elsif (border != 0) or (fill == 1)
        if !@transfmrk[@page].nil?
          pagemark = @transfmrk[@page]
          @transfmrk[@page] += (ccode + "\n").length
        elsif @in_footer
          pagemark = @footerpos[@page]
          @footerpos[@page] += (ccode + "\n").length
        else
          pagemark = @intmrk[@page]
          @intmrk[@page] += (ccode + "\n").length
        end
        pagebuff = getPageBuffer(@page)
        pstart = pagebuff[0, pagemark]
        pend = pagebuff[pagemark..-1].to_s
        setPageBuffer(@page, pstart + ccode + "\n" + pend)
      end
    end

    # Get end-of-cell Y position
    currentY = GetY()

    # restore original margin values
    SetLeftMargin(l_margin)
    SetRightMargin(r_margin)

    if ln > 0
      # Go to the beginning of the next line
      SetY(currentY)
      if ln == 2
        SetX(x + w)
      end
    else
      # go left or right by case
      setPage(startpage)
      @y = y
      SetX(x + w)
    end

    setContentMark()
    return nl
  rescue => err
    Error('MultiCell Error.', err)
  end
  alias_method :multi_cell, :MultiCell

  #
  # Get the border mode accounting for multicell position (opens bottom side of multicell crossing pages)
  # [@param mixed :border]
  #   Indicates if borders must be drawn around the cell block. The value can be either a number:
  #   * 0: no border (default)
  #   * 1: frame
  #   or a string containing some or all of the following characters (in any order):
  #   * L: left
  #   * T: top
  #   * R: right
  #   * B: bottom
  # [@param string multicell position: 'start', 'middle', 'end'
  # [@return mixed] border mode
  # [@access protected]
  # [@since 4.4.002 (2008-12-09)]
  #
  def getBorderMode(border, position='start')
    if !@opencell and (border == 1)
      return 1
    end
    return 0 if border == 0
    cborder = ''
    case position
    when 'start'
      if border == 1
        cborder = 'LTR'
      else
        if nil != border.index('L')
          cborder << 'L'
        end
        if nil != border.index('T')
          cborder << 'T'
        end
        if nil != border.index('R')
          cborder << 'R'
        end
        if !@opencell and (nil != border.index('B'))
          cborder << 'B'
        end
      end
    when 'middle'
      if border == 1
        cborder = 'LR'
      else
        if nil != border.index('L')
          cborder << 'L'
        end
        if !@opencell and (nil != border.index('T'))
          cborder << 'T'
        end
        if nil != border.index('R')
          cborder << 'R'
        end
        if !@opencell and (nil != border.index('B'))
          cborder << 'B'
        end
      end
    when 'end'
      if border == 1
        cborder = 'LRB'
      else
        if nil != border.index('L')
          cborder << 'L'
        end
        if !@opencell and (nil != border.index('T'))
          cborder << 'T'
        end
        if nil != border.index('R')
          cborder << 'R'
        end
        if nil != border.index('B')
          cborder << 'B'
        end
      end
    else
      cborder = border
    end
    return cborder
  end
  protected :getBorderMode

  #
  # This method return the estimated number of lines for print a simple text string in Multicell() method.
  # [@param string :txt] String for calculating his height
  # [@param float :w] Width of cells. If 0, they extend up to the right margin of the page.
  # [@param boolean :reseth] if true reset the last cell height (default false).
  # [@param boolean :autopadding] if true, uses internal padding and automatically adjust it to account for line width (default true).
  # [@param float :cellMargin] Internal cell margin, if empty or <= 0, extended up to current pdf cell margin (default '').
  # [@param float :lineWidth] Line width, if empty or <= 0, extended up to current pdf line width (default '').
  # [@return float] Return the minimal height needed for multicell method for printing the :txt param.
  # [@author] Alexander Escalona Fernendez, Nicola Asuni
  # [@access public]
  # [@since 4.5.011]
  #
  def getNumLines(txt, w=0, reseth=false, autopadding=true, cellMargin='', lineWidth='')
    if empty_string(w) or (w <= 0)
      if @rtl
        w = @x - @l_margin
      else
        w = @w - @r_margin - @x
      end
    end
    if empty_string(cellMargin) or (cellMargin <= 0)
      cellMargin = @c_margin
    end
    if empty_string(lineWidth) or (lineWidth <= 0)
      lineWidth = @line_width
    end
    if autopadding
      # adjust internal padding
      if cellMargin < (lineWidth / 2.0)
        cellMargin = lineWidth / 2.0
      end
    end
    wmax = w - (2 * cellMargin)
    if reseth
      @lasth = @font_size * @cell_height_ratio
    end
    lines = 1
    sum = 0
    chars = UTF8StringToArray(txt)
    chars = utf8Bidi(chars, txt, rtl_text_dir)
    charsWidth = GetArrStringWidth(chars, '', '', 0, true)
    if @rtl
      charsWidth.reverse!
      chars.reverse!
    end
    length = chars.length
    lastSeparator = -1

    i = 0
    while i < length
      charWidth = charsWidth[i]
      if unichr(chars[i]) =~ /\s/
        lastSeparator = i
      end
      if (sum + charWidth >= wmax) or (chars[i] == 10) # 10 = "\n" = new line
        lines += 1
        if lastSeparator != -1
          i = lastSeparator
          lastSeparator = -1
          sum = 0
        else
          sum = charWidth
        end
      else
        sum += charWidth
      end
      i += 1
    end
    return lines
  end
  alias_method :get_num_lines, :getNumLines

  #
  # This method return the estimated needed height for print a simple text string in Multicell() method.
  # Generally, if you want to know the exact height for a block of content you can use the following technique:
  #
  #   # store current object
  #   pdf.start_transaction()
  #   # store starting values
  #   start_y = pdf.get_y()
  #   start_page = pdf.get_page()
  #   # call your printing functions with your parameters
  #   # - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  #   pdf.multi_cell(w=0, h=0, txt, border=1, align='L', fill=0, ln=1, x='', y='', reseth=true, stretch=0, ishtml=false, autopadding=true, maxh=0)
  #   # - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  #   # get the new Y
  #   end_y = pdf.get_y()
  #   end_page = pdf.get_page()
  #   # calculate height
  #   height = 0
  #   if end_page == start_page
  #     height = end_y - start_y
  #   else
  #     start_page.upto(end_page) do |page|
  #       pdf.set_page(page)
  #       if page == start_page
  #         # first page
  #         height = @h - start_y - @b_margin
  #       elsif page == end_page
  #         # last page
  #         height = end_y - @t_margin
  #       else
  #         height = @h - @t_margin - @b_margin
  #       end
  #     end
  #   end
  #   # restore previous object
  #   pdf = pdf.rollbackTransaction()
  #
  # [@param float :w] Width of cells. If 0, they extend up to the right margin of the page.
  # [@param string :txt] String for calculating his height
  # [@param boolean :reseth] if true reset the last cell height (default false).
  # [@param boolean :autopadding] if true, uses internal padding and automatically adjust it to account for line width (default true).
  # [@param float :cellMargin] Internal cell margin, if empty or <= 0, extended up to current pdf cell margin (default '').
  # [@param float :lineWidth] Line width, if empty or <= 0, extended up to current pdf line width (default '').
  # [@return float] Return the minimal height needed for multicell method for printing the :txt param.
  # [@author] Nicola Asuni, Alexander Escalona Fern<E1>ndez
  # [@access public]
  #
  def getStringHeight(w, txt, reseth=false, autopadding=true, cellMargin='', lineWidth='')
    lines = getNumLines(txt, w, reseth, autopadding, cellMargin, lineWidth)
    height = lines * (@font_size * @cell_height_ratio)
    if autopadding
      if empty_string(cellMargin) or (cellMargin <= 0)
        cellMargin = @c_margin
      end
      if empty_string(lineWidth) or (lineWidth <= 0)
        lineWidth = @line_width
      end
      # adjust internal padding
      if cellMargin < (lineWidth / 2.0)
        cellMargin = lineWidth / 2.0
      end
      # add top and bottom space if needed
      if (@lasth - @font_size) < lineWidth
        height += lineWidth
      end
      # add top and bottom padding
      height += 2 * cellMargin
    end
    return height
  end
  alias_method :get_string_height, :getStringHeight

  #
  # This method prints text from the current position.
  # [@param float :h] Line height
  # [@param string :txt] String to print
  # [@param mixed :link] URL or identifier returned by AddLink()
  # [@param int :fill] Indicates if the background must be painted (1) or transparent (0). Default value: 0.
  # [@param string :align]
  #   Allows to center or align the text. Possible values are:
  #   * L or empty string: left align (default value)
  #   * C: center
  #   * R: right align
  #   * J: justify
  # [@param boolean :ln] if true set cursor at the bottom of the line, otherwise set cursor at the top of the line.
  # [@param int :stretch]
  #   stretch carachter mode:
  #   * 0 = disabled
  #   * 1 = horizontal scaling only if necessary
  #   * 2 = forced horizontal scaling
  #   * 3 = character spacing only if necessary
  #   * 4 = forced character spacing
  # [@param boolean :firstline] if true prints only the first line and return the remaining string.
  # [@param boolean :firstblock] if true the string is the starting of a line.
  # [@param float :maxh] maximum height. The remaining unprinted text will be returned. It should be >= :h and less then remaining space to the bottom of the page, or 0 for disable this feature.
  # [@return mixed] Return the number of cells or the remaining string if :firstline = true.
  # [@access public]
  # [@since 1.5]
  #
  def Write(h, txt, link=nil, fill=0, align='', ln=false, stretch=0, firstline=false, firstblock=false, maxh=0)
    txt = txt.dup
    txt.force_encoding('ASCII-8BIT') if txt.respond_to?(:force_encoding)
    if txt.length == 0
      txt = ' '
    end

    # remove carriage returns
    s = txt.gsub("\r", '');

    # check if string contains arabic text
    if s =~ @@k_re_pattern_arabic
      arabic = true
    else
      arabic = false
    end

    # check if string contains RTL text
    if arabic or isRTLTextDir or (txt =~ @@k_re_pattern_rtl)
      rtlmode = true
    else
      rtlmode = false
    end

    # get a char width
    chrwidth = GetCharWidth('.')
    # get array of unicode values
    chars = UTF8StringToArray(s)
    # get array of chars
    uchars = UTF8ArrayToUniArray(chars)

    # get the number of characters
    nb = chars.size

    # replacement for SHY character (minus symbol)
    shy_replacement = 45
    shy_replacement_char = unichr(shy_replacement)
    # widht for SHY replacement
    shy_replacement_width = GetCharWidth(shy_replacement)

    # store current position
    prevx = @x
    prevy = @y

    # max Y
    maxy = @y + maxh - h - (2 * @c_margin)

    # calculating remaining line width (w)
    if @rtl
      w = @x - @l_margin
    else
      w = @w - @r_margin - @x
    end

    # max column width
    wmax = w - (2 * @c_margin)
    if !firstline and (chrwidth > wmax or (GetCharWidth(chars[0]) > wmax))
      # a single character do not fit on column
      return ''
    end

    i = 0    # character position
    j = 0    # current starting position
    sep = -1 # position of the last blank space
    shy = false # true if the last blank is a soft hypen (SHY)
    l = 0    # current string length
    nl = 0   # number of lines
    linebreak = false

    pc = 0 # previous character
    # for each character
    while(i<nb)
      if (maxh > 0) and (@y >= maxy)
        break
      end
      # Get the current character
      c = chars[i]
      if (c == 10) # 10 = "\n" = new line
        #Explicit line break
        if align == 'J'
          if @rtl
            talign = 'R'
          else
            talign = 'L'
          end
        else
          talign = align
        end
        tmpstr = UniArrSubString(uchars, j, i)
        if firstline
          startx = @x
          tmparr = chars[j, i - j]
          if rtlmode
            tmparr = utf8Bidi(tmparr, tmpstr, rtl_text_dir)
          end
          linew = GetArrStringWidth(tmparr)
          tmparr = ''
          if @rtl
            @endlinex = startx - linew
          else
            @endlinex = startx + linew
          end
          w = linew
          tmpcmargin = @c_margin
          if maxh == 0
            @c_margin = 0
          end
        end
        if firstblock and isRTLTextDir()
          tmpstr = tmpstr.rstrip
        end
        Cell(w, h, tmpstr, 0, 1, talign, fill, link, stretch)
        tmpstr = ''
        if firstline
          @c_margin = tmpcmargin
          return UniArrSubString(uchars, i)
        end
        nl += 1
        j = i + 1
        l = 0
        sep = -1
        shy = false;
        # account for margin changes
        if ((@y + @lasth) > @page_break_trigger) and !@in_footer
          AcceptPageBreak()
        end
        w = getRemainingWidth()
        wmax = w - (2 * @c_margin)
      else
        # 160 is the non-breaking space, 173 is SHY (Soft Hypen)
        if (c != 160) and ((unichr(c) =~ /\s/) or (c == 173))
          # update last blank space position
          sep = i
          # check if is a SHY
          if c == 173
            shy = true
            if pc == 45
              tmp_shy_replacement_width = 0
              tmp_shy_replacement_char = ''
            else
              tmp_shy_replacement_width = shy_replacement_width
              tmp_shy_replacement_char = shy_replacement_char
            end
          else
            shy = false
          end
        end

        # update string length
        if ((@current_font['type'] == 'TrueTypeUnicode') or (@current_font['type'] == 'cidfont0')) and arabic
          # with bidirectional algorithm some chars may be changed affecting the line length
          # *** very slow ***
          l = GetArrStringWidth(utf8Bidi(chars[j,i-j], '', rtl_text_dir))
        else
          l += GetCharWidth(c)
        end

        if (l > wmax) or ((c == 173) and ((l + tmp_shy_replacement_width) > wmax))
          # we have reached the end of column
          if (sep == -1)
            # check if the line was already started
            if (@rtl and (@x <= @w - @r_margin - chrwidth)) or (!@rtl and (@x >= @l_margin + chrwidth))
              # print a void cell and go to next line
              Cell(w, h, '', 0, 1)
              linebreak = true
              if firstline
                return UniArrSubString(uchars, j)
              end
            else
              # truncate the word because do not fit on column
              tmpstr = UniArrSubString(uchars, j, i)
              if firstline
                startx = @x
                tmparr = chars[j, i - j]
                if rtlmode
                  tmparr = utf8Bidi(tmparr, tmpstr, rtl_text_dir)
                end
                linew = GetArrStringWidth(tmparr)
                tmparr = ''
                if @rtl
                  @endlinex = startx - linew
                else
                  @endlinex = startx + linew
                end
                w = linew
                tmpcmargin = @c_margin
                if maxh == 0
                  @c_margin = 0
                end
              end
              if firstblock and isRTLTextDir()
                tmpstr = tmpstr.rstrip
              end
              Cell(w, h, tmpstr, 0, 1, align, fill, link, stretch)
              tmpstr = ''
              if firstline
                @c_margin = tmpcmargin
                return UniArrSubString(uchars, i)
              end
              j = i
              i -= 1
            end
          else
            # word wrapping
            if @rtl and !firstblock
              endspace = 1
            else
              endspace = 0
            end
            if shy
              # add hypen (minus symbol) at the end of the line
              shy_width = tmp_shy_replacement_width
              if @rtl
                shy_char_left = tmp_shy_replacement_char
                shy_char_right = ''
              else
                shy_char_left = ''
                shy_char_right = tmp_shy_replacement_char
              end
            else
              shy_width = 0
              shy_char_left = ''
              shy_char_right = ''
            end
            tmpstr = UniArrSubString(uchars, j, sep + endspace)
            if firstline
              startx = @x
              tmparr = chars[j, sep + endspace - j]
              if rtlmode
                tmparr = utf8Bidi(tmparr, tmpstr, rtl_text_dir)
              end
              linew = GetArrStringWidth(tmparr)
              tmparr = ''
              if @rtl
                @endlinex = startx - linew - shy_width
              else
                @endlinex = startx + linew + shy_width
              end
              w = linew
              tmpcmargin = @c_margin
              if maxh == 0
                @c_margin = 0
              end
            end
            # print the line
            if firstblock and isRTLTextDir()
              tmpstr = tmpstr.rstrip
            end
            Cell(w, h, shy_char_left + tmpstr + shy_char_right, 0, 1, align, fill, link, stretch)
            tmpstr = ''
            if firstline
              # return the remaining text
              @c_margin = tmpcmargin
              return UniArrSubString(uchars, sep + endspace)
            end
            i = sep
            sep = -1
            shy = false
            j = i + 1
          end
          # account for margin changes
          if (@y + @lasth > @page_break_trigger) and !@in_footer
            AcceptPageBreak()
          end
          w = getRemainingWidth()
          wmax = w - (2 * @c_margin)
          if linebreak
            linebreak = false
          else
            nl += 1
            l = 0
          end
        end
      end
      # save last character
      pc = c
      i +=1
    end # end while i < nb

    # print last substring (if any)
    if l > 0
      case align
      when 'J' , 'C'
        w = w
      when 'L'
        if @rtl
          w = w
        else
          w = l
        end
      when 'R'
        if @rtl
          w = l
        else
          w = w
        end
      else
        w = l
      end
      tmpstr = UniArrSubString(uchars, j, nb)
      if firstline
        startx = @x
        tmparr = chars[j, nb - j]
        if rtlmode
          tmparr = utf8Bidi(tmparr, tmpstr, rtl_text_dir)
        end
        linew = GetArrStringWidth(tmparr)
        tmparr = ''
        if @rtl
          @endlinex = startx - linew
        else
          @endlinex = startx + linew
        end
        w = linew
        tmpcmargin = @c_margin
        if maxh == 0
          @c_margin = 0
        end
      end
      if firstblock and isRTLTextDir()
        tmpstr = tmpstr.rstrip
      end
      Cell(w, h, tmpstr, 0, (ln ? 1 : 0), align, fill, link, stretch)
      tmpstr = ''
      if firstline
        @c_margin = tmpcmargin
        return UniArrSubString(uchars, nb)
      end
      nl += 1
    end

    if firstline
      return ''
    end
    return nl
  rescue => err
    Error('Write Error.', err)
  end
  alias_method :write, :Write

  #
  # Returns the remaining width between the current position and margins.
  # [@return int] Return the remaining width
  # [@access protected]
  #
  def getRemainingWidth()
    if @rtl
      return @x - @l_margin
    else
      return @w - @r_margin - @x
    end
  end
  protected :getRemainingWidth

  #
  # Extract a slice of the :strarr array and return it as string.
  # [@param string :strarr] The input array of characters. (UCS4)
  # [@param int :start] the starting element of :strarr.
  # [@param int :last] first element that will not be returned.
  # [@return] Return part of a string (UTF-8)
  # [@access public]
  #
  def UTF8ArrSubString(strarr, start=0, last=strarr.size)
    string = ""
    start.upto(last - 1) do |i|
      string << unichr(strarr[i])
    end
    return string
  end
  alias_method :utf8_arr_sub_string, :UTF8ArrSubString

  #
  # Extract a slice of the :uniarr array and return it as string.
  # [@param string :uniarr] The input array of characters. (UTF-8)
  # [@param int :start] the starting element of :strarr.
  # [@param int :las]t first element that will not be returned.
  # [@return] Return part of a string (UTF-8)
  # [@access public]
  # [@since 4.5.037 (2009-04-07)]
  #
  def UniArrSubString(uniarr, start=0, last=uniarr.length)
    string = ''
    start.upto(last - 1) do |i|
      string << uniarr[i]
    end
    return string
  end
  alias_method :uni_arr_sub_string, :UniArrSubString

  #
  # Convert an array of UTF8 values to array of unicode characters
  # [@param string :ta] The input array of UTF8 values. (UCS4)
  # [@return] Return array of unicode characters (UTF-8)
  # [@access public]
  # [@since 4.5.037 (2009-04-07)]
  #
  def UTF8ArrayToUniArray(ta)
    string = []
    ta.each do |i|
      string << unichr(i)
    end
    return string
  end
  alias_method :utf8_array_to_uni_array, :UTF8ArrayToUniArray

  #
  # Returns the unicode caracter specified by UTF-8 value
  # [@param int :c] UTF-8 value (UCS4)
  # [@return] Returns the specified character. (UTF-8)
  # [@author] Miguel Perez, Nicola Asuni
  # [@access public]
  # [@since 2.3.000 (2008-03-05)]
  #
  def unichr(c)
    if !@is_unicode
      return c.chr
    elsif c <= 0x7F
      # one byte
      return c.chr
    elsif c <= 0x7FF
      # two bytes
      return (0xC0 | c >> 6).chr + (0x80 | c & 0x3F).chr
    elsif c <= 0xFFFF
      # three bytes
      return (0xE0 | c >> 12).chr + (0x80 | c >> 6 & 0x3F).chr + (0x80 | c & 0x3F).chr
    elsif c <= 0x10FFFF
      # four bytes
      return (0xF0 | c >> 18).chr + (0x80 | c >> 12 & 0x3F).chr + (0x80 | c >> 6 & 0x3F).chr + (0x80 | c & 0x3F).chr
    else
      return ""
    end
  end

  #
  # Return the image type given the file name or array returned by getimagesize() function.
  # [@param string :imgfile] image file name
  # [@param hash :iminfo] array of image information returned by getimagesize() function.
  # [@return string] image type
  # [@access public]
  # [@since 4.8.017 (2009-11-27)]
  #
  def getImageFileType(imgfile, iminfo={})
    if iminfo.is_a? Hash and iminfo['mime'] and !iminfo['mime'].empty?
      mime = iminfo['mime'].split('/')
      if (mime.length > 1) and (mime[0] == 'image') and !mime[1].empty?
        return mime[1].strip
      end
    end
    type = ''
    return type if imgfile.nil?

    fileinfo = File::extname(imgfile)
    type = fileinfo.sub(/^\./, '').downcase if fileinfo != ''
    if type == 'jpg'
      type = 'jpeg'
    end
    return type
  end
  alias_method :get_image_file_type, :getImageFileType

  #
  # Puts an image in the page.
  # The upper-left corner must be given.
  # The dimensions can be specified in different ways:
  # * explicit width and height (expressed in user unit)
  # * one explicit dimension, the other being calculated automatically in order to keep the original proportions
  # * no explicit dimension, in which case the image is put at 72 dpi
  # Supported formats are PNG images whitout RMagick/MiniMagick library and JPEG and GIF and WebP images supported by RMagick/MiniMagick.
  # For JPEG, all flavors are allowed:
  # * gray scales
  # * true colors (24 bits)
  # * CMYK (32 bits)
  # For PNG, are allowed:
  # * gray scales on at most 8 bits (256 levels)
  # * indexed colors
  # * true colors (24 bits)
  # If a transparent color is defined, it will be taken into account (but will be only interpreted by Acrobat 4 and above).
  # The format can be specified explicitly or inferred from the file extension.
  # It is possible to put a link on the image.
  # * Remark: if an image is used several times, only one copy will be embedded in the file.
  # [@param string :file] Name of the file containing the image.
  # [@param float :x] Abscissa of the upper-left corner.
  # [@param float :y] Ordinate of the upper-left corner.
  # [@param float :w] Width of the image in the page. If not specified or equal to zero, it is automatically calculated.
  # [@param float :h] Height of the image in the page. If not specified or equal to zero, it is automatically calculated.
  # [@param string :type] Image format. Possible values are (case insensitive): JPG, JPEG, PNG, GIF, WebP. If not specified, the type is inferred from the file extension.
  # [@param mixed :link] URL or identifier returned by AddLink().
  # [@param string :align]
  #   Indicates the alignment of the pointer next to image insertion relative to image height. The value can be:
  #   * T: top-right for LTR or top-left for RTL
  #   * M: middle-right for LTR or middle-left for RTL
  #   * B: bottom-right for LTR or bottom-left for RTL
  #   * N: next line
  # [@param mixed :resize] If true resize (reduce) the image to fit :w and :h (requires RMagick/MiniMagick library); if false do not resize; if 2 force resize in all cases (upscaling and downscaling).
  # [@param int :dpi] dot-per-inch resolution used on resize
  # [@param string :palign]
  #   Allows to center or align the image on the current line. Possible values are:
  #   * L : left align
  #   * C : center
  #   * R : right align
  #   * '' : empty string : left for LTR or right for RTL
  # [@param boolean :ismask] true if this image is a mask, false otherwise
  # [@param mixed :imgmask] image object returned by this function or false
  # [@param mixed :border]
  #   Indicates if borders must be drawn around the image. The value can be either a number:
  #   * 0: no border (default)
  #   * 1: frame
  #   or a string containing some or all of the following characters (in any order):
  #   * L: left
  #   * T: top
  #   * R: right
  #   * B: bottom
  # [@param boolean :fitbox] If true scale image dimensions proportionally to fit within the (:w, :h) box.
  # [@param boolean :hidden] if true do not display the image.
  # [@param boolean :fitonpage] if true the image is resized to not exceed page dimensions.
  # [@return] image information
  # [@access public]
  # [@since 1.1]
  #
  def Image(file, x='', y='', w=0, h=0, type='', link=nil, align='', resize=false, dpi=300, palign='', ismask=false, imgmask=false, border=0, fitbox=false, hidden=false, fitonpage=false)
    w = 0 if w == ''
    h = 0 if h == ''

    x = @x if x == ''
    y = @y if y == ''

    # set bottomcoordinates
    @img_rb_y = y + h
    Error('Image filename is empty.') if file.nil? or file.length == 0
    unless File.exist?(file)
      Error('Image file is not found. : ' + file)
    end

    # get image dimensions
    imsize = getimagesize(file)
    if imsize.nil? or imsize == false
      # encode spaces on filename
      file = file.gsub(' ', '%20')
      imsize = getimagesize(file)

      if imsize.nil?
        Error("Can't get image dimension. : " + file)
      elsif imsize == false
        if (w > 0) and (h > 0)
          pw = getHTMLUnitToUnits(w, 0, @pdfunit, true) * @img_scale * @k
          ph = getHTMLUnitToUnits(h, 0, @pdfunit, true) * @img_scale * @k
          imsize = [pw, ph]
        else
          Error('Unable to get image width and height: ' + file)
        end
      end
    end
    # get original image width and height in pixels
    pixw = imsize[0]
    pixh = imsize[1]

    # calculate image width and height on document
    if (w <= 0) and (h <= 0)
      # convert image size to document unit
      w = pixelsToUnits(pixw)
      h = pixelsToUnits(pixh)
    elsif w <= 0
      w = h * pixw / pixh
    elsif h <= 0
      h = w * pixh / pixw
    elsif fitbox and (w > 0) and (h > 0)
      # scale image dimensions proportionally to fit within the (:w, :h) box
      if ((w * pixh) / (h * pixw)) < 1
        h = w * pixh / pixw
      else
        w = h * pixw / pixh
      end
    end

    # resize image to be contained on a single page          # fix at page break case.
    if fitonpage
      ratio_wh = w / h
      if (@t_margin + h) > @page_break_trigger
        h = @page_break_trigger - @t_margin
        w = h * ratio_wh
      end
      if !@rtl and ((x + w) > (@w - @r_margin))
        w = @w - @r_margin - x
        h = w / ratio_wh
      elsif @rtl and ((x - w) < @l_margin)
        w = x - @l_margin
        h = w / ratio_wh
      end
    end

    # Check whether we need a new page first as this does not fit
    prev_x = @x
    if checkPageBreak(h, y)
      y = @y
      y += @c_margin if !empty_string(@thead) and !@in_thead  ### fix ###
      if @rtl
        x += prev_x - @x
      else
        x += @x - prev_x
      end
    end
    # resize image to be contained on a single page
    if fitonpage
      ratio_wh = w / h
      if (y + h) > @page_break_trigger
        h = @page_break_trigger - y
        w = h * ratio_wh
      end
      if !@rtl and ((x + w) > (@w - @r_margin))
        w = @w - @r_margin - x
        h = w / ratio_wh
      elsif @rtl and ((x - w) < @l_margin)
        w = x - @l_margin
        h = w / ratio_wh
      end
    end
    # calculate new minimum dimensions in pixels
    neww = (w * @k * dpi / @dpi).round
    newh = (h * @k * dpi / @dpi).round
    # check if resize is necessary (resize is used only to reduce the image)
    newsize = neww * newh
    pixsize = pixw * pixh
    if resize == 2
      resize = true
    elsif newsize >= pixsize
      resize = false
    end

    # check if image has been already added on document
    newimage = true
    if @imagekeys.include?(file)
      newimage = false;
      # get existing image data
      info = getImageBuffer(file)
      # check if the newer image is larger
      oldsize = info['w'] * info['h']
      if ((oldsize < newsize) and resize) or ((oldsize < pixsize) and !resize)
        newimage = true
      end
    end
    if newimage
      #First use of image, get info
      if (type == '')
        type = getImageFileType(file, imsize)
      else
        type = type.downcase
        type = 'jpeg' if type == 'jpg'
      end

      info = false
      if !resize
        case type
        when 'jpeg'
          info=parsejpeg(file)
        when 'png'
          info=parsepng(file)
        when 'webp'
          tmpFile = imageToPNG(file, false)
          if tmpFile != false
            info=parsepng(tmpFile.path)
            tmpFile.close(true)
          end
        when 'gif'
          tmpFile = imageToPNG(file, false)
          if tmpFile != false
            info=parsepng(tmpFile.path)
            tmpFile.close(true)
          end
        else
          #Allow for additional formats
          mtd='parse' + type;
          unless self.respond_to?(mtd, true)
            Error('Unsupported image type: ' + type);
          end
          info=send(mtd, file);
        end

        if info == 'pngalpha' and ismask == false and (Object.const_defined?(:MiniMagick) or Object.const_defined?(:Magick))
          info = ImagePngAlpha(file, x, y, w, h, 'PNG', link, align, resize, dpi, palign)
          if false != info
            return true
          end
        end
      end
      if !info
        if Object.const_defined?(:MiniMagick)
          # MiniMagick library

          ### T.B.D ### TCPDF 5.0.000 ###
          # if type == 'SVG'
          # else
            img = MiniMagick::Image.open(file)
          # end
          if resize
            img.resize("#{neww}x#{newh}")
          end
          img.format 'jpeg'
          tmpname = Tempfile.new(File::basename(file), @@k_path_cache)
          tmpname.binmode
          tmpname.print img.to_blob
        elsif Object.const_defined?(:Magick)
          # RMagick library

          ### T.B.D ### TCPDF 5.0.000 ###
          # if type == 'SVG'
          # else
            img = Magick::ImageList.new(file)
          # end
          if resize
            img.resize(neww,newh)
          end
          img.format = 'JPEG'
          tmpname = Tempfile.new(File::basename(file), @@k_path_cache)
          tmpname.binmode
          jpeg_quality = @jpeg_quality
          tmpname.print img.to_blob { |image| image.quality = jpeg_quality }
        else
          return false
        end
        tmpname.fsync
        info = parsejpeg(tmpname.path)
        tmpname.close(true)
      end

      if info == false
        # If false, we cannot process image
        return false
      end
      if ismask
        # force grayscale
        info['cs'] = 'DeviceGray'
      end
      info['i'] = @numimages
      if !@imagekeys.include?(file)
        info['i'] += 1
      end
      if imgmask != false
        info['masked'] = imgmask
      end
      # add image to document
      setImageBuffer(file, info)
    end

    # set alignment
    @img_rb_y = y + h
    # set alignment
    if @rtl
      if palign == 'L'
        ximg = @l_margin
      elsif palign == 'C'
        ximg = (@w + @l_margin - @r_margin - w) / 2.0
      elsif palign == 'R'
        ximg = @w - @r_margin - w
      else
        ximg = x - w
      end
      @img_rb_x = ximg
    else
      if palign == 'L'
        ximg = @l_margin
      elsif palign == 'C'
        ximg = (@w + @l_margin - @r_margin - w) / 2.0
      elsif palign == 'R'
        ximg = @w - @r_margin - w
      else
        ximg = x
      end
      @img_rb_x = ximg + w
    end
    if ismask or hidden
      # image is not displayed
      return info['i']
    end
    xkimg = ximg * @k
    out(sprintf('q %.2f 0 0 %.2f %.2f %.2f cm /I%d Do Q', w * @k, h * @k, xkimg, (@h - (y + h)) * @k, info['i']))

    if border != 0
      bx = x
      by = y
      @x = ximg
      if @rtl
        @x += w
      end
      @y = y
      Cell(w, h, '', border, 0, '', 0, '', 0)
      @x = bx
      @y = by
    end

    if link and !link.empty?
      Link(ximg, y, w, h, link)
    end

    # set pointer to align the successive text/objects
    case align
    when 'T'
      @y = y
      @x = @img_rb_x
    when 'M'
      @y = y + (h/2.0).round
      @x = @img_rb_x
    when 'B'
      @y = @img_rb_y
      @x = @img_rb_x
    when 'N'
      SetY(@img_rb_y)
    end
    @endlinex = @img_rb_x
    return info['i']
  end
  alias_method :image, :Image

  #
  # Extract info from a JPEG file
  # [@access protected]
  #
  def parsejpeg(file)
    a=getimagesize(file);
    if a == false or a.nil? or a.empty?
      Error('Missing or incorrect image file: ' + file);
    end
    if (a[2]!='JPEG')
      Error('Not a JPEG file: ' + file);
    end
    if (a['channels'].nil? or a['channels']==3)
      colspace='DeviceRGB';
    elsif (a['channels']==4)
      colspace='DeviceCMYK';
    else
      colspace='DeviceGray';
    end
    bpc=!a['bits'].nil? ? a['bits'] : 8;
    #Read whole file
    data='';
    open(file,'rb') do |f|
      data << f.read()
    end
    return {'w' => a[0],'h' => a[1],'cs' => colspace,'bpc' => bpc,'f'=>'DCTDecode','data' => data}
  end
  protected :parsejpeg

  def imageToPNG(file, delete_alpha=true)
    if Object.const_defined?(:MiniMagick)
      # MiniMagick library

      img = MiniMagick::Image.open(file)
      img.format 'png'
      if delete_alpha
        if ['rgba', 'srgba', 'graya'].include?(img["%[channels]"].downcase.split.first)
          img.combine_options do |mogrify|
              mogrify.alpha 'off'
          end
          if ['rgba', 'srgba', 'graya'].include?(img["%[channels]"].downcase.split.first)
            return false
          end
        end
      end
    elsif Object.const_defined?(:Magick)
      # RMagick library

      img = Magick::ImageList.new(file)
      img.format = 'png'
      if delete_alpha
        if img.alpha?
          # PNG alpha channel delete
          if Magick.const_defined?(:OffAlphaChannel) # RMagick 5.2.0 and later
            img.alpha Magick::OffAlphaChannel
          else # RMagick 5.1.0 and before for ImageMagick 6.x
            img.alpha Magick::DeactivateAlphaChannel
          end
          if img.alpha?
            return false
          end
        end
      end
    else
      return false
    end

    #use a temporary file....
    tmpFile = Tempfile.new(['', '_' + File::basename(file) + '.png'], @@k_path_cache);
    tmpFile.binmode
    tmpFile.print img.to_blob
    tmpFile.fsync
    tmpFile
  end
  protected :imageToPNG

  #
  # Extract info from a PNG file
  # [@access protected]
  #
  def parsepng(file)
    f = open(file,'rb')
    # Check signature
    if f.read(8) != 137.chr + 'PNG' + 13.chr + 10.chr + 26.chr + 10.chr
      Error('Not a PNG file: ' + file)
    end
    # Read header chunk
    f.read(4)
    if f.read(4) != 'IHDR'
      Error('Incorrect PNG file: ' + file)
    end
    w = freadint(f)
    h = freadint(f)
    bpc = f.read(1).unpack('C')[0]
    ct = f.read(1).unpack('C')[0]
    case ct
    when 0
      colspace = 'DeviceGray'
    when 2
      colspace = 'DeviceRGB'
    when 3
      colspace = 'Indexed'
    else
      if Object.const_defined?(:MiniMagick) or Object.const_defined?(:Magick)
        # alpha channel
        return 'pngalpha'
      else
        Error('No RMagick/MiniMagick : Alpha channel not supported: ' + file)
      end
    end
    if f.read(1).unpack('C')[0] != 0
      # Error('Unknown compression method: ' + file)
      return false
    end
    if f.read(1).unpack('C')[0] != 0
      # Error('Unknown filter method: ' + file)
      return false
    end

    if bpc > 8
      if Object.const_defined?(:MiniMagick) or Object.const_defined?(:Magick)
        return false
      else
        Error('No RMagick/MiniMagick : 16-bit depth not supported: ' + file)
      end
    end

    if f.read(1).unpack('C')[0] != 0
      # Error('Interlacing not supported: ' + file)
      return false
    end
    f.read(4)
    parms='/DecodeParms <</Predictor 15 /Colors ' + (ct == 2 ? 3 : 1).to_s + ' /BitsPerComponent ' + bpc.to_s + ' /Columns ' + w.to_s + '>>'
    # Scan chunks looking for palette, transparency and image data
    pal = ''
    trns = ''
    data = ''
    begin
      n = freadint(f)
      type = f.read(4)
      case type
      when 'PLTE'
        # Read palette
        pal = f.read(n)
        f.read(4)
      when 'tRNS'
        # Read transparency info
        t = f.read(n)
        case ct
        when 0 # DeviceGray
          trns = [t[1].unpack('C')[0]]
        when 2 # DeviceRGB
          trns = [t[1].unpack('C')[0], t[3].unpack('C')[0], t[5].unpack('C')[0]]
        else # Indexed
          trns = []
          n.times do |i|
            trns << t[i].unpack('C')[0]
          end
        end
        f.read(4)
      when 'IDAT'
        # Read image data block
        data << f.read(n)
        f.read(4)
      when 'IEND'
        break
      else
        f.read(n + 4)
      end
    end while(n)
    if (colspace == 'Indexed' and pal.empty?)
      # Error('Missing palette in ' + file)
      return false
    end
    return {'w' => w, 'h' => h, 'cs' => colspace, 'bpc' => bpc, 'f'=>'FlateDecode', 'parms' => parms, 'pal' => pal, 'trns' => trns, 'data' => data}
  ensure
    f.close unless f.nil?
  end
  protected :parsepng

  def image_alpha_mask(file)
    if Object.const_defined?(:MiniMagick)
      # MiniMagick library

      img = MiniMagick::Image.open(file)
      img.format('png')
      if ['rgba', 'srgba', 'graya'].include?(img["%[channels]"].downcase.split.first)
        img.combine_options do |mogrify|
          mogrify.channel 'matte'
          mogrify.separate '+matte'
        end
      else
        return false
      end
    elsif  Object.const_defined?(:Magick)
      # RMagick library

      img = Magick::ImageList.new(file)
      img.format = 'png'
      if img.alpha?
        img.alpha Magick::ExtractAlphaChannel   # PNG alpha channel Mask
      else
        return false
      end
    else
      return false
    end

    #use a temporary file....
    tmpFile = Tempfile.new(['msk_', '.png'], @@k_path_cache)
    tmpFile.binmode
    tmpFile.print img.to_blob
    tmpFile.fsync
    tmpFile
  end
  protected :image_alpha_mask

  #
  # Extract info from a PNG image with alpha channel using the RMagick/MiniMagick library.
  # [@param string :file] Name of the file containing the image.
  # [@param float :x] Abscissa of the upper-left corner.
  # [@param float :y] Ordinate of the upper-left corner.
  # [@param float :w] Width of the image in the page. If not specified or equal to zero, it is automatically calculated.
  # [@param float :h] Height of the image in the page. If not specified or equal to zero, it is automatically calculated.
  # [@param string :type] Possible values are (case insensitive): JPEG and PNG (without RMagick/MiniMagick library) and PNG(with alpha channel) and JPEG and GIF and WebP supported by RMagick/MiniMagick. If not specified, the type is inferred from the file extension.
  # [@param mixed :link] URL or identifier returned by AddLink().
  # [@param string :align]
  #   Indicates the alignment of the pointer next to image insertion relative to image height. The value can be:
  #   * T: top-right for LTR or top-left for RTL
  #   * M: middle-right for LTR or middle-left for RTL
  #   * B: bottom-right for LTR or bottom-left for RTL
  #   * N: next line
  # [@param boolean :resize] If true resize (reduce) the image to fit :w and :h (requires RMagick/MiniMagick library).
  # [@param int :dpi] dot-per-inch resolution used on resize
  # [@param string :palign]
  #   Allows to center or align the image on the current line. Possible values are:
  #   * L : left align
  #   * C : center
  #   * R : right align
  #   * '' : empty string : left for LTR or right for RTL
  # [@author] Valentin Schmidt, Nicola Asuni
  # [@access protected]
  # [[@since 4.3.007 (2008-12-04)]
  # [@see] Image()
  #
  def ImagePngAlpha(file, x='', y='', w=0, h=0, type='', link='', align='', resize=false, dpi=300, palign='')
    tempfile_plain = imageToPNG(file)
    if tempfile_plain == false
      return false
    end

    tempfile_alpha = image_alpha_mask(file)
    if tempfile_alpha == false
      return false
    end

    # embed mask image
    imgmask = Image(tempfile_alpha.path, x, y, w, h, 'PNG', '', '', resize, dpi, '', true, false)
    tempfile_alpha.close(true)

    # embed image, masked with previously embedded mask
    Image(tempfile_plain.path, x, y, w, h, type, link, align, resize, dpi, palign, false, imgmask)
    tempfile_plain.close(true)

    return true
  end
  protected :ImagePngAlpha

  #
  # Performs a line break.
  # The current abscissa goes back to the left margin and the ordinate increases by the amount passed in parameter.
  # [@param float :h] The height of the break. By default, the value equals the height of the last printed cell.
  # [@param boolean :cell] if true add a c_margin to the x coordinate
  # [@access public]
  # [@since 1.0]
  # [@see] Cell()
  #
  def Ln(h='', cell=false)
    if (@num_columns > 0) and (@y == @columns[@current_column]['y']) and @columns[@current_column]['x'] and (@x == @columns[@current_column]['x'])
      # revove vertical space from the top of the column
      return
    end
    if cell
      cellmargin = @c_margin
    else
      cellmargin = 0
    end
    if @rtl
      @x = @w - @r_margin - cellmargin
    else
      @x = @l_margin + cellmargin
    end
    if h.is_a?(String)
      @y += @lasth
    else
      @y += h
    end
    @newline = true
  end
  alias_method :ln, :Ln

  #
  # Returns the relative X value of current position.
  # The value is relative to the left border for LTR languages and to the right border for RTL languages.
  # [@return float]
  # [@access public]
  # [@since 1.2]
  # [@see] SetX(), GetY(), SetY()
  #
  def GetX()
    if @rtl
      return @w - @x
    else
      return @x
    end
  end
  alias_method :get_x, :GetX

  #
  # Returns the absolute X value of current position.
  # [@return float]
  # [@access public]
  # [@since 1.2]
  # [@see] SetY(), GetX(), SetX()
  #
  def GetAbsX()
    return @x
  end
  alias_method :get_abs_x, :GetAbsX

  #
  # Returns the ordinate of the current position.
  # [@return float]
  # [@access public]
  # [@since 1.0]
  # [@see] SetY(), GetX(), SetX()
  #
  def GetY()
    return @y;
  end
  alias_method :get_y, :GetY

  #
  # Defines the abscissa of the current position.
  # If the passed value is negative, it is relative to the right of the page (or left if language is RTL).
  # [@param float :x] The value of the abscissa.
  # [@param boolean :rtloff] if true always uses the page top-left corner as origin of axis.
  # [@access public]
  # [@since 1.2]
  # [@see] GetX(), GetY(), SetY(), SetXY()
  #
  def SetX(x, rtloff=false)
    #Set x position
    if !rtloff and @rtl
      if x >= 0
        @x = @w - x
      else
        @x = x.abs
      end
    else
      if x >= 0
        @x = x
      else
        @x = @w + x
      end
    end
  end
  alias_method :set_x, :SetX

  #
  # Moves the current abscissa back to the left margin and sets the ordinate.
  # If the passed value is negative, it is relative to the bottom of the page.
  # [@param float :y] The value of the ordinate.
  # [@param bool :resetx] if true (default) reset the X position.
  # [@param boolean :rtloff] if true always uses the page top-left corner as origin of axis.
  # [@access public]
  # [@since 1.0]
  # [@see] GetX(), GetY(), SetY(), SetXY()
  #
  def SetY(y, resetx=true, rtloff=false)
    if resetx
      # reset x
      if !rtloff and @rtl
        @x = @w - @r_margin
      else
        @x = @l_margin
      end
    end
    if (y>=0)
      @y = y;
    else
      @y=@h+y;
    end

    if @y < 0
      @y = 0
    end
    if @y > @h
      @y = @h
    end
  end
  alias_method :set_y, :SetY

  #
  # Defines the abscissa and ordinate of the current position. If the passed values are negative, they are relative respectively to the right and bottom of the page.
  # [@param float :x] The value of the abscissa.
  # [@param float :y] The value of the ordinate.
  # [@param boolean :rtloff] if true always uses the page top-left corner as origin of axis.
  # [@access public]
  # [@since 1.2]
  # [@see] SetX(), SetY()
  #
  def SetXY(x, y, rtloff=false)
    SetY(y, false, rtloff)
    SetX(x, rtloff)
  end
  alias_method :set_xy, :SetXY

  #
  # Send the document to a given destination: string, local file or browser.
  # In the last case, the plug-in may be used (if present) or a download ("Save as" dialog box) may be forced.
  # The method first calls Close() if necessary to terminate the document.
  # [@param string :name] The name of the file when saved. Note that special characters are removed and blanks characters are replaced with the underscore character.
  # [@param string :dest]
  #   Destination where to send the document. It can take one of the following values:
  #   * I: send the file inline to the browser (default). The plug-in is used if available. The name given by name is used when one selects the "Save as" option on the link generating the PDF.
  #   * D: send to the browser and force a file download with the name given by name.
  #   * F: save to a local server file with the name given by name.
  #   * S: return the document as a string. name is ignored.
  #   * FI: equivalent to F + I option
  #   * FD: equivalent to F + D option
  # [@access public]
  # [@since 1.0]
  # [@see] Close()
  #
  def Output(name='', dest='')
    #Output PDF to some destination
    #Finish document if necessary

    lastPage()

    if (@state < 3)
      Close();
    end
    #Normalize parameters
    # Boolean no longer supported
    # if (dest.is_a?(Boolean))
    #   dest = dest ? 'D' : 'F';
    # end
    dest = dest.upcase
    if (dest=='')
      if (name=='')
        name='doc.pdf';
        dest='I';
      else
        dest='F';
      end
    end
    case (dest)
    when 'I'
        # This is PHP specific code
        ##Send to standard output
        # if (ob_get_contents())
        #   Error('Some data has already been output, can\'t send PDF file');
        # end
        # if (php_sapi_name()!='cli')
        #   #We send to a browser
        #   header('Content-Type: application/pdf');
        #   if (headers_sent())
        #     Error('Some data has already been output to browser, can\'t send PDF file');
        #   end
        #   header('Content-Length: ' + @buffer.length);
        #   header('Content-disposition: inline; filename="' + name + '"');
        # end
      return getBuffer
    when 'D'
        # PHP specific
        #Download file
        # if (ob_get_contents())
        #   Error('Some data has already been output, can\'t send PDF file');
        # end
        # if (!_SERVER['HTTP_USER_AGENT'].nil? && SERVER['HTTP_USER_AGENT'].include?('MSIE'))
        #   header('Content-Type: application/force-download');
        # else
        #   header('Content-Type: application/octet-stream');
        # end
        # if (headers_sent())
        #   Error('Some data has already been output to browser, can\'t send PDF file');
        # end
        # header('Content-Length: '+ @buffer.length);
        # header('Content-disposition: attachment; filename="' + name + '"');
      return getBuffer
    when 'F', 'FI', 'FD'
      # Save PDF to a local file
      if @diskcache
        FileUtils.copy(@buffer.path, name)
      else
        open(name,'wb') do |f|
          f.write(@buffer)
        end
      end
      if dest == 'FI'
      # This is PHP specific code
      #  # send headers to browser
      #  header('Content-Type: application/pdf')
      #  header('Cache-Control: public, must-revalidate, max-age=0') # HTTP/1.1
      #  header('Pragma: public')
      #  header('Expires: Sat, 26 Jul 1997 05:00:00 GMT') # Date in the past
      #  header('Last-Modified: ' + gmdate('D, d M Y H:i:s') + ' GMT')
      #  header('Content-Length: ' + filesize(name))
      #  header('Content-Disposition: inline; filename="' + File.basename(name) + '";')
        # send document to the browser
        data = ''
        open(name) do |f| data<< f.read ;end
        return data
      elsif dest == 'FD'
      # This is PHP specific code
      #  # send headers to browser
      #  if ob_get_contents()
      #    Error('Some data has already been output, can\'t send PDF file')
      #  end
      #  header('Content-Description: File Transfer')
      #  if headers_sent())
      #    Error('Some data has already been output to browser, can\'t send PDF file')
      #  end
      #  header('Cache-Control: public, must-revalidate, max-age=0') # HTTP/1.1
      #  header('Pragma: public')
      #  header('Expires: Sat, 26 Jul 1997 05:00:00 GMT'); # Date in the past
      #  header('Last-Modified: ' + gmdate('D, d M Y H:i:s') + ' GMT')
      #  # force download dialog
      #  header('Content-Type: application/force-download')
      #  header('Content-Type: application/octet-stream', false)
      #  header('Content-Type: application/download', false)
      #  header('Content-Type: application/pdf', false)
      #  # use the Content-Disposition header to supply a recommended filename
      #  header('Content-Disposition: attachment; filename="' + File.basename(name) + '";')
      #  header('Content-Transfer-Encoding: binary')
      #  header('Content-Length: ' + filesize(name))
        # send document to the browser
        data = ''
        open(name) do |f| data<< f.read ;end
        return data
      end
    when 'S'
      # Returns PDF as a string
      return getBuffer
    else
      Error('Incorrect output destination: ' + dest);
    end
    return '';
  ensure
    destroy(true)
  end
  alias_method :output, :Output

  #
  # Unset all class variables except the following critical variables: internal_encoding, state, bufferlen, buffer and diskcache.
  # [@param boolean :destroyall] if true destroys all class variables, otherwise preserves critical variables.
  # [@param boolean :preserve_objcopy] if true preserves the objcopy variable
  # [@access public]
  #
  def destroy(destroyall=false, preserve_objcopy=false)
    if destroyall and @diskcache and !preserve_objcopy and !empty_string(@buffer.path)
      # remove buffer file from cache
      File.delete(@buffer.path)
    end
    self.instance_variables.each { |val|
      if destroyall or ((val != '@internal_encoding') and (val != '@state') and (val != '@bufferlen') and (val != '@buffer') and (val != '@diskcache') and (val != '@sign') and (val != '@signature_data') and (val != '@signature_max_length') and (val != '@byterange_string'))
        if (!preserve_objcopy or (val.to_s != '@objcopy')) and !val.nil?
          eval("#{val} = nil")
        end
      end
    }
  end

  # Protected methods

protected

  #
  # Check for locale-related bug
  # [@access protected]
  #
  def dochecks()
    #Check for locale-related bug
    if (1.1==1)
      Error('Don\'t alter the locale before including class file');
    end
    #Check for decimal separator
    if (sprintf('%.1f',1.0)!='1.0')
      setlocale(LC_NUMERIC,'C');
    end
  end

  #
  # Return fonts path
  # [@access protected]
  #
  def getfontpath(file='')
    # Is it in the @@k_path_fonts?
    if @@k_path_fonts
      fpath = File.join @@k_path_fonts, file
      if File.exist?(fpath)
        return fpath
      end
    end
    # Is it in this plugin's font folder?
    fpath = File.join File.dirname(__FILE__), 'fonts', file
    if File.exist?(fpath)
      return fpath
    end
    # Could not find it.
    nil
  end

  #
  # Start document
  # [@access protected]
  #
  def begindoc()
    #Start document
    @state=1;
    out('%PDF-' + @pdf_version)
  end

  #
  # putpages
  # [@access protected]
  #
  def putpages()
    nb = @numpages
    if @alias_nb_pages
      nbs = formatPageNumber(nb)
      nbu = UTF8ToUTF16BE(nbs, false) # replacement for unicode font
      alias_a = escape(@alias_nb_pages)
      alias_au = escape('{' + @alias_nb_pages + '}')
      if @is_unicode
        alias_b = escape(UTF8ToLatin1(@alias_nb_pages))
        alias_bu = escape(UTF8ToLatin1('{' + @alias_nb_pages + '}'))
        alias_c = escape(utf8StrRev(@alias_nb_pages, false, rtl_text_dir))
        alias_cu = escape(utf8StrRev('{' + @alias_nb_pages + '}', false, rtl_text_dir))
      end
    end
    if @alias_num_page
      alias_pa = escape(@alias_num_page)
      alias_pau = escape('{' + @alias_num_page + '}')
      if @is_unicode
        alias_pb = escape(UTF8ToLatin1(@alias_num_page))
        alias_pbu = escape(UTF8ToLatin1('{' + @alias_num_page + '}'))
        alias_pc = escape(utf8StrRev(@alias_num_page, false, rtl_text_dir))
        alias_pcu = escape(utf8StrRev('{' + @alias_num_page + '}', false, rtl_text_dir))
      end
    end
    pagegroupnum = 0
    filter=(@compress) ? '/Filter /FlateDecode ' : ''
    1.upto(nb) do |n|
      temppage = getPageBuffer(n)
      if !@pagegroups.empty?
        if !@newpagegroup[n].nil?
          pagegroupnum = 0
        end
        pagegroupnum += 1
        @pagegroups.each { |k, v|
          # replace total pages group numbers
          vs = formatPageNumber(v)
          vu = UTF8ToUTF16BE(vs, false)
          alias_ga = escape(k)
          alias_gau = escape('{' + k + '}')
          if @is_unicode
            alias_gb = escape(UTF8ToLatin1(k))
            alias_gbu = escape(UTF8ToLatin1('{' + k + '}'))
            alias_gc = escape(utf8StrRev(k.dup, false, rtl_text_dir))
            alias_gcu = escape(utf8StrRev('{' + k + '}', false, rtl_text_dir))
          end
          temppage = temppage.gsub(alias_gau, vu)
          if @is_unicode
            temppage = temppage.gsub(alias_gbu, vu)
            temppage = temppage.gsub(alias_gcu, vu)
            temppage = temppage.gsub(alias_gb, vs)
            temppage = temppage.gsub(alias_gc, vs)
          end
          temppage = temppage.gsub(alias_ga, vs)
          # replace page group numbers
          pvs = formatPageNumber(pagegroupnum)
          pvu = UTF8ToUTF16BE(pvs, false)
          pk = k.gsub('{nb', '{pnb')
          alias_pga = escape(pk)
          alias_pgau = escape('{' + pk + '}')
          if @is_unicode
            alias_pgb = escape(UTF8ToLatin1(pk))
            alias_pgbu = escape(UTF8ToLatin1('{' + pk + '}'))
            alias_pgc = escape(utf8StrRev(pk, false, rtl_text_dir))
            alias_pgcu = escape(utf8StrRev('{' + pk + '}', false, rtl_text_dir))
          end
          temppage = temppage.gsub(alias_pgau, pvu)
          if @is_unicode
            temppage = temppage.gsub(alias_pgbu, pvu)
            temppage = temppage.gsub(alias_pgcu, pvu)
            temppage = temppage.gsub(alias_pgb, pvs)
            temppage = temppage.gsub(alias_pgc, pvs)
          end
          temppage = temppage.gsub(alias_pga, pvs)
        }
      end
      if @alias_nb_pages
        # replace total pages number
        temppage = temppage.gsub(alias_au, nbu)
        if @is_unicode
          temppage = temppage.gsub(alias_bu, nbu)
          temppage = temppage.gsub(alias_cu, nbu)
          temppage = temppage.gsub(alias_b, nbs)
          temppage = temppage.gsub(alias_c, nbs)
        end
        temppage = temppage.gsub(alias_a, nbs)
      end
      if @alias_num_page
        # replace page number
        pnbs = formatPageNumber(n)
        pnbu = UTF8ToUTF16BE(pnbs, false) # replacement for unicode font
        temppage = temppage.gsub(alias_pau, pnbu)
        if @is_unicode
          temppage = temppage.gsub(alias_pbu, pnbu)
          temppage = temppage.gsub(alias_pcu, pnbu)
          temppage = temppage.gsub(alias_pb, pnbs)
          temppage = temppage.gsub(alias_pc, pnbs)
        end
        temppage = temppage.gsub(alias_pa, pnbs)
      end
      temppage = temppage.gsub(@epsmarker, '')
      #Page
      @page_obj_id[n] = newobj()
      out = '<<'
      out << ' /Type /Page'
      out << ' /Parent 1 0 R'
      out << ' /LastModified ' + datestring()
      out << ' /Resources 2 0 R'

      boxes = ['MediaBox', 'CropBox', 'BleedBox', 'TrimBox', 'ArtBox']
      boxes.each { |box|
        out << ' /' + box
        out << sprintf(' [%.2f %.2f %.2f %.2f]', @pagedim[n][box]['llx'], @pagedim[n][box]['lly'], @pagedim[n][box]['urx'], @pagedim[n][box]['ury'])
      }
      if @pagedim[n]['BoxColorInfo'] and !@pagedim[n]['BoxColorInfo'].empty?
        out << ' /BoxColorInfo <<'
        boxes.each { |box|
          if @pagedim[n]['BoxColorInfo'][box]
            out << ' /' + box + ' <<'
            if @pagedim[n]['BoxColorInfo'][box]['C']
              color = @pagedim[n]['BoxColorInfo'][box]['C']
              out <<= ' /C ['
              out << sprintf(' %.3f %.3f %.3f', color[0]/255.0, color[1]/255.0, color[2]/255.0)
              out << ' ]'
            end
            if @pagedim[n]['BoxColorInfo'][box]['W']
              out << ' /W ' + (@pagedim[n]['BoxColorInfo'][box]['W'] * @k).to_s
            end
            if @pagedim[n]['BoxColorInfo'][box]['S']
              out << ' /S /' + @pagedim[n]['BoxColorInfo'][box]['S']
            end
            if @pagedim[n]['BoxColorInfo'][box]['D']
              dashes = @pagedim[n]['BoxColorInfo'][box]['D']
              out << ' /D ['
              dashes.each { |dash|
                out << sprintf(' %.3f', dash * @k)
              }
              out << ' ]'
            end
            out << ' >>'
          end
        }
        out << ' >>'
      end
      out << ' /Contents ' + (@n + 1).to_s + ' 0 R'
      out << ' /Rotate ' + @pagedim[n]['Rotate'].to_s
      out << ' /Group << /Type /Group /S /Transparency /CS /DeviceRGB >>'
      if @pagedim[n]['trans'] and !@pagedim[n]['trans'].empty?
        # page transitions
        if @pagedim[n]['trans']['Dur']
          out << ' /Dur ' + @pagedim[n]['trans']['Dur']
        end
        out << ' /Trans <<'
        out << ' /Type /Trans'
        if @pagedim[n]['trans']['S']
          out << ' /S /' + @pagedim[n]['trans']['S']
        end
        if @pagedim[n]['trans']['D']
          out << ' /D ' + @pagedim[n]['trans']['D'].to_s
        end
        if @pagedim[n]['trans']['Dm']
          out << ' /Dm /' + @pagedim[n]['trans']['Dm']
        end
        if @pagedim[n]['trans']['M']
          out << ' /M /' + @pagedim[n]['trans']['M']
        end
        if @pagedim[n]['trans']['Di']
          out << ' /Di ' + @pagedim[n]['trans']['Di']
        end
        if @pagedim[n]['trans']['SS']
          out << ' /SS ' + @pagedim[n]['trans']['SS']
        end
        if @pagedim[n]['trans']['B']
          out << ' /B ' + @pagedim[n]['trans']['B']
        end
        out << ' >>'
      end
      out << getannotsrefs(n)
      out << ' /PZ ' + @pagedim[n]['PZ'].to_s
      out << ' >> endobj'

      out(out)
      #Page content
      p=(@compress) ? Zlib::Deflate.deflate(temppage) : temppage
      newobj();
      out('<<' + filter + ' /Length ' + p.length.to_s  + '>> ' + getstream(p) + ' endobj')
      if @diskcache
        # remove temporary files
        File.delete(@pages[n].path)
      end
    end
    #Pages root
    @offsets[1]=@bufferlen
    out = '1 0 obj << /Type /Pages  /Kids ['
    @page_obj_id.each { |page_obj|
      out << ' ' + page_obj.to_s + ' 0 R' unless page_obj.nil?
    }
    out << ' ] /Count ' + nb.to_s + ' >>  endobj'
    out(out)
  end

  #
  # Output references to page annotations
  # [@param int :n] page number
  # [@access protected]
  # [@author] Nicola Asuni
  # [@deprecated]
  # [@since 4.7.000 (2008-08-29)]
  #
  def putannotsrefs(n)
    out(getannotsrefs(n))
  end

  #
  # Get references to page annotations.
  # [@param int :n] page number
  # [@return string]
  # [@access protected]
  # [@author] Nicola Asuni
  # [@since 5.0.010 (2010-05-17)]
  #
  def getannotsrefs(n)
    unless @page_annots[n] or (@sign and @signature_data['cert_type'])
      return ''
    end
    out = ' /Annots ['
    if @page_annots[n]
      num_annots = @page_annots[n].length
      0.upto(num_annots - 1) do |i|
        @curr_annot_obj_id += 1
        if !@radio_groups.include?(@curr_annot_obj_id)
          out << ' ' + @curr_annot_obj_id.to_s + ' 0 R'
        else
          num_annots += 1
        end
      end
    end

    if (n == 1) and @sign and @signature_data['cert_type']
      # set reference for signature object
      out << ' ' + @sig_annot_ref
    end
    out << ' ]'
    return out
  end

  #
  # Output annotations objects for all pages.
  # * !!! THIS METHOD IS NOT YET COMPLETED !!!
  # * See section 12.5 of PDF 32000_2008 reference.
  # [@access protected]
  # [@author] Nicola Asuni
  # [@since 4.0.018 (2008-08-06)]
  #
  def putannotsobjs()
    # reset object counter
    @annot_obj_id = @annots_start_obj_id
    1.upto(@numpages) do |n|
      if !@page_annots[n].nil?
        # set page annotations
        @page_annots[n].each_with_index { |pl, key|
          # create annotation object for grouping radiobuttons
          if @radiobutton_groups[n] and @radiobutton_groups[n][pl['txt']] and @radiobutton_groups[n][pl['txt']].is_a?(Array)
            annots = '<<'
            annots << ' /Type /Annot'
            annots << ' /Subtype /Widget'
            annots << ' /T ' + dataannobjstring(pl['txt'])
            annots << ' /FT /Btn'
            annots << ' /Ff 49152'
            annots << ' /Kids ['
            defval = nil
            @radiobutton_groups[n][pl['txt']].each {|data|
              annots << " #{data['kid']} 0 R"
              if data['def'] != 'Off'
                defval = data['def']
              end
            }
            annots << ' ]'
            annots << " /V /#{defval}" if defval
            annots << ' >>'
            @annot_obj_id += 1
            @offsets[@annot_obj_id] = @bufferlen
            out("#{@annot_obj_id} 0 obj #{annots} endobj")
            @form_obj_id << @annot_obj_id
            # store object id to be used on Parent entry of Kids
            @radiobutton_groups[n][pl['txt']] = @annot_obj_id
          end

          formfield = false
          pl['opt'] = pl['opt'].inject({}) do |pl_opt, keys|
            pl_opt[keys[0].downcase] = keys[1]
            pl_opt
          end
          a = pl['x'] * @k
          b = @pagedim[n]['h'] - ((pl['y'] + pl['h'])  * @k)
          c = pl['w'] * @k
          d = pl['h'] * @k
          rect = sprintf('%.2f %.2f %.2f %.2f', a, b, a + c, b + d)
          # create new annotation object
          annots = '<</Type /Annot'
          annots << ' /Subtype /' + pl['opt']['subtype']
          annots << ' /Rect [' + rect + ']'
          ft = ['Btn', 'Tx', 'Ch', 'Sig']
          if pl['opt']['ft'] and ft.include?(pl['opt']['ft'])
            annots << ' /FT /' + pl['opt']['ft']
            formfield = true
          end
          annots << ' /Contents ' + textannobjstring(pl['txt'])
          annots << ' /P ' + @page_obj_id[n].to_s + ' 0 R'
          annots << ' /NM ' + dataannobjstring(sprintf('%04u-%04u', n, key))
          annots << ' /M ' + datestring()
          if !pl['opt']['f'].nil?
            val = 0
            if pl['opt']['f'].is_a?(Array)
              pl['opt']['f'].each {|f|
                case f.downcase
                when 'invisible'
                  val += 1 << 0
                when 'hidden'
                  val += 1 << 1
                when 'print'
                  val += 1 << 2
                when 'nozoom'
                  val += 1 << 3
                when 'norotate'
                  val += 1 << 4
                when 'noview'
                  val += 1 << 5
                when 'readonly'
                  val += 1 << 6
                when 'locked'
                  val += 1 << 8
                when 'togglenoview'
                  val += 1 << 9
                when 'lockedcontents'
                  val += 1 << 10
                end
              }
            else
              val = pl['opt']['f'].to_i
            end
            annots << " /F #{val}"
          end
          # annots << ' /AP '
          # annots << ' /AS '
          if pl['opt']['as'] and pl['opt']['as'].is_a?(String)
            annots << ' /AS /' + pl['opt']['as']
          end
          if pl['opt']['ap']
            # appearance stream
            annots << ' /AP <<'
            if pl['opt']['ap'].is_a?(Hash)
              pl['opt']['ap'].each {|apmode, apdef|
                # apmode can be: n = normal; r = rollover; d = down
                annots << ' /' + apmode.upcase
                if apdef.is_a?(Hash)
                  annots << ' <<'
                  apdef.each {|apstate, stream|
                    # reference to XObject that define the appearance for this mode-state
                    apsobjid = putAPXObject(c, d, stream)
                    annots << " /#{apstate} #{apsobjid} 0 R"
                  }
                  annots << ' >>'
                else
                  # reference to XObject that define the appearance for this mode
                  apsobjid = putAPXObject(c, d, apdef)
                  annots << " #{apsobjid} 0 R"
                end
              }
            else
              annots << pl['opt']['ap']
            end
            annots << ' >>'
          end
          if !pl['opt']['bs'].nil? and pl['opt']['bs'].is_a?(Hash)
            annots << ' /BS <<'
            annots << ' /Type /Border'
            if !pl['opt']['bs']['w'].nil?
              annots << " /W #{pl['opt']['bs']['w']}"
            end
            bstyles = ['S', 'D', 'B', 'I', 'U']
            if !pl['opt']['bs']['s'].nil? and bstyles.include?(pl['opt']['bs']['s'])
              annots << ' /S /' + pl['opt']['bs']['s']
            end
            if !pl['opt']['bs']['d'].nil? and pl['opt']['bs']['d'].is_a?(Array)
              annots << ' /D ['
              pl['opt']['bs']['d'].each {|cord|
                annots << ' ' + cord.to_i.to_s
              }
              annots << ']'
            end
            annots << ' >>'
          else
            annots << ' /Border ['
            if !pl['opt']['border'].nil? and (pl['opt']['border'].length >= 3)
              annots << pl['opt']['border'][0].to_i + ' '
              annots << pl['opt']['border'][1].to_i + ' '
              annots << pl['opt']['border'][2].to_i
              if pl['opt']['border'][3].nil? and pl['opt']['border'][3].is_a?(Array)
                annots << ' ['
                pl['opt']['border'][3].each {|dash|
                  annots << dash.to_i + ' '
                }
                annots << ']'
              end
            else
              annots << '0 0 0'
            end
            annots << ']'
          end
          if !pl['opt']['be'].nil? and pl['opt']['be'].is_a?(Hash)
            annots << ' /BE <<'
            bstyles = ['S', 'C']
            if !pl['opt']['be']['s'].nil? and markups.include?(pl['opt']['be']['s'])
              annots << ' /S /' + pl['opt']['bs']['s']
            else
              annots << ' /S /S'
            end
            if !pl['opt']['be']['i'].nil? and (pl['opt']['be']['i'] >= 0) and (pl['opt']['be']['i'] <= 2)
              annots << ' /I ' + sprintf(" %.4f", pl['opt']['be']['i'])
            end
            annots << '>>'
          end
          if !pl['opt']['c'].nil? and pl['opt']['c'].is_a?(Array) and !pl['opt']['c'].empty?
            annots << ' /C ['
            pl['opt']['c'].each {|col|
              col = col.to_i
              color = col <= 0 ? 0 : (col >= 255 ? 1 : col / 255.0)
              annots << sprintf(" %.4f", color)
            }
            annots << ']'
          end
          # annots << ' /StructParent '
          # annots << ' /OC '
          markups = ['text', 'freetext', 'line', 'square', 'circle', 'polygon', 'polyline', 'highlight',  'underline', 'squiggly', 'strikeout', 'stamp', 'caret', 'ink', 'fileattachment', 'sound']
          if markups.include?(pl['opt']['subtype'].downcase)
            # this is a markup type
            if !pl['opt']['t'].nil? and pl['opt']['t'].is_a?(String)
              annots << ' /T ' + textannobjstring(pl['opt']['t'])
            end
            # annots << ' /Popup '
            if !pl['opt']['ca'].nil?
              annots << ' /CA ' + sprintf("%.4f", pl['opt']['ca'].to_f)
            end
            if !pl['opt']['rc'].nil?
              annots << ' /RC ' + textannobjstring(pl['opt']['rc'])
            end
            annots << ' /CreationDate ' + datestring()
            # annots << ' /IRT '
            if !pl['opt']['subj'].nil?
              annots << ' /Subj ' + textannobjstring(pl['opt']['subj'])
            end
            # annots << ' /RT '
            # annots << ' /IT '
            # annots << ' /ExData '
          end

          lineendings = ['Square', 'Circle', 'Diamond', 'OpenArrow', 'ClosedArrow', 'None', 'Butt', 'ROpenArrow', 'RClosedArrow', 'Slash']
          # Annotation types
          case pl['opt']['subtype'].downcase
          when 'text'
            if !pl['opt']['open'].nil?
              annots << ' /Open ' + (pl['opt']['open'].downcase == 'true' ? 'true' : 'false')
            end
            iconsapp = ['Comment', 'Help', 'Insert', 'Key', 'NewParagraph', 'Note', 'Paragraph']
            if !pl['opt']['name'].nil? and iconsapp.include?(pl['opt']['name'])
              annots << ' /Name /' + pl['opt']['name']
            else
              annots << ' /Name /Note'
            end
            statemodels = ['Marked', 'Review']
            if !pl['opt']['statemodel'].nil? and statemodels.include?(pl['opt']['statemodel'])
              annots << ' /StateModel /' + pl['opt']['statemodel']
            else
              pl['opt']['statemodel'] = 'Marked'
              annots << ' /StateModel /' + pl['opt']['statemodel']
            end
            if pl['opt']['statemodel'] == 'Marked'
              states = ['Accepted', 'Unmarked']
            else
              states = ['Accepted', 'Rejected', 'Cancelled', 'Completed', 'None']
            end
            if !pl['opt']['state'].nil? and states.include?(pl['opt']['state'])
              annots << ' /State /' + pl['opt']['state']
            else
              if pl['opt']['statemodel'] == 'Marked'
                annots << ' /State /Unmarked'
              else
                annots << ' /State /None'
              end
            end
          when 'link'
            if pl['txt'].is_a?(String)
              # external URI link
              annots << ' /A <</S /URI /URI ' + dataannobjstring(unhtmlentities(pl['txt'])) + '>>'
            else
              # internal link
              l = @links[pl['txt']]
              annots << sprintf(' /Dest [%d 0 R /XYZ 0 %.2f null]', 1 + (2 * l[0]), @pagedim[l[0]]['h'] - (l[1] * @k))
            end
            hmodes = ['N', 'I', 'O', 'P']
            if !pl['opt']['h'].nil? and hmodes.include?(pl['opt']['h'])
              annots << ' /H /' + pl['opt']['h']
            else
              annots << ' /H /I'
            end
            # annots << ' /PA '
            # annots << ' /Quadpoints '
          when 'freetext'
            if pl['opt']['da'] and !pl['opt']['da'].empty?
              annots << ' /DA (' + pl['opt']['da'] + ')'
            end
            if !pl['opt']['q'].nil? and (pl['opt']['q'] >= 0) and (pl['opt']['q'] <= 2)
              annots << ' /Q ' + pl['opt']['q'].to_i
            end
            if !pl['opt']['rc'].nil?
              annots << ' /RC ' + textannobjstring(pl['opt']['rc'])
            end
            if !pl['opt']['ds'].nil?
              annots << ' /DS ' + textannobjstring(pl['opt']['ds'])
            end
            if !['opt']['cl'].nil? and pl['opt']['cl'].is_a?(Array)
              annots << ' /CL ['
              pl['opt']['cl'].each {|cl|
                annots << sprintf("%.4f ", cl * @k)
              }
              annots << ']'
            end
            tfit = ['FreeText', 'FreeTextCallout', 'FreeTextTypeWriter']
            if !pl['opt']['it'].nil? and tfit.include?(pl['opt']['it'])
              annots << ' /IT /' + pl['opt']['it']
            end
            if !pl['opt']['rd'].nil? and pl['opt']['rd'].is_a?(Array)
              l = pl['opt']['rd'][0] * @k
              r = pl['opt']['rd'][1] * @k
              t = pl['opt']['rd'][2] * @k
              b = pl['opt']['rd'][3] * @k
              annots << ' /RD [' + sprintf('%.2f %.2f %.2f %.2f', l, r, t, b) + ']'
            end
            if pl['opt']['le'] and lineendings.include?(pl['opt']['le'])
              annots << ' /LE /' + pl['opt']['le']
            end
          # ... to be completed ...
          when 'fileattachment'
            if pl['opt']['fs'].nil?
              break
            end
            filename = File.basename(pl['opt']['fs'])
            if !@embeddedfiles[filename]['n'].nil?
              annots << ' /FS <</Type /Filespec /F ' + dataannobjstring(filename) + ' /EF <</F ' + @embeddedfiles[filename]['n'].to_s + ' 0 R>> >>'
              iconsapp = ['Graph', 'Paperclip', 'PushPin', 'Tag']
              if !pl['opt']['name'].nil? and iconsapp.include?(pl['opt']['name'])
                annots << ' /Name /' + pl['opt']['name']
              else
                annots << ' /Name /PushPin'
              end
            end
          when 'sound'
            if pl['opt']['fs'].nil?
              break
            end
            filename = File.basename(pl['opt']['fs'])
            if !@embeddedfiles[filename]['n'].nil?
              # ... TO BE COMPLETED ...
              # /R /C /B /E /CO /CP
              annots << ' /Sound <</Type /Filespec /F ' + dataannobjstring(filename) + ' /EF <</F ' + @embeddedfiles[filename]['n'] + ' 0 R>> >>'
              iconsapp = ['Speaker', 'Mic']
              if !pl['opt']['name'].nil? and iconsapp.include?(pl['opt']['name'])
                annots << ' /Name /' + pl['opt']['name']
              else
                annots << ' /Name /Speaker'
              end
            end
          when 'widget'
            hmode = ['N', 'I', 'O', 'P', 'T']
            if pl['opt']['h'] and hmode.include?(pl['opt']['h'])
              annots << ' /H /' + pl['opt']['h']
            end
            if pl['opt']['mk'] and pl['opt']['mk'].is_a?(Hash) and !pl['opt']['mk'].empty?
              annots << ' /MK <<'
              if pl['opt']['mk']['r']
                annots << ' /R ' + pl['opt']['mk']['r']
              end
              if pl['opt']['mk']['bc'] and (pl['opt']['mk']['bc'] != false)
                annots << ' /BC ['
                pl['opt']['mk']['bc'].each {|col|
                  col = col.to_i
                  color = col <= 0 ? 0 : (col >= 255 ? 1 : col / 255.0)
                  annots << sprintf(' %.2f', color)
                }
                annots << ']'
              end
              if pl['opt']['mk']['bg'] and (pl['opt']['mk']['bg'] != false)
                annots << ' /BG ['
                pl['opt']['mk']['bg'].each {|col|
                  col = col.to_i
                  color = col <= 0 ? 0 : (col >= 255 ? 1 : col / 255.0)
                  annots << sprintf(' %.2f', color)
                }
                annots << ']'
              end
              if pl['opt']['mk']['ca']
                annots << ' /CA ' + pl['opt']['mk']['ca'] + ''
              end
              if pl['opt']['mk']['rc']
                annots << ' /RC ' + pl['opt']['mk']['ca'] + ''
              end
              if pl['opt']['mk']['ac']
                annots << ' /AC ' + pl['opt']['mk']['ca'] + ''
              end
              if pl['opt']['mk']['i']
                info = getImageBuffer(pl['opt']['mk']['i'])
                if info != false
                  annots << ' /I ' + info['n'] + ' 0 R'
                end
              end
              if pl['opt']['mk']['ri']
                info = getImageBuffer(pl['opt']['mk']['ri'])
                if info != false
                  annots << ' /RI ' + info['n'] + ' 0 R'
                end
              end
              if pl['opt']['mk']['ix']
                info = getImageBuffer(pl['opt']['mk']['ix'])
                if info != false
                  annots << ' /IX ' + info['n'] + ' 0 R'
                end
              end
              if pl['opt']['mk']['if'] and pl['opt']['mk']['if'].is_a?(Hash) and !pl['opt']['mk']['if'].empty?
                annots << ' /IF <<'
                if_sw = ['A', 'B', 'S', 'N']
                if pl['opt']['mk']['if']['sw'] and if_sw.include?(pl['opt']['mk']['if']['sw'])
                  annots << ' /SW /' + pl['opt']['mk']['if']['sw']
                end
                if_s = ['A', 'P']
                if pl['opt']['mk']['if']['s'] and if_s.include?(pl['opt']['mk']['if']['s'])
                  annots << ' /S /' + pl['opt']['mk']['if']['s']
                end
                if pl['opt']['mk']['if']['a'] and pl['opt']['mk']['if']['a'].is_a?(Array) and !pl['opt']['mk']['if']['a'].empty?
                  annots << sprintf(' /A [%.2f  %.2f]', pl['opt']['mk']['if']['a'][0], pl['opt']['mk']['if']['a'][1])
                end
                if pl['opt']['mk']['if']['fb'] and pl['opt']['mk']['if']['fb']
                  annots << ' /FB true'
                end
                annots << '>>'
              end
              if pl['opt']['mk']['tp'] and (pl['opt']['mk']['tp'] >= 0) and (pl['opt']['mk']['tp'] <= 6)
                annots << ' /TP ' + pl['opt']['mk']['tp']
              else
                annots << ' /TP 0'
              end
              annots << '>>'
            end # end MK

            # --- Entries for field dictionaries ---
            if @radiobutton_groups[n] and @radiobutton_groups[n][pl['txt']]
              # set parent
              annots << " /Parent #{@radiobutton_groups[n][pl['txt']]} 0 R"
            end
            if pl['opt']['t'] and pl['opt']['t'].is_a?(String)
              annots << ' /T ' + dataannobjstring(pl['opt']['t'])
            end
            if pl['opt']['tu'] and pl['opt']['tu'].is_a?(String)
              annots << ' /TU ' + dataannobjstring(pl['opt']['tu'])
            end
            if pl['opt']['tm'] and pl['opt']['tm'].is_a?(String)
              annots << ' /TM ' + dataannobjstring(pl['opt']['tm'])
            end
            if pl['opt']['ff']
              if pl['opt']['ff'].is_a?(Array)
                # array of bit settings
                flag = 0
                pl['opt']['ff'].each {|val|
                  flag += 1 << (val - 1)
                }
              else
                flag = pl['opt']['ff'].to_i
              end
              annots << " /Ff #{flag}"
            end
            if pl['opt']['maxlen']
              annots << ' /MaxLen ' + pl['opt']['maxlen'].to_i.to_s
            end
            if pl['opt']['v']
              annots << ' /V'
              if pl['opt']['v'].is_a?(Array)
                pl['opt']['v'].each { |optval|
                  if optval.is_a? Float
                    optval = sprintf('%.2f', optval)
                  end
                  annots << ' ' + optval
                }
              else
                annots << ' ' + textannobjstring(pl['opt']['v'])
              end
            end
            if pl['opt']['dv']
              annots << ' /DV'
              if pl['opt']['dv'].is_a?(Array)
                pl['opt']['dv'].eath {|optval|
                  if optval.is_a? Float
                    optval = sprintf('%.2f', optval)
                  end
                  annots << ' ' + optval
                }
              else
                annots << ' ' + textannobjstring(pl['opt']['dv'])
              end
            end
            if pl['opt']['rv']
              annots << ' /RV'
              if pl['opt']['rv'].is_a?(Array)
                pl['opt']['rv'].eath {|optval|
                  if optval.is_a? Float
                    optval = sprintf('%.2f', optval)
                  end
                  annots << ' ' + optval
                }
              else
                annots << ' ' + textannobjstring(pl['opt']['rv'])
              end
            end
            if pl['opt']['a'] and !pl['opt']['a'].empty?
              annots << ' /A << ' + pl['opt']['a'] + ' >>'
            end
            if pl['opt']['aa'] and !pl['opt']['aa'].empty?
              annots << ' /AA << ' + pl['opt']['aa'] + ' >>'
            end
            if pl['opt']['da'] and !pl['opt']['da'].empty?
              annots << ' /DA (' + pl['opt']['da'] + ')'
            end
            if pl['opt']['q'] and (pl['opt']['q'] >= 0) and (pl['opt']['q'] <= 2)
              annots << ' /Q ' + pl['opt']['q'].to_i.to_s
            end
            if pl['opt']['opt'] and pl['opt']['opt'].is_a?(Array) and !pl['opt']['opt'].empty?
              annots << ' /Opt ['
              pl['opt']['opt'].each {|copt|
                if copt.is_a?(Array)
                  annots << ' [' + textannobjstring(copt[0]) + ' ' + textannobjstring(copt[1]) + ']'
                else
                  annots << ' ' + textannobjstring(copt)
                end
              }
              annots << ']'
            end
            if pl['opt']['ti']
              annots << ' /TI ' + pl['opt']['ti'].to_i.to_s
            end
            if pl['opt']['i'] and pl['opt']['i'].is_a?(Array) and !pl['opt']['i'].empty?
              annots << ' /I ['
              pl['opt']['i'].each {|copt|
                annots << copt.to_i.to_s + ' '
              }
              annots << ']'
            end
          else
          end

          annots << '>>'
          # create new annotation object
          @annot_obj_id += 1
          @offsets[@annot_obj_id] = @bufferlen
          out(@annot_obj_id.to_s + ' 0 obj ' + annots + ' endobj')

          if formfield and !(@radiobutton_groups[n] and @radiobutton_groups[n][pl['txt']])
            # store reference of form object
            @form_obj_id << @annot_obj_id
          end
        }
      end # end for each page
    end
  end

  #
  # Put appearance streams XObject used to define annotation's appearance states
  # [@param int :w] annotation width
  # [@param int :h] annotation height
  # [@param string :stream] appearance stream
  # [@return int] object ID
  # [@access protected]
  # [@since 4.8.001 (2009-09-09)]
  #
  def putAPXObject(w=0, h=0, stream='')
    stream = stream.strip
    @apxo_obj_id += 1
    @offsets[@apxo_obj_id] = @bufferlen
    out = @apxo_obj_id.to_s + ' 0 obj'
    out << ' <<'
    out << ' /Type /XObject'
    out << ' /Subtype /Form'
    out << ' /FormType 1'
    if @compress
      stream = Zlib::Deflate.deflate(stream)
      out << ' /Filter /FlateDecode'
    end
    rect = sprintf('%.2f %.2f', w, h)
    out << ' /BBox [0 0 ' + rect + ']'
    out << ' /Matrix [1 0 0 1 0 0]'
    out << ' /Resources 2 0 R'
    out << ' /Length ' + stream.length.to_s
    out << ' >>'
    out << ' ' + getstream(stream)
    out << ' endobj'
    out(out)
    return @apxo_obj_id
  end

  #
  # Get ULONG from string (Big Endian 32-bit unsigned integer).
  # [@parameter string :str] string from where to extract value
  # [@parameter int :offset] point from where to read the data
  # [@return int] 32 bit value
  # [@author Nicola Asuni]
  # [@access protected]
  # [@since 5.2.000 (2010-06-02)]
  #
  def getULONG(str, offset)
    v = str[offset, 4].unpack('N')
    return v[0].to_i
  end

  #
  # Get USHORT from string (Big Endian 16-bit unsigned integer).
  # [@parameter string :str] string from where to extract value
  # [@parameter int :offset] point from where to read the data
  # [@return int] 16 bit value
  # [@author Nicola Asuni]
  # [@access protected]
  # [@since 5.2.000 (2010-06-02)]
  #
  def getUSHORT(str, offset)
    v = str[offset, 2].unpack('n')
    return v[0].to_i
  end

  #
  # Get SHORT from string (Big Endian 16-bit signed integer).
  # [@parameter string :str] string from where to extract value
  # [@parameter int :offset] point from where to read the data
  # [@return int] 16 bit value
  # [@author Nicola Asuni]
  # [@access protected]
  # [@since 5.2.000 (2010-06-02)]
  #
  def getSHORT(str, offset)
    v = str[offset, 2].unpack('s')
    return v[0].to_i
  end

  #
  # Get BYTE from string (8-bit unsigned integer).
  # [@parameter string :str] string from where to extract value
  # [@parameter int :offset] point from where to read the data
  # [@return int] 8 bit value
  # [@author Nicola Asuni]
  # [@access protected]
  # [@since 5.2.000 (2010-06-02)]
  #
  def getBYTE(str, offset)
    v = str[offset, 1].unpack('C')
    return v[0].to_i
  end

  #
  # Returns a subset of the TrueType font data without the unused glyphs.
  # [@parameter string :font] TrueType font data
  # [@parameter array :subsetchars] array of used characters (the glyphs to keep)
  # [@return string] a subset of TrueType font data without the unused glyphs
  # [@author Nicola Asuni]
  # [@access protected]
  # [@since 5.2.000 (2010-06-02)]
  #
  def getTrueTypeFontSubset(font, subsetchars)
    #ksort(subsetchars)
    offset = 0 # offset position of the font data
    if getULONG(font, offset) != 0x10000
      # sfnt version must be 0x00010000 for TrueType version 1.0.
      return font
    end
    offset += 4

    # get number of tables
    numTables = getUSHORT(font, offset); offset += 2
    # skip searchRange, entrySelector and rangeShift
    offset += 6
    # tables array(Hash)
    table = {}
    # for each table
    numTables.times {
      # get table info
      tag = font[offset, 4]
      offset += 4

      table[tag] = {}
      table[tag]['checkSum'] = getULONG(font, offset); offset += 4
      table[tag]['offset'] = getULONG(font, offset); offset += 4
      table[tag]['length'] = getULONG(font, offset); offset += 4
    }
    # check magicNumber
    offset = table['head']['offset'] + 12
    if getULONG(font, offset) != 0x5F0F3CF5
      # magicNumber must be 0x5F0F3CF5
      return font
    end
    offset += 4

    # get offset mode (indexToLocFormat : 0 = short, 1 = long)
    offset = table['head']['offset'] + 50
    short_offset = (getSHORT(font, offset) == 0); offset += 2
    # get the offsets to the locations of the glyphs in the font, relative to the beginning of the glyphData table
    indexToLoc = []
    offset = table['loca']['offset']
    if short_offset
      # short version
      n = table['loca']['length'] / 2 # numGlyphs + 1
      n.times {|i|
        indexToLoc[i] = getUSHORT(font, offset) * 2; offset += 2
      }
    else
      # long version
      n = table['loca']['length'] / 4 # numGlyphs + 1
      n.times {|i|
        indexToLoc[i] = getULONG(font, offset); offset += 4
      }
    end
    # get glyphs indexes of chars from cmap table
    subsetglyphs = [] # glyph IDs on key
    subsetglyphs[0] = true # character codes that do not correspond to any glyph in the font should be mapped to glyph index 0
    offset = table['cmap']['offset'] + 2
    numEncodingTables = getUSHORT(font, offset); offset += 2
    encodingTables = []
    numEncodingTables.times {|i|
      encodingTables[i] ||= {}
      encodingTables[i]['platformID'] = getUSHORT(font, offset); offset += 2
      encodingTables[i]['encodingID'] = getUSHORT(font, offset); offset += 2
      encodingTables[i]['offset'] = getULONG(font, offset); offset += 4
    }
    encodingTables.each {|enctable|
      if (enctable['platformID'] == 3) and (enctable['encodingID'] == 0)
        modesymbol = true
      else
        modesymbol = false
      end
      offset = table['cmap']['offset'] + enctable['offset']
      format = getUSHORT(font, offset); offset += 2
      case format
      when 0 # Format 0: Byte encoding table
        offset += 4 # skip length and version/language
        256.times {|k|
          if subsetchars[k]
            g = getBYTE(font, offset); offset += 1
            subsetglyphs[g] = k
          else
            offset += 1
          end
        }
      when 2 # Format 2: High-byte mapping through table
        offset += 4 # skip length and version
        # to be implemented ...
      when 4 # Format 4: Segment mapping to delta values
        length = getUSHORT(font, offset); offset += 2
        offset += 2 # skip version/language
        segCount = getUSHORT(font, offset) / 2; offset += 2
        offset += 6 # skip searchRange, entrySelector, rangeShift
        endCount = [] # array of end character codes for each segment
        segCount.times {|k|
          endCount[k] = getUSHORT(font, offset); offset += 2
        }
        offset += 2 # skip reservedPad
        startCount = [] # array of start character codes for each segment
        segCount.times {|k|
          startCount[k] = getUSHORT(font, offset); offset += 2
        }
        idDelta = [] # delta for all character codes in segment
        segCount.times {|k|
          idDelta[k] = getUSHORT(font, offset); offset += 2
        }
        idRangeOffset = [] # Offsets into glyphIdArray or 0
        segCount.times {|k|
            idRangeOffset[k] = getUSHORT(font, offset); offset += 2
        }
        gidlen = (length / 2) - 8 - (4 * segCount)
        glyphIdArray = [] # glyph index array
        gidlen.times {|k|
          glyphIdArray[k] = getUSHORT(font, offset); offset += 2
        }
        segCount.times {|k|
          startCount[k].upto(endCount[k]) {|c|
            if subsetchars[c]
              if idRangeOffset[k] == 0
                g = c
              else
                gid = (idRangeOffset[k] / 2) + (c - startCount[k]) - (segCount - k)
                g = glyphIdArray[gid]
              end
              g += (idDelta[k] - 65536)
              if g < 0
                g = 0
              end
              subsetglyphs[g] = c
            end
          }
        }
      when 6 # Format 6: Trimmed table mapping
        offset += 4 # skip length and version/language
        firstCode = getUSHORT(font, offset); offset += 2
        entryCount = getUSHORT(font, offset); offset += 2
        entryCount.times {|k|
          c = k + firstCode
          if subsetchars[c]
            g = getUSHORT(font, offset); offset += 2
            subsetglyphs[g] = c
          else
            offset += 2
          end
        }
      when 8 # Format 8: Mixed 16-bit and 32-bit coverage
        offset += 10 # skip length and version
        # to be implemented ...
      when 10 # Format 10: Trimmed array
        offset += 10 # skip length and version/language
        startCharCode = getULONG(font, offset); offset += 4
        numChars = getULONG(font, offset); offset += 4
        numChars.times {|k|
          c = k + startCharCode
          if subsetchars[c]
            g = getUSHORT(font, offset); offset += 2
            subsetglyphs[g] = c
          else
            offset += 2
          end
        }
      when 12 # Format 12: Segmented coverage
        offset += 10 # skip length and version/language
        nGroups = getULONG(font, offset); offset += 4
        nGroups.times {|k|
          startCharCode = getULONG(font, offset); offset += 4
          endCharCode = getULONG(font, offset); offset += 4
          startGlyphCode = getULONG(font, offset); offset += 4
          startCharCode.upto(endCharCode) {|c|
            if subsetchars[c]
              subsetglyphs[startGlyphCode] = c
            end
            startGlyphCode += 1
          }
        }
      end
    }
    # sort glyphs by key
    #ksort(subsetglyphs)
    # add composite glyps to subsetglyphs and remove missing glyphs
    subsetglyphs_tmp = []
    subsetglyphs.each_with_index {|val, key|
      next if val.nil?

      if indexToLoc[key]
        subsetglyphs_tmp[key] = val
        offset = table['glyf']['offset'] + indexToLoc[key]
        numberOfContours = getSHORT(font, offset); offset += 2
        if numberOfContours < 0  # composite glyph
          offset += 8 # skip xMin, yMin, xMax, yMax
          loop {
            flags = getUSHORT(font, offset); offset += 2
            glyphIndex = getUSHORT(font, offset); offset += 2
            if subsetglyphs[glyphIndex].nil? and indexToLoc[glyphIndex]
              # add missing glyphs
              subsetglyphs_tmp[glyphIndex] = true
            end
            # skip some bytes by case
            if (flags & 1) != 0
              offset += 4
            else
              offset += 2
            end
            if (flags & 8) != 0
              offset += 2
            elsif (flags & 64) != 0
              offset += 4
            elsif (flags & 128) != 0
              offset += 8
            end

            break if (flags & 32) == 0
          }
        end
      end
    }
    subsetglyphs = subsetglyphs_tmp

    # build new glyf table with only used glyphs
    glyf = ''
    glyfSize = 0
    # create new empty indexToLoc table
    newIndexToLoc = Array.new(indexToLoc.length, 0)
    goffset = 0
    subsetglyphs.each_with_index {|char, glyphID|
      next if char.nil?
      if indexToLoc[glyphID] and indexToLoc[glyphID + 1]
        start = indexToLoc[glyphID]
        length = indexToLoc[glyphID + 1] - start
        glyf << font[table['glyf']['offset'] + start, length]
        newIndexToLoc[glyphID] = goffset
        goffset += length
      end
    }
    # build new loca table
    loca = ''
    if short_offset
      newIndexToLoc.each {|offset|
        loca << [offset / 2].pack('n')
      }
    else
      newIndexToLoc.each {|offset|
        loca << [offset].pack('N')
      }
    end
    # array of table names to preserve (loca and glyf tables will be added later)
    # table_names = ['cmap', 'head', 'hhea', 'hmtx', 'maxp', 'name', 'OS/2', 'post', 'cvt ', 'fpgm', 'prep']
    table_names = ['head', 'hhea', 'hmtx', 'maxp', 'OS/2', 'cvt ', 'fpgm', 'prep']
    # get the tables to preserve
    offset = 12
    table.each {|tag, val|
      if table_names.include?(tag)
        table[tag]['data'] = font[table[tag]['offset'], table[tag]['length']]
        if tag == 'head'
          # set the checkSumAdjustment to 0
          table[tag]['data'] = table[tag]['data'][0, 8] + "\x0\x0\x0\x0" + table[tag]['data'][12..-1]
        end
        pad = 4 - (table[tag]['length'] % 4)
        if pad != 4
          # the length of a table must be a multiple of four bytes
          table[tag]['length'] += pad
          table[tag]['data'] << "\x0" * pad
        end
        table[tag]['offset'] = offset
        offset += table[tag]['length']
        # table[tag]['checkSum'] = getTTFtableChecksum(table[tag]['data'], table[tag]['length'])
      else
        table.delete(tag)
      end
    }
    # add loca

    table['loca'] = {}
    table['loca']['data'] = loca
    table['loca']['length'] = loca.length
    pad = 4 - (table['loca']['length'] % 4)
    if pad != 4
      # the length of a table must be a multiple of four bytes
      table['loca']['length'] += pad
      table['loca']['data'] << "\x0" * pad
    end
    table['loca']['offset'] = offset
    table['loca']['checkSum'] = getTTFtableChecksum(table['loca']['data'], table['loca']['length'])
    offset += table['loca']['length']
    # add glyf
    table['glyf'] = {}
    table['glyf']['data'] = glyf
    table['glyf']['length'] = glyf.length
    pad = 4 - (table['glyf']['length'] % 4)
    if pad != 4
      # the length of a table must be a multiple of four bytes
      table['glyf']['length'] += pad
      table['glyf']['data'] << "\x0" * pad
    end
    table['glyf']['offset'] = offset
    table['glyf']['checkSum'] = getTTFtableChecksum(table['glyf']['data'], table['glyf']['length'])
    # rebuild font
    font = ''
    font << [0x10000].pack('N') # sfnt version
    numTables = table.length
    font << [numTables].pack('n') # numTables
    entrySelector = (Math.log(numTables) / Math.log(2.0)).floor

    searchRange = 2 ** entrySelector * 16
    rangeShift = numTables * 16 - searchRange
    font << [searchRange].pack('n') # searchRange
    font << [entrySelector].pack('n') # entrySelector
    font << [rangeShift].pack('n') # rangeShift
    offset = numTables * 16
    table.each{|tag, data|
      font << tag # tag
      font << [data['checkSum']].pack('N') # checkSum
      font << [data['offset'] + offset].pack('N') # offset
      font << [data['length']].pack('N') # length
    }
    table.each{|tag, data|
      font << data['data']
    }
    # set checkSumAdjustment on head table
    checkSumAdjustment = 0xB1B0AFBA - getTTFtableChecksum(font, font.length)
    font = font[0, table['head']['offset'] + 8] + [checkSumAdjustment].pack('N') + font[(table['head']['offset'] + 12)..-1]
    return font
  end

  #
  # Returs the checksum of a TTF table.
  # [@parameter string :table] table to check
  # [@parameter int :length] lenght of table in bytes
  # [@return int] checksum
  # [@author Nicola Asuni]
  # [@access protected]
  # [@since 5.2.000 (2010-06-02)]
  #
  def getTTFtableChecksum(table, length)
    sum = 0
    tlen = length / 4
    offset = 0
    tlen.times {
      v = table[offset, 4].unpack('N')
      sum += v[0]
      offset += 4
    }
    sum %= 0x100000000
    sum = [sum].pack('N').unpack('N')
    return sum[0]
  end

  #
  # Outputs font widths
  # [@parameter array :font] font data
  # [@parameter int :cidoffset] offset for CID values
  # [@return] PDF command string for font widths
  # [@author] Nicola Asuni
  # [@access protected]
  # [@since 4.4.000 (2008-12-07)]
  #
  def putfontwidths(font, cidoffset=0)
    font_cw = font['cw'].sort
    rangeid = 0
    range = []
    prevcid = -2
    prevwidth = -1
    interval = false
    range_interval = []
    # for each character
    font_cw.each {|cid, width|
      cid -= cidoffset
      if font['subset'] and (cid > 255) and font['subsetchars'][cid].nil?
        # ignore the unused characters (font subsetting)
        next
      end
      if width != font['dw']
        if cid == prevcid + 1
          # consecutive CID
          if width == prevwidth
            if width == range[rangeid][0]
              range[rangeid].push width
            else
              range[rangeid].pop
              # new range
              rangeid = prevcid
              range[rangeid] = []
              range[rangeid].push prevwidth
              range[rangeid].push width
            end
            interval = true
            range_interval[rangeid] = true
          else
            if interval
              # new range
              rangeid = cid
              range[rangeid] = []
              range[rangeid].push width
            else
              range[rangeid].push width
            end
            interval = false
          end
        else
          # new range
          rangeid = cid
          range[rangeid] = []
          range[rangeid].push width
          interval = false
        end
        prevcid = cid
        prevwidth = width
      end
    }
    # optimize ranges
    prevk = -1
    nextk = -1
    prevint = false
    range.each_with_index {|ws, k|
      cws = ws ? ws.length : 0
      if (k == nextk) and !prevint and (range_interval[k].nil? or (cws < 4))
        if !range_interval[k].nil?
          range_interval[k] = nil
        end
        range[prevk] = range[prevk].concat(range[k]) if range[k]
        range[k] = nil
      else
        prevk = k
      end
      nextk = k + cws
      if !range_interval[k].nil?
        if cws > 3
          prevint = true
        else
          prevint = false
        end
        range_interval[k] = nil
        nextk -= 1
      else
        prevint = false
      end
    }
    # output data
    w = ''
    range.each_with_index {|ws, k|
      if ws and ws.uniq.length == 1
        # interval mode is more compact
        w << ' ' + k.to_s + ' ' + (k + ws.length - 1).to_s + ' ' + ws[0].to_s
      elsif ws
        # range mode
        w << ' ' + k.to_s + ' [ ' + ws.join(' ') + ' ]'
      end
    }
    return ('/W [' + w + ' ]')
  end

  #
  # Output fonts.
  # [@author Nicola Asuni]
  # [@access protected]
  #
  def putfonts()
    nf=@n;
    @diffs.each do |diff|
      #Encodings
      newobj();
      out('<< /Type /Encoding /BaseEncoding /WinAnsiEncoding /Differences [' + diff + '] >> endobj')
    end
    @font_files.each do |file, info|
      # search and get font file to embedd
      fontdir = info['fontdir']

      file = file.downcase
      fontfile = ''
      # search files on various directories
      if (fontdir != false) and File.exist?(fontdir + file)
        fontfile = fontdir + file
      elsif fontfile = getfontpath(file)
      elsif File.exist?(file)
        fontfile = file
      end

      if !empty_string(fontfile)
        font = ''
        open(fontfile,'rb') do |f|
          font = f.read()
        end
        compressed = (file[-2,2] == '.z')
        if !compressed && !info['length2'].nil?
          header = (font[0][0] == 128)
          if header
            # Strip first binary header
            font = font[6]
          end
          if header && (font[info['length1']][0] == 128)
            # Strip second binary header
            font = font[0..info['length1']] + font[info['length1'] + 6]
          end
        elsif info['subset'] and (!compressed or (compressed and Object.const_defined?(:Zlib)))

          if compressed
            # uncompress font
            font = Zlib::Inflate.inflate(font)
          end
          # merge subset characters
          subsetchars = [] # used chars
          info['fontkeys'].each {|fontkey|
            fontinfo = getFontBuffer(fontkey)
            subsetchars += fontinfo['subsetchars']
          }
          font = getTrueTypeFontSubset(font, subsetchars)
          if compressed
            # recompress font
            font = Zlib::Deflate.deflate(font)
          end
        end
        newobj()
        @font_files[file]['n'] = @n
        out = '<</Length '+ font.length.to_s
        if compressed
          out << ' /Filter /FlateDecode'
        end
        out << ' /Length1 ' + info['length1'].to_s
        if !info['length2'].nil?
          out << ' /Length2 ' + info['length2'].to_s + ' /Length3 0'
        end
        out << ' >>'
        out << ' '+ getstream(font)
        out << ' endobj'
        out(out)
      end
    end
    @fontkeys.each_with_index do |k, i|
      #Font objects
      setFontSubBuffer(k, 'n', @n + 1)
      font = getFontBuffer(k)
      type = font['type'];
      name = font['name'];
      if (type=='core')
        # standard core font
        obj_id = newobj()
        out = '<</Type /Font'
        out << ' /Subtype /Type1'
        out << ' /BaseFont /' + name
        out << ' /Name /F' + font['i'].to_s
        if (name.downcase != 'symbol' && name.downcase != 'zapfdingbats')
          out << ' /Encoding /WinAnsiEncoding'
        end
        if name.downcase == 'helvetica'
          # add default font for annotations
          @annotation_fonts['helvetica'] = i
        end
        out << ' >> endobj'
        out(out)
      elsif (type=='Type1' || type=='TrueType')
        # additional Type1 or TrueType font
        obj_id = newobj()
        out = '<</Type /Font'
        out << ' /Subtype /' + type
        out << ' /BaseFont /' + name
        out << ' /Name /F' + font['i'].to_s
        out << ' /FirstChar 32 /LastChar 255'
        out << ' /Widths ' + (@n+1).to_s + ' 0 R'
        out << ' /FontDescriptor ' + (@n+2).to_s + ' 0 R'
        if (font['enc'])
          if (!font['diff'].nil?)
            out << ' /Encoding ' + (nf+font['diff']).to_s + ' 0 R'
          else
            out << ' /Encoding /WinAnsiEncoding'
          end
        end
        out << ' >> endobj'
        out(out)
        #Widths
        newobj();
        cw=font['cw']; # &
        s='[';
        32.upto(255) do |i|
          s << cw[i.chr] + ' ';
        end
        out(s + '] endobj')
        #Descriptor
        newobj();
        s='<</Type /FontDescriptor /FontName /' + name;
        font['desc'].each do |fdk, fdv|
          if fdv.is_a? Float
            fdv = sprintf('%.3f', fdv)
          end
          s << ' /' + fdk + ' ' + fdv + ''
        end
        if !empty_string(font['file'])
          s << ' /FontFile' + (type=='Type1' ? '' : '2') + ' ' + @font_files[font['file']]['n'] + ' 0 R'
        end
        out(s + '>> endobj')
      else
        # additional types
        mtd='put' + type.downcase;
        unless self.respond_to?(mtd, true)
          Error('Unsupported font type: ' + type)
        end
        obj_id = self.send(mtd,font)
      end
      # store object ID for current font
      @font_obj_ids[k] = obj_id
    end
  end

  #
  # Adds unicode fonts.
  # Based on PDF Reference 1.3 (section 5)
  # [@parameter array :font] font data
  # [@return int] font object ID
  # [@access protected]
  # [@author] Nicola Asuni
  # [@since 1.52.0.TC005 (2005-01-05)]
  #
  def puttruetypeunicode(font)
    fontname = ''
    if font['subset']
      # change name for font subsetting
      subtag = sprintf('%06u', font['i'])
      subtag = subtag.gsub('0123456789', 'ABCDEFGHIJ')
      fontname << subtag + '+'
    end
    fontname << font['name']
    # Type0 Font
    # A composite font composed of other fonts, organized hierarchically
    obj_id = newobj()
    out = '<</Type /Font'
    out << ' /Subtype /Type0'
    out << ' /BaseFont /' + fontname + ''
    out << ' /Name /F' + font['i'].to_s
    out << ' /Encoding /' + font['enc']
    out << " /ToUnicode #{@n + 1} 0 R"
    out << " /DescendantFonts [#{@n + 2} 0 R]"
    out << ' >>'
    out << ' endobj'
    out(out)

    # ToUnicode Object
    newobj()
    filter = @compress ? '/Filter /FlateDecode ' : ''
    stream = @compress ? Zlib::Deflate.deflate(@@cmap_identity_h) : @@cmap_identity_h
    stream = getrawstream(stream)
    out("<<#{filter}/Length #{stream.length}>> stream\n#{stream}\nendstream\nendobj")

    # CIDFontType2
    # A CIDFont whose glyph descriptions are based on TrueType font technology
    newobj();
    out = '<</Type /Font'
    out << ' /Subtype /CIDFontType2'
    out << ' /BaseFont /' + fontname

    # A dictionary containing entries that define the character collection of the CIDFont.

    cidinfo = '/Registry ' + datastring(font['cidinfo']['Registry'])
    cidinfo << ' /Ordering ' + datastring(font['cidinfo']['Ordering'])
    cidinfo << ' /Supplement ' + font['cidinfo']['Supplement'].to_s

    out << ' /CIDSystemInfo <<' + cidinfo + '>>'
    out << ' /FontDescriptor ' + (@n + 1).to_s + ' 0 R'
    out << ' /DW ' + font['dw'].to_s + '' # default width
    out << "\n" + putfontwidths(font, 0)
    out << ' /CIDToGIDMap ' + (@n + 2).to_s + ' 0 R'
    out << ' >> endobj'
    out(out)

    # Font descriptor
    # A font descriptor describing the CIDFont default metrics other than its glyph widths
    newobj();
    out = '<</Type /FontDescriptor'
    out << ' /FontName /' + fontname
    font['desc'].each do |key, value|
      if value.is_a? Float
        value = sprintf('%.3f', value)
      end
      out << ' /' + key.to_s + ' ' + value.to_s
    end
    fontdir = false
    if !empty_string(font['file'])
      # A stream containing a TrueType font
      out << ' /FontFile2 ' + @font_files[font['file']]['n'].to_s + ' 0 R'
      fontdir = @font_files[font['file']]['fontdir']
    end
    out << ' >> endobj'
    out(out)

    if font['ctg'] and !empty_string(font['ctg'])
      newobj()
      # Embed CIDToGIDMap
      # A specification of the mapping from CIDs to glyph indices
      # search and get CTG font file to embedd
      ctgfile = font['ctg'].downcase

      # search and get ctg font file to embedd
      fontfile = ''
      # search files on various directories
      if (fontdir != false) and File.exist?(fontdir + ctgfile)
        fontfile = fontdir + ctgfile
      elsif fontfile = getfontpath(ctgfile)
      elsif File.exist?(ctgfile)
        fontfile = ctgfile
      end

      if empty_string(fontfile)
        Error('Font file not found: ' + ctgfile)
      end
      size = File.size(fontfile)
      out = '<</Length ' + size.to_s + ''
      if (fontfile[-2,2] == '.z') # check file extension
        # Decompresses data encoded using the public-domain
        # zlib/deflate compression method, reproducing the
        # original text or binary data
        out << ' /Filter /FlateDecode'
      end
      out << ' >>'
      open(fontfile, 'rb') do |f|
        out << ' ' + getstream(f.read())
      end
      out << ' endobj'
      out(out)
    end

    return obj_id
  end

  #
  # Output CID-0 fonts.
  # A Type 0 CIDFont contains glyph descriptions based on the Adobe Type 1 font format
  # [@param array :font] font data
  # [@return int] font object ID
  # [@access protected]
  # [@author] Andrew Whitehead, Nicola Asuni, Yukihiro Nakadaira
  # [@since 3.2.000 (2008-06-23)]
  #
  def putcidfont0(font)
    cidoffset = 0
    if font['cw'][1].nil?
      cidoffset = 31
    end
    if font['cidinfo']['uni2cid']
      # convert unicode to cid.
      uni2cid = font['cidinfo']['uni2cid']
      cw = {}
      font['cw'].each { |uni, width|
        if uni2cid[uni]
          cw[(uni2cid[uni] + cidoffset)] = width
        elsif uni < 256
          cw[uni] = width
        end # else unknown character
      }
      font = font.merge({'cw' => cw})
    end
    name = font['name']
    enc = font['enc']
    if enc
      longname = name + '-' + enc
    else
      longname = name
    end
    obj_id = newobj()
    out = '<</Type /Font'
    out << ' /Subtype /Type0'
    out << ' /BaseFont /' + longname
    out << ' /Name /F' + font['i'].to_s
    if enc
      out << ' /Encoding /' + enc
    end
    out << ' /DescendantFonts [' + (@n + 1).to_s + ' 0 R]'
    out << ' >> endobj'
    out(out)
    newobj()
    out = '<</Type /Font'
    out << ' /Subtype /CIDFontType0'
    out << ' /BaseFont /' + name
    cidinfo = '/Registry ' + datastring(font['cidinfo']['Registry'])
    cidinfo << ' /Ordering ' + datastring(font['cidinfo']['Ordering'])
    cidinfo << ' /Supplement ' + font['cidinfo']['Supplement'].to_s
    out << ' /CIDSystemInfo <<' + cidinfo + '>>'
    out << ' /FontDescriptor ' + (@n + 1).to_s + ' 0 R'
    out << ' /DW ' + font['dw'].to_s
    out << "\n" + putfontwidths(font, cidoffset)
    out << ' >> endobj'
    out(out)
    newobj()
    s = '<</Type /FontDescriptor /FontName /' + name
    font['desc'].each {|k, v|
      if k != 'Style'
        if v.is_a? Float
          v = sprintf('%.3f', v)
        end
        s << ' /' + k + ' ' + v.to_s + ''
      end
    }
    out(s + '>> endobj')

    return obj_id
  end

  #
  # Output images.
  # [@access protected]
  #
  def putimages()
    filter=(@compress) ? '/Filter /FlateDecode ' : '';
    @imagekeys.each do |file|
      info = getImageBuffer(file)
      newobj();
      setImageSubBuffer(file, 'n', @n)
      out = '<</Type /XObject'
      out << ' /Subtype /Image'
      out << ' /Width ' + info['w'].to_s
      out << ' /Height ' + info['h'].to_s
      if info.key?('masked')
        out << ' /SMask ' + (@n - 1).to_s + ' 0 R'
      end
      if (info['cs']=='Indexed')
        out << ' /ColorSpace [/Indexed /DeviceRGB ' + (info['pal'].length / 3 - 1).to_s + ' ' + (@n + 1).to_s + ' 0 R]'
      else
        out << ' /ColorSpace /' + info['cs']
        if (info['cs']=='DeviceCMYK')
          out << ' /Decode [1 0 1 0 1 0 1 0]'
        end
      end
      out << ' /BitsPerComponent ' + info['bpc'].to_s
      if (!info['f'].nil?)
        out << ' /Filter /' + info['f']
      end
      if (!info['parms'].nil?)
        out << ' ' + info['parms']
      end
      if (!info['trns'].nil? and info['trns'].kind_of?(Array))
        trns='';
        count_info = info['trns'].length
        count_info.times do |i|
          trns << info['trns'][i].to_s + ' ' + info['trns'][i].to_s + ' '
        end
        out << ' /Mask [' + trns + ']'
      end
      out << ' /Length ' + info['data'].length.to_s + '>>'
      out << ' ' + getstream(info['data'])
      out << ' endobj'
      out(out)
      #Palette
      if (info['cs']=='Indexed')
        newobj();
        pal = @compress ? Zlib::Deflate.deflate(info['pal']) : info['pal']
        out('<<' + filter + '/Length ' + pal.length.to_s + '>> ' + getstream(pal) + ' endobj')
      end
    end
  end

  #
  # Maps HTML anchor links to anchors.
  # [@access protected]
  #
  def mapLinksToHtmlAnchors
    @html_anchors.each do |anchor, positon|
      links = @html_anchor_links.find_all { |url, link_anchor| link_anchor == anchor}
      links.each {|url, link_anchor|  @links[url] = positon }
    end
  end

  #
  # Output Spot Colors Resources.
  # [@access protected[
  # [@since 4.0.024 (2008-09-12)]
  #
  def putspotcolors()
    @spot_colors.each { |name, color|
      newobj()
      @spot_colors[name]['n'] = @n
      out = '[/Separation /' + name.gsub(' ', '#20')
      out << ' /DeviceCMYK <<'
      out << ' /Range [0 1 0 1 0 1 0 1] /C0 [0 0 0 0]'
      out << ' ' + sprintf('/C1 [%.4f %.4f %.4f %.4f] ', color['c']/100.0, color['m']/100.0, color['y']/100.0, color['k']/100.0)
      out << ' /FunctionType 2 /Domain [0 1] /N 1>>]'
      out << ' endobj'
      out(out)
    }
  end

  #
  # putresourcedict
  # [@access protected]
  #
  def putresourcedict()
    out = '2 0 obj'
    out << ' << /ProcSet [/PDF /Text /ImageB /ImageC /ImageI]'
    out << ' /Font <<'
    @fontkeys.each do |fontkey|
      font = getFontBuffer(fontkey)
      out << ' /F' + font['i'].to_s + ' ' + font['n'].to_s + ' 0 R'
    end
    out << ' >>'
    out << ' /XObject <<'
    @imagekeys.each do |file|
      info = getImageBuffer(file)
      out << ' /I' + info['i'].to_s + ' ' + info['n'].to_s + ' 0 R'
    end
    out << ' >>'
    # visibility
    out << ' /Properties <</OC1 ' + @n_ocg_print.to_s + ' 0 R /OC2 ' + @n_ocg_view.to_s + ' 0 R>>'
    # transparency
    out << ' /ExtGState <<'
    @extgstates.each_with_index { |extgstate, k|
      if extgstate
      if extgstate['name']
        out << ' /' + extgstate['name']
      else
        out << ' /GS' + k.to_s
      end
      out << ' ' + extgstate['n'].to_s + ' 0 R'
      end
    }
    out << ' >>'
=begin
    # gradient patterns
    if @gradients and !@gradients.empty?
      out << ' /Pattern <<'
      @gradients.each_with_index  {|grad, id|
        out << ' /p' + id + ' ' + grad['pattern'] + ' 0 R'
      }
      out << ' >>'
    end
    # gradient shadings
    if @gradients and !@gradients.empty?
      out << ' /Shading <<'
      @gradients.each_with_index  {|grad, id|
        out << ' /Sh' + id + ' ' + grad['id'] + ' 0 R'
      }
      out << ' >>'
    end
    # spot colors
    if @spot_colors and !@spot_colors.empty?
      out << ' /ColorSpace <<'
      @spot_colors.each  {|color|
        out << ' /CS' + color['i'] + ' ' + color['n'] + ' 0 R'
      }
      out << ' >>'
    end
=end
    out << ' >> endobj'
    out(out)
  end

  #
  # Output Resources.
  # [@access protected]
  #
  def putresources()
    mapLinksToHtmlAnchors()
    putextgstates()
    putocg()
    putfonts();
    putimages();
    putspotcolors()

    #Resource dictionary
    @offsets[2]=@bufferlen
    putresourcedict();
    putbookmarks()
    putEmbeddedFiles()
    putannotsobjs()
    putjavascript()
    # encryption

    ### T.B.D ### TCPDF 5.0.000 ###
  end

  #
  # Adds some Metadata information (Document Information Dictionary)
  # * (see Chapter 14.3.3 Document Information Dictionary of PDF32000_2008.pdf Reference)
  # [@access protected]
  #
  def putinfo()
    newobj()
    out = '<<'
    if !empty_string(@title)
      # The document's title.
      out << ' /Title ' + textstring(@title)
    end
    if !empty_string(@author)
      # The name of the person who created the document.
      out << ' /Author ' + textstring(@author)
    end
    if !empty_string(@subject)
      # The subject of the document.
      out << ' /Subject ' + textstring(@subject)
    end
    if !empty_string(@keywords)
      # Keywords associated with the document.
      out << ' /Keywords ' + textstring(@keywords)
    end
    if !empty_string(@creator)
      # If the document was converted to PDF from another format, the name of the conforming product that created the original document from which it was converted.
      out << ' /Creator ' + textstring(@creator)
    end
    if defined?(PDF_PRODUCER)
      # If the document was converted to PDF from another format, the name of the conforming product that converted it to PDF.
      out << ' /Producer ' + textstring(PDF_PRODUCER)
    else
      # default producer
      out << ' /Producer ' + textstring('RBPDF')
    end
    # The date and time the document was created, in human-readable form
    out << ' /CreationDate ' + datestring()
    # The date and time the document was most recently modified, in human-readable form
    out << ' /ModDate ' + datestring()
    # A name object indicating whether the document has been modified to include trapping information
    # out << ' /Trapped /False'
    out << ' >> endobj'
    out(out)
  end

  #
  # putcatalog
  # [@access protected]
  #
  def putcatalog()
    newobj()
    out = '<< /Type /Catalog'
    out << ' /Pages 1 0 R'
    if @zoom_mode == 'fullpage'
      out << ' /OpenAction [3 0 R /Fit]'
    elsif @zoom_mode == 'fullwidth'
      out << ' /OpenAction [3 0 R /FitH null]'
    elsif @zoom_mode == 'real'
      out << ' /OpenAction [3 0 R /XYZ null null 1]'
    elsif @zoom_mode.is_a?(Numeric)
      out << ' /OpenAction [3 0 R /XYZ null null ' + (@zoom_mode/100.0).to_s + ']'
    end
    if @layout_mode and !empty_string(@layout_mode)
      out << ' /PageLayout /' + @layout_mode
    end
    if @page_mode and !empty_string(@page_mode)
      out << ' /PageMode /' + @page_mode
    end

    if @l['a_meta_language']
      out << ' /Lang /' + @l['a_meta_language']
    end
    out << ' /Names <<'
    if !@javascript.empty? or !@js_objects.empty?
      out << " /JavaScript #{@n_js} 0 R"
    end
    out << ' >>'

    if @outlines.size > 0
      out << ' /Outlines ' + @outline_root.to_s + ' 0 R'
      out << ' /PageMode /UseOutlines'
    end
    out << ' ' + putviewerpreferences()
    p = @n_ocg_print.to_s + ' 0 R'
    v = @n_ocg_view.to_s + ' 0 R'
    as = '<</Event /Print /OCGs [' + p + ' ' + v + '] /Category [/Print]>> <</Event /View /OCGs [' + p + ' ' + v + '] /Category [/View]>>'
    out << ' /OCProperties <</OCGs [' + p + ' ' + v + '] /D <</ON [' + p + '] /OFF [' + v + '] /AS [' + as + ']>>>>'
    # AcroForm
    if !@form_obj_id.empty? || (@sign && @signature_data['cert_type'])
      out << ' /AcroForm<<'
      objrefs = ''
      if @sign && @signature_data['cert_type']
          objrefs << "#{@sig_obj_id} 0 R"
      end
      @form_obj_id.each{|objid|
        objrefs << " #{objid} 0 R"
      }
      out << " /Fields [#{objrefs}]"
      if @sign && @signature_data['cert_type']
        out << ' /SigFlags 3'
      end

      #out << ' /CO '
      unless @annotation_fonts.empty?
        out << ' /DR <<'
        out << ' /Font <<'
        @annotation_fonts.each {|font, fontkey|
          out << " /F#{fontkey + 1} #{@font_obj_ids[font]} 0 R"
        }
        out << ' >> >>'
      end
      out << " /DA (/F#{@fontkeys.index('helvetica') + 1} 0 Tf 0 g)"
      out << ' /Q ' + (@rtl ? '2' : '0')
      #out << ' /XFA '
      out << ' >>'
      # signatures
      if @sign && @signature_data['cert_type']
        if @signature_data['cert_type'] > 0
          out << " /Perms<</DocMDP #{@sig_obj_id + 1} 0 R>>"
        else
          out << " /Perms<</UR3 #{@sig_obj_id + 1} 0 R>>"
        end
      end
    end
    out << ' >> endobj'
    out(out)
  end

  #
  # Output viewer preferences.
  # [@return string] for viewer preferences
  # [@author] Nicola asuni
  # [@since 3.1.000 (2008-06-09)]
  # [@access protected]
  #
  def putviewerpreferences()
    out = '/ViewerPreferences <<'
    if @rtl
      out << ' /Direction /R2L'
    else
      out << ' /Direction /L2R'
    end

    if @viewer_preferences['HideToolbar'] and (@viewer_preferences['HideToolbar'] == true)
      out << ' /HideToolbar true'
    end
    if @viewer_preferences['HideMenubar'] and (@viewer_preferences['HideMenubar'] == true)
      out << ' /HideMenubar true'
    end
    if @viewer_preferences['HideWindowUI'] and (@viewer_preferences['HideWindowUI'] == true)
      out << ' /HideWindowUI true'
    end
    if @viewer_preferences['FitWindow'] and (@viewer_preferences['FitWindow'] == true)
      out << ' /FitWindow true'
    end
    if @viewer_preferences['CenterWindow'] and (@viewer_preferences['CenterWindow'] == true)
      out << ' /CenterWindow true'
    end
    if @viewer_preferences['DisplayDocTitle'] and (@viewer_preferences['DisplayDocTitle'] == true)
      out << ' /DisplayDocTitle true'
    end
    if @viewer_preferences['NonFullScreenPageMode']
      out << ' /NonFullScreenPageMode /' + @viewer_preferences['NonFullScreenPageMode']
    end
    if @viewer_preferences['ViewArea']
      out << ' /ViewArea /' + @viewer_preferences['ViewArea']
    end
    if @viewer_preferences['ViewClip']
      out << ' /ViewClip /' + @viewer_preferences['ViewClip']
    end
    if @viewer_preferences['PrintArea']
      out << ' /PrintArea /' + @viewer_preferences['PrintArea']
    end
    if @viewer_preferences['PrintClip']
      out << ' /PrintClip /' + @viewer_preferences['PrintClip']
    end
    if @viewer_preferences['PrintScaling']
      out << ' /PrintScaling /' + @viewer_preferences['PrintScaling']
    end
    if @viewer_preferences['Duplex'] and !empty_string(@viewer_preferences['Duplex'])
      out << ' /Duplex /' + @viewer_preferences['Duplex']
    end
    if @viewer_preferences['PickTrayByPDFSize']
      if @viewer_preferences['PickTrayByPDFSize']
        out << ' /PickTrayByPDFSize true'
      else
        out << ' /PickTrayByPDFSize false'
      end
    end
    if @viewer_preferences['PrintPageRange']
      print_page_range_num = ''
      @viewer_preferences['PrintPageRange'].each { |v|
        print_page_range_num << ' ' + (v - 1).to_s + ''
      }
      out << ' /PrintPageRange [' + print_page_range_num.sub(/^ /, '') + ']'
    end
    if @viewer_preferences['NumCopies']
      out << ' /NumCopies ' + @viewer_preferences['NumCopies'].to_s
    end

    out << ' >>'
    return out
  end

  #
  # puttrailer
  # [@access protected]
  #
  def puttrailer()
    out = 'trailer <<'
    out << ' /Size ' + (@n+1).to_s
    out << ' /Root ' + @n.to_s + ' 0 R'
    out << ' /Info ' + (@n-1).to_s + ' 0 R'
    #if @encrypted
    #  out << ' /Encrypt ' + @encryptdata['objid'] + ' 0 R'
    #  out << ' /ID [ <' + @file_id + '> <' + @file_id + '> ]'
    #end
    out << ' >>'
    out(out)
  end

  #
  # putheader
  # [@access protected]
  #
  def putheader()
    out('%PDF-' + @pdf_version);
  end

  #
  # Output end of document (EOF).
  # [@access protected]
  #
  def enddoc()
    @state = 1
    putheader();
    putpages();
    putresources();

    ### T.B.D ### TCPDF 5.0.000 ###

    #Info
    putinfo();
    #Catalog
    putcatalog();
    #Cross-ref
    o=@bufferlen
    out('xref');
    out('0 ' + (@n+1).to_s);
    out('0000000000 65535 f ');
    1.upto(@n) do |i|
      out(sprintf('%010d 00000 n ',@offsets[i]));
    end
    # Embedded Files
    if !@embeddedfiles.nil? and (@embeddedfiles.length > 0)
      out(@embedded_start_obj_id.to_s + ' ' + @embeddedfiles.length.to_s)
      @embeddedfiles.each { |filename, filedata|
        out(sprintf('%010d 00000 n ', @offsets[filedata['n']]))
      }
    end
    # Annotation Objects
    if @annot_obj_id > @annots_start_obj_id
      out((@annots_start_obj_id + 1).to_s + ' ' + (@annot_obj_id - @annots_start_obj_id).to_s)
      (@annots_start_obj_id + 1).upto(@annot_obj_id) do |i|
        out(sprintf('%010d 00000 n ', @offsets[i]))
      end
    end
    # Javascript Objects
    if @js_obj_id > @js_start_obj_id
      out((@js_start_obj_id + 1).to_s + ' ' + (@js_obj_id - @js_start_obj_id).to_s)
      (@js_start_obj_id + 1).upto(@js_obj_id) do |i|
        out(sprintf('%010d 00000 n ', @offsets[i]))
      end
    end
    # Appearance streams XObjects
    if @apxo_obj_id > @apxo_start_obj_id
      out((@apxo_start_obj_id + 1).to_s + ' ' + (@apxo_obj_id - @apxo_start_obj_id).to_s)
      (@apxo_start_obj_id + 1).upto(@apxo_obj_id) do |i|
        out(sprintf('%010d 00000 n ', @offsets[i]))
      end
    end
    #Trailer
    puttrailer();
    out('startxref');
    out(o);
    out('%%EOF');
    @state=3 # end-of-doc
    if @diskcache
      # remove temporary files used for images
      @imagekeys.each do |key|
        # remove temporary files
        File.delete(@images[key].path)
      end
      @fontkeys.each do |key|
        # remove temporary files
        File.delete(@fonts[key].path)
      end
    end
  end

  #
  # Initialize a new page
  # beginpage
  # [@param string :orientation]
  #   page orientation. Possible values are (case insensitive):
  #   * P or PORTRAIT (default)
  #   * L or LANDSCAPE
  # [@param mixed :format]
  #   The format used for pages. It can be either:<b>A string indicating the page format:</b>
  #   * 4A0,2A0,A0,A1,A2,A3,A4 (default),A5,A6,A7,A8,A9,A10
  #   * B0,B1,B2,B3,B4,B5,B6,B7,B8,B9,B10
  #   * C0,C1,C2,C3,C4,C5,C6,C7,C8,C9,C10
  #   * RA0,RA1,RA2,RA3,RA4
  #   * SRA0,SRA1,SRA2,SRA3,SRA4
  #   * LETTER,LEGAL,EXECUTIVE,FOLIO
  #   <b>An array containing page measures and advanced options:</b> see setPageFormat()
  # [@access protected]
  #
  def beginpage(orientation='', format='')
    @page += 1;
    setPageBuffer(@page, '')
    # initialize array for graphics tranformation positions inside a page buffer
    @state=2;
    if empty_string(orientation)
      if @cur_orientation
        orientation = @cur_orientation
      elsif @fw_pt > @fh_pt
        # landscape
        orientation = 'L'
      else
        # portrait
        orientation = 'P'
      end
    end
    if empty_string(format)
      @pagedim[@page] = @pagedim[@page - 1]
      setPageOrientation(orientation)
    else
      setPageFormat(format, orientation)
    end
    if @rtl
      @x = @w - @r_margin
    else
      @x = @l_margin
    end
    @y=@t_margin;
    if !@newpagegroup[@page].nil?
      # start a new group
      n = @pagegroups.size + 1
      alias_nb = '{nb' + n.to_s + '}'
      @pagegroups[alias_nb] = 1
      @currpagegroup = alias_nb
    elsif @currpagegroup
      @pagegroups[@currpagegroup] += 1
    end
  end

  #
  # End of page contents
  # [@access protected]
  #
  def endpage()
    setVisibility('all')
    @state=1;
  end

  #
  # Begin a new object and return the object number
  # [@return int] object number
  # [@access protected]
  #
  def newobj()
    @n += 1;
    @offsets[@n]=@bufferlen
    out(@n.to_s + ' 0 obj');

    return @n
  end

  #
  # Underline text
  # [@param int :x] X coordinate
  # [@param int :y] Y coordinate
  # [@param string :txt] text to underline
  # [@access protected]
  #
  def dounderline(x, y, txt)
    w = GetStringWidth(txt)
    return dounderlinew(x, y, w)
  end

  #
  # Underline for rectangular text area.
  # [@param int :x] X coordinate
  # [@param int :y] Y coordinate
  # [@param int :w] width to underline
  # [@access protected]
  # [@since 4.8.008 (2009-09-29)]
  #
  def dounderlinew(x, y, w)
    linew = - @current_font['ut'] / 1000.0 * @font_size_pt
    return sprintf('%.2f %.2f %.2f %.2f re f', x * @k, (@h - y) * @k + linew, w * @k, linew)
  end

  #
  # Line through text
  # [@param int :x] X coordinate
  # [@param int :y] Y coordinate
  # [@param string :txt] text to linethrough
  # [@access protected]
  #
  def dolinethrough(x, y, txt)
    w = GetStringWidth(txt)
    return dolinethroughw(x, y, w)
  end

  #
  # Line through for rectangular text area.
  # [@param int :x] X coordinate
  # [@param int :y] Y coordinate
  # [@param int :w] width to linethrough
  # [@access protected]
  # [@since 4.9.008 (2009-09-29)]
  #
  def dolinethroughw(x, y, w)
    linew = - @current_font['ut'] / 1000.0 * @font_size_pt
    return sprintf('%.2f %.2f %.2f %.2f re f', x * @k, (@h - y) * @k + linew + (@font_size_pt / 3.0), w * @k, linew)
  end

  #
  # Overline text.
  # [@param int :x] X coordinate
  # [@param int :y] Y coordinate
  # [@param string :txt] text to overline
  # [@access protected]
  # [@since 4.9.015 (2010-04-19)]
  #
  def dooverline(x, y, txt)
    w = GetStringWidth(txt)
    return dooverlinew(x, y, w)
  end

  #
  # Overline for rectangular text area.
  # [@param int :x] X coordinate
  # [@param int :y] Y coordinate
  # [@param int :w] width to overline
  # [@access protected]
  # [@since 4.9.015 (2010-04-19)]
  #
  def dooverlinew(x, y, w)
    linew = - @current_font['ut'] / 1000.0 * @font_size_pt
    return sprintf('%.2f %.2f %.2f %.2f re f', x * @k, (@h - y + @font_ascent) * @k - linew, w * @k, linew)
  end

  #
  # Read a 4-byte (32 bit) integer from file
  # [@param string :f] file name.
  # [@return] 4-byte integer
  # [@access protected]
  #
  def freadint(f)
    # Read a 4-byte integer from file
    a = f.read(4).unpack('N')
    return a[0]
  end

  #
  # Add \ before \, ( and )
  # [@access protected]
  #
  def escape(s)
    # Add \ before \, ( and )
    s.gsub('\\','\\\\\\').gsub('(','\\(').gsub(')','\\)').gsub(13.chr, '\r')
  end

  #
  # Format a data string for meta information
  # [@param string :s] data string to escape.
  # [@return string] escaped string.
  # [@access protected]
  #
  def datastring(s)
    s = encrypt_data(@n, s)
    return '(' + escape(s) + ')'
  end

  #
  # Format a data string for annotation objects
  # [@param string :s] data string to escape.
  # [@return string] escaped string.
  # [@access protected]
  #
  def dataannobjstring(s)
    s = encrypt_data(@annot_obj_id + 1, s)
    return '(' + escape(s) + ')'
  end
  #
  # Returns a formatted date for meta information
  # [@return string] escaped date string.
  # [@access protected]
  # [@since 4.6.028 (2009-08-25)]
  #
  def datestring()
    current_time = Time.now.strftime('%Y%m%d%H%M%S%z').insert(-3, '\'') + '\''
    return datastring('D:' + current_time)
  end

  #
  # Format a text string for meta information
  # [@param string :s] string to escape.
  # [@return string] escaped string.
  # [@access protected]
  #
  def textstring(s)
    if (@is_unicode)
      #Convert string to UTF-16BE
      s = UTF8ToUTF16BE(s, true);
    end
    return datastring(s)
  end

  #
  # Format a UTF-8 text string for meta information on annotations
  # [@param string :s] string to escape.
  # [@return string] escaped string.
  # [@access protected]
  #
  def textannobjstring(s)
    if @is_unicode
      # Convert string to UTF-16BE
      s = UTF8ToUTF16BE(s, true)
    end
    return dataannobjstring(s)
  end

  #
  # Format a text string
  # [@param string :s] string to escape.
  # [@return string] escaped string.
  # [@access protected]
  #
  def escapetext(s)
    if (@is_unicode)
      if (@current_font['type'] == 'core') or (@current_font['type'] == 'TrueType') or (@current_font['type'] == 'Type1')
        s = UTF8ToLatin1(s)
      else
        # Convert string to UTF-16BE and reverse RTL language
        s = utf8StrRev(s, false, rtl_text_dir)
      end
    end
    return escape(s);
  end

  #
  # get raw output stream.
  # [@param string :s] string to output.
  # [@param int :n] object reference for encryption mode
  # [@access protected]
  #
  def getrawstream(s, n=0)
    if n <= 0
      # default to current object
      n = @n
    end
    encrypt_data(n, s)
  end

  #
  # Format output stream
  # [@param string :s] string to output.
  # [@param int :n] object reference for encryption mode
  # [@access protected]
  #
  def getstream(s, n=0)
    "stream\n" + getrawstream(s, n=0) + "\nendstream"
  end

  #
  # Output a stream.
  # [@param string :s] string to output.
  # [@param int :n] object reference for encryption mode
  # [@access protected]
  #
  def putstream(s, n=0)
    out(getstream(s, n))
  end

  #
  # Output a string to the document.
  # [@param string :s] string to output.
  # [@access protected]
  #
  def out(s)
    s.force_encoding('ASCII-8BIT') if s.respond_to?(:force_encoding)

    if @tmp_buffer
      @tmp_buffer << "#{s}\n"
    elsif (@state==2)
      if !@in_footer and !@footerlen[@page].nil? and (@footerlen[@page] > 0)
        # puts data before page footer
        pagebuff = getPageBuffer(@page)
        page = pagebuff[0..(-@footerlen[@page]-1)]
        footer = pagebuff[-@footerlen[@page]..-1]
        setPageBuffer(@page, page + s.to_s + "\n" + footer)
        # update footer position
        @footerpos[@page] += (s.to_s + "\n").length
      else
        setPageBuffer(@page, s.to_s + "\n", true)
      end
    else
      setBuffer(s.to_s + "\n")
    end
  end

  #
  # Converts UTF-8 strings to codepoints array.
  # Invalid byte sequences will be replaced with 0xFFFD (replacement character)
  # * Based on: http://www.faqs.org/rfcs/rfc3629.html
  #
  #   Char. number range  |        UTF-8 octet sequence
  #      (hexadecimal)    |              (binary)
  #   --------------------+------------------------------------------------
  #   0000 0000-0000 007F | 0xxxxxxx
  #   0000 0080-0000 07FF | 110xxxxx 10xxxxxx
  #   0000 0800-0000 FFFF | 1110xxxx 10xxxxxx 10xxxxxx
  #   0001 0000-0010 FFFF | 11110xxx 10xxxxxx 10xxxxxx 10xxxxxx
  #   ---------------------------------------------------------------------
  #
  #   ABFN notation:
  #   ---------------------------------------------------------------------
  #   UTF8-octets =#( UTF8-char )
  #   UTF8-char   = UTF8-1 / UTF8-2 / UTF8-3 / UTF8-4
  #   UTF8-1      = %x00-7F
  #   UTF8-2      = %xC2-DF UTF8-tail
  #
  #   UTF8-3      = %xE0 %xA0-BF UTF8-tail / %xE1-EC 2( UTF8-tail ) /
  #                 %xED %x80-9F UTF8-tail / %xEE-EF 2( UTF8-tail )
  #   UTF8-4      = %xF0 %x90-BF 2( UTF8-tail ) / %xF1-F3 3( UTF8-tail ) /
  #                 %xF4 %x80-8F 2( UTF8-tail )
  #   UTF8-tail   = %x80-BF
  #   ---------------------------------------------------------------------
  #
  # [@param string :str] string to process. (UTF-8)
  # [@return array] containing codepoints (UTF-8 characters values) (UCS4)
  # [@access protected]
  # [@author] Nicola Asuni
  # [@since 1.53.0.TC005 (2005-01-05)]
  #
  def UTF8StringToArray(str)
    if @cache_utf8_string_to_array[str]
      # return cached value
      return @cache_utf8_string_to_array[str].dup
    end
    # check cache size
    if @cache_size_utf8_string_to_array >= @cache_maxsize_utf8_string_to_array
      # remove first element
      @cache_utf8_string_to_array.shift
    end
    @cache_size_utf8_string_to_array += 1
    if !@is_unicode
      # split string into array of chars
      strarr = str.split(//)
      # convert chars to equivalent code
      strarr.each_with_index do |char, pos| # was while(list(pos,char)=each(strarr))
        strarr[pos] = char.unpack('C')[0]
      end
      # insert new value on cache
      @cache_utf8_string_to_array[str] = strarr.dup
      return strarr
    end

    unichar = -1 # last unicode char
    unicode = [] # array containing unicode values
    bytes  = [] # array containing single character byte sequences
    numbytes  = 1; # number of octetc needed to represent the UTF-8 character

    str = str.to_s; # force :str to be a string

    str.each_byte do |char|
      if (bytes.length == 0) # get starting octect
        if (char <= 0x7F)
          unichar = char # use the character "as is" because is ASCII
          numbytes = 1
        elsif ((char >> 0x05) == 0x06) # 2 bytes character (0x06 = 110 BIN)
          bytes << ((char - 0xC0) << 0x06)
          numbytes = 2
        elsif ((char >> 0x04) == 0x0E) # 3 bytes character (0x0E = 1110 BIN)
          bytes << ((char - 0xE0) << 0x0C)
          numbytes = 3
        elsif ((char >> 0x03) == 0x1E) # 4 bytes character (0x1E = 11110 BIN)
          bytes << ((char - 0xF0) << 0x12)
          numbytes = 4
        else
          # use replacement character for other invalid sequences
          unichar = 0xFFFD
          bytes = []
          numbytes = 1
        end
      elsif ((char >> 0x06) == 0x02) # bytes 2, 3 and 4 must start with 0x02 = 10 BIN
        bytes << (char - 0x80)
        if (bytes.length == numbytes)
          # compose UTF-8 bytes to a single unicode value
          char = bytes[0]
          1.upto(numbytes-1) do |j|
            char += (bytes[j] << ((numbytes - j - 1) * 0x06))
          end
          if (((char >= 0xD800) and (char <= 0xDFFF)) or (char >= 0x10FFFF))
            # The definition of UTF-8 prohibits encoding character numbers between
            # U+D800 and U+DFFF, which are reserved for use with the UTF-16
            # encoding form (as surrogate pairs) and do not directly represent
            # characters
            unichar = 0xFFFD # use replacement character
          else
            unichar = char # add char to array
          end
          # reset data for next char
          bytes = []
          numbytes = 1
        end
      else
        # use replacement character for other invalid sequences
        unichar = 0xFFFD
        bytes = []
        numbytes = 1;
      end
      if unichar >= 0
        # insert unicode value into array
        unicode.push unichar
        # store this char for font subsetting
        @current_font['subsetchars'][unichar] = true
        unichar = -1
      end
    end
    # update font subsetchars
    setFontSubBuffer(@current_font['fontkey'], 'subsetchars', @current_font['subsetchars'])
    # insert new value on cache
    @cache_utf8_string_to_array[str] = unicode.dup
    return unicode;
  end

  #
  # Converts UTF-8 strings to UTF16-BE.
  # [@param string :str] string to process.
  # [@param boolean :setbom] if true set the Byte Order Mark (BOM = 0xFEFF)
  # [@return string]
  # [@access protected]
  # [@author] Nicola Asuni
  # [@since 1.53.0.TC005 (2005-01-05)]
  # [@uses] UTF8StringToArray(), arrUTF8ToUTF16BE()
  #
  def UTF8ToUTF16BE(str, setbom=true)
    if !@is_unicode
      return str # string is not in unicode
    end
    unicode = UTF8StringToArray(str) # array containing UTF-8 unicode values (UCS4)
    return arrUTF8ToUTF16BE(unicode, setbom)
  end

  #
  # Converts UTF-8 strings to Latin1 when using the standard 14 core fonts.
  # [@param string :str] string to process.
  # [@return string]
  # [@author] Andrew Whitehead, Nicola Asuni
  # [@access protected]
  # [@since 3.2.000 (2008-06-23)]
  #
  def UTF8ToLatin1(str)
    if !@is_unicode
      return str # string is not in unicode
    end
    outstr = '' # string to be returned
    unicode = UTF8StringToArray(str) # array containing UTF-8 unicode values
    unicode.each {|char|
      if char < 256
        outstr << char.chr
      elsif @@utf8tolatin.key?(char)
        # map from UTF-8
        outstr << @@utf8tolatin[char].chr
      elsif char == 0xFFFD
        # skip
      else
        outstr << '?'
      end
    }
    return outstr
  end

  #
  # Converts UTF-8 characters array to array of Latin1 characters
  # [@param array :unicode] array containing UTF-8 unicode values
  # [@return array]
  # [@author] Nicola Asuni
  # [@access protected]
  # [@since 4.8.023 (2010-01-15)]
  #
  def UTF8ArrToLatin1(unicode)
    if !@is_unicode or (@current_font['type'] == 'TrueTypeUnicode') or (@current_font['type'] == 'cidfont0')
      return unicode # string is not in unicode
    end
    outarr = [] # array to be returned
    unicode.each {|char|
      if char < 256
        outarr.push char
      elsif @@utf8tolatin.key?(char)
        # map from UTF-8
        outarr.push @@utf8tolatin[char]
      elsif char == 0xFFFD
        # skip
      else
        outarr.push 63 # '?' character
      end
    }
    return outarr
  end

  #
  # Converts array of UTF-8 characters to UTF16-BE string.
  # * Based on: http://www.faqs.org/rfcs/rfc2781.html
  #
  #   Encoding UTF-16:
  #
  #   Encoding of a single character from an ISO 10646 character value to
  #    UTF-16 proceeds as follows. Let U be the character number, no greater
  #    than 0x10FFFF.
  #
  #    1) If U < 0x10000, encode U as a 16-bit unsigned integer and
  #       terminate.
  #
  #    2) Let U' = U - 0x10000. Because U is less than or equal to 0x10FFFF,
  #       U' must be less than or equal to 0xFFFFF. That is, U' can be
  #       represented in 20 bits.
  #
  #    3) Initialize two 16-bit unsigned integers, W1 and W2, to 0xD800 and
  #       0xDC00, respectively. These integers each have 10 bits free to
  #       encode the character value, for a total of 20 bits.
  #
  #    4) Assign the 10 high-order bits of the 20-bit U' to the 10 low-order
  #       bits of W1 and the 10 low-order bits of U' to the 10 low-order
  #       bits of W2. Terminate.
  #
  #    Graphically, steps 2 through 4 look like:
  #    U' = yyyyyyyyyyxxxxxxxxxx
  #    W1 = 110110yyyyyyyyyy
  #    W2 = 110111xxxxxxxxxx
  #
  # [@param array :unicode] array containing UTF-8 unicode values (UCS4)
  # [@param boolean :setbom] if true set the Byte Order Mark (BOM = 0xFEFF)
  # [@return] string (UTF-16BE)
  # [@access protected]
  # [@author] Nicola Asuni
  # [@since 2.1.000 (2008-01-08)]
  # [@see] UTF8ToUTF16BE()
  #
  def arrUTF8ToUTF16BE(unicode, setbom=true)
    outstr = ""; # string to be returned
    if (setbom)
      outstr << "\xFE\xFF"; # Byte Order Mark (BOM)
    end
    unicode.each do |char|
      if (char == 0xFFFD)
        outstr << "\xFF\xFD"; # replacement character
      elsif (char < 0x10000)
        outstr << (char >> 0x08).chr;
        outstr << (char & 0xFF).chr;
      else
        char -= 0x10000;
        w1 = 0xD800 | (char >> 0x10);
        w2 = 0xDC00 | (char & 0x3FF);
        outstr << (w1 >> 0x08).chr;
        outstr << (w1 & 0xFF).chr;
        outstr << (w2 >> 0x08).chr;
        outstr << (w2 & 0xFF).chr;
      end
    end
    return outstr;
  end

  # ====================================================
public

  #
  # Set Font Subsetting.
  # [@param boolean :subset] subset of the font default setting.
  # [@access public]
  #
  def setFontSubsetting(subset)
    @font_subsetting = (subset == true ? true : false)
  end
  alias_method :set_font_subsetting, :setFontSubsetting

  #
  # Get Font Subsetting.
  # [@return boolean]
  # [@access public]
  #
  def getFontSubsetting()
    return @font_subsetting
  end
  alias_method :get_font_subsetting, :getFontSubsetting

  #
  # Set header font.
  # [@param array :font] font
  # [@access public]
  # [@since 1.1]
  #
  def setHeaderFont(font)
    @header_font = font;
  end
  alias_method :set_header_font, :setHeaderFont

  def SetHeaderFont(font)
    warn "[DEPRECATION] 'SetHeaderFont' is deprecated. Please use 'set_header_font' instead."
    setHeaderFont(font)
  end

  #
  # Get header font.
  # [@return array]
  # [@access public]
  # [@since 4.0.012 (2008-07-24)]
  #
  def getHeaderFont()
    return @header_font
  end
  alias_method :get_header_font, :getHeaderFont

  #
  # Set footer font.
  # [@param array :font] font
  # [@access public]
  # [@since 1.1]
  #
  def setFooterFont(font)
    @footer_font = font;
  end
  alias_method :set_footer_font, :setFooterFont

  def SetFooterFont(font)
    warn "[DEPRECATION] 'SetFooterFont' is deprecated. Please use 'set_footer_font' instead."
    setFooterFont(font)
  end

  #
  # Get Footer font.
  # [@return array]
  # [@access public]
  # [@since 4.0.012 (2008-07-24)]
  #
  def getFooterFont(font)
    return @footer_font
  end
  alias_method :get_footer_font, :getFooterFont

  #
  # Set language array.
  # [@param array :language]
  # [@since 1.1]
  #
  def setLanguageArray(language)
    @l = language;
    if @l['a_meta_dir']
      @rtl = (@l['a_meta_dir'] == 'rtl') ? true : false
    else
      @rtl = false
    end
  end
  alias_method :set_language_array, :setLanguageArray

  def SetLanguageArray(language)
    warn "[DEPRECATION] 'SetLanguageArray' is deprecated. Please use 'set_language_array' instead."
    setLanguageArray(language)
  end

  #
  # Returns the PDF data.
  # [@access public]
  #
  def getPDFData()
    if (@state < 3)
      Close();
    end
    return @buffer;
  end
  alias_method :get_pdf_data, :getPDFData

  def GetPDFData()
    warn "[DEPRECATION] 'GetPDFData' is deprecated. Please use 'get_pdf_data' instead."
    getPDFData()
  end

  #
  # Output anchor link.
  # [@param string :url] link URL or internal link (i.e.: <a href="#23">link to page 23</a>)
  # [@param string :name] link name
  # [@param int :fill] Indicates if the cell background must be painted (1) or transparent (0). Default value: 0.
  # [@param boolean :firstline] if true prints only the first line and return the remaining string.
  # [@param array :color] array of RGB text color
  # [@param string :style] font style (U, D, B, I)
  # [@param boolean :firstblock] if true the string is the starting of a line.
  # [@return] the number of cells used or the remaining text if :firstline = true
  # [@access public]
  #
  def addHtmlLink(url, name, fill=0, firstline=false, color='', style=-1, firstblock=false)
    if !empty_string(url) and (url[0, 1] == '#')
      # convert url to internal link
      anchor = url.sub(/^#/, "")
      page = anchor.to_i
      url = AddLink()
      @html_anchor_links[url] = anchor
      SetLink(url, 0, page)
    end
    # store current settings
    prevcolor = @fgcolor
    prevstyle = @font_style
    if color.empty?
      SetTextColorArray(@html_link_color_array)
    else
      SetTextColorArray(color)
    end
    if style == -1
      SetFont('', @font_style + @html_link_font_style)
    else
      SetFont('', @font_style + style)
    end
    ret = Write(@lasth, name, url, fill, '', false, 0, firstline, firstblock, 0)
    # restore settings
    SetFont('', prevstyle)
    SetTextColorArray(prevcolor)
    return ret
  end
  alias_method :add_html_link, :addHtmlLink

  #
  # Adds HTML anchor and remembers it's position
  # [@param string :anchor] html anchor id
  # [@access public]
  #
  def addHtmlAnchor(anchor)
    @html_anchors[anchor] = [@page, @y]
  end
  alias_method :add_html_anchor, :addHtmlAnchor

  #
  # Outputs HTML anchor position
  # [@param string :anchor] html anchor id
  # [@return array] [Page, Y] of anchor
  # [@access public]
  #
  def getHtmlAnchorPosition(anchor)
    @html_anchors[anchor]
  end
  alias_method :get_html_anchor_position, :getHtmlAnchorPosition

  #
  # Returns an associative array (keys: R,G,B) from an html color name or a six-digit or three-digit hexadecimal color representation (i.e. #3FE5AA or #7FF).
  # [@param string :color] html color
  # [@return array] RGB color or empty array in case of error.
  # [@access public]
  #
  def convertHTMLColorToDec(color = "#FFFFFF")
    color = color.gsub(/[\s]*/, '') # remove extra spaces
    color = color.downcase
    if !(dotpos = color.index('.')).nil?
      # remove class parent (i.e.: color.red)
      color = color[(dotpos + 1)..-1]
    end
    if color.length == 0
      return []
    end
    returncolor = ActiveSupport::OrderedHash.new
    #  RGB ARRAY
    if color[0,3] == 'rgb'
      codes = color.sub(/^rgb\(/, '')
      codes = codes.gsub(')', '')
      returncolor = codes.split(',', 3)
      returncolor[0] = returncolor[0].to_i
      returncolor[1] = returncolor[1].to_i
      returncolor[2] = returncolor[2].to_i
      return returncolor
    end
    # CMYK ARRAY
    if color[0,4] == 'cmyk'
      codes = color.sub(/^cmyk\(/, '')
      codes = codes.gsub(')', '')
      returncolor[0] = returncolor[0].to_i
      returncolor[1] = returncolor[1].to_i
      returncolor[2] = returncolor[2].to_i
      returncolor[3] = returncolor[3].to_i
      return returncolor
    end
    # COLOR NAME
    if color[0].chr != "#"
      # decode color name
      if @@webcolor[color]
        color_code = @@webcolor[color]
      else
        return []
      end
    else
      color_code = color.sub(/^#/, "")
    end
    # RGB VALUE
    case color_code.length
    when 3
      # three-digit hexadecimal representation
      r = color_code[0]
      g = color_code[1]
      b = color_code[2]
      returncolor['R'] = (r + r).hex
      returncolor['G'] = (g + g).hex
      returncolor['B'] = (b + b).hex
    when 6
      # six-digit hexadecimal representation
      returncolor['R'] = color_code[0,2].hex
      returncolor['G'] = color_code[2,2].hex
      returncolor['B'] = color_code[4,2].hex
    else
      returncolor = []
    end
    return returncolor
  end
  alias_method :convert_html_color_to_dec, :convertHTMLColorToDec

  #
  # Converts pixels to Units.
  # [@param int] :px pixels
  # [@return float] millimeters
  # [@access public]
  # [@see] setImageScale(), getImageScale()
  #
  def pixelsToUnits(px)
    return (px.to_f / (@img_scale * @k))
  end
  alias_method :pixels_to_units, :pixelsToUnits

  #
  # Reverse function for htmlentities.
  # Convert entities in UTF-8.
  #
  # [@param :text_to_convert] Text to convert.
  # [@return string] converted
  # [@access public]
  #
  def unhtmlentities(string)
    if @@decoder.nil?
      CGI.unescapeHTML(string)
    else
      @@decoder.decode(string)
    end
  end

  # ENCRYPTION METHODS ----------------------------------

  #
  # Encrypt the input string.
  # * Note: not yet implemented.
  # [@param int :n] object number
  # [@param string :s] data string to encrypt
  # [@access protected]
  # [@author] Nicola Asuni
  # [@since 5.0.005 (2010-05-11)]
  #
  def encrypt_data(n, s)
    #unless @encrypted
      return s
    #end
    #case @encryptdata['mode']
    #when 0, 1:   # 0: RC4 40 bit, 1: RC4 128 bit
    #  s = _RC4(objectkey(n), s)
    #when 2:      # AES 128 bit
    #  s = _AES(objectkey(n), s)
    #end
    #return s
  end
  protected :encrypt_data

  # END OF ENCRYPTION FUNCTIONS -------------------------

  # START TRANSFORMATIONS SECTION -----------------------

  #
  # Starts a 2D tranformation saving current graphic state.
  # This function must be called before scaling, mirroring, translation, rotation and skewing.
  # Use StartTransform() before, and StopTransform() after the transformations to restore the normal behavior.
  # [@access public]
  # [@since 2.1.000 (2008-01-07)]
  # [@see] StartTransform(), StopTransform()
  #
  def StartTransform
    out('q');
    @transfmrk[@page] = @pagelen[@page]
    @transfmatrix_key += 1
    @transfmatrix[@transfmatrix_key] = []
  end
  alias_method :start_transform, :StartTransform

  #
  # Stops a 2D tranformation restoring previous graphic state.
  # This function must be called after scaling, mirroring, translation, rotation and skewing.
  # Use StartTransform() before, and StopTransform() after the transformations to restore the normal behavior.
  # [@access public]
  # [@since 2.1.000 (2008-01-07)]
  # [@see] StartTransform(), StopTransform()
  #
  def StopTransform
    out('Q');
    if @transfmatrix[@transfmatrix_key]
      @transfmatrix[@transfmatrix_key].pop
      @transfmatrix_key -= 1
    end
    @transfmrk[@page] = nil
  end
  alias_method :stop_transform, :StopTransform

  #
  # Rotate object.
  # [@param float :angle] angle in degrees for counter-clockwise rotation
  # [@param int :x] abscissa of the rotation center. Default is current x position
  # [@param int :y] ordinate of the rotation center. Default is current y position
  # [@access public]
  # [@since 2.1.000 (2008-01-07)]
  # [@see] StartTransform(), StopTransform()
  #
  def Rotate(angle, x="", y="")
    if (x == '')
      x = @x
    end

    if (y == '')
      y = @y
    end

    y = (@h - y) * @k
    x *= @k

    # calculate elements of transformation matrix
    tm = []
    tm[0] = ::Math::cos(angle * ::Math::PI / 180) # deg2rad
    tm[1] = ::Math::sin(angle * ::Math::PI / 180) # deg2rad
    tm[2] = -tm[1]
    tm[3] = tm[0]
    tm[4] = x + tm[1] * y - tm[0] * x
    tm[5] = y - tm[0] * y - tm[1] * x

    # generate the transformation matrix
    Transform(tm)
  end
  alias_method :rotate, :Rotate

  #
  # Apply graphic transformations.
  # [@param array :tm] transformation matrix
  # [@access protected]
  # [@since 2.1.000 (2008-01-07)]
  # [@see] StartTransform(), StopTransform()
  #
  def Transform(tm)
    out(sprintf('%.3f %.3f %.3f %.3f %.3f %.3f cm', tm[0], tm[1], tm[2], tm[3], tm[4], tm[5]))
    # add tranformation matrix
    @transfmatrix[@transfmatrix_key].push 'a' => tm[0], 'b' => tm[1], 'c' => tm[2], 'd' => tm[3], 'e' => tm[4], 'f' => tm[5]
    # update tranformation mark
    if !@transfmrk[@page].nil?
      @transfmrk[@page] = @pagelen[@page]
    end
  end
  protected :Transform

  # END TRANSFORMATIONS SECTION -------------------------

  # START GRAPHIC FUNCTIONS SECTION ---------------------
  # The following section is based on the code provided by David Hernandez Sanz

  #
  # Defines the line width. By default, the value equals 0.2 mm. The method can be called before the first page is created and the value is retained from page to page.
  # [@param float :width] The width.
  # [@access public]
  # [@since 1.0]
  # [@see] Line(), Rect(), Cell(), MultiCell()
  #
  def SetLineWidth(width)
    #Set line width
    @line_width = width;
    @linestyle_width = sprintf('%.2f w', width * @k)
    if (@page>0)
      out(@linestyle_width)
    end
  end
  alias_method :set_line_width, :SetLineWidth

  #
  # Returns the current the line width.
  # [@return int] Line width
  # [@access public]
  # [@since 2.1.000 (2008-01-07)]
  # [@see] Line(), SetLineWidth()
  #
  def GetLineWidth()
    return @line_width
  end
  alias_method :get_line_width, :GetLineWidth

  #
  # Set line style.
  # [@param hash :style]
  #   Line style. Array with keys among the following:
  #   * width (float): Width of the line in user units.
  #   * cap (string): Type of cap to put on the line. Possible values are: butt, round, square. The difference between "square" and "butt" is that "square" projects a flat end past the end of the line.
  #   * join (string): Type of join. Possible values are: miter, round, bevel.
  #   * dash (mixed): Dash pattern. Is 0 (without dash) or string with series of length values, which are the lengths of the on and off dashes. For example: "2" represents 2 on, 2 off, 2 on, 2 off, ...; "2,1" is 2 on, 1 off, 2 on, 1 off, ...
  #   * phase (integer): Modifier on the dash pattern which is used to shift the point at which the pattern starts.
  #   * color (array): Draw color. Format: array(GREY) or array(R,G,B) or array(C,M,Y,K).
  # [@access public]
  # [@since 2.1.000 (2008-01-08)]
  #
  def SetLineStyle(style)
    unless style.is_a? Hash
      return
    end
    if !style['width'].nil?
      width = style['width']
      width_prev = @line_width
      SetLineWidth(width)
      @line_width = width_prev
    end
    if !style['cap'].nil?
      cap = style['cap']
      ca = {'butt' => 0, 'round'=> 1, 'square' => 2}
      if !ca[cap].nil?
        @linestyle_cap = ca[cap].to_s + ' J'
        out(@linestyle_cap)
      end
    end
    if !style['join'].nil?
      join = style['join']
      ja = {'miter' => 0, 'round' => 1, 'bevel' => 2}
      if !ja[join].nil?
        @linestyle_join = ja[join].to_s + ' j'
        out(@linestyle_join);
      end
    end
    if !style['dash'].nil?
      dash = style['dash']
      dash_string = ''
      if dash != 0 and dash != ''
        if dash.is_a?(String) && dash =~ /^.+,/
          tab = dash.split(',')
        else
          tab = [dash]
        end
        dash_string = ''
        tab.each_with_index { |v, i|
          if i != 0
            dash_string << ' '
          end
          dash_string << sprintf("%.2f", v.to_f)
        }
      end
      phase = 0
      @linestyle_dash = sprintf("[%s] %.2f d", dash_string, phase)
      out(@linestyle_dash)
    end
    if !style['color'].nil?
      color = style['color']
      SetDrawColorArray(color)
    end
  end
  alias_method :set_line_style, :SetLineStyle

protected

  #
  # Begin a new subpath by moving the current point to coordinates (x, y), omitting any connecting line segment.
  # [@param float :x] Abscissa of point.
  # [@param float :y] Ordinate of point.
  # [@access protected]
  # [@since 2.1.000 (2008-01-08)]
  #
  def outPoint(x, y)
    out(sprintf("%.2f %.2f m", x * @k, (@h - y) * @k))
  end

  #
  # Append a straight line segment from the current point to the point (x, y).
  # The new current point shall be (x, y).
  # [@param float :x] Abscissa of end point.
  # [@param float :y] Ordinate of end point.
  # [@access protected]
  # [@since 2.1.000 (2008-01-08)]
  #
  def outLine(x, y)
    out(sprintf("%.2f %.2f l", x * @k, (@h - y) * @k))
  end

  #
  # Append a rectangle to the current path as a complete subpath, with lower-left corner (x, y) and dimensions widthand height in user space.
  # [@param float :x] Abscissa of upper-left corner (or upper-right corner for RTL language).
  # [@param float :y] Ordinate of upper-left corner (or upper-right corner for RTL language).
  # [@param float :w] Width.
  # [@param float :h] Height.
  # [@param string :op] options
  # [@access protected]
  # [@since 2.1.000 (2008-01-08)]
  #
  def outRect(x, y, w, h, op)
    out(sprintf('%.2f %.2f %.2f %.2f re %s', x * @k, (@h - y) * @k, w * @k, -h * @k, op))
  end

  #
  # Append a cubic Bezier curve to the current path. The curve shall extend from the current point to the point (x3, y3), using (x1, y1) and (x2, y2) as the Bezier control points.
  # The new current point shall be (x3, y3).
  # [@param float :x1] Abscissa of control point 1.
  # [@param float :y1] Ordinate of control point 1.
  # [@param float :x2] Abscissa of control point 2.
  # [@param float :y2] Ordinate of control point 2.
  # [@param float :x3] Abscissa of end point.
  # [@param float :y3] Ordinate of end point.
  # [@access protected]
  # [@since 2.1.000 (2008-01-08)]
  #
  def outCurve(x1, y1, x2, y2, x3, y3)
    out(sprintf("%.2f %.2f %.2f %.2f %.2f %.2f c", x1 * @k, (@h - y1) * @k, x2 * @k, (@h - y2) * @k, x3 * @k, (@h - y3) * @k))
  end

  #
  # Append a cubic Bezier curve to the current path. The curve shall extend from the current point to the point (x3, y3), using the current point and (x2, y2) as the Bezier control points.
  # The new current point shall be (x3, y3).
  # [@param float :x2] Abscissa of control point 2.
  # [@param float :y2] Ordinate of control point 2.
  # [@param float :x3] Abscissa of end point.
  # [@param float :y3] Ordinate of end point.
  # [@access protected]
  # [@since 4.9.019 (2010-04-26)]
  #
  def outCurveV(x2, y2, x3, y3)
    out(sprintf('%.2f %.2f %.2f %.2f v', x2 * @k, (@h - y2) * @k, x3 * @k, (@h - y3) * @k))
  end

  #
  # Append a cubic Bezier curve to the current path. The curve shall extend from the current point to the point (x3, y3), using (x1, y1) and (x3, y3) as the Bezier control points.
  # The new current point shall be (x3, y3).
  # [@param float :x1] Abscissa of control point 1.
  # [@param float :y1] Ordinate of control point 1.
  # [@param float :x2] Abscissa of control point 2.
  # [@param float :y2] Ordinate of control point 2.
  # [@param float :x3] Abscissa of end point.
  # [@param float :y3] Ordinate of end point.
  # [@access protected]
  # [@since 4.9.019 (2010-04-26)]
  #
  def outCurveY(x1, y1, x3, y3)
    out(sprintf('%.2f %.2f %.2f %.2f y', x1 * @k, (@h - y1) * @k, x3 * @k, (@h - y3) * @k))
  end

public

  #
  # Draws a line between two points.
  # [@param float :x1] Abscissa of first point
  # [@param float :y1] Ordinate of first point
  # [@param float :x2] Abscissa of second point
  # [@param float :y2]] Ordinate of second point
  # [@param hash :style] Line style. Array like for {@link SetLineStyle SetLineStyle}. Default value: default line style (empty array).
  # [@access public]
  # [@since 1.0]
  # [@see] SetLineWidth(), SetDrawColor(), SetLineStyle()
  #
  def Line(x1, y1, x2, y2, style=nil)
    if style.is_a? Hash
      SetLineStyle(style)
    end
    outPoint(x1, y1)
    outLine(x2, y2)
    out('S')
  end
  alias_method :line, :Line

  #
  # Draws a rectangle.
  # [@param float :x] Abscissa of upper-left corner (or upper-right corner for RTL language).
  # [@param float :y] Ordinate of upper-left corner (or upper-right corner for RTL language).
  # [@param float :w] Width.
  # [@param float :h] Height.
  # [@param string :style]
  #   Style of rendering. See the getPathPaintOperator() function for more information.
  #   * all: Line style of all borders. Array like for {@link SetLineStyle SetLineStyle}.
  #   * L, T, R, B or combinations: Line style of left, top, right or bottom border. Array like for {@link SetLineStyle SetLineStyle}.
  #   If a key is not present or is null, not draws the border. Default value: default line style (empty array).
  # [@param array :border_style] Border style of rectangle. Array like for {@link SetLineStyle SetLineStyle}. Default value: default line style (empty array).
  # [@param array :fill_color] Fill color. Format: array(GREY) or array(R,G,B) or array(C,M,Y,K). Default value: default color (empty array).
  # [@access public]
  # [@since 1.0]
  # [@see] SetLineStyle()
  #
  def Rect(x, y, w, h, style='', border_style={}, fill_color={})
    if style.index('F') != nil and !fill_color.empty?
      SetFillColorArray(fill_color)
    end
    op = getPathPaintOperator(style)
    if !border_style or !border_style['all'].nil?
      if !border_style['all'].nil? and border_style['all']
        SetLineStyle(border_style['all'])
        border_style = {}
      end
    end
    outRect(x, y, w, h, op)

    if border_style
      border_style2 = {}
      border_style.each { |line, value|
        length = line.length
        0.upto(length - 1) do |i|
          border_style2[line[i]] = value
        end
      }
      border_style = border_style2
      if !border_style['L'].nil? and border_style['L']
        Line(x, y, x, y + h, border_style['L'])
      end
      if !border_style['T'].nil? and border_style['T']
        Line(x, y, x + w, y, border_style['T'])
      end
      if !border_style['R'].nil? and border_style['R']
        Line(x + w, y, x + w, y + h, border_style['R'])
      end
      if !border_style['B'].nil? and border_style['B']
        Line(x, y + h, x + w, y + h, border_style['B'])
      end
    end
  end
  alias_method :rect, :Rect

  #
  # Draws a Bezier curve.
  # The Bezier curve is a tangent to the line between the control points at
  # either end of the curve.
  # [@param float :x0] Abscissa of start point.
  # [@param float :y0] Ordinate of start point.
  # [@param float :x1] Abscissa of control point 1.
  # [@param float :y1] Ordinate of control point 1.
  # [@param float :x2] Abscissa of control point 2.
  # [@param float :y2] Ordinate of control point 2.
  # [@param float :x3] Abscissa of end point.
  # [@param float :y3] Ordinate of end point.
  # [@param string :style] Style of rendering. See the getPathPaintOperator() function for more information.
  # [@param array :line_style] Line style of curve. Array like for {@link SetLineStyle SetLineStyle}. Default value: default line style (empty array).
  # [@param array :fill_color] Fill color. Format: array(GREY) or array(R,G,B) or array(C,M,Y,K). Default value: default color (empty array).
  # [@access public]
  # [@see] SetLineStyle()
  # [@since 2.1.000 (2008-01-08)]
  #
  def Curve(x0, y0, x1, y1, x2, y2, x3, y3, style='', line_style=nil, fill_color=nil)
    if style and (style.index('F') != nil) and fill_color
      SetFillColorArray(fill_color)
    end
    op = getPathPaintOperator(style)
    if line_style
      SetLineStyle(line_style)
    end
    outPoint(x0, y0)
    outCurve(x1, y1, x2, y2, x3, y3)
    out(op)
  end
  alias_method :curve, :Curve

  #
  # Draws an ellipse.
  # An ellipse is formed from n Bezier curves.
  # [@param float :x0] Abscissa of center point.
  # [@param float :y0] Ordinate of center point.
  # [@param float :rx] Horizontal radius.
  # [@param float :ry] Vertical radius (if ry = 0 then is a circle, see {@link Circle Circle}). Default value: 0.
  # [@param float :angle] Angle oriented (anti-clockwise). Default value: 0.
  # [@param float :astart] Angle start of draw line. Default value: 0.
  # [@param float :afinish] Angle finish of draw line. Default value: 360.
  # [@param string :style] Style of rendering. See the getPathPaintOperator() function for more information.
  # [@param array :line_style] Line style of ellipse. Array like for {@link SetLineStyle SetLineStyle}. Default value: default line style (empty array).
  # [@param array :fill_color] Fill color. Format: array(GREY) or array(R,G,B) or array(C,M,Y,K). Default value: default color (empty array).
  # [@param integer :nc] Number of curves used to draw a 90 degrees portion of ellipse.
  # [@author] Nicola Asuni
  # [@access public]
  # [@since 2.1.000 (2008-01-08)]
  #
  def Ellipse(x0, y0, rx, ry='', angle=0, astart=0, afinish=360, style='', line_style=nil, fill_color=nil, nc=2)
    style = '' if style.nil?
    if empty_string(ry) or (ry == 0)
      ry = rx
    end
    if (nil != style.index('F')) and fill_color
      SetFillColorArray(fill_color)
    end
    op = getPathPaintOperator(style)
    if op == 'f'
      line_style = nil
    end

    if line_style and !line_style.empty?
      SetLineStyle(line_style)
    end
    outellipticalarc(x0, y0, rx, ry, angle, astart, afinish, false, nc)
    out(op)
  end
  alias_method :ellipse, :Ellipse

  #
  # Append an elliptical arc to the current path.
  # An ellipse is formed from n Bezier curves.
  # [@param float :xc] Abscissa of center point.
  # [@param float :yc] Ordinate of center point.
  # [@param float :rx] Horizontal radius.
  # [@param float :ry] Vertical radius (if ry = 0 then is a circle, see {@link Circle Circle}). Default value: 0.
  # [@param float :xang] Angle between the X-axis and the major axis of the ellipse. Default value: 0.
  # [@param float :angs] Angle start of draw line. Default value: 0.
  # [@param float :angf] Angle finish of draw line. Default value: 360.
  # [@param boolean :pie] if true do not mark the border point (used to draw pie sectors).
  # [@param integer :nc] Number of curves used to draw a 90 degrees portion of ellipse.
  # [@author] Nicola Asuni
  # [@access protected]
  # [@since 4.9.019 (2010-04-26)]
  #
  def outellipticalarc(xc, yc, rx, ry, xang=0, angs=0, angf=360, pie=false, nc=2)
    return if rx == 0 && ry == 0

    k = @k
    if nc < 2
      nc = 2
    end
    if pie
      # center of the arc
      outPoint(xc, yc)
    end
    xang = xang * ::Math::PI / 180 # deg2rad
    angs = angs * ::Math::PI / 180 # deg2rad
    angf = angf * ::Math::PI / 180 # deg2rad
    as = ::Math.atan2((::Math.sin(angs) / ry), (::Math.cos(angs) / rx))
    af = ::Math.atan2((::Math.sin(angf) / ry), (::Math.cos(angf) / rx))
    if as < 0
      as += (2 * ::Math::PI)
    end
    if af < 0
      af += (2 * ::Math::PI)
    end
    if as > af
      # reverse rotation go clockwise
      as -= (2 * ::Math::PI)
    end
    total_angle = af - as
    if nc < 2
      nc = 2
    end
    # total arcs to draw
    nc *= (2 * total_angle.abs / ::Math::PI)
    nc = nc.round + 1
    # angle of each arc
    arcang = total_angle / nc
    # center point in PDF coordiantes
    x0 = xc
    y0 = @h - yc
    # starting angle
    ang = as
    alpha = ::Math.sin(arcang) * (::Math.sqrt(4 + 3 * (::Math.tan(arcang / 2) ** 2)) - 1) / 3
    cos_xang = ::Math.cos(xang)
    sin_xang = ::Math.sin(xang)
    cos_ang = ::Math.cos(ang)
    sin_ang = ::Math.sin(ang)
    # first arc point
    px1 = x0 + (rx * cos_xang * cos_ang) - (ry * sin_xang * sin_ang)
    py1 = y0 + (rx * sin_xang * cos_ang) + (ry * cos_xang * sin_ang)
    # first Bezier control point
    qx1 = alpha * ((-rx * cos_xang * sin_ang) - (ry * sin_xang * cos_ang))
    qy1 = alpha * ((-rx * sin_xang * sin_ang) + (ry * cos_xang * cos_ang))
    if pie
      outLine(px1, @h - py1)
    else
      outPoint(px1, @h - py1)
    end
    # draw arcs
    1.upto(nc) do |i|
      # starting angle
      ang = as + i * arcang
      cos_xang = ::Math.cos(xang)
      sin_xang = ::Math.sin(xang)
      cos_ang = ::Math.cos(ang)
      sin_ang = ::Math.sin(ang)
      # second arc point
      px2 = x0 + (rx * cos_xang * cos_ang) - (ry * sin_xang * sin_ang)
      py2 = y0 + (rx * sin_xang * cos_ang) + (ry * cos_xang * sin_ang)
      # second Bezier control point
      qx2 = alpha * ((-rx * cos_xang * sin_ang) - (ry * sin_xang * cos_ang))
      qy2 = alpha * ((-rx * sin_xang * sin_ang) + (ry * cos_xang * cos_ang))
      # draw arc
      outCurve(px1 + qx1, @h - (py1 + qy1), px2 - qx2, @h - (py2 - qy2), px2, @h - py2)
      # move to next point
      px1 = px2
      py1 = py2
      qx1 = qx2
      qy1 = qy2
    end
    if pie
      outLine(xc, yc)
    end
  end
  protected :outellipticalarc

  #
  # Draws a circle.
  # A circle is formed from n Bezier curves.
  # [@param float :x0] Abscissa of center point.
  # [@param float :y0] Ordinate of center point.
  # [@param float :r] Radius.
  # [@param float :angstr] Angle start of draw line. Default value: 0.
  # [@param float :angend] Angle finish of draw line. Default value: 360.
  # [@param string :style] Style of rendering. See the getPathPaintOperator() function for more information.
  # [@param array :line_style] Line style of circle. Array like for {@link SetLineStyle SetLineStyle}. Default value: default line style (empty array).
  # [@param array :fill_color] Fill color. Format: array(red, green, blue). Default value: default color (empty array).
  # [@param integer :nc] Number of curves used to draw a 90 degrees portion of circle.
  # [@access public]
  # [@since 2.1.000 (2008-01-08)]
  #
  def Circle(x0, y0, r, angstr=0, angend=360, style='', line_style=nil, fill_color=nil, nc=2)
    Ellipse(x0, y0, r, r, 0, angstr, angend, style, line_style, fill_color, nc)
  end
  alias_method :circle, :Circle

  #
  # Draws a polygonal line
  # [@param array :p] Points 0 to (:np - 1). Array with values (x0, y0, x1, y1,..., x(np-1), y(np - 1))
  # [@param string :style] Style of rendering. See the getPathPaintOperator() function for more information.
  # [@param array :line_style]
  #   Line style of polygon. Array with keys among the following:
  #   * all: Line style of all lines. Array like for {@link SetLineStyle SetLineStyle}.
  #   * 0 to (:np - 1): Line style of each line. Array like for {@link SetLineStyle SetLineStyle}.
  #   If a key is not present or is null, not draws the line. Default value is default line style (empty array).
  # [@param array :fill_color Fill color. Format: array(GREY) or array(R,G,B) or array(C,M,Y,K). Default value: default color (empty array).
  # [@param boolean :closed if true the polygon is closes, otherwise will remain open
  # [@access public]
  # [@since 4.8.003 (2009-09-15)]
  #
  def PolyLine(p, style='', line_style=nil, fill_color=nil)
    Polygon(p, style, line_style, fill_color, false)
  end
  alias_method :poly_line, :PolyLine

  #
  # Draws a polygon.
  # [@param array :p] Points 0 to (np - 1). Array with values (x0, y0, x1, y1,..., x(np-1), y(np - 1))
  # [@param string :style] Style of rendering. See the getPathPaintOperator() function for more information.
  # [@param array :line_style]
  #   Line style of polygon. Array with keys among the following:
  #   * all: Line style of all lines. Array like for {@link SetLineStyle SetLineStyle}.
  #   * 0 to (:np - 1): Line style of each line. Array like for {@link SetLineStyle SetLineStyle}.
  # If a key is not present or is null, not draws the line. Default value is default line style (empty array).
  # [@param array :fill_color] Fill color. Format: array(GREY) or array(R,G,B) or array(C,M,Y,K). Default value: default color (empty array).
  # [@param boolean :closed] if true the polygon is closes, otherwise will remain open
  # [@access public]
  # [@since 2.1.000 (2008-01-08)]
  #
  def Polygon(p, style='', line_style=nil, fill_color=nil, closed=true)
    style = '' if style.nil?
    nc = p.length # number of coordinates
    np = nc / 2 # number of points
    if closed
      # close polygon by adding the first 2 points at the end (one line)
      0.upto(3) do |i|
        p[nc + i] = p[i]
      end
      # copy style for the last added line
      if line_style
        if line_style.is_a? Array and line_style[0]
          line_style[np] = line_style[0]
        elsif line_style.is_a? Hash and line_style['all']
          line_style[np] = line_style['all']
        end
      end
      nc += 4
    end
    if (nil != style.index('F')) and fill_color
      SetFillColorArray(fill_color)
    end
    op = getPathPaintOperator(style)
    if op == 'f'
      line_style = []
    end
    draw = true
    if line_style
      if line_style.is_a? Hash and line_style['all']
        SetLineStyle(line_style['all'])
      else
        draw = false
        if op == 'B'
          # draw fill
          op = 'f'
          outPoint(p[0], p[1])
          2.step(nc - 1, 2) do |i|
            outLine(p[i], p[i + 1])
          end
          out(op)
        end
        # draw outline
        outPoint(p[0], p[1])
        2.step(nc - 1, 2) do |i|
          line_num = i / 2 - 1
          if line_style[line_num]
            if line_style[line_num] != 0
              if line_style[line_num].is_a? Hash
                out('S')
                SetLineStyle(line_style[line_num])
                outPoint(p[i - 2], p[i - 1])
                outLine(p[i], p[i + 1])
                out('S')
                outPoint(p[i], p[i + 1])
              else
                outLine(p[i], p[i + 1])
              end
            end
          else
            outLine(p[i], p[i + 1])
          end
        end
        out(op)
      end
    end
    if draw
      outPoint(p[0], p[1])
      2.step(nc - 1, 2) do |i|
        outLine(p[i], p[i + 1])
      end
      out(op)
    end
  end
  alias_method :polygon, :Polygon

  #
  # Draws a regular polygon.
  # [@param float :x0] Abscissa of center point.
  # [@param float :y0] Ordinate of center point.
  # [@param float :r] Radius of inscribed circle.
  # [@param integer :ns] Number of sides.
  # [@param float :angle] Angle oriented (anti-clockwise). Default value: 0.
  # [@param boolean :draw_circle] Draw inscribed circle or not. Default value: false.
  # [@param string :style] Style of rendering. See the getPathPaintOperator() function for more information.
  # [@param array :line_style]
  #   Line style of polygon sides. Array with keys among the following:
  #   * all: Line style of all sides. Array like for {@link SetLineStyle SetLineStyle}.
  #   * 0 to (:ns - 1): Line style of each side. Array like for {@link SetLineStyle SetLineStyle}.
  #   If a key is not present or is null, not draws the side. Default value is default line style (empty array).
  # [@param array :fill_color] Fill color. Format: array(red, green, blue). Default value: default color (empty array).
  # [@param string :circle_style]
  #   Style of rendering of inscribed circle (if draws). Possible values are:
  #   * D or empty string: Draw (default).
  #   * F: Fill.
  #   * DF or FD: Draw and fill.
  #   * CNZ: Clipping mode (using the even-odd rule to determine which regions lie inside the clipping path).
  #   * CEO: Clipping mode (using the nonzero winding number rule to determine which regions lie inside the clipping path).
  # [@param array :circle_outLine_style] Line style of inscribed circle (if draws). Array like for {@link SetLineStyle SetLineStyle}. Default value: default line style (empty array).
  # [@param array :circle_fill_color] Fill color of inscribed circle (if draws). Format: array(red, green, blue). Default value: default color (empty array).
  # [@access public]
  # [@since 2.1.000 (2008-01-08)]
  #
  def RegularPolygon(x0, y0, r, ns, angle=0, draw_circle=false, style='', line_style=nil, fill_color=nil, circle_style='', circle_outLine_style=nil, circle_fill_color=nil)
    draw_circle = false if draw_circle == 0
    if 3 > ns
      ns = 3
    end
    if draw_circle
      Circle(x0, y0, r, 0, 360, circle_style, circle_outLine_style, circle_fill_color)
    end
    p = []
    0.upto(ns - 1) do |i|
      a = angle + i * 360 / ns
      a_rad = a * ::Math::PI / 180 # deg2rad
      p.push x0 + (r * ::Math.sin(a_rad))
      p.push y0 + (r * ::Math.cos(a_rad))
    end
    Polygon(p, style, line_style, fill_color)
  end
  alias_method :regular_polygon, :RegularPolygon

  #
  # Draws a star polygon
  # [@param float :x0] Abscissa of center point.
  # [@param float :y0] Ordinate of center point.
  # [@param float :r] Radius of inscribed circle.
  # [@param integer :nv] Number of vertices.
  # [@param integer :ng] Number of gap (if (:ng % :nv = 1) then is a regular polygon).
  # [@param float :angle] Angle oriented (anti-clockwise). Default value: 0.
  # [@param boolean :draw_circle] Draw inscribed circle or not. Default value is false.
  # [@param string :style] Style of rendering. See the getPathPaintOperator() function for more information.
  # [@param array :line_style]
  #   Line style of polygon sides. Array with keys among the following:
  #   * all: Line style of all sides. Array like for {@link SetLineStyle SetLineStyle}.
  #   * 0 to (n - 1): Line style of each side. Array like for {@link SetLineStyle SetLineStyle}.
  # If a key is not present or is null, not draws the side. Default value is default line style (empty array).
  # [@param array :fill_color ]Fill color. Format: array(red, green, blue). Default value: default color (empty array).
  # [@param string :circle_style]
  #   Style of rendering of inscribed circle (if draws). Possible values are:
  #   * D or empty string: Draw (default).
  #   * F: Fill.
  #   * DF or FD: Draw and fill.
  #   * CNZ: Clipping mode (using the even-odd rule to determine which regions lie inside the clipping path).
  #   * CEO: Clipping mode (using the nonzero winding number rule to determine which regions lie inside the clipping path).
  # [@param array :circle_outLine_style] Line style of inscribed circle (if draws). Array like for {@link SetLineStyle SetLineStyle}. Default value: default line style (empty array).
  # [@param array :circle_fill_color] Fill color of inscribed circle (if draws). Format: array(red, green, blue). Default value: default color (empty array).
  # [@access public]
  # [@since 2.1.000 (2008-01-08)]
  #
  def StarPolygon(x0, y0, r, nv, ng, angle=0, draw_circle=false, style='', line_style=nil, fill_color=nil, circle_style='', circle_outLine_style=nil, circle_fill_color=nil)
    draw_circle = false if draw_circle == 0
    if nv < 2
      nv = 2
    end
    if draw_circle
      Circle(x0, y0, r, 0, 360, circle_style, circle_outLine_style, circle_fill_color)
    end
    p2 = []
    visited = []
    0.upto(nv - 1) do |i|
      a = angle + i * 360 / nv
      a_rad = a * ::Math::PI / 180 # deg2rad
      p2.push x0 + r * ::Math.sin(a_rad)
      p2.push y0 + r * ::Math.cos(a_rad)
      visited.push false
    end
    p = []
    i = 0
    while true
      p.push p2[i * 2]
      p.push p2[i * 2 + 1]
      visited[i] = true
      i += ng
      i %= nv
      break if visited[i]
    end
    Polygon(p, style, line_style, fill_color)
  end
  alias_method :star_polygon, :StarPolygon

  #
  # Draws a rounded rectangle.
  # [@param float :x] Abscissa of upper-left corner.
  # [@param float :y] Ordinate of upper-left corner.
  # [@param float :w] Width.
  # [@param float :h] Height.
  # [@param float :r] the radius of the circle used to round off the corners of the rectangle.
  # [@param string :round_corner] Draws rounded corner or not. String with a 0 (not rounded i-corner) or 1 (rounded i-corner) in i-position. Positions are, in order and begin to 0: top left, top right, bottom right and bottom left. Default value: all rounded corner ("1111").
  # [@param string :style] Style of rendering. See the getPathPaintOperator() function for more information.
  # [@param array :border_style] Border style of rectangle. Array like for {@link SetLineStyle SetLineStyle}. Default value: default line style (empty array).
  # [@param array :fill_color] Fill color. Format: array(GREY) or array(R,G,B) or array(C,M,Y,K). Default value: default color (empty array).
  # [@access public]
  # [@since 2.1.000 (2008-01-08)]
  #
  def RoundedRect(x, y, w, h, r, round_corner='1111', style='', border_style=nil, fill_color=nil)
    RoundedRectXY(x, y, w, h, r, r, round_corner, style, border_style, fill_color)
  end
  alias_method :rounded_rect, :RoundedRect

  #
  # Draws a rounded rectangle.
  # [@param float :x] Abscissa of upper-left corner.
  # [@param float :y] Ordinate of upper-left corner.
  # [@param float :w] Width.
  # [@param float :h] Height.
  # [@param float :rx] the x-axis radius of the ellipse used to round off the corners of the rectangle.
  # [@param float :ry] the y-axis radius of the ellipse used to round off the corners of the rectangle.
  # [@param string :round_corner] Draws rounded corner or not. String with a 0 (not rounded i-corner) or 1 (rounded i-corner) in i-position. Positions are, in order and begin to 0: top left, top right, bottom right and bottom left. Default value: all rounded corner ("1111").
  # [@param string :style] Style of rendering. See the getPathPaintOperator() function for more information.
  # [@param array :border_style] Border style of rectangle. Array like for {@link SetLineStyle SetLineStyle}. Default value: default line style (empty array).
  # [@param array :fill_color] Fill color. Format: array(GREY) or array(R,G,B) or array(C,M,Y,K). Default value: default color (empty array).
  # [@access public]
  # [@since 4.9.019 (2010-04-22)]
  #
  def RoundedRectXY(x, y, w, h, rx, ry, round_corner='1111', style='', border_style=nil, fill_color=nil)
    style = '' if style.nil?
    if (round_corner == '0000') or ((rx == ry) and (rx == 0))
      # Not rounded
      Rect(x, y, w, h, style, border_style, fill_color)
      return
    end
    # Rounded
    if (nil != style.index('F')) and fill_color
      SetFillColorArray(fill_color)
    end
    op = getPathPaintOperator(style)
    if op == 'f'
      border_style = []
    end
    if border_style
      SetLineStyle(border_style)
    end
    myArc = 4 / 3.0 * (::Math.sqrt(2) - 1)
    outPoint(x + rx, y)
    xc = x + w - rx
    yc = y + ry
    outLine(xc, y)
    if round_corner[0,1] == '1'
      outCurve(xc + (rx * myArc), yc - ry, xc + rx, yc - (ry * myArc), xc + rx, yc)
    else
      outLine(x + w, y)
    end
    xc = x + w - rx
    yc = y + h - ry
    outLine(x + w, yc)
    if round_corner[1,1] == '1'
      outCurve(xc + rx, yc + (ry * myArc), xc + (rx * myArc), yc + ry, xc, yc + ry)
    else
      outLine(x + w, y + h)
    end
    xc = x + rx
    yc = y + h - ry
    outLine(xc, y + h)
    if round_corner[2,1] == '1'
      outCurve(xc - (rx * myArc), yc + ry, xc - rx, yc + (ry * myArc), xc - rx, yc)
    else
      outLine(x, y + h)
    end
    xc = x + rx
    yc = y + ry
    outLine(x, yc)
    if round_corner[3,1] == '1'
      outCurve(xc - rx, yc - (ry * myArc), xc - (rx * myArc), yc - ry, xc, yc - ry)
    else
      outLine(x, y)
      outLine(x + rx, y)
    end
    out(op)
  end
  alias_method :rounded_rect_xy, :RoundedRectXY

  #
  # Draws a grahic arrow.
  # [@parameter float :x0] Abscissa of first point.
  # [@parameter float :y0] Ordinate of first point.
  # [@parameter float :x0] Abscissa of second point.
  # [@parameter float :y1] Ordinate of second point.
  # [@parameter int :head_style] (0 = draw only arrowhead arms, 1 = draw closed arrowhead, but no fill, 2 = closed and filled arrowhead, 3 = filled arrowhead)
  # [@parameter float :arm_size] length of arrowhead arms
  # [@parameter int :arm_angle] angle between an arm and the shaft
  # [@author] Piotr Galecki, Nicola Asuni, Andy Meier
  # [@access public]
  # [@since 4.6.018 (2009-07-10)]
  #
  def Arrow(x0, y0, x1, y1, head_style=0, arm_size=5, arm_angle=15)
    # getting arrow direction angle
    # 0 deg angle is when both arms go along X axis. angle grows clockwise.
    dir_angle = ::Math.atan2(y0 - y1, x0 - x1)
    if dir_angle < 0
      dir_angle += 2 * ::Math::PI
    end
    arm_angle = arm_angle * ::Math::PI / 180 # deg2rad
    sx1 = x1
    sy1 = y1
    if head_style > 0
      # calculate the stopping point for the arrow shaft
      sx1 = x1 + (arm_size - @line_width) * ::Math.cos(dir_angle)
      sy1 = y1 + (arm_size - @line_width) * ::Math.sin(dir_angle)
    end
    # main arrow line / shaft
    Line(x0, y0, sx1, sy1)
    # left arrowhead arm tip
    x2L = x1 + (arm_size * ::Math.cos(dir_angle + arm_angle))
    y2L = y1 + (arm_size * ::Math.sin(dir_angle + arm_angle))
    # right arrowhead arm tip
    x2R = x1 + (arm_size * ::Math.cos(dir_angle - arm_angle))
    y2R = y1 + (arm_size * ::Math.sin(dir_angle - arm_angle))
    mode = 'D'
    style = []
    case head_style
    when 0
      # draw only arrowhead arms
      mode = 'D'
      style = [1, 1, 0]
    when 1
      # draw closed arrowhead, but no fill
      mode = 'D'
    when 2
      # closed and filled arrowhead
      mode = 'DF'
    when 3
      # filled arrowhead
      mode = 'F'
    end
    Polygon([x2L, y2L, x1, y1, x2R, y2R], mode, style, nil)
  end
  alias_method :arrow, :Arrow

  # END GRAPHIC FUNCTIONS SECTION -----------------------

  # BIDIRECTIONAL TEXT SECTION --------------------------

  #
  # Reverse the RLT substrings using the Bidirectional Algorithm (http://unicode.org/reports/tr9/).
  # [@param string :str] string to manipulate. (UTF-8)
  # [@param bool :setbom] if true set the Byte Order Mark (BOM = 0xFEFF)
  # [@param bool :forcertl] if true forces RTL text direction
  # [@return] string (UTF-16BE)
  # [@access protected]
  # [@author] Nicola Asuni
  # [@since 2.1.000 (2008-01-08)]
  #
  def utf8StrRev(str, setbom=false, forcertl=false)
    return utf8StrArrRev(UTF8StringToArray(str), str, setbom, forcertl)
  end
  protected :utf8StrRev

  #
  # Reverse the RLT substrings array using the Bidirectional Algorithm (http://unicode.org/reports/tr9/).
  # [@param array :arr] array of unicode values.
  # [@param string :str] string to manipulate (or empty value).
  # [@param bool :setbom] if true set the Byte Order Mark (BOM = 0xFEFF)
  # [@param bool :forcertl] if true forces RTL text direction
  # [@return string]
  # [@access protected]
  # [@author] Nicola Asuni
  # [@since 4.9.000 (2010-03-27)]
  #
  def utf8StrArrRev(arr, str='', setbom=false, forcertl=false)
    return arrUTF8ToUTF16BE(utf8Bidi(arr, str, forcertl), setbom)
  end
  protected :utf8StrArrRev

  #
  # Reverse the RLT substrings using the Bidirectional Algorithm (http://unicode.org/reports/tr9/).
  # [@param array :ta] array of characters composing the string. (UCS4)
  # [@param string :str] string to process
  # [@param bool :forcertl] if 'R' forces RTL, if 'L' forces LTR
  # [@return] array of unicode chars (UCS4)
  # [@author] Nicola Asuni
  # [@access protected]
  # [@since 2.4.000 (2008-03-06)]
  #
  def utf8Bidi(ta, str='', forcertl=false)
    str = str.dup
    # paragraph embedding level
    pel = 0
    # max level
    maxlevel = 0

    if empty_string(str)
      # create string from array
      str = UTF8ArrSubString(ta)
    end

    # check if string contains arabic text
    str.force_encoding('ASCII-8BIT') if str.respond_to?(:force_encoding)
    if str =~ @@k_re_pattern_arabic
      arabic = true
    else
      arabic = false
    end

    # check if string contains RTL text
    unless forcertl or arabic or (str =~ @@k_re_pattern_rtl)
      return ta
    end

    # get number of chars
    numchars = ta.length

    if forcertl == 'R'
      pel = 1
    elsif forcertl == 'L'
      pel = 0
    else
      # P2. In each paragraph, find the first character of type L, AL, or R.
      # P3. If a character is found in P2 and it is of type AL or R, then set the paragraph embedding level to one; otherwise, set it to zero.
      numchars.times do |i|
        type = @@unicode[ta[i]]
        if type == 'L'
          pel = 0
          break
        elsif (type == 'AL') or (type == 'R')
          pel = 1
          break
        end
      end
    end

    # Current Embedding Level
    cel = pel
    # directional override status
    dos = 'N'
    remember = []
    # start-of-level-run
    sor = (pel % 2 == 1) ? 'R' : 'L'
    eor = sor

    # Array of characters data
    chardata = []

    # X1. Begin by setting the current embedding level to the paragraph embedding level. Set the directional override status to neutral. Process each character iteratively, applying rules X2 through X9. Only embedding levels from 0 to 61 are valid in this phase.
    #   In the resolution of levels in rules I1 and I2, the maximum embedding level of 62 can be reached.
    numchars.times do |i|
      case ta[i]
      when @@k_rle, @@k_lre, @@k_rlo, @@k_lro, @@k_pdf
      else
        # X6. For all types besides RLE, LRE, RLO, LRO, and PDF:
        #  a. Set the level of the current character to the current embedding level.
        #  b. Whenever the directional override status is not neutral, reset the current character type to the directional override status.
        if dos != 'N'
          chardir = dos
        else
          chardir = @@unicode[ta[i]]
          chardir = 'L' if chardir.nil?
        end
        # stores string characters and other information
        chardata << {:char => ta[i], :level => cel, :type => chardir, :sor => sor, :eor => eor}
        next
      end

      case ta[i]
      when @@k_rle
        # X2. With each RLE, compute the least greater odd embedding level.
        #  a. If this new level would be valid, then this embedding code is valid. Remember (push) the current embedding level and override status. Reset the current level to this new level, and reset the override status to neutral.
        #  b. If the new level would not be valid, then this code is invalid. Do not change the current level or override status.
        next_level = cel + (cel % 2) + 1
        if next_level < 62
          remember << {:num => @@k_rle, :cel => cel, :dos => dos}
          cel = next_level
          dos = 'N'
          sor = eor
          eor = (cel % 2 == 1) ? 'R' : 'L'
        end
      when @@k_lre
        # X3. With each LRE, compute the least greater even embedding level.
        #  a. If this new level would be valid, then this embedding code is valid. Remember (push) the current embedding level and override status. Reset the current level to this new level, and reset the override status to neutral.
        #  b. If the new level would not be valid, then this code is invalid. Do not change the current level or override status.
        next_level = cel + 2 - (cel % 2)
        if next_level < 62
          remember << {:num => @@k_lre, :cel => cel, :dos => dos}
          cel = next_level
          dos = 'N'
          sor = eor
          eor = (cel % 2 == 1) ? 'R' : 'L'
        end
      when @@k_rlo
        # X4. With each RLO, compute the least greater odd embedding level.
        #  a. If this new level would be valid, then this embedding code is valid. Remember (push) the current embedding level and override status. Reset the current level to this new level, and reset the override status to right-to-left.
        #  b. If the new level would not be valid, then this code is invalid. Do not change the current level or override status.
        next_level = cel + (cel % 2) + 1
        if next_level < 62
          remember << {:num => @@k_rlo, :cel => cel, :dos => dos}
          cel = next_level
          dos = 'R'
          sor = eor
          eor = (cel % 2 == 1) ? 'R' : 'L'
        end
      when @@k_lro
        # X5. With each LRO, compute the least greater even embedding level.
        #  a. If this new level would be valid, then this embedding code is valid. Remember (push) the current embedding level and override status. Reset the current level to this new level, and reset the override status to left-to-right.
        #  b. If the new level would not be valid, then this code is invalid. Do not change the current level or override status.
        next_level = cel + 2 - (cel % 2)
        if next_level < 62
          remember << {:num => @@k_lro, :cel => cel, :dos => dos}
          cel = next_level
          dos = 'L'
          sor = eor
          eor = (cel % 2 == 1) ? 'R' : 'L'
        end
      when @@k_pdf
        # X7. With each PDF, determine the matching embedding or override code. If there was a valid matching code, restore (pop) the last remembered (pushed) embedding level and directional override.
        unless remember.empty?
          last = remember.length - 1
          case remember[last][:num]
          when @@k_rle, @@k_lre, @@k_rlo, @@k_lro
            match = remember.pop
            cel = match[:cel]
            dos = match[:dos]
            sor = eor
            eor = ((cel > match[:cel] ? cel : match[:cel]) % 2 == 1) ? 'R' : 'L'
          end
        end
      end
    end # end for each char

    # X8. All explicit directional embeddings and overrides are completely terminated at the end of each paragraph. Paragraph separators are not included in the embedding.
    # X9. Remove all RLE, LRE, RLO, LRO, PDF, and BN codes.
    # X10. The remaining rules are applied to each run of characters at the same level. For each run, determine the start-of-level-run (sor) and end-of-level-run (eor) type, either L or R. This depends on the higher of the two levels on either side of the boundary (at the start or end of the paragraph, the level of the 'other' run is the base embedding level). If the higher level is odd, the type is R; otherwise, it is L.

    # 3.3.3 Resolving Weak Types
    # Weak types are now resolved one level run at a time. At level run boundaries where the type of the character on the other side of the boundary is required, the type assigned to sor or eor is used.
    # Nonspacing marks are now resolved based on the previous characters.
    numchars = chardata.length

    # W1. Examine each nonspacing mark (NSM) in the level run, and change the type of the NSM to the type of the previous character. If the NSM is at the start of the level run, it will get the type of sor.
    prevlevel = -1 # track level changes
    levcount = 0 # counts consecutive chars at the same level
    numchars.times do |i|
      if chardata[i][:type] == 'NSM'
        if levcount
          chardata[i][:type] = chardata[i][:sor]
        elsif i > 0
          chardata[i][:type] = chardata[i-1][:type]
        end
      end
      if chardata[i][:level] != prevlevel
        levcount = 0
      else
        levcount += 1
      end
      prevlevel = chardata[i][:level]
    end

    # W2. Search backward from each instance of a European number until the first strong type (R, L, AL, or sor) is found. If an AL is found, change the type of the European number to Arabic number.
    prevlevel = -1
    levcount = 0
    numchars.times do |i|
      if chardata[i][:type] == 'EN'
        levcount.downto(0) do |j|
          if chardata[j][:type] == 'AL'
            chardata[i][:type] = 'AN'
          elsif (chardata[j][:type] == 'L') or (chardata[j][:type] == 'R')
            break
          end
        end
      end
      if chardata[i][:level] != prevlevel
        levcount = 0
      else
        levcount +=1
      end
      prevlevel = chardata[i][:level]
    end

    # W3. Change all ALs to R.
    numchars.times do |i|
      if chardata[i][:type] == 'AL'
        chardata[i][:type] = 'R'
      end
    end

    # W4. A single European separator between two European numbers changes to a European number. A single common separator between two numbers of the same type changes to that type.
    prevlevel = -1
    levcount = 0
    numchars.times do |i|
      if (levcount > 0) and (i+1 < numchars) and (chardata[i+1][:level] == prevlevel)
        if (chardata[i][:type] == 'ES') and (chardata[i-1][:type] == 'EN') and (chardata[i+1][:type] == 'EN')
          chardata[i][:type] = 'EN'
        elsif (chardata[i][:type] == 'CS') and (chardata[i-1][:type] == 'EN') and (chardata[i+1][:type] == 'EN')
          chardata[i][:type] = 'EN'
        elsif (chardata[i][:type] == 'CS') and (chardata[i-1][:type] == 'AN') and (chardata[i+1][:type] == 'AN')
          chardata[i][:type] = 'AN'
        end
      end
      if chardata[i][:level] != prevlevel
        levcount = 0
      else
        levcount += 1
      end
      prevlevel = chardata[i][:level]
    end

    # W5. A sequence of European terminators adjacent to European numbers changes to all European numbers.
    prevlevel = -1
    levcount = 0
    numchars.times do |i|
      if chardata[i][:type] == 'ET'
        if (levcount > 0) and (chardata[i-1][:type] == 'EN')
          chardata[i][:type] = 'EN'
        else
          j = i+1
          while (j < numchars) and (chardata[j][:level] == prevlevel)
            if chardata[j][:type] == 'EN'
              chardata[i][:type] = 'EN'
              break
            elsif chardata[j][:type] != 'ET'
              break
            end
            j += 1
          end
        end
      end
      if chardata[i][:level] != prevlevel
        levcount = 0
      else
        levcount += 1
      end
      prevlevel = chardata[i][:level]
    end

    # W6. Otherwise, separators and terminators change to Other Neutral.
    prevlevel = -1
    levcount = 0
    reg_ET_ES_CS = /^(ET|ES|CS)$/
    numchars.times do |i|
      if chardata[i][:type] =~ reg_ET_ES_CS
        chardata[i][:type] = 'ON'
      end
      if chardata[i][:level] != prevlevel
        levcount = 0
      else
        levcount += 1
      end
      prevlevel = chardata[i][:level]
    end

    # W7. Search backward from each instance of a European number until the first strong type (R, L, or sor) is found. If an L is found, then change the type of the European number to L.
    prevlevel = -1
    levcount = 0
    numchars.times do |i|
      if chardata[i][:type] == 'EN'
        levcount.downto(0) do |j|
          if chardata[j][:type] == 'L'
            chardata[i][:type] = 'L'
          elsif chardata[j][:type] == 'R'
            break
          end
        end
      end
      if chardata[i][:level] != prevlevel
        levcount = 0
      else
        levcount += 1
      end
      prevlevel = chardata[i][:level]
    end

    # N1. A sequence of neutrals takes the direction of the surrounding strong text if the text on both sides has the same direction. European and Arabic numbers act as if they were R in terms of their influence on neutrals. Start-of-level-run (sor) and end-of-level-run (eor) are used at level run boundaries.
    prevlevel = -1
    levcount = 0
    reg_NI = /^(B|S|WS|ON)$/
    reg_R_EN_AN = /^(R|EN|AN)$/
    reg_EN_AN = /^(EN|AN)$/
    ni = nil
    numchars.times do |i|
      if (chardata[i][:type] =~ reg_NI)
        if (levcount > 0) and (i+1 < numchars) and (chardata[i+1][:level] == prevlevel)
          if !ni.nil? and ni > i
            next_non_space_char = chardata[ni][:type]
          else
            ni = chardata[i+1..-1].index {|item| item[:type] !~ reg_NI}
            unless ni.nil?
              ni += i+1
              next_non_space_char = chardata[ni][:type]
            end
          end
          if (chardata[i-1][:type] == 'L') and (next_non_space_char == 'L')
            chardata[i][:type] = 'L'
          elsif ((chardata[i-1][:type] == 'R') and (next_non_space_char =~ reg_R_EN_AN) or
                 (chardata[i-1][:type] =~ reg_EN_AN) and (next_non_space_char == 'R'))
            chardata[i][:type] = 'R'
          else
            # N2. Any remaining neutrals take the embedding direction
            chardata[i][:type] = chardata[i][:sor]
          end
        elsif (levcount == 0) and (i+1 < numchars) and (chardata[i+1][:level] == prevlevel)
          ni = chardata[i+1..-1].index {|item| item[:type] !~ reg_NI}
          unless ni.nil?
            ni += i+1
            next_non_space_char = chardata[ni][:type]
          end
          # first char
          if (chardata[i][:sor] == 'L') and (next_non_space_char == 'L')
            chardata[i][:type] = 'L'
          elsif ((chardata[i][:sor] == 'R') and (next_non_space_char =~ reg_R_EN_AN) or
                 (chardata[i][:sor] =~ reg_EN_AN) and (next_non_space_char == 'R'))
            chardata[i][:type] = 'R'
          else
            # N2. Any remaining neutrals take the embedding direction
            chardata[i][:type] = chardata[i][:sor]
          end
        elsif (levcount > 0) and ((i+1 == numchars) or ((i+1 < numchars) and (chardata[i+1][:level] != prevlevel)))
          # last char
          if (chardata[i-1][:type] == 'L') and (chardata[i][:eor] == 'L')
            chardata[i][:type] = 'L'
          elsif ((chardata[i-1][:type] == 'R') and (chardata[i][:eor] =~ reg_R_EN_AN) or
                 (chardata[i-1][:type] =~ reg_EN_AN) and (chardata[i][:eor] == 'R'))
            chardata[i][:type] = 'R'
          else
            # N2. Any remaining neutrals take the embedding direction
            chardata[i][:type] = chardata[i][:sor]
          end
        else
          # N2. Any remaining neutrals take the embedding direction
          chardata[i][:type] = chardata[i][:sor]
        end
      end
      if chardata[i][:level] != prevlevel
        levcount = 0
      else
        levcount += 1
      end
      prevlevel = chardata[i][:level]
    end

    # I1. For all characters with an even (left-to-right) embedding direction, those of type R go up one level and those of type AN or EN go up two levels.
    # I2. For all characters with an odd (right-to-left) embedding direction, those of type L, EN or AN go up one level.
    prevlevel = -1
    reg_L_AN_EN = /^(L|AN|EN)$/
    reg_AN_EN = /^(AN|EN)$/

    numchars.times do |i|
      odd = chardata[i][:level] % 2
      if odd == 1 # I2.
        if chardata[i][:type] =~ reg_L_AN_EN
          chardata[i][:level] += 1
        end
      else # I1.
        if chardata[i][:type] == 'R'
          chardata[i][:level] += 1
        elsif chardata[i][:type] == 'BN' and prevlevel != -1
          chardata[i][:level] = prevlevel
        elsif chardata[i][:type] =~ reg_AN_EN
          chardata[i][:level] += 2
        end
      end
      prevlevel = chardata[i][:level]
      maxlevel = [chardata[i][:level],maxlevel].max
    end

    # L1. On each line, reset the embedding level of the following characters to the paragraph embedding level:
    #  1. Segment separators,
    #  2. Paragraph separators,
    #  3. Any sequence of whitespace characters preceding a segment separator or paragraph separator, and
    #  4. Any sequence of white space characters at the end of the line.
    reg_B_S = /^(B|S)$/
    numchars.times do |i|
      if chardata[i][:type] =~ reg_B_S
        chardata[i][:level] = pel
      elsif chardata[i][:type] == 'WS'
        j = i+1
        while j < numchars
          if (chardata[j][:type] =~ reg_B_S) or
            ((j == numchars-1) and (chardata[j][:type] == 'WS'))
            chardata[i][:level] = pel
            break
          elsif chardata[j][:type] != 'WS'
            break
          end
          j += 1
        end
      end
    end

    # Arabic Shaping
    # Cursively connected scripts, such as Arabic or Syriac, require the selection of positional character shapes that depend on adjacent characters. Shaping is logically applied after the Bidirectional Algorithm is used and is limited to characters within the same directional run.
    if arabic
      endedletter = [1569,1570,1571,1572,1573,1575,1577,1583,1584,1585,1586,1608,1688]
      alfletter = [1570,1571,1573,1575]
      chardata2 = chardata.dup
      laaletter = false
      charAL = []
      x = 0
      numchars.times do |i|
        c = chardata[i][:char]
        if (@@unicode[c] == 'AL') or (c == 32) or (c == 8204) # Unicode Character 'ZERO WIDTH NON-JOINER' (U+200C)
          charAL[x] = chardata[i].dup
          charAL[x][:i] = i
          chardata[i][:x] = x
          x += 1
        end
      end
      numAL = x
      reg_AL_NSM = /^(AL|NSM)$/
      numchars.times do |i|
        thischar = chardata[i].dup
        if i > 0
          prevchar = chardata[i-1]
        else
          prevchar = false
        end
        if i+1 < numchars
          nextchar = chardata[i+1]
        else
          nextchar = false
        end
        if @@unicode[thischar[:char]] == 'AL'
          x = thischar[:x]
          if x > 0
            prevchar = charAL[x-1]
          else
            prevchar = false
          end
          if x+1 < numAL
            nextchar = charAL[x+1]
          else
            nextchar = false
          end
          # if laa letter
          if (prevchar != false) and (prevchar[:char] == 1604) and alfletter.include?(thischar[:char])
            arabicarr = @@laa_array
            laaletter = true
            if x > 1
              prevchar = charAL[x-2]
            else
              prevchar = false
            end
          else
            arabicarr = @@unicode_arlet
            laaletter = false
          end
          if (prevchar != false) and (nextchar != false) and
            (@@unicode[prevchar[:char]] =~ reg_AL_NSM) and
            (@@unicode[nextchar[:char]] =~ reg_AL_NSM) and
            (nextchar[:type] == thischar[:type]) and
            (nextchar[:char] != 1567)
            # medial
            if endedletter.include?(prevchar[:char])
              if !arabicarr[thischar[:char]].nil? and !arabicarr[thischar[:char]][2].nil?
                # initial
                chardata2[i][:char] = arabicarr[thischar[:char]][2]
              end
            else
              if !arabicarr[thischar[:char]].nil? and !arabicarr[thischar[:char]][3].nil?
                # medial
                chardata2[i][:char] = arabicarr[thischar[:char]][3]
              end
            end
          elsif (nextchar != false) and
            (@@unicode[nextchar[:char]] =~ reg_AL_NSM) and
            (nextchar[:type] == thischar[:type]) and
            (nextchar[:char] != 1567)
            if !arabicarr[thischar[:char]].nil? and !arabicarr[thischar[:char]][2].nil?
              # initial
              chardata2[i][:char] = arabicarr[thischar[:char]][2]
            end
          elsif ((prevchar != false) and
            (@@unicode[prevchar[:char]] =~ reg_AL_NSM) and
            (prevchar[:type] == thischar[:type])) or
            ((nextchar != false) and (nextchar[:char] == 1567))
            # final
            if (i > 1) and (thischar[:char] == 1607) and
              (chardata[i-1][:char] == 1604) and
              (chardata[i-2][:char] == 1604)
              # Allah Word
              # mark characters to delete with false
              chardata2[i-2][:char] = false
              chardata2[i-1][:char] = false
              chardata2[i][:char] = 65010
            else
              if (prevchar != false) and endedletter.include?(prevchar[:char])
                if !arabicarr[thischar[:char]].nil? and !arabicarr[thischar[:char]][0].nil?
                  # isolated
                  chardata2[i][:char] = arabicarr[thischar[:char]][0]
                end
              else
                if !arabicarr[thischar[:char]].nil? and !arabicarr[thischar[:char]][1].nil?
                  # final
                  chardata2[i][:char] = arabicarr[thischar[:char]][1]
                end
              end
            end
          elsif !arabicarr[thischar[:char]].nil? and !arabicarr[thischar[:char]][0].nil?
            # isolated
            chardata2[i][:char] = arabicarr[thischar[:char]][0]
          end
          # if laa letter
          if laaletter
            # mark characters to delete with false
            chardata2[charAL[x-1][:i]][:char] = false
          end
        end # end if AL (Arabic Letter)
      end # end for each char

      #
      # Combining characters that can occur with Arabic Shadda (0651 HEX, 1617 DEC) are replaced.
      # Putting the combining mark and shadda in the same glyph allows us to avoid the two marks overlapping each other in an illegible manner.
      #
      cw = @current_font['cw']
      (numchars-1).times do |i|
        if (chardata2[i][:char] == 1617) and !@@diacritics[chardata2[i+1][:char]].nil?
          # check if the subtitution font is defined on current font
          unless cw[@@diacritics[chardata2[i+1][:char]]].nil?
            chardata2[i][:char] = false
            chardata2[i+1][:char] = @@diacritics[chardata2[i+1][:char]]
          end
        end
      end
      # remove marked characters
      chardata = chardata2.reject {|value| value[:char] == false }
      numchars = chardata.size
      chardata2 = nil
      arabicarr = nil
      laaletter = nil
      charAL = nil
    end

    # L2. From the highest level found in the text to the lowest odd level on each line, including intermediate levels not actually present in the text, reverse any contiguous sequence of characters that are at that level or higher.
    maxlevel.downto(1) do |j|
      ordarray = []
      revarr = []
      onlevel = false
      numchars.times do |i|
        if chardata[i][:level] >= j
          onlevel = true
          um = @@unicode_mirror[chardata[i][:char]]
          if um
            # L4. A character is depicted by a mirrored glyph if and only if (a) the resolved directionality of that character is R, and (b) the Bidi_Mirrored property value of that character is true.
            chardata[i][:char] = um
          end
          revarr << chardata[i]
        else
          if onlevel
            revarr.reverse!
            ordarray.concat(revarr)
            revarr = []
            onlevel = false
          end
          ordarray << chardata[i]
        end
      end
      if onlevel
        revarr.reverse!
        ordarray.concat(revarr)
      end
      chardata = ordarray
    end

    ordarray = []
    numchars.times do |i|
      ordarray.push chardata[i][:char]
      # store char values for subsetting
      @current_font['subsetchars'][chardata[i][:char]] = true
    end

    # update font subsetchars
    setFontSubBuffer(@current_font['fontkey'], 'subsetchars', @current_font['subsetchars'])
    return ordarray
  end
  protected :utf8Bidi

  # END OF BIDIRECTIONAL TEXT SECTION -------------------

  #
  # Adds a bookmark.
  # [@param string :txt] bookmark description.
  # [@param int :level] bookmark level.
  # [@param float :y] Ordinate of the boorkmark position (default = -1 = current position).
  # [@param int :page] target page number (leave empty for current page).
  # [@access public]
  # [@author] Olivier Plathey, Nicola Asuni
  # [@since 2.1.002 (2008-02-12)]
  #
  def Bookmark(txt, level=0, y=-1, page=nil)
    if level < 0
      level = 0
    end
    if @outlines[0]
      lastoutline = @outlines[-1]
      maxlevel = lastoutline[:l] + 1
    else
      maxlevel = 0
    end
    if level > maxlevel
      level = maxlevel
    end
    if y == -1
      y = GetY()
    end
    if page.nil?
      page = PageNo()
    end
    @outlines.push :t => txt, :l => level, :y => y, :p => page
  end
  alias_method :bookmark, :Bookmark

  #
  # Create a bookmark PDF string.
  # [@access private]
  # [@author] Olivier Plathey, Nicola Asuni
  # [@since 2.1.002 (2008-02-12)]
  #
  def putbookmarks()
    nb = @outlines.size
    if nb == 0
      return
    end
    # sort outlines by page and original position
    @outlines = @outlines.sort_by {|x| [x[:p], x[:y]] }
    lru = []
    level = 0
    @outlines.each_with_index do |o, i|
      if o[:l] > 0
        parent = lru[o[:l] - 1]
        # Set parent and last pointers
        @outlines[i][:parent] = parent
        @outlines[parent][:last] = i
        if o[:l] > level
          # Level increasing: set first pointer
          @outlines[parent][:first] = i
        end
      else
        @outlines[i][:parent] = nb
      end
      if o[:l] <= level and i > 0
        # Set prev and next pointers
        prev = lru[o[:l]]
        @outlines[prev][:next] = i
        @outlines[i][:prev] = prev
      end
      lru[o[:l]] = i
      level = o[:l]
    end
    # Outline items
    n = @n + 1
    @outlines.each_with_index do |o, i|
      newobj()
      # covert HTML title to string
      nltags = /<br[\s]?\/>|<\/(blockquote|dd|dl|div|dt|h1|h2|h3|h4|h5|h6|hr|li|ol|p|pre|ul|table|tr|td)>/mi
      title = o[:t].gsub(nltags, "\n")
      title = title.gsub(/[\r]+/mi, '')
      title = title.gsub(/[\n]+/mi, "\n")
      title = title.strip.gsub(/<[^>]+>/, '')
      out = '<</Title ' + textstring(title)
      out << ' /Parent ' + (n + o[:parent]).to_s + ' 0 R'
      out << ' /Prev ' + (n + o[:prev]).to_s + ' 0 R' if !o[:prev].nil?
      out << ' /Next ' + (n + o[:next]).to_s + ' 0 R' if !o[:next].nil?
      out << ' /First ' + (n + o[:first]).to_s + ' 0 R' if !o[:first].nil?
      out << ' /Last ' + (n + o[:last]).to_s + ' 0 R' if !o[:last].nil?
      out << ' ' + sprintf('/Dest [%d 0 R /XYZ 0 %.2f null]', 1 + 2 * o[:p], @pagedim[o[:p]]['h'] - o[:y] * @k)
      out << ' /Count 0>> endobj'
      out(out)
    end
    # Outline root
    newobj()
    @outline_root = @n
    out('<</Type /Outlines /First ' + n.to_s + ' 0 R /Last ' + (n + lru[0]).to_s + ' 0 R>> endobj')
  end
  protected :putbookmarks

  # --- JAVASCRIPT ------------------------------------------------------
  #
  # Adds a javascript
  # [@param string :script] Javascript code
  # [@access public]
  # [@author Johannes G�ntert, Nicola Asuni]
  # [@since 2.1.002 (2008-02-12)]
  #
  def IncludeJS(script)
    @javascript << script
  end

  #
  # Adds a javascript object and return object ID
  # [@param string :script] Javascript code
  # [@param boolean :onload] if true executes this object when opening the document
  # [@return int] internal object ID
  # [@access public]
  # [@author Nicola Asuni]
  # [@since 4.8.000 (2009-09-07)]
  #
  def addJavascriptObject(script, onload = false)
    @js_obj_id += 1
    @js_objects[@js_obj_id] = {'js' => script, 'onload' => onload}
    @js_obj_id
  end

  #
  # Create a javascript PDF string.
  # [@access protected]
  # [@author Johannes G�ntert, Nicola Asuni]
  # [@since 2.1.002 (2008-02-12)]
  #
  def putjavascript()
    return if @javascript.empty? && @js_objects.empty?

    if @javascript.index 'this.addField'
      # @setUserRights() unless @ur

      # the following two lines are used to avoid form fields duplication after saving
      # The addField method only works on Acrobat Writer, unless the document is signed with Adobe private key (UR3)
      jsa = sprintf("ftcpdfdocsaved=this.addField('%s','%s',%d,[%.2f,%.2f,%.2f,%.2f]);", 'tcpdfdocsaved', 'text', 0, 0, 1, 0, 1)
      jsb = "getField('tcpdfdocsaved').value='saved';"
      @javascript = "#{jsa}\n#{@javascript}\n#{jsb}"
    end
    @n_js = newobj()
    out = ' << /Names ['
    unless @javascript.empty?
      out << " (EmbeddedJS) #{@n + 1} 0 R"
    end
    unless @js_objects.empty?
      @js_objects.each{|key, val|
        out << " (JS#{key}) #{key} 0 R" if val['onload']
      }
    end
    out << ' ] >> endobj'
    out(out)
    # default Javascript object
    unless @javascript.empty?
      newobj()
      out = '<< /S /JavaScript'
      out << " /JS #{textstring(@javascript)}"
      out << ' >> endobj'
      out(out)
    end
    # additional Javascript objects
    unless @js_objects.empty?
      @js_objects.each {|key, val|
        @offsets[key] = @bufferlen
        out = "#{key} 0 obj\n << /S /JavaScript /JS #{textstring(val['js'])} >> endobj"
        out(out)
      }
    end
  end

  #
  # Convert color to javascript color.
  # [@param string :color] color name or #RRGGBB
  # [@access protected}
  # [@author Denis Van Nuffelen, Nicola Asuni]
  # [@since 2.1.002 (2008-02-12)]
  #
  def JScolor(color)
    aColors = ['transparent', 'black', 'white', 'red', 'green', 'blue', 'cyan', 'magenta', 'yellow', 'dkGray', 'gray', 'ltGray']
    if color[0] == '#'
      return sprintf("['RGB',%.3f,%.3f,%.3f]", color[1, 2].to_i(16) / 255, color[3, 2].to_i(16) / 255, color[5, 2].to_i(16) / 255)
    end

    unless aColors.include? color
      Error('Invalid color: ' + color)
    end
    'color.' + color
  end
  protected :JScolor

  #
  # Adds a javascript form field.
  # [@param string :type] field type
  # [@param string :name] field name
  # [@param int :x] horizontal position
  # [@param int :y] vertical position
  # [@param int :w] width
  # [@param int :h] height
  # [@param array :prop] javascript field properties. Possible values are described on official Javascript for Acrobat API reference.
  # [@access protected]
  # [@author Denis Van Nuffelen, Nicola Asuni]
  # [@since 2.1.002 (2008-02-12)]
  #
  def addfield(type, name, x, y, w, h, prop)
    x = x - w if @rtl

    # the followind avoid fields duplication after saving the document
    @javascript << "if(getField('tcpdfdocsaved').value != 'saved') {"
    k = @k
    @javascript << "f#{name}=this.addField('#{name}','#{type}',#{PageNo() - 1},[#{sprintf("%.2f,%.2f,%.2f,%.2f", x * k, (@h - y) * k + 1, (x + w) * k, (@h - y - h) * k + 1)}]);\n"
    @javascript << "f#{name}.textSize=#{@font_size_pt};\n"
    prop.each {|k, v|
      val = k[-5..-1] == 'Color' ? JScolor(v) : "'#{v}'"
      @javascript << "f#{name}.#{k}=#{val};\n"
    }
    if @rtl
      @x -= w
    else
      @x += w
    end
    @javascript << '}'
  end
  protected :addfield

  # --- FORM FIELDS -----------------------------------------------------

  #
  # Convert JavaScript form fields properties array to Annotation Properties array.
  # [@param array :prop] javascript field properties. Possible values are described on official Javascript for Acrobat API reference.
  # [@return array of annotation properties]
  # [@access protected]
  # [@author Nicola Asuni]
  # [@since 4.8.000 (2009-09-06)]
  #
  def getAnnotOptFromJSProp(prop)
    # the annotation options area already defined
    return prop['aopt'] if prop['aopt'].is_a?(Array)

    opt = {} # value to be returned
    # alignment: Controls how the text is laid out within the text field.
    if prop['alignment']
      opt['q'] = case prop['alignment']
                 when 'left'; 0
                 when 'center'; 1
                 when 'right'; 2
                 else @rtl ? 2 : 0
                 end
    end
    # lineWidth: Specifies the thickness of the border when stroking the perimeter of a field's rectangle.
    if prop['lineWidth']
      linewidth = prop['lineWidth'].to_i
    else
      linewidth = 1
    end
    # borderStyle: The border style for a field.
    case prop['borderStyle']
    when 'border.d', 'dashed'
      opt['border'] = [0, 0, linewidth, [3, 2]]
      opt['bs'] = {'w'=>linewidth, 's'=>'D', 'd'=>[3, 2]}
    when 'border.b', 'beveled'
      opt['border'] = [0, 0, linewidth]
      opt['bs'] = {'w'=>linewidth, 's'=>'B'}
    when 'border.i', 'inset'
      opt['border'] = [0, 0, linewidth]
      opt['bs'] = {'w'=>linewidth, 's'=>'I'}
    when 'border.u', 'underline'
      opt['border'] = [0, 0, linewidth]
      opt['bs'] = {'w'=>linewidth, 's'=>'U'}
    else # 'border.s', 'solid'
      opt['border'] = [0, 0, linewidth]
      opt['bs'] = {'w'=>linewidth, 's'=>'S'}
    end

    opt['border'] = prop['border'] if prop['border'].is_a?(Array)
    opt['mk'] ||= {}
    opt['mk']['if'] ||= {}
    opt['mk']['if']['a'] = [0.5, 0.5]
    # buttonAlignX: Controls how space is distributed from the left of the button face with respect to the icon.
    opt['mk']['if']['a'][0] = prop['buttonAlignX'] if prop['buttonAlignX']
    # buttonAlignY: Controls how unused space is distributed from the bottom of the button face with respect to the icon.
    opt['mk']['if']['a'][1] = prop['buttonAlignY'] if prop['buttonAlignY']
    # buttonFitBounds: If true, the extent to which the icon may be scaled is set to the bounds of the button field.
    opt['mk']['if']['fb'] = true if prop['buttonFitBounds'] && (prop['buttonFitBounds'] == 'true')
    # buttonScaleHow: Controls how the icon is scaled (if necessary) to fit inside the button face.
    case prop['buttonScaleHow']
    when 'scaleHow.proportional'; opt['mk']['if']['s'] = 'P'
    when 'scaleHow.anamorphic';   opt['mk']['if']['s'] = 'A'
    end
    # buttonScaleWhen: Controls when an icon is scaled to fit inside the button face.
    case prop['buttonScaleWhen']
    when 'scaleWhen.always';   opt['mk']['if']['sw'] = 'A'
    when 'scaleWhen.never';    opt['mk']['if']['sw'] = 'N'
    when 'scaleWhen.tooBig';   opt['mk']['if']['sw'] = 'B'
    when 'scaleWhen.tooSmall'; opt['mk']['if']['sw'] = 'S'
    end
    # buttonPosition: Controls how the text and the icon of the button are positioned with respect to each other within the button face.
    case prop['buttonPosition']
    when 0, 'position.textOnly';  opt['mk']['tp'] = 0
    when 1, 'position.iconOnly';  opt['mk']['tp'] = 1
    when 2, 'position.iconTextV'; opt['mk']['tp'] = 2
    when 3, 'position.textIconV'; opt['mk']['tp'] = 3
    when 4, 'position.iconTextH'; opt['mk']['tp'] = 4
    when 5, 'position.textIconH'; opt['mk']['tp'] = 5
    when 6, 'position.overlay';   opt['mk']['tp'] = 6
    end
    # fillColor: Specifies the background color for a field.
    if prop['fillColor']
      if prop['fillColor'].is_a? Array
        opt['mk']['bg'] = prop['fillColor']
      else
        opt['mk']['bg'] = convertHTMLColorToDec(prop['fillColor'])
      end
    end
    # strokeColor: Specifies the stroke color for a field that is used to stroke the rectangle of the field with a line as large as the line width.
    if prop['strokeColor']
      if prop['strokeColor'].is_a? Array
        opt['mk']['bc'] = prop['strokeColor']
      else
        opt['mk']['bc'] = convertHTMLColorToDec(prop['strokeColor'])
      end
    end
    # rotation: The rotation of a widget in counterclockwise increments.
    opt['mk']['r'] = prop['rotation'] if prop['rotation']
    # charLimit: Limits the number of characters that a user can type into a text field.
    opt['maxlen'] = prop['charLimit'].to_i if prop['charLimit']

    ff ||= 0
    # readonly: The read-only characteristic of a field. If a field is read-only, the user can see the field but cannot change it.
    ff |= 1 << 0 if prop['readonly'] == 'true'
    # required: Specifies whether a field requires a value.
    ff |= 1 << 1 if prop['required'] == 'true'
    # multiline: Controls how text is wrapped within the field.
    ff |= 1 << 12 if prop['multiline'] == 'true'
    # password: Specifies whether the field should display asterisks when data is entered in the field.
    ff |= 1 << 13 if prop['password'] == 'true'
    # NoToggleToOff: If set, exactly one radio button shall be selected at all times; selecting the currently selected button has no effect.
    ff |= 1 << 14 if prop['NoToggleToOff'] == 'true'
    # Radio: If set, the field is a set of radio buttons.
    ff |= 1 << 15 if prop['Radio'] == 'true'
    # Pushbutton: If set, the field is a pushbutton that does not retain a permanent value.
    ff |= 1 << 16 if prop['Pushbutton'] == 'true'
    # Combo: If set, the field is a combo box; if clear, the field is a list box.
    ff |= 1 << 17 if prop['Combo'] == 'true'
    # editable: Controls whether a combo box is editable.
    ff |= 1 << 18 if prop['editable'] == 'true'
    # Sort: If set, the field's option items shall be sorted alphabetically.
    ff |= 1 << 19 if prop['Sort'] == 'true'
    # fileSelect: If true, sets the file-select flag in the Options tab of the text field (Field is Used for File Selection).
    ff |= 1 << 20 if prop['fileSelect'] == 'true'
    # multipleSelection: If true, indicates that a list box allows a multiple selection of items.
    ff |= 1 << 21 if prop['multipleSelection'] == 'true'
    # doNotSpellCheck: If true, spell checking is not performed on this editable text field.
    ff |= 1 << 22 if prop['doNotSpellCheck'] == 'true'
    # doNotScroll: If true, the text field does not scroll and the user, therefore, is limited by the rectangular region designed for the field.
    ff |= 1 << 23 if prop['doNotScroll'] == 'true'
    # comb: If set to true, the field background is drawn as series of boxes (one for each character in the value of the field) and each character of the content is drawn within those boxes. The number of boxes drawn is determined from the charLimit property. It applies only to text fields. The setter will also raise if any of the following field properties are also set multiline, password, and fileSelect. A side-effect of setting this property is that the doNotScroll property is also set.
    ff |= 1 << 24 if prop['comb'] == 'true'
    # radiosInUnison: If false, even if a group of radio buttons have the same name and export value, they behave in a mutually exclusive fashion, like HTML radio buttons.
    ff |= 1 << 25 if prop['radiosInUnison'] == 'true'
    # richText: If true, the field allows rich text formatting.
    ff |= 1 << 25 if prop['richText'] == 'true'
    # commitOnSelChange: Controls whether a field value is committed after a selection change.
    ff |= 1 << 26 if prop['commitOnSelChange'] == 'true'
    opt['ff'] = ff

    # defaultValue: The default value of a field - that is, the value that the field is set to when the form is reset.
    opt['dv'] = prop['defaultValue'] if prop['defaultValue']
    f = 1 << 2 # default value for annotation flags
    # readonly: The read-only characteristic of a field. If a field is read-only, the user can see the field but cannot change it.
    if prop['readonly'] == 'true'
      f |= 1 << 6
    end
    # display: Controls whether the field is hidden or visible on screen and in print.
    case prop['display']
    when 'display.visible'
      #
    when 'display.hidden'
      f |= 1 << 1
    when 'display.noPrint'
      f &= ~(1 << 2)
    when 'display.noView'
      f |= 1 << 5
    end
    opt['f'] = f

    # currentValueIndices: Reads and writes single or multiple values of a list box or combo box.
    opt['i'] = prop['currentValueIndices'] if prop['currentValueIndices'].is_a?(Array)
    # value: The value of the field data that the user has entered.
    if prop['value']
      if prop['value'].is_a?(Array)
        opt['opt'] = []
        prop['value'].each_with_index {|v, i|
          # exportValues: An array of strings representing the export values for the field.
          if prop['exportValues'] && prop['exportValues'][i]
            opt['opt'][i] = [prop['exportValues'][i], v]
          else
            opt['opt'][i] = v
          end
        }
      else
        opt['v'] = prop['value']
      end
    end
    # richValue: This property specifies the text contents and formatting of a rich text field.
    opt['rv'] = prop['richValue'] if prop['richValue']
    # submitName: If nonempty, used during form submission instead of name. Only applicable if submitting in HTML format (that is, URL-encoded).
    opt['tm'] = prop['submitName'] if prop['submitName']
    # name: Fully qualified field name.
    opt['t'] = prop['name'] if prop['name']
    # userName: The user name (short description string) of the field.
    opt['tu'] = prop['userName'] if prop['userName']
    # highlight: Defines how a button reacts when a user clicks it.
    case prop['highlight']
    when 'none',    'highlight.n'; opt['h'] = 'N'
    when 'invert',  'highlight.i'; opt['h'] = 'i'
    when 'push',    'highlight.p'; opt['h'] = 'P'
    when 'outline', 'highlight.o'; opt['h'] = 'O'
    end
    # Unsupported options:
    # - calcOrderIndex: Changes the calculation order of fields in the document.
    # - delay: Delays the redrawing of a field's appearance.
    # - defaultStyle: This property defines the default style attributes for the form field.
    # - style: Allows the user to set the glyph style of a check box or radio button.
    # - textColor, textFont, textSize
    opt
  end
  protected :getAnnotOptFromJSProp

  #
  # Set default properties for form fields.
  # [@param array :prop] javascript field properties. Possible values are described on official Javascript for Acrobat API reference.
  # [@access public]
  # [@author Nicola Asuni]
  # [@since 4.8.000 (2009-09-06)]
  #
  def setFormDefaultProp(prop = [])
    @default_form_prop = prop
  end
  alias_method :set_form_default_prop, :setFormDefaultProp

  #
  # Return the default properties for form fields.
  # [@return array :prop] javascript field properties. Possible values are described on official Javascript for Acrobat API reference.
  # [@access public]
  # [@author Nicola Asuni]
  # [@since 4.8.000 (2009-09-06)]
  #
  def getFormDefaultProp()
    @default_form_prop
  end
  alias_method :get_form_default_prop, :getFormDefaultProp

  #
  # Creates a text field
  # [@param string :name] field name
  # [@param float :w] Width of the rectangle
  # [@param float :h] Height of the rectangle
  # [@param array :prop] javascript field properties. Possible values are described on official Javascript for Acrobat API reference.
  # [@param array :opt] annotation parameters. Possible values are described on official PDF32000_2008 reference.
  # [@param float :x] Abscissa of the upper-left corner of the rectangle
  # [@param float :y] Ordinate of the upper-left corner of the rectangle
  # [@param boolean :js] if true put the field using JavaScript (requires Acrobat Writer to be rendered).
  # [@access public]
  # [@author Nicola Asuni]
  # [@since 4.8.000 (2009-09-07)]
  #
  def TextField(name, w, h, prop = {}, opt = {}, x = '', y = '', js = false)
    x = @x if x == ''
    y = @y if y == ''

    if js
      addfield('text', name, x, y, w, h, prop)
      return
    end
    # get default style
    prop = getFormDefaultProp.merge prop
    # get annotation data
    popt = getAnnotOptFromJSProp(prop)
    # set default appearance stream
    font = @font_family
    fontkey = @fontkeys.index font
    unless @annotation_fonts.include? fontkey
      @annotation_fonts[font] = fontkey
    end
    fontstyle = sprintf("/F%d %.2f Tf %s", fontkey + 1, @font_size_pt, @text_color)
    popt['da'] = fontstyle
    popt['ap'] = {}

    if opt['v'] && !empty_string(opt['v'])
      # set Appearances
      popt['ap']['n'] = "/Tx BMC q #{fontstyle} "
      gvars = getGraphicVars()
      @h = h
      @w = w
      @t_margin = 0
      @c_margin = 0.2

      @tmp_buffer = ''
      multi_cell(w, h, opt['v'], 0, '', 0, 0, 0.2, 0, true, 0, false, true, 0)
      popt['ap']['n'] << @tmp_buffer
      @tmp_buffer = nil
      popt['ap']['n'] << 'Q EMC'

      # restore previous values
      setGraphicVars(gvars, true)
    else
      popt['ap']['n'] = "q BT #{fontstyle} ET Q"
    end

    # merge options
    opt = popt.merge opt
    # remove some conflicting options
    opt.delete :bs
    # set remaining annotation data
    opt['Subtype'] = 'Widget'
    opt['ft'] = 'Tx'
    opt['t'] = name
    #
    # Additional annotation's parameters (check _putannotsobj() method):
    # opt['f']
    # opt['ap']
    # opt['as']
    # opt['bs']
    # opt['be']
    # opt['c']
    # opt['border']
    # opt['h']
    # opt['mk']
    # opt['mk']['r']
    # opt['mk']['bc']
    # opt['mk']['bg']
    # opt['mk']['ca']
    # opt['mk']['rc']
    # opt['mk']['ac']
    # opt['mk']['i']
    # opt['mk']['ri']
    # opt['mk']['ix']
    # opt['mk']['if']
    # opt['mk']['if']['sw']
    # opt['mk']['if']['s']
    # opt['mk']['if']['a']
    # opt['mk']['if']['fb']
    # opt['mk']['tp']
    # opt['tu']
    # opt['tm']
    # opt['ff']
    # opt['v']
    # opt['dv']
    # opt['a']
    # opt['aa']
    # opt['q']
    Annotation(x, y, w, h, name, opt, 0)
    if @rtl
      @x -= w
    else
      @x += w
    end
  end
  alias_method :text_field, :TextField

  #
  # Creates a RadioButton field
  # [@param string :name] field name
  # [@param int :w] width
  # [@param array :prop] javascript field properties. Possible values are described on official Javascript for Acrobat API reference.
  # [@param array :opt] annotation parameters. Possible values are described on official PDF32000_2008 reference.
  # [@param string :onvalue] value to be returned if selected.
  # [@param boolean :checked] define the initial state.
  # [@param float :x] Abscissa of the upper-left corner of the rectangle
  # [@param float :y] Ordinate of the upper-left corner of the rectangle
  # [@param boolean :js] if true put the field using JavaScript (requires Acrobat Writer to be rendered).
  # [@access public]
  # [@author Nicola Asuni]
  # [@since 4.8.000 (2009-09-07)]
  #
  def RadioButton(name, w, prop = {}, opt = {}, onvalue = 'On', checked = false, x = '', y = '', js = false)
    x = @x if x == ''
    y = @y if y == ''

    if js
      addfield('radiobutton', name, x, y, w, w, prop)
      return
    end

    onvalue = 'On' if empty_string(onvalue)
    defval = checked ? onvalue : 'Off'
    # set data for parent group
    @radiobutton_groups[@page] ||= {}
    unless @radiobutton_groups[@page][name]
      @radiobutton_groups[@page][name] = []
      @annot_obj_id += 1
      @radio_groups << @annot_obj_id
    end
    # save object ID to be added on Kids entry on parent object
    @radiobutton_groups[@page][name] << {'kid' => @annot_obj_id + 1, 'def' => defval}
    # get default style
    prop = getFormDefaultProp.merge prop
    prop['NoToggleToOff'] = 'true'
    prop['Radio'] = 'true'
    prop['borderStyle'] = 'inset'
    # get annotation data
    popt = getAnnotOptFromJSProp(prop)
    # set additional default values
    font = 'zapfdingbats'
    AddFont(font)
    fontkey = @fontkeys.index font
    unless @annotation_fonts.include? fontkey
      @annotation_fonts[font] = fontkey
    end
    fontstyle = sprintf('/F%d %.2f Tf', fontkey + 1, @font_size_pt)
    popt['da'] = "#{fontstyle} #{@text_color}"
    popt['ap'] = {}
    popt['ap']['n'] = {}
    popt['ap']['n'][onvalue] = "q #{@text_color} BT #{fontstyle} 0 0 Td (n) Tj ET Q"
    popt['ap']['n']['Off'] = "q #{@text_color} BT #{fontstyle} 0 0 Td (o) Tj ET Q"
    popt['mk'] ||= {}
    popt['mk']['ca'] = '(l)'
    # merge options
    opt = popt.merge opt
    # set remaining annotation data
    opt['Subtype'] = 'Widget'
    opt['ft'] = 'Btn'
    if checked
      opt['v'] = ["/#{onvalue}"]
      opt['as'] = onvalue
    else
      opt['as'] = 'Off'
    end
    Annotation(x, y, w, w, name, opt, 0)
    if @rtl
      @x -= w
    else
      @x += w
    end
  end
  alias_method :radio_button, :RadioButton

  #
  # Creates a List-box field
  # [@param string :name] field name
  # [@param int :w] width
  # [@param int :h] height
  # [@param array :values] array containing the list of values.
  # [@param array :prop] javascript field properties. Possible values are described on official Javascript for Acrobat API reference.
  # [@param array :opt] annotation parameters. Possible values are described on official PDF32000_2008 reference.
  # [@param float :x] Abscissa of the upper-left corner of the rectangle
  # [@param float :y] Ordinate of the upper-left corner of the rectangle
  # [@param boolean :js] if true put the field using JavaScript (requires Acrobat Writer to be rendered).
  # [@access public]
  # [@author Nicola Asuni]
  # [@since 4.8.000 (2009-09-07)]
  #
  def ListBox(name, w, h, values, prop = {}, opt = {}, x = '', y = '', js = false)
    x = @x if x == ''
    y = @y if y == ''

    if js
      addfield('listbox', name, x, y, w, h, prop)
      s = ''
      values.each {|v|
        if v.is_a?(Array)
          s << "['#{v[0]}','#{v[1]}'],"
        else
          s << "'#{v}',"
        end
      }
      @javascript << "f#{name}.setItems([#{s[0...-1]}]);\n"
      return
    end
    # get default style
    prop = getFormDefaultProp.merge prop
    # get annotation data
    popt = getAnnotOptFromJSProp(prop)
    # set additional default values
    font = @font_family
    fontkey = @fontkeys.index font
    unless @annotation_fonts.include? fontkey
      @annotation_fonts[font] = fontkey
    end
    s = ''
    values.each {|v|
      if v.is_a?(Array)
        s << "#{v[1]}\n"
      else
        s << "#{v}\n"
      end
    }

    fontstyle = sprintf('/F%d %.2f Tf %s', fontkey + 1, @font_size_pt, @text_color)
    popt['da'] = fontstyle
    popt['ap'] = {}
    # set Appearances
    popt['ap']['n'] = "/Tx BMC q #{fontstyle} "
    gvars = getGraphicVars()
    @h = h
    @w = w
    @t_margin = 0
    @c_margin = 0.2

    @tmp_buffer = ''
    multi_cell(w, h, s, 0, '', 0, 0, 0.2, 0, true, 0, false, true, 0)
    popt['ap']['n'] << @tmp_buffer
    popt['ap']['n'] << 'Q EMC'
    @tmp_buffer = nil

    # restore previous values
    setGraphicVars(gvars, true)

    # merge options
    opt = popt.merge opt
    # set remaining annotation data
    opt['Subtype'] = 'Widget'
    opt['ft'] = 'Ch'
    opt['t'] = name
    opt['opt'] = values
    Annotation(x, y, w, h, name, opt, 0)
    if @rtl
      @x -= w
    else
      @x += w
    end
  end
  alias_method :list_box, :ListBox

  #
  # Creates a Combo-box field
  # [@param string :name] field name
  # [@param int :w] width
  # [@param int :h] height
  # [@param array :values] array containing the list of values.
  # [@param array :prop] javascript field properties. Possible values are described on official Javascript for Acrobat API reference.
  # [@param array :opt] annotation parameters. Possible values are described on official PDF32000_2008 reference.
  # [@param float :x] Abscissa of the upper-left corner of the rectangle
  # [@param float :y] Ordinate of the upper-left corner of the rectangle
  # [@param boolean :js] if true put the field using JavaScript (requires Acrobat Writer to be rendered).
  # [@access public]
  # [@author Nicola Asuni]
  # [@since 4.8.000 (2009-09-07)]
  #
  def ComboBox(name, w, h, values, prop = {}, opt = {}, x = '', y = '', js = false)
    x = @x if x == ''
    y = @y if y == ''

    if js
      addfield('combobox', name, x, y, w, h, prop)
      s = ''
      values.each {|v|
        if v.is_a?(Array)
          s << "['#{v[0]}','#{v[1]}'],"
        else
          s << "'#{v}',"
        end
      }
      @javascript << "f#{name}.setItems([#{s[0...-1]}]);\n"
      return
    end
    # get default style
    prop = getFormDefaultProp.merge prop
    prop['Combo'] = 'true'
    # get annotation data
    popt = getAnnotOptFromJSProp(prop)
    # set additional default options
    font = @font_family
    fontkey = @fontkeys.index font
    unless @annotation_fonts.include? fontkey
      @annotation_fonts[font] = fontkey
    end

    s = ''
    values.each {|v|
      if v.is_a?(Array)
        s << "#{v[1]}\n"
      else
        s << "#{v}\n"
      end
    }
    fontstyle = sprintf('/F%d %.2f Tf %s', fontkey + 1, @font_size_pt, @text_color)
    popt['da'] = fontstyle
    popt['ap'] = {}
    # set Appearances
    popt['ap']['n'] = "/Tx BMC q #{fontstyle} "
    gvars = getGraphicVars()
    @h = h
    @w = w
    @t_margin = 0
    @c_margin = 0.2

    @tmp_buffer = ''
    multi_cell(w, h, s, 0, '', 0, 0, 0.2, 0, true, 0, false, true, 0)
    popt['ap']['n'] << @tmp_buffer
    popt['ap']['n'] << 'Q EMC'
    @tmp_buffer = nil

    # restore previous values
    setGraphicVars(gvars, true)

    # merge options
    opt = popt.merge opt
    # set remaining annotation data
    opt['Subtype'] = 'Widget'
    opt['ft'] = 'Ch'
    opt['t'] = name
    opt['opt'] = values
    Annotation(x, y, w, h, name, opt, 0)
    if @rtl
      @x -= w
    else
      @x += w
    end
  end
  alias_method :combo_box, :ComboBox

  #
  # Creates a CheckBox field
  # [@param string :name] field name
  # [@param int :w] width
  # [@param boolean :checked] define the initial state.
  # [@param array :prop] javascript field properties. Possible values are described on official Javascript for Acrobat API reference.
  # [@param array :opt] annotation parameters. Possible values are described on official PDF32000_2008 reference.
  # [@param string :onvalue] value to be returned if selected.
  # [@param float :x] Abscissa of the upper-left corner of the rectangle
  # [@param float :y] Ordinate of the upper-left corner of the rectangle
  # [@param boolean :js] if true put the field using JavaScript (requires Acrobat Writer to be rendered).
  # [@access public]
  # [@author Nicola Asuni]
  # [@since 4.8.000 (2009-09-07)]
  #
  def CheckBox(name, w, checked=false, prop = {}, opt = {}, onvalue = 'Yes', x = '', y = '', js = false)
    x = @x if x == ''
    y = @y if y == ''

    if js
      addfield('checkbox', name, x, y, w, w, prop)
      return
    end

    prop['value'] ||= ['Yes']
    # get default style
    prop = getFormDefaultProp.merge prop
    prop['borderStyle'] = 'inset'
    # get annotation data
    popt = getAnnotOptFromJSProp(prop)
    # set additional default options
    font = 'zapfdingbats'
    AddFont(font)
    fontkey = @fontkeys.index font
    unless @annotation_fonts.include? fontkey
      @annotation_fonts[font] = fontkey
    end
    fontstyle = sprintf('/F%d %.2f Tf', fontkey + 1, @font_size_pt)
    popt['da'] = "#{fontstyle} #{@text_color}"
    popt['ap'] = {}
    popt['ap']['n'] = {}
    popt['ap']['n']['Yes'] = "q #{@text_color} BT #{fontstyle} 0 0 Td (n) Tj ET Q"
    popt['ap']['n']['Off'] = "q #{@text_color} BT #{fontstyle} 0 0 Td (o) Tj ET Q"

    # merge options
    opt = popt.merge opt
    # set remaining annotation data
    opt['Subtype'] = 'Widget'
    opt['ft'] = 'Btn'
    opt['t'] = name
    if empty_string(onvalue)
      onvalue = 'Yes'
    end
    opt['opt'] = [onvalue]
    if checked
      opt['v'] = ['/Yes']
      opt['as'] = 'Yes'
    else
      opt['v'] = ['/Off']
      opt['as'] = 'Off'
    end
    Annotation(x, y, w, w, name, opt, 0)
    if @rtl
      @x -= w
    else
      @x += w
    end
  end
  alias_method :check_box, :CheckBox

  #
  # Creates a button field
  # [@param string :name] field name
  # [@param int :w] width
  # [@param int :h] height
  # [@param string :caption] caption.
  # [@param mixed :action] action triggered by pressing the button. Use a string to specify a javascript action. Use an array to specify a form action options as on section 12.7.5 of PDF32000_2008.
  # [@param array :prop] javascript field properties. Possible values are described on official Javascript for Acrobat API reference.
  # [@param array :opt] annotation parameters. Possible values are described on official PDF32000_2008 reference.
  # [@param float :x] Abscissa of the upper-left corner of the rectangle
  # [@param float :y] Ordinate of the upper-left corner of the rectangle
  # [@param boolean :js] if true put the field using JavaScript (requires Acrobat Writer to be rendered).
  # [@access public]
  # [@author Nicola Asuni]
  # [@since 4.8.000 (2009-09-07)]
  #
  def Button(name, w, h, caption, action, prop = {}, opt = {}, x = '', y = '', js = false)
    x = @x if x == ''
    y = @y if y == ''

    if js
      addfield('button', name, x, y, w, h, prop)
      @javascript << "f#{name}.buttonSetCaption('#{caption}');\n"
      @javascript << "f#{name}.setAction('MouseUp','#{action}');\n"
      @javascript << "f#{name}.highlight='push';\n"
      @javascript << "f#{name}.print=false;\n"
      return
    end
    # get default style
    prop = getFormDefaultProp.merge prop
    prop['Pushbutton'] = 'true'
    prop['highlight'] = 'push'
    prop['display'] = 'display.noPrint'
    # get annotation data
    popt = getAnnotOptFromJSProp(prop)
    # set additional default options
    popt['mk'] ||= {}
    popt['mk']['ca'] = textstring(caption)
    popt['mk']['rc'] = textstring(caption)
    popt['mk']['ac'] = textstring(caption)
    font = @font_family
    fontkey = @fontkeys.index font
    unless @annotation_fonts.include? fontkey
      @annotation_fonts[font] = fontkey
    end
    fontstyle = sprintf('/F%d %.2f Tf %s', fontkey + 1, @font_size_pt, @text_color)
    popt['da'] = fontstyle
    popt['ap'] = {}
    # set Appearances
    popt['ap']['n'] = "/Tx BMC q #{fontstyle} 0.800 g\n"

    gvars = getGraphicVars()
    @h = h
    @w = w
    @c_margin *= 1.6

    @tmp_buffer = ''
    SetLineStyle({'width' => 1.0, 'cap' => 'butt', 'join' => 'miter', 'dash' => 0, 'color' => [231]})
    SetFillColor(204)
    multi_cell(w, h, caption, 1, 'C', 1, 0, 0, 0, true)
    popt['ap']['n'] << @tmp_buffer
    popt['ap']['n'] << 'Q EMC'
    @tmp_buffer = nil

    # restore previous values
    setGraphicVars(gvars, true)

    # merge options
    opt = popt.merge opt
    # set remaining annotation data
    opt['Subtype'] = 'Widget'
    opt['ft'] = 'Btn'
    opt['t'] = caption
    opt['v'] = name
    unless action.empty?
      if action.is_a?(Hash)
        # form action options as on section 12.7.5 of PDF32000_2008.
        opt['aa'] = '/D <<'
        bmode = ['SubmitForm', 'ResetForm', 'ImportData']
        action.each {|key, val|
          if (key == 'S') && bmode.include?(val)
            opt['aa'] << " /S /#{val}"
          elsif (key == 'F') && !val.empty?
            opt['aa'] << " /F #{datastring(val)}"
          elsif (key == 'Fields') && val.is_a?(Array) && !val.empty?
            opt['aa'] << ' /Fields ['
            val.each {|field|
              opt['aa'] << " #{textstring(field)}"
            }
            opt['aa'] << ']'
          elsif key == 'Flags'
            ff = 0
            if val.is_a?(Array)
              val.each {|flag|
                case flag
                when 'Include/Exclude';      ff |= 1 << 0
                when 'IncludeNoValueFields'; ff |= 1 << 1
                when 'ExportFormat';         ff |= 1 << 2
                when 'GetMethod';            ff |= 1 << 3
                when 'SubmitCoordinates';    ff |= 1 << 4
                when 'XFDF';                 ff |= 1 << 5
                when 'IncludeAppendSaves';   ff |= 1 << 6
                when 'IncludeAnnotations';   ff |= 1 << 7
                when 'SubmitPDF';            ff |= 1 << 8
                when 'CanonicalFormat';      ff |= 1 << 9
                when 'ExclNonUserAnnots';    ff |= 1 << 10
                when 'ExclFKey';             ff |= 1 << 11
                when 'EmbedForm';            ff |= 1 << 13
                end
              }
            else
              ff = val.to_i
            end
            opt['aa'] << " /Flags #{ff}"
          end
        }
        opt['aa'] << ' >>'
      else
        # Javascript action or raw action command
        js_obj_id = addJavascriptObject(action)
        opt['aa'] = "/D #{js_obj_id} 0 R"
      end
    end
    Annotation(x, y, w, h, name, opt, 0)
    if @rtl
      @x -= w
    else
      @x += w
    end
  end
  alias_method :button, :Button

  # --- END FORMS FIELDS ------------------------------------------------

  #
  # Create a new page group.
  # * NOTE: call this function before calling AddPage()
  # [@param int :page] starting group page (leave empty for next page).
  # [@access public]
  # [@since 3.0.000 (2008-03-27)]
  #
  def startPageGroup(page=0)
    if !page.is_a? Integer or page.zero?
      page = @page + 1
    end
    @newpagegroup[page] = true
  end
  alias_method :start_page_group, :startPageGroup

  #
  # Defines an alias for the total number of pages.
  # It will be substituted as the document is closed.
  # [@param string :alias] The alias.
  # [@access public]
  # [@since 1.4]
  # [@see] getAliasNbPages(), PageNo(), Footer()
  #
  def AliasNbPages(alias_nb ='{nb}')
    @alias_nb_pages = alias_nb
  end
  alias_method :alias_nb_pages, :AliasNbPages

  #
  # Returns the string alias used for the total number of pages.
  # If the current font is unicode type, the returned string is surrounded by additional curly braces.
  # [@return string]
  # [@access public]
  # [@since 4.0.018 (2008-08-08)]
  # [@see] AliasNbPages(), PageNo(), Footer()
  #
  def getAliasNbPages()
    if (@current_font['type'] == 'TrueTypeUnicode') or (@current_font['type'] == 'cidfont0')
      return '{' + @alias_nb_pages + '}'
    end
    return @alias_nb_pages
  end
  alias_method :get_alias_nb_pages, :getAliasNbPages

  #
  # Defines an alias for the page number.
  # It will be substituted as the document is closed.
  # [@param string :alias] The alias.
  # [@access public]
  # [@since 4.5.000 (2009-01-02)]
  # [@see] getAliasNbPages(), PageNo(), Footer()
  #
  def AliasNumPage(alias_num='{pnb}')
    # Define an alias for total number of pages
    @alias_num_page = alias_num
  end
  alias_method :alias_num_page, :AliasNumPage

  #
  # Returns the string alias used for the page number.
  # If the current font is unicode type, the returned string is surrounded by additional curly braces.
  # [@return string]
  # [@access public]
  # [@since 4.5.000 (2009-01-02)]
  # [@see] AliasNbPages(), PageNo(), Footer()
  #
  def getAliasNumPage()
    if (@current_font['type'] == 'TrueTypeUnicode') or (@current_font['type'] == 'cidfont0')
      return '{' + @alias_num_page + '}'
    end
    return @alias_num_page
  end
  alias_method :get_alias_num_page, :getAliasNumPage

  #
  # Return the current page in the group.
  # [@return] current page in the group
  # [@access public]
  # [@since 3.0.000 (2008-03-27)]
  #
  def getGroupPageNo()
    return @pagegroups[@currpagegroup]
  end
  alias_method :get_group_page_no, :getGroupPageNo

  #
  # Returns the current group page number formatted as a string.
  # [@access public]
  # [@since 4.3.003 (2008-11-18)]
  # [@see] PaneNo(), formatPageNumber()
  #
  def getGroupPageNoFormatted()
    return formatPageNumber(getGroupPageNo())
  end
  alias_method :get_group_page_no_formatted, :getGroupPageNoFormatted

  #
  # Return the alias of the current page group
  # If the current font is unicode type, the returned string is surrounded by additional curly braces.
  # (will be replaced by the total number of pages in this group).
  # [@return] alias of the current page group
  # [@access public]
  # [@since 3.0.000 (2008-03-27)]
  #
  def getPageGroupAlias()
    if (@current_font['type'] == 'TrueTypeUnicode') or (@current_font['type'] == 'cidfont1')
      return '{' + @currpagegroup + '}'
    end
    return @currpagegroup
  end
  alias_method :get_page_group_alias, :getPageGroupAlias

  #
  # Return the alias for the page number on the current page group
  # If the current font is unicode type, the returned string is surrounded by additional curly braces.
  # (will be replaced by the total number of pages in this group).
  # [@return] alias of the current page group
  # [@access public]
  # [@since 4.5.000 (2009-01-02)]
  #
  def getPageNumGroupAlias()
    if (@current_font['type'] == 'TrueTypeUnicode') or (@current_font['type'] == 'cidfont0')
      return '{' + @currpagegroup.gsub('{nb', '{pnb') +'}'
    end
    return @currpagegroup.gsub('{nb', '{pnb')
  end
  alias_method :get_page_num_group_alias, :getPageNumGroupAlias

  #
  # Format the page numbers.
  # This method can be overriden for custom formats.
  # [@param int :num] page number
  # [@access protected]
  # [@since 4.2.005 (2008-11-06)]
  #
  def formatPageNumber(num)
    return number_with_delimiter(num, :delimiter => ",")
  end
  protected :formatPageNumber

  #
  # Format the page numbers on the Table Of Content.
  # This method can be overriden for custom formats.
  # [@param int :num] page number
  # [@access protected]
  # [@since 4.5.001 (2009-01-04)]
  # [@see] addTOC(), addHTMLTOC()
  #
  def formatTOCPageNumber(num)
    return number_with_delimiter(num, :delimiter => ",")
  end
  protected :formatTOCPageNumber

  #
  # Returns the current page number formatted as a string.
  # [@access public]
  # [@since 4.2.005 (2008-11-06)]
  # [@see] PaneNo(), formatPageNumber()
  #
  def PageNoFormatted()
    return formatPageNumber(PageNo())
  end
  alias_method :page_no_formatted, :PageNoFormatted

  #
  # Put visibility settings.
  # [@access protected]
  # [@since 3.0.000 (2008-03-27)]
  #
  def putocg()
    newobj()
    @n_ocg_print = @n
    out('<< /Type /OCG /Name ' + textstring('print') + ' /Usage << /Print <</PrintState /ON>> /View <</ViewState /OFF>> >> >> endobj')
    newobj()
    @n_ocg_view = @n
    out('<< /Type /OCG /Name ' + textstring('view') + ' /Usage << /Print <</PrintState /OFF>> /View <</ViewState /ON>> >> >> endobj')
  end
  protected :putocg

  #
  # Set the visibility of the successive elements.
  # This can be useful, for instance, to put a background
  # image or color that will show on screen but won't print.
  # [@param string :v] visibility mode. Legal values are: all, print, screen.
  # [@access public]
  # [@since 3.0.000 (2008-03-27)]
  #
  def setVisibility(v)
    if @open_marked_content
      # close existing open marked-content
      out('EMC')
      @open_marked_content = false
    end
    case v
    when 'print'
      out('/OC /OC1 BDC')
      @open_marked_content = true
    when 'screen'
      out('/OC /OC2 BDC')
      @open_marked_content = true
    when 'all'
      out('')
    else
      Error('Incorrect visibility: ' + v)
    end
    @visibility = v
  end
  alias_method :set_visibility, :setVisibility

  #
  # Add transparency parameters to the current extgstate
  # [@param array :params] parameters
  # [@return] the number of extgstates
  # [@access protected]
  # [@since 3.0.000 (2008-03-27)]
  #
  def addExtGState(parms)
    n = @extgstates.length + 1
    # check if this ExtGState already exist
    1.upto(n - 1) do |i|
      if @extgstates[i] and (@extgstates[i]['parms'] == parms)
        # return reference to existing ExtGState
        return i
      end
    end
    @extgstates[n] ||= {}
    @extgstates[n]['parms'] = parms
    return n
  end
  protected :addExtGState

  #
  # Add an extgstate
  # [@param array :gs] extgstate
  # [@access protected]
  # [@since 3.0.000 (2008-03-27)]
  #
  def setExtGState(gs)
    out(sprintf('/GS%d gs', gs))
  end
  protected :setExtGState

  #
  # Put extgstates for object transparency
  # [@param array :gs] extgstate
  # [@access protected]
  # [@since 3.0.000 (2008-03-27)]
  #
  def putextgstates()
    ne = @extgstates.length
    1.upto(ne) do |i|
      newobj()
      @extgstates[i] ||= {}
      @extgstates[i]['n'] = @n
      out = '<< /Type /ExtGState'
      if @extgstates[i]['parms']
        @extgstates[i]['parms'].each {|k, v|
          if v.is_a? Float
            v = sprintf('%.2f', v)
          end
          out << ' /' + k + ' ' + v.to_s
        }
      end
      out << ' >> endobj'
      out(out)
    end
  end
  protected :putextgstates

  #
  # Set alpha for stroking (CA) and non-stroking (ca) operations.
  # [@param float :alpha] real value from 0 (transparent) to 1 (opaque)
  # [@param string :bm] blend mode, one of the following: Normal, Multiply, Screen, Overlay, Darken, Lighten, ColorDodge, ColorBurn, HardLight, SoftLight, Difference, Exclusion, Hue, Saturation, Color, Luminosity
  # [@access public]
  # [@since 3.0.000 (2008-03-27)]
  #
  def setAlpha(alpha, bm='Normal')
    gs = addExtGState({'ca' => alpha, 'CA' => alpha, 'BM' => '/' + bm, 'AIS' => 'false'})
    setExtGState(gs)
  end
  alias_method :set_alpha, :setAlpha

  #
  # Set the default JPEG compression quality (1-100)
  # [@param int :quality] JPEG quality, integer between 1 and 100
  # [@access public]
  # [@since 3.0.000 (2008-03-27)]
  #
  def setJPEGQuality(quality)
    if (quality < 1) or (quality > 100)
      quality = 75
    end
    @jpeg_quality = quality
  end
  alias_method :set_jpeg_quality, :setJPEGQuality

  #
  # Set the height of cell repect font height.
  # [@param int :h] cell proportion respect font height (typical value = 1.25).
  # [@access public]
  # [@since 3.0.014 (2008-06-04)]
  #
  def setCellHeightRatio(h)
    @cell_height_ratio = h
  end
  alias_method :set_cell_height_ratio, :setCellHeightRatio

  #
  # return the height of cell repect font height.
  # [@access public]
  # [@since 4.0.012 (2008-07-24)]
  #
  def getCellHeightRatio()
    return @cell_height_ratio
  end
  alias_method :get_cell_height_ratio, :getCellHeightRatio

  #
  # Set the PDF version (check PDF reference for valid values).
  # Default value is 1.t
  # [@access public]
  # [@since 3.1.000 (2008-06-09)]
  #
  def setPDFVersion(version='1.7')
    @pdf_version = version
  end
  alias_method :set_pdf_version, :setPDFVersion

  #
  # Set the viewer preferences dictionary controlling the way the document is to be presented on the screen or in print.
  # (see Section 8.1 of PDF reference, "Viewer Preferences").
  # * HideToolbar boolean (Optional) A flag specifying whether to hide the viewer application's tool bars when the document is active. Default value: false.
  # * HideMenubar boolean (Optional) A flag specifying whether to hide the viewer application's menu bar when the document is active. Default value: false.
  # * HideWindowUI boolean (Optional) A flag specifying whether to hide user interface elements in the document's window (such as scroll bars and navigation controls), leaving only the document's contents displayed. Default value: false.
  # * FitWindow boolean (Optional) A flag specifying whether to resize the document's window to fit the size of the first displayed page. Default value: false.
  # * CenterWindow boolean (Optional) A flag specifying whether to position the document's window in the center of the screen. Default value: false.
  # * DisplayDocTitle boolean (Optional; PDF 1.4) A flag specifying whether the window's title bar should display the document title taken from the Title entry of the document information dictionary (see Section 10.2.1, "Document Information Dictionary"). If false, the title bar should instead display the name of the PDF file containing the document. Default value: false.
  # * NonFullScreenPageMode name (Optional) The document's page mode, specifying how to display the document on exiting full-screen mode:
  #   * UseNone Neither document outline nor thumbnail images visible
  #   * UseOutlines Document outline visible
  #   * UseThumbs Thumbnail images visible
  #   * UseOC Optional content group panel visible
  #   This entry is meaningful only if the value of the PageMode entry in the catalog dictionary (see Section 3.6.1, "Document Catalog") is FullScreen; it is ignored otherwise. Default value: UseNone.
  # * ViewArea name (Optional; PDF 1.4) The name of the page boundary representing the area of a page to be displayed when viewing the document on the screen. Valid values are (see Section 10.10.1, "Page Boundaries").:
  #   * MediaBox
  #   * CropBox (default)
  #   * BleedBox
  #   * TrimBox
  #   * ArtBox
  # * ViewClip name (Optional; PDF 1.4) The name of the page boundary to which the contents of a page are to be clipped when viewing the document on the screen. Valid values are (see Section 10.10.1, "Page Boundaries").:
  #   * MediaBox
  #   * CropBox (default)
  #   * BleedBox
  #   * TrimBox
  #   * ArtBox
  # * PrintArea name (Optional; PDF 1.4) The name of the page boundary representing the area of a page to be rendered when printing the document. Valid values are (see Section 10.10.1, "Page Boundaries").:
  #   * MediaBox
  #   * CropBox (default)
  #   * BleedBox
  #   * TrimBox
  #   * ArtBox
  # * PrintClip name (Optional; PDF 1.4) The name of the page boundary to which the contents of a page are to be clipped when printing the document. Valid values are (see Section 10.10.1, "Page Boundaries").:
  #   * MediaBox
  #   * CropBox (default)
  #   * BleedBox
  #   * TrimBox
  #   * ArtBox
  # * PrintScaling name (Optional; PDF 1.6) The page scaling option to be selected when a print dialog is displayed for this document. Valid values are:
  #   * None, which indicates that the print dialog should reflect no page scaling
  #   * AppDefault (default), which indicates that applications should use the current print scaling
  # * Duplex name (Optional; PDF 1.7) The paper handling option to use when printing the file from the print dialog. The following values are valid:
  #   * Simplex - Print single-sided
  #   * DuplexFlipShortEdge - Duplex and flip on the short edge of the sheet
  #   * DuplexFlipLongEdge - Duplex and flip on the long edge of the sheet
  #   Default value: none
  # * PickTrayByPDFSize boolean (Optional; PDF 1.7) A flag specifying whether the PDF page size is used to select the input paper tray. This setting influences only the preset values used to populate the print dialog presented by a PDF viewer application. If PickTrayByPDFSize is true, the check box in the print dialog associated with input paper tray is checked. Note: This setting has no effect on Mac OS systems, which do not provide the ability to pick the input tray by size.
  # * PrintPageRange array (Optional; PDF 1.7) The page numbers used to initialize the print dialog box when the file is printed. The first page of the PDF file is denoted by 1. Each pair consists of the first and last pages in the sub-range. An odd number of integers causes this entry to be ignored. Negative numbers cause the entire array to be ignored. Default value: as defined by PDF viewer application
  # * NumCopies integer (Optional; PDF 1.7) The number of copies to be printed when the print dialog is opened for this file. Supported values are the integers 2 through 5. Values outside this range are ignored. Default value: as defined by PDF viewer application, but typically 1
  # [@param array :preferences] array of options.
  # [@author] Nicola Asuni
  # [@access public]
  # [@since 3.1.000 (2008-06-09)]
  #
  def setViewerPreferences(preferences)
    @viewer_preferences = preferences
  end
  alias_method :set_viewer_preferences, :setViewerPreferences

  #
  # Draw the sector of a circle.
  # It can be used for instance to render pie charts.
  # [@param float :xc] abscissa of the center.
  # [@param float :yc] ordinate of the center.
  # [@param float :r] radius.
  # [@param float :a] start angle (in degrees).
  # [@param float :b] end angle (in degrees).
  # [@param string :style] Style of rendering. See the getPathPaintOperator() function for more information.
  # [@param float :cw] indicates whether to go clockwise (default: true).
  # [@param float :o] origin of angles (0 for 3 o'clock, 90 for noon, 180 for 9 o'clock, 270 for 6 o'clock). Default: 90.
  # [@author] Maxime Delorme, Nicola Asuni
  # [@since 3.1.000 (2008-06-09)]
  # [@access public]
  #
  def PieSector(xc, yc, r, a, b, style='FD', cw=true, o=90)
    PieSectorXY(xc, yc, r, r, a, b, style, cw, o)
  end
  alias_method :pie_sector, :PieSector

  #
  # Draw the sector of an ellipse.
  # It can be used for instance to render pie charts.
  # [@param float :xc] abscissa of the center.
  # [@param float :yc] ordinate of the center.
  # [@param float :rx] the x-axis radius.
  # [@param float :ry] the y-axis radius.
  # [@param float :a] start angle (in degrees).
  # [@param float :b] end angle (in degrees).
  # [@param string :style] Style of rendering. See the getPathPaintOperator() function for more information.
  # [@param float :cw] indicates whether to go clockwise.
  # [@param float :o] origin of angles (0 for 3 o'clock, 90 for noon, 180 for 9 o'clock, 270 for 6 o'clock).
  # [@param integer :nc] Number of curves used to draw a 90 degrees portion of arc.
  # [@author] Maxime Delorme, Nicola Asuni
  # [@since 3.1.000 (2008-06-09)]
  # [@access public]
  #
  def PieSectorXY(xc, yc, rx, ry, a, b, style='FD', cw=false, o=0, nc=2)
    if @rtl
      xc = @w - xc
    end
    op = getPathPaintOperator(style)
    ### not use ###
    #if op == 'f'
    #  line_style = nil
    #end
    if cw
      d = b
      b = 360 - a + o
      a = 360 - d + o
    else
      b += o
      a += o
    end
    outellipticalarc(xc, yc, rx, ry, 0, a, b, true, nc)
    out(op)
  end
  alias_method :pie_sector_xy, :PieSectorXY

=begin
  #
  # Set document barcode.
  # [@param string :bc] barcode
  # [@access public]
  #
  def setBarcode(bc="")
    @barcode = bc;
  end
  alias_method :set_barcode, :setBarcode

  def SetBarcode(bc="")
     warn "[DEPRECATION] 'SetBarcode' is deprecated. Please use 'set_barcode' instead."
     setBarcode(bc)
  end

  #
  # Get current barcode.
  # [@return string]
  # [@access public]
  # [@since 4.0.012 (2008-07-24)]
  #
  def getBarcode()
    return @barcode
  end
  alias_method :get_barcode, :getBarcode

  #
  # Print Barcode.
  # [@param int :x] x position in user units
  # [@param int :y] y position in user units
  # [@param int :w] width in user units
  # [@param int :h] height position in user units
  # [@param string :type] type of barcode (I25, C128A, C128B, C128C, C39)
  # [@param string :style] barcode style
  # [@param string :font] font for text
  # [@param int :xres] x resolution
  # [@param string :code] code to print
  # [@access public]
  #
  def writeBarcode(x, y, w, h, type, style, font, xres, code)
    require(File.dirname(__FILE__) + "/barcode/barcode.rb");
    require(File.dirname(__FILE__) + "/barcode/i25object.rb");
    require(File.dirname(__FILE__) + "/barcode/c39object.rb");
    require(File.dirname(__FILE__) + "/barcode/c128aobject.rb");
    require(File.dirname(__FILE__) + "/barcode/c128bobject.rb");
    require(File.dirname(__FILE__) + "/barcode/c128cobject.rb");

    if (code.empty?)
      return;
    end

    if (style.empty?)
      style  = BCS_ALIGN_LEFT;
      style |= BCS_IMAGE_PNG;
      style |= BCS_TRANSPARENT;
      #:style |= BCS_BORDER;
      #:style |= BCS_DRAW_TEXT;
      #:style |= BCS_STRETCH_TEXT;
      #:style |= BCS_REVERSE_COLOR;
    end
    if (font.empty?) then font = BCD_DEFAULT_FONT; end
    if (xres.empty?) then xres = BCD_DEFAULT_XRES; end

    scale_factor = 1.5 * xres * @k;
    bc_w = (w * scale_factor).round #width in points
    bc_h = (h * scale_factor).round #height in points

    case (type.upcase)
      when "I25"
        obj = I25Object.new(bc_w, bc_h, style, code);
      when "C128A"
        obj = C128AObject.new(bc_w, bc_h, style, code);
      when "C128B"
        obj = C128BObject.new(bc_w, bc_h, style, code);
      when "C128C"
        obj = C128CObject.new(bc_w, bc_h, style, code);
      when "C39"
        obj = C39Object.new(bc_w, bc_h, style, code);
    end

    obj.SetFont(font);
    obj.DrawObject(xres);

    #use a temporary file....
    tmpName = tempnam(@@k_path_cache,'img');
    imagepng(obj.getImage(), tmpName);
    Image(tmpName, x, y, w, h, 'png');
    obj.DestroyObject();
    obj = nil
    unlink(tmpName);
  end
  alias_method :write_barcode, :writeBarcode
=end

  #
  # Returns an array containing current margins:
  #
  #  * ret['left'] = left  margin
  #  * ret['right'] = right margin
  #  * ret['top'] = top margin
  #  * ret['bottom'] = bottom margin
  #  * ret['header'] = header margin
  #  * ret['footer'] = footer margin
  #  * ret['cell'] = cell margin
  #
  # [@return array] containing all margins measures
  # [@access public]
  # [@since 3.2.000 (2008-06-23)]
  #
  def getMargins()
    ret = {
        'left' => @l_margin,
        'right' => @r_margin,
        'top' => @t_margin,
        'bottom' => @b_margin,
        'header' => @header_margin,
        'footer' => @footer_margin,
        'cell' => @c_margin,
    }
    return ret
  end
  alias_method :get_margins, :getMargins

  #
  # Returns an array containing original margins:
  #   ret['left'] = left  margin
  #   ret['right'] = right margin
  # [@return array] containing all margins measures
  # [@access public]
  # [@since 4.0.012 (2008-07-24)]
  #
  def getOriginalMargins()
    ret = { 'left' => @original_l_margin, 'right' => @original_r_margin }
    return ret
  end
  alias_method :get_original_margins, :getOriginalMargins

  #
  # Returns the current font size.
  # [@return] current font size
  # [@access public]
  # [@since 3.2.000 (2008-06-23)]
  #
  def getFontSize()
    return @font_size
  end
  alias_method :get_font_size, :getFontSize

  #
  # Returns the current font size in points unit.
  # [@return] current font size in points unit
  # [@access public]
  # [@since 3.2.000 (2008-06-23)]
  #
  def getFontSizePt()
    return @font_size_pt
  end
  alias_method :get_font_size_pt, :getFontSizePt

  #
  # Returns the current font family name.
  # [@return string] current font family name
  # [@access public]
  # [@since 4.3.008 (2008-12-05)]
  #
  def getFontFamily()
    return @font_family
  end
  alias_method :get_font_family, :getFontFamily

  #
  # Returns the current font style.
  # [@return string] current font style
  # [@access public]
  # [@since 4.3.008 (2008-12-05)]
  #
  def getFontStyle()
    return @font_style
  end
  alias_method :get_font_style, :getFontStyle

  # --- HTML PARSER FUNCTIONS ---

protected

  #
  # Extracts the CSS properties from a CSS string.
  # [@param string :cssdata] string containing CSS definitions.
  # [@return] A hash where the keys are the CSS selectors and the values are the CSS properties.
  # [@author] Nicola Asuni
  # [@since 5.1.000 (2010-05-25)]
  # [@access protected]
  #
  def extractCSSproperties(cssdata)
    if cssdata.empty?
      return {}
    end
    # remove comments
    cssdata = cssdata.gsub(/\/\*[^\*]*\*\//, '')
    # remove newlines and multiple spaces
    cssdata.gsub!(/[\s]+/, ' ')
    # remove some spaces
    cssdata.gsub!(/[\s]*([;:\{\}]{1})[\s]*/, '\\1')
    # remove empty blocks
    cssdata.gsub!(/([^\}\{]+)\{\}/, '')
    # replace media type parenthesis
    cssdata.gsub!(/@media[\s]+([^\{]*)\{/i, "@media \\1\t")
    cssdata.gsub!(/\}\}/mi, "}\t")
    # trim string
    cssdata = cssdata.lstrip
    # find media blocks (all, braille, embossed, handheld, print, projection, screen, speech, tty, tv)
    cssblocks = {}
    matches = cssdata.scan(/@media +([^\t]*)\t([^\t]*)\t/i)
    unless matches.empty?
      matches.each { |type|
        cssblocks[type[0]] = type[1]
      }
      # remove media blocks
      cssdata.gsub!(/@media +([^\t]*)\t([^\t]*)\t/i, '')
    end
    # keep 'all' and 'print' media, other media types are discarded
    if cssblocks['all'] and !cssblocks['all'].empty?
      cssdata << cssblocks['all']
    end
    if cssblocks['print'] and !cssblocks['print'].empty?
      cssdata << cssblocks['print']
    end
    # reset css blocks array
    cssblocks = []
    # explode css data string into array
    if cssdata[-1, 1] == '}'
      # remove last parethesis
      cssdata = cssdata.chop
    end
    matches = cssdata.split('}')
    matches.each_with_index { |block, key|
      # index 0 contains the CSS selector, index 1 contains CSS properties
      cssblocks[key] = block.split('{')
    }
    # split groups of selectors (comma-separated list of selectors)
    cssblocks_tmp = []
    cssblocks.each_with_index { |block, key|
      # index 0 contains the CSS selector, index 1 contains CSS properties
      if block[0].index(',')
        selectors = block[0].split(',')
        selectors.each {|sel|
          cssblocks_tmp.push [sel.strip, block[1]]
        }
      else
        cssblocks_tmp.push [block[0], block[1]]
      end
    }
    cssblocks = cssblocks_tmp

    # covert array to selector => properties
    cssdata = {}
    cssblocks.each { |block|
      selector = block[0]
      # calculate selector's specificity
      a = 0 # the declaration is not from is a 'style' attribute
      b = selector.scan(/[\#]/).size # number of ID attributes
      c = selector.scan(/[\[\.]/).size # number of other attributes
      c += selector.scan(/[\:]link|visited|hover|active|focus|target|lang|enabled|disabled|checked|indeterminate|root|nth|first|last|only|empty|contains|not/i).size # number of pseudo-classes
      d = (' ' + selector).scan(/[\>\+\~\s]{1}[a-zA-Z0-9\*]+/).size # number of element names
      d += selector.scan(/[\:][\:]/).size # number of pseudo-elements
      specificity = a.to_s + b.to_s + c.to_s + d.to_s
      # add specificity to the beginning of the selector
      cssdata[specificity + ' ' + selector] = block[1]
    }
    # sort selectors alphabetically to account for specificity
    # ksort(cssdata, SORT_STRING)
    # return array
    return cssdata
  end

  #
  # Returns true if the CSS selector is valid for the selected HTML tag
  # [@param array :dom] array of HTML tags and properties
  # [@param int :key] key of the current HTML tag
  # [@param string :selector] CSS selector string
  # [@return] true if the selector is valid, false otherwise
  # [@access protected]
  # [@since 5.1.000 (2010-05-25)]
  #
  def isValidCSSSelectorForTag(dom, key, selector)
    valid = false; # value to be returned
    tag = dom[key]['value']
    selector_class = ''
    if dom[key]['attribute'] and dom[key]['attribute']['class'] and !dom[key]['attribute']['class'].empty?
      selector_class = dom[key]['attribute']['class'].downcase
    end
    id = ''
    if dom[key]['attribute'] and dom[key]['attribute']['id'] and !dom[key]['attribute']['id'].empty?
      selector_id = dom[key]['attribute']['id'].downcase
    end

    selector_offset = 0
    offset = nil
    operator = ''
    lasttag = ''
    attrib = ''
    while selector_offset = selector.index(/([\>\+\~\s]{1})([a-zA-Z0-9\*]+)([^\>\+\s]*)/mi, selector_offset)
      offset = selector_offset
      selector_offset += $&.length
      operator = $1
      lasttag = $2.strip.downcase
      attrib = $3.strip.downcase
    end
    if offset
      if (lasttag == '*') or (lasttag == tag)
        # the last element on selector is our tag or 'any tag'
        if !attrib.empty?
          # check if matches class, id, attribute, pseudo-class or pseudo-element
          case attrib[0, 1]
          when '.'  # class
            valid = true  if attrib.sub(/^./, "") == selector_class
          when '#'  # ID
            valid = true  if attrib.sub(/^#/, "") == selector_id
          when '['  # attribute
            attrmatch = attrib.scan(/\[([a-zA-Z0-9]*)[\s]*([\~\^\$\*\|\=]*)[\s]*["]?([^"\]]*)["]?\]/i)
            if !attrmatch.empty?
              att = attrmatch[0][0].downcase
              val = attrmatch[0][2]

              if dom[key]['attribute'][att]
                case attrmatch[0][1]
                when '='
                  valid = true  if dom[key]['attribute'][att] == val
                when '~='
                  valid = true  if dom[key]['attribute'][att].split(' ').include?(val)
                when '^='
                  valid = true  if val == dom[key]['attribute'][att][0, val.length]
                when '$='
                  valid = true  if val == dom[key]['attribute'][att][-val.length..-1]
                when '*='
                  valid = true  if dom[key]['attribute'][att].index(val) != nil
                when '|='
                  if dom[key]['attribute'][att] == val
                    valid = true
                  elsif ! dom[key]['attribute'][att].scan(/#{val}[\-]{1}/i).empty?
                    valid = true
                  end
                else
                  valid = true
                end
              end
            end
          when ':'  # pseudo-class or pseudo-element
            if attrib[1] == ':'  # pseudo-element
              # pseudo-elements are not supported!
              # (::first-line, ::first-letter, ::before, ::after)
            else # pseudo-class
              # pseudo-classes are not supported!
              # (:root, :nth-child(n), :nth-last-child(n), :nth-of-type(n), :nth-last-of-type(n), :first-child, :last-child, :first-of-type, :last-of-type, :only-child, :only-of-type, :empty, :link, :visited, :active, :hover, :focus, :target, :lang(fr), :enabled, :disabled, :checked)
            end
          end # end of switch
        else
          valid = true
        end

        if valid and (offset > 0)
          valid = false
          # check remaining selector part
          selector = selector[0, offset]
          case operator
          when ' '  # descendant of an element
            while dom[key]['parent'] > 0
              if isValidCSSSelectorForTag(dom, dom[key]['parent'], selector)
                valid = true
                break
              else
                key = dom[key]['parent']
              end
            end
          when '>'  # child of an element
            valid = isValidCSSSelectorForTag(dom, dom[key]['parent'], selector)
          when '+'  # immediately preceded by an element
            (key - 1).downto(dom[key]['parent'] + 1) do |i|
              if dom[i]['tag'] and dom[i]['opening']
                valid = isValidCSSSelectorForTag(dom, i, selector)
                break
              end
            end
          when '~'  # preceded by an element
            (key - 1).downto(dom[key]['parent'] + 1) do |i|
              if dom[i]['tag'] and dom[i]['opening']
                if isValidCSSSelectorForTag(dom, i, selector)
                  break
                end
              end
            end
          end
        end
      end
    end
    return valid
  end

  #
  # Returns the styles that apply for the selected HTML tag.
  # [@param array :dom] array of HTML tags and properties
  # [@param int :key] key of the current HTML tag
  # [@param hash :css] array of CSS properties
  # [@return string] containing CSS properties
  # [@access protected]
  # [@since 5.1.000 (2010-05-25)]
  #
  def getTagStyleFromCSS(dom, key, css)
    tagstyle = '' # style to be returned
    # get all styles that apply
    css.each { |selector, style|
      # remove specificity
      selector = selector[selector.index(' ')..-1] if selector.index(' ')
      # check if this selector apply to current tag
      if isValidCSSSelectorForTag(dom, key, selector)
        # apply style
        tagstyle << ';' + style
      end
    }
    if dom[key]['attribute'] and dom[key]['attribute']['style']
      # attach inline style (latest properties have high priority)
      tagstyle << ';' + dom[key]['attribute']['style']
    end
    # remove multiple semicolons
    tagstyle.gsub!(/[;]+/, ';')
    return tagstyle
  end

  #
  # Returns the HTML DOM array.
  #   dom[key]['tag'] = true if tag, false otherwise
  #   dom[key]['value'] = tag name or text
  #   dom[key]['opening'] = true if opening tag, false otherwise
  #   dom[key]['attribute'] = array of attributes (attribute name is the key)
  #   dom[key]['style'] = array of style attributes (attribute name is the key)
  #   dom[key]['parent'] = id of parent element
  #   dom[key]['fontname'] = font family name
  #   dom[key]['fontstyle'] = font style
  #   dom[key]['fontsize'] = font size in points
  #   dom[key]['bgcolor'] = RGB array of background color
  #   dom[key]['fgcolor'] = RGB array of foreground color
  #   dom[key]['width'] = width in pixels
  #   dom[key]['height'] = height in pixels
  #   dom[key]['align'] = text alignment
  #   dom[key]['cols'] = number of colums in table
  #   dom[key]['rows'] = number of rows in table
  # [@param string :html] html code
  # [@return array]
  # [@access protected]
  # [@since 3.2.000 (2008-06-20)]
  #
  def getHtmlDomArray(html)
    html = html.dup
    html.force_encoding('UTF-8') if @is_unicode and html.respond_to?(:force_encoding)
    # array of CSS styles ( selector => properties).
    css = {}
    # extract external CSS files
    matches = html.scan(/<link([^\>]*?)>/mi)
    unless matches.empty?
      matches.each { |link|
        type = link[0].scan(/type[\s]*=[\s]*"text\/css"/)
        next if type.empty?

        type = link[0].scan(/media[\s]*=[\s]*"([^"]*)"/)
        # get 'all' and 'print' media, other media types are discarded
        # (all, braille, embossed, handheld, print, projection, screen, speech, tty, tv)
        if type.empty? or (type[0][0] and ((type[0][0] == 'all') or (type[0][0] == 'print')))
          type = link[0].scan(/href[\s]*=[\s]*"([^"]*)"/)
          next if type.empty?

          # read CSS data file
          uri = type[0][0].strip
          if uri =~ %r{^/}
            uri_path = Rails.root.join('public')
            uri.sub!(%r{^/}, '')
            uri.split('/').each {|path|
              uri_path = uri_path.join(path)
            }
            cssdata = ''
            next unless File.exist?(uri_path)

            open(uri_path) do |f|
              cssdata << f.read
            end
          else
            uri = URI(uri)
            next if !uri.scheme or !uri.host

            res = Net::HTTP.get_response(uri)
            cssdata = res.body
          end
          css = css.merge(extractCSSproperties(cssdata))
        end
      }
    end
    # extract style tags
    matches = html.scan(/<style([^\>]*?)>([^\<]*?)<\/style>/mi)
    unless matches.empty?
      matches.each { |media|
        type = media[0].scan(/media[\s]*=[\s]*"([^"]*)"/)
        # get 'all' and 'print' media, other media types are discarded
        # (all, braille, embossed, handheld, print, projection, screen, speech, tty, tv)
        if type.empty? or (type[0] and ((type[0] == 'all') or (type[0] == 'print')))
          cssdata = media[1]
          css = css.merge(extractCSSproperties(cssdata))
        end
      }
    end
    # remove heade and style blocks
    html.gsub!(/<head([^\>]*?)>(.*)<\/head>/mi, '')
    html.gsub!(/<style([^\>]*?)>([^\<]*?)<\/style>/mi, '')
    # remove comments
    html.gsub!(/<!--(.|\s)*?-->/m, '')

    # define block tags
    blocktags = ['blockquote','br','dd','dl','div','dt','h1','h2','h3','h4','h5','h6','hr','li','ol','p','pre','ul','table','tr','td']

    # remove all unsupported tags (the line below lists all supported tags)
    html = sanitize_html(html)

    # replace some blank characters
    html.gsub!(/<pre/, '<xre') # preserve pre tag
    html.gsub!(/<(table|tr|td|th|blockquote|dd|div|dt|h1|h2|h3|h4|h5|h6|br|hr|li|ol|ul|p)([^\>]*)>[\n\r\t]+/, '<\\1\\2>')
    html.gsub!(/@(\r\n|\r)@/, "\n")
    html.gsub!(/[\t\0\x0B]/, " ")

    offset = 0
    while (offset < html.length) and ((pos = html.index('</pre>', offset)) != nil)
      html_a = html[0, offset]
      html_b = html[offset, pos - offset + 6]
      while html_b =~ /<xre([^\>]*)>(.*?)\n(.*?)<\/pre>/mi
        # preserve newlines on <pre> tag
        html_b = html_b.gsub(/<xre([^\>]*)>(.*?)\n(.*?)<\/pre>/mi) do
          if ($2 != '') and ($3 != '')
            "<xre#{$1}>#{$2}<br />#{$3}</pre>"
          elsif ($2 == '') and ($3 != '')
            "<xre#{$1}>#{$3}</pre>"
          elsif ($2 != '') and ($3 == '')
            "<xre#{$1}>#{$2}</pre>"
          else
            "<xre#{$1}></pre>"
          end
        end
      end

      # Delete the <br />(<br>) tag located immediately after the <pre> tag.
      html_b = html_b.gsub(/<xre([^\>]*)>((?:<[^\>]+>)*)<br *\/*>/, "<xre\\1>\\2")
      # Delete the <br />(<br>) tag located immediately before the </pre> tag.
      html_b = html_b.gsub(/<br *\/*>((?:<\/[^\>]+>)*)<\/pre>/, "\\1</pre>")

      while html_b =~ /<xre([^\>]*)>(.*?)[\s](.*?)<\/pre>/mi
        # preserve whitespace on <pre> tag
        html_b = html_b.gsub(/<xre([^\>]*)>(.*?)[\s](.*?)<\/pre>/mi, "<xre\\1>\\2&nbsp;\\3</pre>")
      end
      html = html_a + html_b + html[(pos + 6)..-1]
      offset = (html_a + html_b).length
    end

    offset = 0
    while (offset < html.length) && (pos = html.index('</textarea>', offset))
      html_a = html[0, offset]
      html_b = html[offset, pos - offset + 11]
      while html_b =~ %r@<textarea([^\>]*)>(.*?)\n(.*?)</textarea>@mi
        # preserve newlines on <textarea> tag
        html_b.gsub!(%r@<textarea([^\>]*)>(.*?)\n(.*?)</textarea>@mi, "<textarea\\1>\\2<TBR>\\3</textarea>")
        html_b.gsub!(%r@<textarea([^\>]*)>(.*?)[\"](.*?)</textarea>@mi, "<textarea\\1>\\2''\\3</textarea>")
      end
      html = html_a + html_b + html[(pos + 11)..-1]
      offset = html_a.length + html_b.length
    end
    html.gsub!(/([\s]*)<option/mi, "<option")
    html.gsub!(%r@</option>([\s]*)@mi, "</option>")
    offset = 0
    while (offset < html.length) && (pos = html.index('</option>', offset))
      html_a = html[0, offset]
      html_b = html[offset, pos - offset + 9]
      while html_b =~ %r@<option([^\>]*)>(.*?)</option>@mi
        html_b.gsub!(%r@<option([\s]+)value=\"([^\"]*)\"([^\>]*)>(.*?)</option>@mi, "\\2\t\\4\r")
        html_b.gsub!(%r@<option([^\>]*)>(.*?)</option>@mi, "\\2\r")
      end
      html = html_a + html_b + html[(pos + 9)..-1]
      offset = html_a.length + html_b.length
    end
    html.gsub!(/<select([^\>]*)>/mi, "<select\\1 opt=\"")
    html.gsub!(%r@([\s]+)</select>@mi, "\" />")
    html.gsub!(/[\n]/, " ")

    # restore textarea newlines
    html.gsub!('<TBR>', "\n")

    # remove extra spaces from code
    html.gsub!(/[\s]+<\/(table|tr|td|th|ul|ol|li|dl|dt|dd)>/, '</\\1>')
    html.gsub!(/[\s]+<(tr|td|th|ul|ol|li|dl|dt|dd|br)/, '<\\1')
    html.gsub!(/<\/(table|tr|td|th|blockquote|dd|dl|div|dt|h1|h2|h3|h4|h5|h6|hr|li|ol|ul|p)>[\s]+</, '</\\1><')

    html.gsub!(/<\/(td|th)>/, '<marker style="font-size:0"/></\\1>')
    html.gsub!(/<\/table>([\s]*)<marker style="font-size:0"\/>/, '</table>')
    html.gsub!(/[\s]*<img/, ' <img')
    html.gsub!(/<img([^\>]*)>/xi, '<img\\1><span><marker style="font-size:0"/></span>')
    html.gsub!(/<xre/, '<pre') # restore pre tag
    html.gsub!(/<textarea([^\>]*)>/xi, '<textarea\\1 value="')
    html.gsub!(/<\/textarea>/, '" />')

    # trim string
    html.gsub!(/^[\s]+/, '')
    html.gsub!(/[\s]+$/, '')

    # pattern for generic tag
    tagpattern = /(<[^>]+>)/
    # explodes the string
    a = html.split(tagpattern).compact.delete_if {|x| x.empty?}
    # count elements
    maxel = a.size
    elkey = 0
    key = 0
    # create an array of elements
    dom = []
    dom[key] = {}
    # set inheritable properties fot the first void element
    # possible inheritable properties are: azimuth, border-collapse, border-spacing, caption-side, color, cursor, direction, empty-cells, font, font-family, font-stretch, font-size, font-size-adjust, font-style, font-variant, font-weight, letter-spacing, line-height, list-style, list-style-image, list-style-position, list-style-type, orphans, page, page-break-inside, quotes, speak, speak-header, text-align, text-indent, text-transform, volume, white-space, widows, word-spacing
    dom[key]['tag'] = false
    dom[key]['block'] = false
    dom[key]['value'] = ''
    dom[key]['parent'] = 0
    dom[key]['fontname'] = @font_family.dup
    dom[key]['fontstyle'] = @font_style.dup
    dom[key]['fontsize'] = @font_size_pt
    dom[key]['stroke'] = @textstrokewidth
    dom[key]['fill'] = ((@textrendermode % 2) == 0)
    dom[key]['clip'] = (@textrendermode > 3)
    dom[key]['line-height'] = @cell_height_ratio
    dom[key]['bgcolor'] = ActiveSupport::OrderedHash.new
    dom[key]['fgcolor'] = @fgcolor.dup # color
    dom[key]['strokecolor'] = @strokecolor.dup

    dom[key]['align'] = ''
    dom[key]['listtype'] = ''
    dom[key]['text-indent'] = 0
    dom[key]['attribute'] = {} # reset attribute array
    thead = false # true when we are inside the THEAD tag
    key += 1
    level = []
    level.push(0) # root
    while elkey < maxel
      dom[key] = {}
      element = a[elkey]
      dom[key]['elkey'] = elkey
      if element =~ tagpattern
        # html tag
        element = element[1..-2]
        # get tag name
        tag = element.scan(/[\/]?([a-zA-Z0-9]*)/).flatten.delete_if {|x| x.length == 0}
        tagname = tag[0].downcase
        # check if we are inside a table header
        if tagname == 'thead'
          if element[0,1] == '/'
            thead = false
          else
            thead = true
          end
          elkey += 1
          next
        end
        dom[key]['tag'] = true
        dom[key]['value'] = tagname
        if blocktags.include?(dom[key]['value'])
          dom[key]['block'] = true
        else
          dom[key]['block'] = false
        end
        if element[0,1] == '/'
          # *** closing html tag
          dom[key]['opening'] = false
          dom[key]['parent'] = level[-1]
          level.pop if level.length > 1

          grandparent = dom[(dom[key]['parent'])]['parent']
          dom[key]['fontname'] = dom[grandparent]['fontname'].dup
          dom[key]['fontstyle'] = dom[grandparent]['fontstyle'].dup
          dom[key]['fontsize'] = dom[grandparent]['fontsize']
          dom[key]['stroke'] = dom[grandparent]['stroke']
          dom[key]['fill'] = dom[grandparent]['fill']
          dom[key]['clip'] = dom[grandparent]['clip']
          dom[key]['line-height'] = dom[grandparent]['line-height']
          dom[key]['bgcolor'] = dom[grandparent]['bgcolor'].dup
          dom[key]['fgcolor'] = dom[grandparent]['fgcolor'].dup
          dom[key]['strokecolor'] = dom[grandparent]['strokecolor'].dup
          dom[key]['align'] = dom[grandparent]['align'].dup
          if !dom[grandparent]['listtype'].nil?
            dom[key]['listtype'] = dom[grandparent]['listtype'].dup
          end
          # set the number of columns in table tag
          if (dom[key]['value'] == 'tr') and dom[grandparent]['cols'].nil?
            dom[grandparent]['cols'] = dom[(dom[key]['parent'])]['cols']
          end
          if (dom[key]['value'] == 'td') or (dom[key]['value'] == 'th')
            dom[(dom[key]['parent'])]['content'] = ''
            (dom[key]['parent'] + 1).upto(key - 1) do |i|
              dom[(dom[key]['parent'])]['content'] << a[dom[i]['elkey']]
            end
            # mark nested tables
            dom[(dom[key]['parent'])]['content'] = dom[(dom[key]['parent'])]['content'].gsub('<table', '<table nested="true"')
            # remove thead sections from nested tables
            dom[(dom[key]['parent'])]['content'] = dom[(dom[key]['parent'])]['content'].gsub('<thead>', '')
            dom[(dom[key]['parent'])]['content'] = dom[(dom[key]['parent'])]['content'].gsub('</thead>', '')
          end
          # store header rows on a new table
          if (dom[key]['value'] == 'tr') and (dom[(dom[key]['parent'])]['thead'] == true)
            if empty_string(dom[grandparent]['thead'])
              if dom[grandparent]['attribute'].nil? or dom[grandparent]['attribute']['style'].nil?
                dom[grandparent]['thead'] = a[dom[grandparent]['elkey']].dup
              else
                dom[grandparent]['thead'] = '<style>' + dom[grandparent]['value'] + ' {' + dom[grandparent]['attribute']['style'] + '}</style>' + a[dom[grandparent]['elkey']].dup
              end
            end
            dom[key]['parent'].upto(key) do |i|
              dom[grandparent]['thead'] << a[dom[i]['elkey']]
            end
            if dom[(dom[key]['parent'])]['attribute'].nil?
              dom[(dom[key]['parent'])]['attribute'] = {}
            end
            # header elements must be always contained in a single page
            dom[(dom[key]['parent'])]['attribute']['nobr'] = 'true'
          end
          if (dom[key]['value'] == 'table') and !empty_string(dom[(dom[key]['parent'])]['thead'])
            # remove the nobr attributes from the table header
            dom[(dom[key]['parent'])]['thead'] = dom[(dom[key]['parent'])]['thead'].gsub(' nobr="true"', '').sub(/<table([ >])/, '<table tablehead="1"\1')
            dom[(dom[key]['parent'])]['thead'] << '</table>'
          end
        else
          # *** opening html tag
          dom[key]['opening'] = true
          dom[key]['parent'] = level[-1]
          if element[-1, 1] == '/' or (dom[key]['value'] =~ /(br|img|hr|input)/)
            # self-closing tag
            dom[key]['self'] = true
          else
            level.push(key)
            dom[key]['self'] = false
          end
          # copy some values from parent
          parentkey = 0
          if key > 0
            parentkey = dom[key]['parent']
            dom[key]['fontname'] = dom[parentkey]['fontname'].dup
            dom[key]['fontstyle'] = dom[parentkey]['fontstyle'].dup
            dom[key]['fontsize'] = dom[parentkey]['fontsize']
            dom[key]['stroke'] = dom[parentkey]['stroke']
            dom[key]['fill'] = dom[parentkey]['fill']
            dom[key]['clip'] = dom[parentkey]['clip']
            dom[key]['line-height'] = dom[parentkey]['line-height']
            dom[key]['bgcolor'] = dom[parentkey]['bgcolor'].dup
            dom[key]['fgcolor'] = dom[parentkey]['fgcolor'].dup
            dom[key]['strokecolor'] = dom[parentkey]['strokecolor'].dup
            dom[key]['align'] = dom[parentkey]['align'].dup
            dom[key]['listtype'] = dom[parentkey]['listtype'].dup
            dom[key]['text-indent'] = dom[parentkey]['text-indent']
          end
          # get attributes
          attr_array = element.scan(/([^=\s]+)[\s]*(?:=[\s]*"([^"]*)")*/)[1..-1]
          dom[key]['attribute'] = {} # reset attribute array
          attr_array.each do |name, value|
            dom[key]['attribute'][name.downcase] = value
          end
          if !css.empty?
            # merge eternal CSS style to current style
            dom[key]['attribute']['style'] = getTagStyleFromCSS(dom, key, css)
          end
          # split style attributes
          if !dom[key]['attribute']['style'].nil?
            # get style attributes
            style_array = dom[key]['attribute']['style'].scan(/([^;:\s]*):([^;]*)/)
            dom[key]['style'] = {} # reset style attribute array
            style_array.each do |name, value|
              # in case of duplicate attribute the last replace the previous
              dom[key]['style'][name.downcase] = value.strip
            end
            # --- get some style attributes ---
            if !dom[key]['style']['font-family'].nil?
              # font family
              if !dom[key]['style']['font-family'].nil?
                fontslist = dom[key]['style']['font-family'].downcase.split(',')
                fontslist.each {|font|
                  font = font.downcase.strip
                  if @fontlist.include?(font) or @fontkeys.include?(font)
                    dom[key]['fontname'] = font
                    break
                  end
                }
              end
            end
            # list-style-type
            if !dom[key]['style']['list-style-type'].nil?
              dom[key]['listtype'] = dom[key]['style']['list-style-type'].downcase.strip
              if dom[key]['listtype'] == 'inherit'
                dom[key]['listtype'] = dom[parentkey]['listtype']
              end
            end
            # text-indent
            if dom[key]['style']['text-indent']
              dom[key]['text-indent'] = getHTMLUnitToUnits(dom[key]['style']['text-indent'])
              if dom[key]['text-indent'] == 'inherit'
                dom[key]['text-indent'] = dom[parentkey]['text-indent']
              end
            end
            # font size
            if !dom[key]['style']['font-size'].nil?
              fsize = dom[key]['style']['font-size'].strip
              case fsize
                # absolute-size
              when 'xx-small'
                dom[key]['fontsize'] = dom[0]['fontsize'] - 4
              when 'x-small'
                dom[key]['fontsize'] = dom[0]['fontsize'] - 3
              when 'small'
                dom[key]['fontsize'] = dom[0]['fontsize'] - 2
              when 'medium'
                dom[key]['fontsize'] = dom[0]['fontsize']
              when 'large'
                dom[key]['fontsize'] = dom[0]['fontsize'] + 2
              when 'x-large'
                dom[key]['fontsize'] = dom[0]['fontsize'] + 4
              when 'xx-large'
                dom[key]['fontsize'] = dom[0]['fontsize'] + 6
                # relative-size
              when 'smaller'
                dom[key]['fontsize'] = dom[parentkey]['fontsize'] - 3
              when 'larger'
                dom[key]['fontsize'] = dom[parentkey]['fontsize'] + 3
              else
                dom[key]['fontsize'] = getHTMLUnitToUnits(fsize, dom[parentkey]['fontsize'], 'pt', true)
              end
            end
            # line-height
            if dom[key]['style']['line-height']
              lineheight = dom[key]['style']['line-height'].strip
              case lineheight
                # A normal line height. This is default
              when 'normal'
                dom[key]['line-height'] = dom[0]['line-height']
              else
                if lineheight =~ /^[\d]*[.]?[\d]+$/  # 1.2, .2, 0.33, etc..
                  lineheight = lineheight.to_f * 100
                end

                dom[key]['line-height'] = getHTMLUnitToUnits(lineheight, 1, '%', true)
              end
            end
            # font style
            dom[key]['fontstyle'] ||= ""
            if !dom[key]['style']['font-weight'].nil? and (dom[key]['style']['font-weight'][0,1].downcase == 'b')
              dom[key]['fontstyle'] << 'B'
            end
            if !dom[key]['style']['font-style'].nil? and (dom[key]['style']['font-style'][0,1].downcase == 'i')
              dom[key]['fontstyle'] << 'I'
            end
            # font color
            if !empty_string(dom[key]['style']['color'])
              dom[key]['fgcolor'] = convertHTMLColorToDec(dom[key]['style']['color'])
            elsif dom[key]['value'] == 'a'
              dom[key]['fgcolor'] = @html_link_color_array
            end
            # background color
            if !empty_string(dom[key]['style']['background-color'])
              dom[key]['bgcolor'] = convertHTMLColorToDec(dom[key]['style']['background-color'])
            end
            # text-decoration
            if !dom[key]['style']['text-decoration'].nil?
              decors = dom[key]['style']['text-decoration'].downcase.split(' ')
              decors.each {|dec|
                dec = dec.strip
                unless empty_string(dec)
                  if dec[0,1] == 'u'
                    # underline
                    dom[key]['fontstyle'] << 'U'
                  elsif dec[0,1] == 'l'
                    # line-trough
                    dom[key]['fontstyle'] << 'D'
                  elsif dec[0,1] == 'o'
                    # overline
                    dom[key]['fontstyle'] << 'O'
                  end
                end
              }
            elsif dom[key]['value'] == 'a'
              dom[key]['fontstyle'] = @html_link_font_style
            end
            # check for width attribute
            if !dom[key]['style']['width'].nil?
              dom[key]['width'] = dom[key]['style']['width']
            end
            # check for height attribute
            if !dom[key]['style']['height'].nil?
              dom[key]['height'] = dom[key]['style']['height']
            end
            # check for text alignment
            if !dom[key]['style']['text-align'].nil?
              dom[key]['align'] = dom[key]['style']['text-align'][0,1].upcase
            end
            # check for border attribute
            if !dom[key]['style']['border'].nil?
              dom[key]['attribute']['border'] = dom[key]['style']['border']
            end

            # page-break-inside
            if dom[key]['style']['page-break-inside'] and (dom[key]['style']['page-break-inside'] == 'avoid')
              dom[key]['attribute']['nobr'] = 'true'
            end
            # page-break-before
            if dom[key]['style']['page-break-before']
              if dom[key]['style']['page-break-before'] == 'always'
                dom[key]['attribute']['pagebreak'] = 'true'
              elsif dom[key]['style']['page-break-before'] == 'left'
                dom[key]['attribute']['pagebreak'] = 'left'
              elsif dom[key]['style']['page-break-before'] == 'right'
                dom[key]['attribute']['pagebreak'] = 'right'
              end
            end
            # page-break-after
            if dom[key]['style']['page-break-after']
              if dom[key]['style']['page-break-after'] == 'always'
                dom[key]['attribute']['pagebreakafter'] = 'true'
              elsif dom[key]['style']['page-break-after'] == 'left'
                dom[key]['attribute']['pagebreakafter'] = 'left'
              elsif dom[key]['style']['page-break-after'] == 'right'
                dom[key]['attribute']['pagebreakafter'] = 'right'
              end
            end
          end
          # check for font tag
          if dom[key]['value'] == 'font'
            # font family
            if !dom[key]['attribute']['face'].nil?
              fontslist = dom[key]['attribute']['face'].downcase.split(',')
              fontslist.each { |font|
                font = font.downcase.strip
                if @fontlist.include?(font) or @fontkeys.include?(font)
                  dom[key]['fontname'] = font
                  break
                end
              }
            end
            # font size
            if !dom[key]['attribute']['size'].nil?
              if key > 0
                if dom[key]['attribute']['size'][0,1] == '+'
                  dom[key]['fontsize'] = dom[(dom[key]['parent'])]['fontsize'] + dom[key]['attribute']['size'][1..-1].to_i
                elsif dom[key]['attribute']['size'][0,1] == '-'
                  dom[key]['fontsize'] = dom[(dom[key]['parent'])]['fontsize'] - dom[key]['attribute']['size'][1..-1].to_i
                else
                  dom[key]['fontsize'] = dom[key]['attribute']['size'].to_i
                end
              else
                dom[key]['fontsize'] = dom[key]['attribute']['size'].to_i
              end
            end
          end
          # force natural alignment for lists
          if (dom[key]['value'] == 'ul') or (dom[key]['value'] == 'ol') or (dom[key]['value'] == 'dl') and (empty_string(dom[key]['align']) or (dom[key]['align'] != 'J'))
            if @rtl
              dom[key]['align'] = 'R'
            else
              dom[key]['align'] = 'L'
            end
          end
          if (dom[key]['value'] == 'small') or (dom[key]['value'] == 'sup') or (dom[key]['value'] == 'sub')
            if dom[key]['attribute']['size'].nil? and (dom[key]['style'].nil? or dom[key]['style']['font-size'].nil?)
              dom[key]['fontsize'] = dom[key]['fontsize'] * @@k_small_ratio
            end
          end
          if (dom[key]['value'] == 'strong') or (dom[key]['value'] == 'b')
            dom[key]['fontstyle'] << 'B'
          end
          if (dom[key]['value'] == 'em') or (dom[key]['value'] == 'i')
            dom[key]['fontstyle'] << 'I'
          end
          if dom[key]['value'] == 'u' or dom[key]['value'] == 'ins'
            dom[key]['fontstyle'] << 'U'
          end
          if dom[key]['value'] == 'del'
            dom[key]['fontstyle'] << 'D'
          end
          if (dom[key]['style'].nil? or dom[key]['style']['text-decoration'].nil?) and (dom[key]['value'] == 'a')
            dom[key]['fontstyle'] = @html_link_font_style
          end
          if (dom[key]['value'] == 'pre') or (dom[key]['value'] == 'tt')
            dom[key]['fontname'] = @default_monospaced_font
          end
          if (dom[key]['value'][0,1] == 'h') and (dom[key]['value'][1,1].to_i > 0) and (dom[key]['value'][1,1].to_i < 7)
            # headings h1, h2, h3, h4, h5, h6
            if dom[key]['attribute']['size'].nil? and (dom[key]['style'].nil? or dom[key]['style']['font-size'].nil?)
              headsize = (4 - dom[key]['value'][1,1].to_i) * 2
              dom[key]['fontsize'] = dom[0]['fontsize'] + headsize
            end
            if dom[key]['style'].nil? or dom[key]['style']['font-weight'].nil?
              dom[key]['fontstyle'] << 'B'
            end
          end
          if dom[key]['value'] == 'table'
            dom[key]['rows'] = 0 # number of rows
            dom[key]['trids'] = [] # IDs of TR elements
            dom[key]['thead'] = '' # table header rows
          end
          if dom[key]['value'] == 'tr'
            dom[key]['cols'] = 0
            if thead
              dom[key]['thead'] = true
              # rows on thead block are printed as a separate table
            else
              dom[key]['thead'] = false
              # store the number of rows on table element
              dom[(dom[key]['parent'])]['rows'] += 1
              # store the TR elements IDs on table element
              dom[(dom[key]['parent'])]['trids'].push(key)
            end
          end
          if (dom[key]['value'] == 'th') or (dom[key]['value'] == 'td')
            if !dom[key]['attribute']['colspan'].nil?
              colspan = dom[key]['attribute']['colspan'].to_i
            else
              colspan = 1
            end
            dom[key]['attribute']['colspan'] = colspan
            dom[(dom[key]['parent'])]['cols'] += colspan
          end
          # set foreground color attribute
          if !empty_string(dom[key]['attribute']['color'])
            dom[key]['fgcolor'] = convertHTMLColorToDec(dom[key]['attribute']['color'])
          elsif (dom[key]['style'].nil? or dom[key]['style']['color'].nil?) and (dom[key]['value'] == 'a')
            dom[key]['fgcolor'] = @html_link_color_array
          end
          # set background color attribute
          if !empty_string(dom[key]['attribute']['bgcolor'])
            dom[key]['bgcolor'] = convertHTMLColorToDec(dom[key]['attribute']['bgcolor'])
          end
          # set stroke color attribute
          if !empty_string(dom[key]['attribute']['strokecolor'])
            dom[key]['strokecolor'] = convertHTMLColorToDec(dom[key]['attribute']['strokecolor'])
          end
          # check for width attribute
          if !dom[key]['attribute']['width'].nil?
            dom[key]['width'] = dom[key]['attribute']['width']
          end
          # check for height attribute
          if !dom[key]['attribute']['height'].nil?
            dom[key]['height'] = dom[key]['attribute']['height']
          end
          # check for text alignment
          if !empty_string(dom[key]['attribute']['align']) and (dom[key]['value'] != 'img')
            dom[key]['align'] = dom[key]['attribute']['align'][0,1].upcase
          end
          # check for text rendering mode (the following attributes do not exist in HTML)
          if !dom[key]['attribute']['stroke'].nil?
            # font stroke width
            dom[key]['stroke'] = getHTMLUnitToUnits(dom[key]['attribute']['stroke'], dom[key]['fontsize'], 'pt', true)
          end
          if !dom[key]['attribute']['fill'].nil?
            # font fill
            if dom[key]['attribute']['fill'] == 'true'
              dom[key]['fill'] = true
            else
              dom[key]['fill'] = false
            end
          end
          if !dom[key]['attribute']['clip'].nil?
            # clipping mode
            if dom[key]['attribute']['clip'] == 'true'
              dom[key]['clip'] = true
            else
              dom[key]['clip'] = false
            end
          end
        end # end opening tag
      else
        # text
        dom[key]['tag'] = false
        dom[key]['block'] = false
        dom[key]['value'] = unhtmlentities(element)
        dom[key]['parent'] = level[-1]
      end
      elkey += 1
      key += 1
    end
    return dom
  end

  #
  # Convert to accessible file path
  # [@param string :attrname] image file name
  #
  def get_image_filename( attrname )
    attrname_escape = File.join(File.dirname(attrname),  ERB::Util.url_encode(File.basename(attrname)))
    testscrtype = URI.parse(attrname_escape)
    if testscrtype.query.nil? or testscrtype.query.empty?
      # convert URL to server path
      attrname = attrname.gsub(@@k_path_url, @@k_path_main)
    end
  end

  #
  # Get image file from remote URL
  # [@param string :image_uri] image URI path
  #
  def get_image_file(image_uri)
    image_uri = File.join(File.dirname(image_uri),  ERB::Util.url_encode(File.basename(image_uri)))
    uri = URI.parse(image_uri)
    extname = File.extname(uri.path)

    #use a temporary file....
    tmpFile = Tempfile.new(['tmp_', extname], @@k_path_cache)
    tmpFile.binmode
    Net::HTTP.start(uri.host, uri.port) do |http|
      res = http.get(uri.path)
      tmpFile.print res.body
    end
    tmpFile.fsync
    tmpFile
  end

  #
  # Convert to accessible url path
  # [@param string :url] url path
  #
  def get_sever_url(url)
    if !empty_string(url) and (url[0, 1] == '/')
      ''
    else
      url
    end
  end

  #
  # Returns the string used to find spaces
  # [@return string]
  # [@access protected]
  # [@author] Nicola Asuni
  # [@since 4.8.024 (2010-01-15)]
  #
  def getSpaceString()
    spacestr = 32.chr
    if (@current_font['type'] == 'TrueTypeUnicode') or (@current_font['type'] == 'cidfont0')
      spacestr = 0.chr + 32.chr
    end
    return spacestr
  end

public

  #
  # Prints a cell (rectangular area) with optional borders, background color and html text string. The upper-left corner of the cell corresponds to the current position. After the call, the current position moves to the right or to the next line.
  # If automatic page breaking is enabled and the cell goes beyond the limit, a page break is done before outputting.
  # [@param float :w] Cell width. If 0, the cell extends up to the right margin.
  # [@param float :h] Cell minimum height. The cell extends automatically if needed.
  # [@param float :x] upper-left corner X coordinate
  # [@param float :y] upper-left corner Y coordinate
  # [@param string :html] html text to print. Default value: empty string.
  # [@param mixed :border]
  #   Indicates if borders must be drawn around the cell. The value can be either a number:
  #   * 0: no border (default)
  #   * 1: frame
  #   or a string containing some or all of the following characters (in any order):
  #   * L: left
  #   * T: top
  #   * R: right
  #   * B: bottom
  # [@param int :ln]
  #   Indicates where the current position should go after the call. Possible values are:
  #   * 0: to the right (or left for RTL language)
  #   * 1: to the beginning of the next line
  #   * 2: below
  #   Putting 1 is equivalent to putting 0 and calling Ln() just after. Default value: 0.
  # [@param int :fill] Indicates if the cell background must be painted (1) or transparent (0). Default value: 0.
  # [@param boolean :reseth] if true reset the last cell height (default true).
  # [@param string :align]
  #   Allows to center or align the text. Possible values are:
  #   * L : left align
  #   * C : center
  #   * R : right align
  #   * '' : empty string : left for LTR or right for RTL
  # [@param boolean :autopadding] if true, uses internal padding and automatically adjust it to account for line width.
  # [@access public]
  # [@uses] MultiCell()
  # [@see] Multicell(), writeHTML(), Cell()
  #
  def writeHTMLCell(w, h, x, y, html='', border=0, ln=0, fill=0, reseth=true, align='', autopadding=true)
    rtn = MultiCell(w, h, html, border, align, fill, ln, x, y, reseth, 0, true, autopadding, 0)
    return rtn
  rescue => err
    Error('writeHTMLCell Error.', err)
  end
  alias_method :write_html_cell, :writeHTMLCell

  def sanitize_html(html)
    # Escape '<' character for not tag case.
    html = html.gsub(%r{(<+)([^/a-zA-Z])}){CGI.escapeHTML($1) + $2}.gsub(%r{</([^a-zA-Z])}){'&lt;/' +  $1}
    "%s" % sanitize(html,
            :tags=> %w(a b blockquote body br dd del div dl dt em font form h1 h2 h3 h4 h5 h6 hr i img input label li ol option p pre select small span strong sub sup table td textarea th thead tr tt u ins ul),
            :attributes => %w(cellspacing cellpadding bgcolor color value width height src size colspan rowspan style align border face href name dir class id nobr stroke strokecolor fill nested tablehead cols rows type action enctype method maxlength onclick multiple checked disabled))
  end
  protected :sanitize_html

  #
  # Allows to preserve some HTML formatting (limited support).
  # IMPORTANT: The HTML must be well formatted - try to clean-up it using an application like HTML-Tidy before submitting.
  # Supported tags are: a, b, blockquote, br, dd, del, div, dl, dt, em, font, h1, h2, h3, h4, h5, h6, hr, i, img, li, ol, p, pre, small, span, strong, sub, sup, table, td, th, thead, tr, tt, u, ul
  # [@param string :html] text to display
  # [@param boolean :ln] if true add a new line after text (default = true)
  # [@param int :fill] Indicates if the background must be painted (1:true) or transparent (0:false).
  # [@param boolean :reseth] if true reset the last cell height (default false).
  # [@param boolean :cell] if true add the default c_margin space to each Write (default false).
  # [@param string :align]
  #   Allows to center or align the text. Possible values are:
  #   * L : left align
  #   * C : center
  #   * R : right align
  #   * '' : empty string : left for LTR or right for RTL
  # [@access public]
  #
  def writeHTML(html, ln=true, fill=0, reseth=false, cell=false, align='')
    ln = false if ln == 0
    reseth = false if reseth == 0
    cell = false if cell == 0
    case fill
    when true
      fill = 1
    when false
      fill = 0
    end

    gvars = getGraphicVars()
    # store current values
    prevPage = @page
    prevlMargin = @l_margin
    prevrMargin = @r_margin
    curfontname = @font_family
    curfontstyle = @font_style
    curfontsize = @font_size_pt
    curfontascent = getFontAscent(curfontname, curfontstyle, curfontsize)
    curfontdescent = getFontDescent(curfontname, curfontstyle, curfontsize)
    @newline = true
    startlinepage = @page
    minstartliney = @y
    maxbottomliney = 0
    startlinex = @x
    startliney = @y
    yshift = 0
    newline = true
    loop = 0
    curpos = 0
    opentagpos = nil
    this_method_vars = {}
    undo = false
    fontaligned = false
    @premode = false
    if !@page_annots[@page].nil?
      pask = @page_annots[@page].length
    else
      pask = 0
    end
    if !@in_footer
      if !@footerlen[@page].nil?
        @footerpos[@page] = @pagelen[@page] - @footerlen[@page]
      else
        @footerpos[@page] = @pagelen[@page]
      end
      startlinepos = @footerpos[@page]
    else
      startlinepos = @pagelen[@page]
    end
    lalign = align
    plalign = align
    if @rtl
      w = @x - @l_margin
    else
      w = @w - @r_margin - @x
    end
    w -= 2 * @c_margin

    if cell
      if @rtl
        @x -= @c_margin
      else
        @x += @c_margin
      end
    end
    if @customlistindent >= 0
      @listindent = @customlistindent
    else
      @listindent = GetStringWidth('0000')
    end
    @listindentlevel = 0
    # save previous states
    prev_cell_height_ratio = @cell_height_ratio
    prev_listnum = @listnum
    prev_listordered = @listordered
    prev_listcount = @listcount
    prev_lispacer = @lispacer
    prev_li_position_x = @li_position_x
    @listnum = 0
    @listordered = []
    @listcount = []
    @lispacer = ''
    if empty_string(@lasth) or reseth
      #set row height
      @lasth = @font_size * @cell_height_ratio
    end
    dom = getHtmlDomArray(html)
    maxel = dom.size
    key = 0
    while key < maxel
      if dom[key]['tag'] and dom[key]['attribute'] and dom[key]['attribute']['pagebreak']
        # check for pagebreak
        if (dom[key]['attribute']['pagebreak'] == 'true') or (dom[key]['attribute']['pagebreak'] == 'left') or (dom[key]['attribute']['pagebreak'] == 'right')
          # add a page (or trig AcceptPageBreak() for multicolumn mode)
          checkPageBreak(@page_break_trigger + 1)
        end
        if ((dom[key]['attribute']['pagebreak'] == 'left') and ((!@rtl and (@page % 2 == 0)) or (@rtl and (@page % 2 != 0)))) or ((dom[key]['attribute']['pagebreak'] == 'right') and ((!@rtl and (@page % 2 != 0)) or (@rtl and (@page % 2 == 0))))
          # add a page (or trig AcceptPageBreak() for multicolumn mode)
          checkPageBreak(@page_break_trigger + 1)
        end
      end
      if dom[key]['tag'] and dom[key]['opening'] and dom[key]['attribute']['nobr'] and (dom[key]['attribute']['nobr'] == 'true')
        if dom[(dom[key]['parent'])]['attribute']['nobr'] and (dom[(dom[key]['parent'])]['attribute']['nobr'] == 'true')
          dom[key]['attribute']['nobr'] = false
        else
          # store current object
          startTransaction()
          # save this method vars
          this_method_vars['html'] = html.dup
          this_method_vars['ln'] = ln
          this_method_vars['fill'] = fill
          this_method_vars['reseth'] = reseth
          this_method_vars['cell'] = cell
          this_method_vars['align'] = align.dup
          this_method_vars['gvars'] = Marshal.load(Marshal.dump(gvars))
          this_method_vars['prevPage'] = prevPage
          this_method_vars['prevlMargin'] = prevlMargin
          this_method_vars['prevrMargin'] = prevrMargin
          this_method_vars['curfontname'] = curfontname.dup
          this_method_vars['curfontstyle'] = curfontstyle.dup
          this_method_vars['curfontsize'] = curfontsize
          this_method_vars['curfontascent'] = curfontascent
          this_method_vars['curfontdescent'] = curfontdescent
          this_method_vars['minstartliney'] = minstartliney
          this_method_vars['maxbottomliney'] = maxbottomliney
          this_method_vars['yshift'] = yshift
          this_method_vars['startlinepage'] = startlinepage
          this_method_vars['startlinepos'] = startlinepos
          this_method_vars['startlinex'] = startlinex
          this_method_vars['startliney'] = startliney
          this_method_vars['newline'] = newline
          this_method_vars['loop'] = loop
          this_method_vars['curpos'] = curpos
          this_method_vars['pask'] = pask
          this_method_vars['lalign'] = lalign
          this_method_vars['plalign'] = plalign
          this_method_vars['w'] = w
          this_method_vars['prev_cell_height_ratio'] = prev_cell_height_ratio
          this_method_vars['prev_listnum'] = prev_listnum
          this_method_vars['prev_listordered'] = prev_listordered
          this_method_vars['prev_listcount'] = prev_listcount
          this_method_vars['prev_lispacer'] = prev_lispacer
          this_method_vars['fontaligned'] = fontaligned
          this_method_vars['key'] = key
          this_method_vars['dom'] = Marshal.load(Marshal.dump(dom))
        end
      end
      # print THEAD block
      if (dom[key]['value'] == 'tr') and dom[key]['thead'] and dom[key]['thead']
        if dom[key]['parent'] and dom[(dom[key]['parent'])]['thead'] and !empty_string(dom[(dom[key]['parent'])]['thead'])
          @in_thead = true

          prev_lMargin = @l_margin
          prev_rMargin = @r_margin
          @l_margin = @thead_margins['lmargin']
          @r_margin = @thead_margins['rmargin']

          # print table header (thead)
          writeHTML(@thead, false, false, false, false, '')

          @l_margin = prev_lMargin
          @r_margin = prev_rMargin

          if (@start_transaction_page == (@numpages - 1)) or (@y < @start_transaction_y) or checkPageBreak(@lasth, '', false)
            # restore previous object
            rollbackTransaction(true)
            # restore previous values
            this_method_vars.each {|vkey , vval|
              eval("#{vkey} = vval")
            }
            # add a page (or trig AcceptPageBreak() for multicolumn mode)
            pre_y = @y
            if !checkPageBreak(@page_break_trigger + 1) and (@y < pre_y)
              # fix for multicolumn mode
              startliney = @y
            end
            @start_transaction_page = @page
            @start_transaction_y = @y
          end
        end
        # move :key index forward to skip THEAD block
        while (key < maxel) and !((dom[key]['tag'] and dom[key]['opening'] and (dom[key]['value'] == 'tr') and (dom[key]['thead'].nil? or !dom[key]['thead'])) or (dom[key]['tag'] and !dom[key]['opening'] and (dom[key]['value'] == 'table')))
          key += 1
        end
      end
      if dom[key]['tag'] or (key == 0)
        if dom[key]['line-height']
          # set line height
          @cell_height_ratio = dom[key]['line-height']
          @lasth = @font_size * @cell_height_ratio
        end
        if ((dom[key]['value'] == 'table') or (dom[key]['value'] == 'tr')) and !dom[key]['align'].nil?
          dom[key]['align'] = @rtl ? 'R' : 'L'
        end
        # vertically align image in line
        if !@newline and (dom[key]['value'] == 'img') and dom[key]['height'] and (dom[key]['height'].to_i > 0)
          # get image height
          imgh = getHTMLUnitToUnits(dom[key]['height'], @lasth, 'px')
          # check for automatic line break
          autolinebreak = false
          if dom[key]['width'] and (dom[key]['width'].to_i > 0)
            imgw = getHTMLUnitToUnits(dom[key]['width'], 1, 'px', false)
            if (@rtl and (@x - imgw < @l_margin + @c_margin)) or (!@rtl and (@x + imgw > @w - @r_margin - @c_margin))
              # add automatic line break
              autolinebreak = true
              Ln('', cell)
              # go back to evaluate this line break
              key -= 1
            end
          end
          if !autolinebreak
            if !@in_footer
              pre_y = @y
              # check for page break
              if !checkPageBreak(imgh) and (@y < pre_y)
                # fix for multicolumn mode
                startliney = @y
              end
            end
            if @page > startlinepage
              # fix line splitted over two pages
              if !@footerlen[startlinepage].nil?
                curpos = @pagelen[startlinepage] - @footerlen[startlinepage]
              end
              # line to be moved one page forward
              pagebuff = getPageBuffer(startlinepage)
              linebeg = pagebuff[startlinepos, curpos - startlinepos]
              tstart = pagebuff[0, startlinepos]
              tend = pagebuff[curpos..-1]
              # remove line from previous page
              setPageBuffer(startlinepage, tstart + '' + tend)
              pagebuff = getPageBuffer(@page)
              tstart = pagebuff[0, @cntmrk[@page]]
              tend = pagebuff[@cntmrk[@page]..-1]
              # add line start to current page
              yshift = minstartliney - @y
              if fontaligned
                yshift += curfontsize / @k
              end
              try = sprintf('1 0 0 1 0 %.3f cm', (yshift * @k))
              setPageBuffer(@page, tstart + "\nq\n" + try + "\n" + linebeg + "\nQ\n" + tend)
              # shift the annotations and links
              if @page_annots[@page]
                next_pask = @page_annots[@page].length
              else
                next_pask = 0
              end
              if !@page_annots[startlinepage].nil?
                @page_annots[startlinepage].each_with_index { |pac, pak|
                  if pak >= pask
                    @page_annots[@page].push pac
                    @page_annots[startlinepage].delete_at(pak)
                    npak = @page_annots[@page].length - 1
                    @page_annots[@page][npak]['y'] -= yshift
                  end
                }
              end
              pask = next_pask
              startlinepos = @cntmrk[@page]
              startlinepage = @page
              startliney = @y
            end
            @y += ((curfontsize * @cell_height_ratio / @k) + curfontascent - curfontdescent) / 2.0  - imgh
            minstartliney = [@y, minstartliney].min
            maxbottomliney = startliney + @font_size * @cell_height_ratio
          end
        elsif !dom[key]['fontname'].nil? or !dom[key]['fontstyle'].nil? or !dom[key]['fontsize'].nil?
          # account for different font size
          pfontname = curfontname
          pfontstyle = curfontstyle
          pfontsize = curfontsize
          fontname  = !dom[key]['fontname'].nil?  ? dom[key]['fontname']  : curfontname
          fontstyle = !dom[key]['fontstyle'].nil? ? dom[key]['fontstyle'] : curfontstyle
          fontsize  = !dom[key]['fontsize'].nil?  ? dom[key]['fontsize']  : curfontsize
          fontascent = getFontAscent(fontname, fontstyle, fontsize)
          fontdescent = getFontDescent(fontname, fontstyle, fontsize)
          if (fontname != curfontname) or (fontstyle != curfontstyle) or (fontsize != curfontsize)
            if fontsize.is_a?(Numeric) and (fontsize >= 0) and curfontsize.is_a?(Numeric) and (curfontsize >= 0) and (fontsize != curfontsize) and !@newline and (key < maxel - 1)
              if !@newline and (@page > startlinepage)
                # fix lines splitted over two pages
                if !@footerlen[startlinepage].nil?
                  curpos = @pagelen[startlinepage] - @footerlen[startlinepage]
                end
                # line to be moved one page forward
                pagebuff = getPageBuffer(startlinepage)
                linebeg = pagebuff[startlinepos, curpos - startlinepos]
                tstart = pagebuff[0, startlinepos]
                tend = pagebuff[curpos..-1]
                # remove line from previous page
                setPageBuffer(startlinepage, tstart + '' + tend)
                pagebuff = getPageBuffer(@page)
                tstart = pagebuff[0, @cntmrk[@page]]
                tend = pagebuff[@cntmrk[@page]..-1]
                # add line start to current page
                yshift = minstartliney - @y
                try = sprintf('1 0 0 1 0 %.3f cm', yshift * @k)
                setPageBuffer(@page, tstart + "\nq\n" + try + "\n" + linebeg + "\nQ\n" + tend)
                # shift the annotations and links
                if @page_annots[@page]
                  next_pask = @page_annots[@page].length
                else
                  next_pask = 0
                end
                if !@page_annots[startlinepage].nil?
                  @page_annots[startlinepage].each_with_index { |pac, pak|
                    if pak >= pask
                      @page_annots[@page].push = pac
                      @page_annots[startlinepage].delete_at(pak)
                      npak = @page_annots[@page].length - 1
                      @page_annots[@page][npak]['y'] -= yshift
                    end
                  }
                end
                pask = next_pask
                startlinepos = @cntmrk[@page]
                startlinepage = @page
                startliney = @y
              end
              if !dom[key]['block']
                @y += (((curfontsize - fontsize) * @cell_height_ratio / @k) + curfontascent - fontascent - curfontdescent + fontdescent) / 2.0
                if (dom[key]['value'] != 'sup') and (dom[key]['value'] != 'sub')
                  minstartliney = [@y, minstartliney].min
                  maxbottomliney = [@y + ((fontsize * @cell_height_ratio) / @k), maxbottomliney].max
                end
              end
              fontaligned = true
            end
            SetFont(fontname, fontstyle, fontsize)
            @lasth = @font_size * @cell_height_ratio
            curfontname = fontname
            curfontstyle = fontstyle
            curfontsize = fontsize
            curfontascent = fontascent
            curfontdescent = fontdescent
          end
        end
        # set text rendering mode
        textstroke = !dom[key]['stroke'].nil? ? dom[key]['stroke'] : @textstrokewidth
        textfill = !dom[key]['fill'].nil? ? dom[key]['fill'] : ((@textrendermode % 2) == 0)
        textclip = !dom[key]['clip'].nil? ? dom[key]['clip'] : (@textrendermode > 3)
        setTextRenderingMode(textstroke, textfill, textclip)
        if (plalign == 'J') and dom[key]['block']
          plalign = ''
        end
        # get current position on page buffer
        curpos = @pagelen[startlinepage]
        if !dom[key]['bgcolor'].nil? and (dom[key]['bgcolor'].length > 0)
          SetFillColorArray(dom[key]['bgcolor'])
          wfill = 1
        else
          wfill = fill
        end
        if !dom[key]['fgcolor'].nil? and (dom[key]['fgcolor'].length > 0)
          SetTextColorArray(dom[key]['fgcolor'])
        end
        if !dom[key]['strokecolor'].nil? and (dom[key]['strokecolor'].length > 0)
          SetDrawColorArray(dom[key]['strokecolor'])
        end
        if !dom[key]['align'].nil?
          lalign = dom[key]['align']
        end
        if empty_string(lalign)
          lalign = align
        end
      end
      # align lines
      if @newline and (dom[key]['value'].length > 0) and (dom[key]['value'] != 'td') and (dom[key]['value'] != 'th')
        newline = true
        fontaligned = false
        # we are at the beginning of a new line
        if !startlinex.nil?
          yshift = minstartliney - startliney
          if (yshift > 0) or (@page > startlinepage)
            yshift = 0
          end
          t_x = 0
          # the last line must be shifted to be aligned as requested
          linew = (@endlinex - startlinex).abs
          pstart = getPageBuffer(startlinepage)[0, startlinepos]
          if !opentagpos.nil? and !@footerlen[startlinepage].nil? and !@in_footer
            @footerpos[startlinepage] = @pagelen[startlinepage] - @footerlen[startlinepage]
            midpos = [opentagpos, @footerpos[startlinepage]].min
          elsif !opentagpos.nil?
            midpos = opentagpos
          elsif !@footerlen[startlinepage].nil? and !@in_footer
            @footerpos[startlinepage] = @pagelen[startlinepage] - @footerlen[startlinepage]
            midpos = @footerpos[startlinepage]
          else
            midpos = 0
          end
          if midpos > 0
            pmid = getPageBuffer(startlinepage)[startlinepos, midpos - startlinepos]
            pend = getPageBuffer(startlinepage)[midpos..-1]
          else
            pmid = getPageBuffer(startlinepage)[startlinepos..-1]
            pend = ''
          end
          if (!plalign.nil? and ((plalign == 'C') or (plalign == 'J') or ((plalign == 'R') and !@rtl) or ((plalign == 'L') and @rtl))) or (yshift < 0)
            # calculate shifting amount
            tw = w
            if (plalign == 'J') and isRTLTextDir() and (@num_columns > 1)
              tw += @c_margin
            end
            if @l_margin != prevlMargin
              tw += prevlMargin - @l_margin
            end
            if @r_margin != prevrMargin
              tw += prevrMargin - @r_margin
            end
            one_space_width = GetStringWidth(32.chr)
            mdiff = (tw - linew).abs
            if plalign == 'C'
              if @rtl
                t_x = -(mdiff / 2.0)
              else
                t_x = (mdiff / 2.0)
              end
            elsif (plalign == 'R') and !@rtl
              # right alignment on LTR document
              if revstrpos(pmid, ')]').to_i == revstrpos(pmid, ' )]').to_i + 1
                # remove last space (if any)
                linew -= one_space_width
                mdiff = (tw - linew).abs
              end
              t_x = mdiff
            elsif (plalign == 'L') and @rtl
              # left alignment on RTL document
              if revstrpos(pmid, '[(') and ((revstrpos(pmid, '[( ').to_i == revstrpos(pmid, '[(').to_i) or (revstrpos(pmid, '[(' + 0.chr + 32.chr).to_i == revstrpos(pmid, '[(').to_i))
                # remove first space (if any)
                linew -= one_space_width
              end
              if pmid.index('[(') and (pmid.index('[(').to_i == revstrpos(pmid, '[(').to_i)
                # remove last space (if any)
                linew -= one_space_width
                if (@current_font['type'] == 'TrueTypeUnicode') or (@current_font['type'] == 'cidfont0')
                  linew -= one_space_width
                end
              end
              mdiff = (tw - linew).abs
              t_x = -mdiff
            elsif (plalign == 'J') and (plalign == lalign)
              # Justification
              if isRTLTextDir()
                t_x = @l_margin - @endlinex + @c_margin
              end
              no = 0 # spaces without trim
              ns = 0 # spaces with trim

              pmidtemp = pmid.dup
              # escape special characters
              pmidtemp.gsub!(/[\\][\(]/x, '\\#!#OP#!#')
              pmidtemp.gsub!(/[\\][\)]/x, '\\#!#CP#!#')
              # search spaces
              lnstring = pmidtemp.scan(/\[\(([^\)]*)\)\]/x)
              if !lnstring.empty?
                spacestr = getSpaceString()
                maxkk = lnstring.length - 1
                0.upto(maxkk) do |kk|
                  # restore special characters
                  lnstring[kk][0].gsub!('#!#OP#!#', '(')
                  lnstring[kk][0].gsub!('#!#CP#!#', ')')
                  if kk == maxkk
                    if isRTLTextDir()
                      tvalue = lnstring[kk][0].lstrip
                    else
                      tvalue = lnstring[kk][0].rstrip
                    end
                  else
                    tvalue = lnstring[kk][0]
                  end
                  # store number of spaces on the strings
                  lnstring[kk][1] = lnstring[kk][0].count(spacestr)
                  lnstring[kk][2] = tvalue.count(spacestr)
                  # count total spaces on line
                  no += lnstring[kk][1]
                  ns += lnstring[kk][2]
                  lnstring[kk][3] = no
                  lnstring[kk][4] = ns
                end
                if isRTLTextDir()
                  t_x = @l_margin - @endlinex + @c_margin - ((no - ns) * one_space_width)
                end
                # calculate additional space to add to each space
                spacelen = one_space_width
                spacewidth = (((tw - linew) + ((no - ns) * spacelen)) / (ns ? ns : 1)) * @k
                spacewidthu = -1000 * ((tw - linew) + (no * spacelen)) / (ns ? ns : 1) / @font_size
                nsmax = ns
                ns = 0
                # reset(lnstring)
                offset = 0
                strcount = 0
                prev_epsposbeg = 0
                textpos = 0;
                if isRTLTextDir()
                  textpos = @w_pt
                end
                while pmid_offset = pmid.index(/([0-9\.\+\-]*)[\s](Td|cm|m|l|c|re)[\s]/x, offset)
                  pmid_data = $1
                  pmid_mark = $2
                  # check if we are inside a string section '[( ... )]'
                  stroffset = pmid.index('[(', offset)
                  if (stroffset != nil) and (stroffset <= pmid_offset)
                    # set offset to the end of string section
                    offset = pmid.index(')]', stroffset)
                    while (offset != nil) and (pmid[offset - 1, 1] == '\\')
                      offset = pmid.index(')]', offset + 1)
                    end
                    if offset == false
                      Error('HTML Justification: malformed PDF code.')
                    end
                    next
                  end
                  if isRTLTextDir()
                    spacew = spacewidth * (nsmax - ns)
                  else
                    spacew = spacewidth * ns
                  end
                  offset = pmid_offset + $&.length
                  epsposbeg = pmid.index('q' + @epsmarker, offset)
                  epsposbeg = 0 if epsposbeg.nil?
                  epsposend = pmid.index(@epsmarker + 'Q', offset)
                  epsposend = 0 if epsposend.nil?
                  epsposend += (@epsmarker + 'Q').length
                  if ((epsposbeg > 0) and (epsposend > 0) and (offset > epsposbeg) and (offset < epsposend)) or ((epsposbeg === false) and (epsposend > 0) and (offset < epsposend))
                    # shift EPS images
                    trx = sprintf('1 0 0 1 %.3f 0 cm', spacew)
                    epsposbeg = pmid.index('q' + @epsmarker, prev_epsposbeg - 6)
                    epsposbeg = 0 if epsposbeg.nil?
                    pmid_b = pmid[0, epsposbeg]
                    pmid_m = pmid[epsposbeg, epsposend - epsposbeg]
                    pmid_e = pmid[epsposend..-1]
                    pmid = pmid_b + "\nq\n" + trx + "\n" + pmid_m + "\nQ\n" + pmid_e
                    offset = epsposend
                    next
                  end
                  prev_epsposbeg = epsposbeg
                  currentxpos = 0
                  # shift blocks of code
                  case pmid_mark
                  when 'Td', 'cm', 'm', 'l'
                    # get current X position
                    pmid =~ /([0-9\.\+\-]*)[\s](#{pmid_data})[\s](#{pmid_mark})([\s]*)/x
                    currentxpos = $1.to_i
                    textpos = currentxpos
                    if (strcount <= maxkk) and (pmid_mark == 'Td')
                      if strcount == maxkk
                        if isRTLTextDir()
                          tvalue = lnstring[strcount][0]
                        else
                          tvalue = lnstring[strcount][0].rstrip
                        end
                      else
                        tvalue = lnstring[strcount][0]
                      end
                      ns += tvalue.count(spacestr)
                      strcount += 1
                    end
                    if isRTLTextDir()
                      spacew = spacewidth * (nsmax - ns)
                    end
                    # justify block
                    pmid.sub!(/([0-9\.\+\-]*)[\s](#{pmid_data})[\s](#{pmid_mark})([\s]*)/x, "" + sprintf("%.2f", $1.to_f + spacew) + " " + $2 + " x*#!#*x" + $3 + $4)
                  when 're'
                    # justify block
                    pmid =~ /([0-9\.\+\-]*)[\s]([0-9\.\+\-]*)[\s]([0-9\.\+\-]*)[\s](#{pmid_data})[\s](re)([\s]*)/x
                    currentxpos = $1.to_i
                    x_diff = 0
                    w_diff = 0
                    if isRTLTextDir() # RTL
                      if currentxpos < textpos
                        x_diff = spacewidth * (nsmax - lnstring[strcount][4])
                        w_diff = spacewidth * lnstring[strcount][2]
                      else
                        if strcount > 0
                          x_diff = spacewidth * (nsmax - lnstring[strcount - 1][4])
                          w_diff = spacewidth * lnstring[strcount - 1][2]
                        end
                      end
                    else # LTR
                      if currentxpos > textpos
                        if strcount > 0
                          x_diff = spacewidth * lnstring[strcount - 1][3]
                        end
                        w_diff = spacewidth * lnstring[strcount][2]
                      else
                        if strcount > 1
                          x_diff = spacewidth * lnstring[strcount - 2][3]
                        end
                        if strcount > 0
                          w_diff = spacewidth * lnstring[strcount - 1][2]
                        end
                      end
                    end
                    pmid.sub!(/(#{$1})[\s](#{$2})[\s](#{$3})[\s](#{pmid_data})[\s](re)([\s]*)/x, "" + sprintf("%.2f", $1.to_f + x_diff) + " " + $2 + " " + sprintf("%.2f", $3.to_f + w_diff) + " " + $4 + " x*#!#*x" + $5 + $6)
                  when 'c'
                    # get current X position
                    pmid =~ /([0-9\.\+\-]*)[\s]([0-9\.\+\-]*)[\s]([0-9\.\+\-]*)[\s]([0-9\.\+\-]*)[\s]([0-9\.\+\-]*)[\s](#{pmid_data})[\s](c)([\s]*)/x
                    currentxpos = $1.to_i
                    # justify block
                    pmid.sub!(/(#{$1})[\s](#{$2})[\s](#{$3})[\s](#{$4})[\s](${5})[\s](#{pmid_data})[\s](c)([\s]*)/x, "" + sprintf("%.3f", $1.to_f + spacew) + " " + $2 + " " +  sprintf("%.3f", $3.to_f + spacew) + " " + $4 + " " + sprintf("%.3f", $5.to_f + spacew) + " " + $6 + " x*#!#*x" + $7 + $8)
                  end
                  # shift the annotations and links
                  if !@page_annots[@page].nil?
                    cxpos = currentxpos / @k
                    lmpos = @l_margin + @c_margin + @feps

                    @page_annots[@page].each_with_index { |pac, pak|
                      if (pac['y'] >= minstartliney) and (pac['x'] * @k >= currentxpos - @feps) and (pac['x'] * @k <= currentxpos + @feps)
                        if cxpos > lmpos
                          @page_annots[@page][pak]['x'] += (spacew - one_space_width) / @k
                          @page_annots[@page][pak]['w'] += (spacewidth * pac['numspaces']) / @k
                        else
                          @page_annots[@page][pak]['w'] += ((spacewidth * pac['numspaces']) - one_space_width) / @k
                        end
                        break
                      end
                    }
                  end
                end # end of while
                # remove markers
                pmid.gsub!('x*#!#*x', '')
                if (@current_font['type'] == 'TrueTypeUnicode') or (@current_font['type'] == 'cidfont0')
                  # multibyte characters
                  spacew = spacewidthu
                  pmidtemp = pmid.dup
                  # escape special characters
                  pmidtemp.gsub!(/[\\][\(]/x, '\\#!#OP#!#')
                  pmidtemp.gsub!(/[\\][\)]/x, '\\#!#CP#!#')
                  pmidtemp =~ /\[\(([^\)]*)\)\]/x
                  matches1 = $1.gsub("#!#OP#!#", "(")
                  matches1.gsub!("#!#CP#!#", ")")
                  pmid = pmidtemp.sub(/\[\(([^\)]*)\)\]/x,  "[(" + matches1.gsub(0.chr + 32.chr, ") " + sprintf("%.3f", spacew) + " (") + ")]")
                  setPageBuffer(startlinepage, pstart + "\n" + pmid + "\n" + pend)
                  endlinepos = (pstart + "\n" + pmid + "\n").length
                else
                  # non-unicode (single-byte characters)
                  rs = sprintf("%.3f Tw", spacewidth)
                  pmid.gsub!(/\[\(/x, "#{rs} [(")
                  setPageBuffer(startlinepage, pstart + "\n" + pmid + "\nBT 0 Tw ET\n" + pend)
                  endlinepos = (pstart + "\n" + pmid + "\nBT 0 Tw ET\n").length
                end
              end
            end # end of J
          end # end if $startlinex
          if (t_x != 0) or (yshift < 0)
            # shift the line
            trx = sprintf('1 0 0 1 %.3f %.3f cm', t_x * @k, yshift * @k)
            setPageBuffer(startlinepage, pstart + "\nq\n" + trx + "\n" + pmid + "\nQ\n" + pend)
            endlinepos = (pstart + "\nq\n" + trx + "\n" + pmid + "\nQ\n").length
            # shift the annotations and links
            if !@page_annots[@page].nil?
              @page_annots[@page].each_with_index { |pac, pak|
                if pak >= pask
                  @page_annots[@page][pak]['x'] += t_x
                  @page_annots[@page][pak]['y'] -= yshift
                end
              }
            end
            @y -= yshift
          end
        end
        pbrk = checkPageBreak(@lasth)
        @y += @c_margin if pbrk and !dom[key]['tag'] and !empty_string(@thead) and !@in_thead ### fix ###
        @newline = false
        startlinex = @x
        startliney = @y
        if dom[dom[key]['parent']]['value'] == 'sup'
          startliney -= (0.3 * @font_size_pt) / @k
        elsif dom[dom[key]['parent']]['value'] == 'sub'
          startliney -= (@font_size_pt / 0.7) / @k
        else
          minstartliney = startliney
          maxbottomliney = startliney + @font_size * @cell_height_ratio
        end
        if startlinepage == @page and !endlinepos.nil? and !pbrk # fix startlinepos at page break case.
          startlinepos = endlinepos
        else
          startlinepage = @page
          if !@in_footer
            if !@footerlen[@page].nil?
              @footerpos[@page] = @pagelen[@page] - @footerlen[@page]
            else
              @footerpos[@page] = @pagelen[@page]
            end
            startlinepos = @footerpos[@page]
          else
            startlinepos = @pagelen[@page]
          end
        end
        endlinepos = nil
        plalign = lalign
        if !@page_annots[@page].nil?
          pask = @page_annots[@page].length
        else
          pask = 0
        end
        SetFont(fontname, fontstyle, fontsize)
        if wfill  == 1
          SetFillColorArray(@bgcolor)
        end
      end # end newline
      if !opentagpos.nil?
        opentagpos = nil
      end
      if dom[key]['tag']
        addHtmlAnchor(@html_anchor) if @html_anchor
        if dom[key]['opening']
          # get text indentation (if any)
          if dom[key]['text-indent'] and dom[key]['block']
            @textindent = dom[key]['text-indent']
            @newline = true
          end
          if dom[key]['value'] == 'table'
            # available page width
            if @rtl
              wtmp = @x - @l_margin
            else
              wtmp = @w - @r_margin - @x
            end
            if cell or (dom[key]['attribute']['nested'] and (dom[key]['attribute']['nested'] == 'true'))
              # add margin for nested tables
              wtmp -= @c_margin
            end
            # table width
            if !dom[key]['width'].nil?
              table_width = getHTMLUnitToUnits(dom[key]['width'], wtmp, 'px')
            else
              table_width = wtmp
            end
          end
          if (dom[key]['value'] == 'td') or (dom[key]['value'] == 'th')
            trid = dom[key]['parent']
            table_el = dom[trid]['parent']
            if dom[table_el]['cols'].nil?
              dom[table_el]['cols'] = dom[trid]['cols']
            end
            oldmargin = @c_margin
            currentcmargin = @c_margin
            if !dom[(dom[trid]['parent'])]['attribute']['cellpadding'].nil?
              currentcmargin = getHTMLUnitToUnits(dom[(dom[trid]['parent'])]['attribute']['cellpadding'], 1, 'px')
            end
            if currentcmargin < (@line_width / 2.0)
              currentcmargin = @line_width / 2.0
            end
            @c_margin = currentcmargin
            if !dom[(dom[trid]['parent'])]['attribute']['cellspacing'].nil?
              cellspacing = getHTMLUnitToUnits(dom[(dom[trid]['parent'])]['attribute']['cellspacing'], 1, 'px')
            else
              cellspacing = 0
            end
            if @rtl
              cellspacingx = -cellspacing
            else
              cellspacingx = cellspacing
            end
            colspan = dom[key]['attribute']['colspan']
            table_columns_width = table_width - (cellspacing * (dom[table_el]['cols'] - 1))
            wtmp = colspan * (table_columns_width / dom[table_el]['cols']) + (colspan - 1) * cellspacing
            if !dom[key]['width'].nil?
              cellw = getHTMLUnitToUnits(dom[key]['width'], table_columns_width, 'px')
            else
              cellw = wtmp
            end
            if !dom[key]['height'].nil?
              # minimum cell height
              cellh = getHTMLUnitToUnits(dom[key]['height'], 0, 'px')
            else
              cellh = 0
            end
            if !dom[key]['content'].nil?
              cell_content = dom[key]['content']
            else
              cell_content = '&nbsp;'
            end
            tagtype = dom[key]['value']
            parentid = key
            while (key < maxel) and !(dom[key]['tag'] and !dom[key]['opening'] and (dom[key]['value'] == tagtype) and (dom[key]['parent'] == parentid))
              # move :key index forward
              key += 1
            end
            if dom[trid]['startpage'].nil?
              dom[trid]['startpage'] = @page
            else
               setPage(dom[trid]['startpage'])
            end
            if dom[trid]['starty'].nil?
              dom[trid]['starty'] = @y
            else
              @y = dom[trid]['starty']
            end
            if dom[trid]['startx'].nil?
              dom[trid]['startx'] = @x
            else
              @x += (cellspacingx / 2.0)
            end
            if !dom[parentid]['attribute']['rowspan'].nil?
              rowspan = dom[parentid]['attribute']['rowspan'].to_i
            else
              rowspan = 1
            end
            # skip row-spanned cells started on the previous rows
            if !dom[table_el]['rowspans'].nil?
              rsk = 0
              rskmax = dom[table_el]['rowspans'].length
              while rsk < rskmax
                trwsp = dom[table_el]['rowspans'][rsk]
                rsstartx = trwsp['startx']
                rsendx = trwsp['endx']
                # account for margin changes
                if trwsp['startpage'] < @page
                  if @rtl and (@pagedim[@page]['orm'] != @pagedim[trwsp['startpage']]['orm'])
                    dl = @pagedim[@page]['orm'] - @pagedim[trwsp['startpage']]['orm']
                    rsstartx -= dl
                    rsendx -= dl
                  elsif !@rtl and (@pagedim[@page]['olm'] != @pagedim[trwsp['startpage']]['olm'])
                    dl = @pagedim[@page]['olm'] - @pagedim[trwsp['startpage']]['olm']
                    rsstartx += dl
                    rsendx += dl
                  end
                end
                if  (trwsp['rowspan'] > 0) and (rsstartx > @x - cellspacing - currentcmargin - @feps) and (rsstartx < @x + cellspacing + currentcmargin + @feps) and ((trwsp['starty'] < @y - @feps) or (trwsp['startpage'] < @page))
                  # set the starting X position of the current cell
                  @x = rsendx + cellspacingx
                  if (trwsp['rowspan'] == 1) and !dom[trid]['endy'].nil? and !dom[trid]['endpage'].nil? and (trwsp['endpage'] == dom[trid]['endpage'])
                    # set ending Y position for row
                    dom[table_el]['rowspans'][rsk]['endy'] = [dom[trid]['endy'], trwsp['endy']].max
                    dom[trid]['endy'] = dom[table_el]['rowspans'][rsk]['endy']
                  end
                  rsk = 0
                else
                  rsk += 1
                end
              end
            end
            # add rowspan information to table element
            if rowspan > 1
              dom[table_el]['rowspans'].push({'trid' => trid, 'rowspan' => rowspan, 'mrowspan' => rowspan, 'colspan' => colspan, 'startpage' => @page, 'startx' => @x, 'starty' => @y})
              trsid = dom[table_el]['rowspans'].size
            end
            dom[trid]['cellpos'].push({'startx' => @x})
            cellid = dom[trid]['cellpos'].size
            if rowspan > 1
              dom[trid]['cellpos'][cellid - 1]['rowspanid'] = trsid - 1
            end
            # push background colors
            if !dom[parentid]['bgcolor'].nil? and (dom[parentid]['bgcolor'].length > 0)
              dom[trid]['cellpos'][cellid - 1]['bgcolor'] = dom[parentid]['bgcolor'].dup
            end
            prevLastH = @lasth
            # ****** write the cell content ******
            MultiCell(cellw, cellh, cell_content, 0, lalign, 0, 2, '', '', true, 0, true)
            @lasth = prevLastH
            @c_margin = oldmargin
            dom[trid]['cellpos'][cellid - 1]['endx'] = @x
            # update the end of row position
            if rowspan <= 1
              if !dom[trid]['endy'].nil?
                if @page == dom[trid]['endpage']
                  dom[trid]['endy'] = [@y, dom[trid]['endy']].max
                elsif @page > dom[trid]['endpage']
                  dom[trid]['endy'] = @y
                end
              else
                dom[trid]['endy'] = @y
              end
              if !dom[trid]['endpage'].nil?
                dom[trid]['endpage'] = [@page, dom[trid]['endpage']].max
              else
                dom[trid]['endpage'] = @page
              end
            else
              # account for row-spanned cells
              dom[table_el]['rowspans'][trsid - 1]['endx'] = @x
              dom[table_el]['rowspans'][trsid - 1]['endy'] = @y
              dom[table_el]['rowspans'][trsid - 1]['endpage'] = @page
            end
            if !dom[table_el]['rowspans'].nil?
              # update endy and endpage on rowspanned cells
              dom[table_el]['rowspans'].each_with_index { |trwsp, k|
                if trwsp['rowspan'] > 0
                  if !dom[trid]['endpage'].nil?
                    if trwsp['endpage'] == dom[trid]['endpage']
                      dom[table_el]['rowspans'][k]['endy'] = [dom[trid]['endy'], trwsp['endy']].max
                    elsif trwsp['endpage'] < dom[trid]['endpage']
                      dom[table_el]['rowspans'][k]['endy'] = dom[trid]['endy']
                      dom[table_el]['rowspans'][k]['endpage'] = dom[trid]['endpage']
                    else
                      dom[trid]['endy'] = @pagedim[dom[trid]['endpage']]['hk'] - @pagedim[dom[trid]['endpage']]['bm']
                    end
                  end
                end
              }
            end
            @x += (cellspacingx / 2.0)
          else
            # opening tag (or self-closing tag)
            if opentagpos.nil?
              if !@in_footer
                if !@footerlen[@page].nil?
                  @footerpos[@page] = @pagelen[@page] - @footerlen[@page]
                else
                  @footerpos[@page] = @pagelen[@page]
                end
                opentagpos = @footerpos[@page]
              end
            end
            dom = openHTMLTagHandler(dom, key, cell)
          end
        else
          # closing tag
          prev_numpages = @numpages
          dom = closeHTMLTagHandler(dom, key, cell, maxbottomliney)
          if prev_numpages > @numpages
            startlinepage = @page
          end
        end
      elsif dom[key]['value'].length > 0
        # print list-item
        if !empty_string(@lispacer)
          SetFont(pfontname, pfontstyle, pfontsize)
          @lasth = @font_size * @cell_height_ratio
          minstartliney = @y
          maxbottomliney = startliney + @font_size * @cell_height_ratio
          putHtmlListBullet(@listnum, @lispacer, pfontsize)
          SetFont(curfontname, curfontstyle, curfontsize)
          @lasth = @font_size * @cell_height_ratio
          if pfontsize.is_a?(Numeric) and (pfontsize > 0) and curfontsize.is_a?(Numeric) and (curfontsize > 0) and (pfontsize != curfontsize)
            pfontascent = getFontAscent(pfontname, pfontstyle, pfontsize)
            pfontdescent = getFontDescent(pfontname, pfontstyle, pfontsize)
            @y += ((pfontsize - curfontsize) * @cell_height_ratio / @k + pfontascent - curfontascent - pfontdescent + curfontdescent) / 2.0
            minstartliney = [@y, minstartliney].min
            maxbottomliney = [@y + pfontsize * @cell_height_ratio / @k, maxbottomliney].max
          end
        end
        # text
        @htmlvspace = 0 unless dom[key]['value'].strip.length == 0
        if !@premode and isRTLTextDir()
          # reverse spaces order
          len1 = dom[key]['value'].length
          lsp = len1 - dom[key]['value'].lstrip.length
          rsp = len1 - dom[key]['value'].rstrip.length
          tmpstr = ''
          if rsp > 0
            tmpstr << dom[key]['value'][-rsp..-1]
          end
          tmpstr << (dom[key]['value']).strip
          if lsp > 0
            tmpstr << dom[key]['value'][0, lsp]
          end
          dom[key]['value'] = tmpstr
        end
        if newline
          if !@premode
            prelen = dom[key]['value'].length
            if isRTLTextDir()
              dom[key]['value'] = dom[key]['value'].rstrip
            else
              dom[key]['value'] = dom[key]['value'].lstrip
            end
            postlen = dom[key]['value'].length
            if (postlen == 0) and (prelen > 0)
              dom[key]['trimmed_space'] = true
            end
          end
          newline = false
          firstblock = true
        else
          firstblock = false
        end
        strrest = ''
        if @rtl
          @x -= @textindent
        else
          @x += @textindent
        end
        if !@href.empty? and @href['url']
          # HTML <a> Link
          hrefcolor = ''
          if dom[(dom[key]['parent'])]['fgcolor'] and !dom[(dom[key]['parent'])]['fgcolor'].empty?
            hrefcolor = dom[(dom[key]['parent'])]['fgcolor']
          end
          hrefstyle = -1
          if dom[(dom[key]['parent'])]['fontstyle'] and (dom[(dom[key]['parent'])]['fontstyle'] != false)
            hrefstyle = dom[(dom[key]['parent'])]['fontstyle']
          end
          strrest = addHtmlLink(@href['url'], dom[key]['value'], wfill, true, hrefcolor, hrefstyle, true)
        else
          # ****** write only until the end of the line and get the rest ******
          strrest = Write(@lasth, dom[key]['value'], '', wfill, '', false, 0, true, firstblock, 0)
        end
        @textindent = 0

        if !strrest.nil? and strrest.length > 0
          # store the remaining string on the previous :key position
          @newline = true
          if cell
            if @rtl
              @x -= @c_margin
            else
              @x += @c_margin
            end
          end
          if strrest == dom[key]['value']
            # used to avoid infinite loop
            loop += 1
          else
            loop = 0
          end
          if !@href.empty? and @href['url']
            dom[key]['value'] = strrest.strip
          elsif @premode
            dom[key]['value'] = strrest
          elsif isRTLTextDir()
            dom[key]['value'] = strrest.rstrip
          else
            dom[key]['value'] = strrest.lstrip
          end
          if loop < 3
            key -= 1
          end
        else
          loop = 0
        end
      end
      key += 1
      if dom[key] and dom[key]['tag'] and (dom[key]['opening'].nil? or !dom[key]['opening']) and dom[(dom[key]['parent'])]['attribute']['nobr'] and (dom[(dom[key]['parent'])]['attribute']['nobr'] == 'true')
        if !undo and (@start_transaction_page == (@numpages - 1)) or (@y < @start_transaction_y)
          # restore previous object
          rollbackTransaction(true)
          # restore previous values
          this_method_vars.each {|vkey , vval|
            eval("#{vkey} = vval")
          }
          # add a page (or trig AcceptPageBreak() for multicolumn mode)
          pre_y = @y
          if !checkPageBreak(@page_break_trigger + 1) and (@y < pre_y)
            startliney = @y
          end
          undo = true # avoid infinite loop
        else
          undo = false
        end
      end
    end # end for each :key
    # align the last line
    if !startlinex.nil?
      yshift = minstartliney - startliney
      if (yshift > 0) or (@page > startlinepage)
        yshift = 0
      end
      t_x = 0
      # the last line must be shifted to be aligned as requested
      linew = (@endlinex - startlinex).abs
      pstart = getPageBuffer(startlinepage)[0, startlinepos]
      if !opentagpos.nil? and !@footerlen[startlinepage].nil? and !@in_footer
        @footerpos[startlinepage] = @pagelen[startlinepage] - @footerlen[startlinepage]
        midpos = [opentagpos, @footerpos[startlinepage]].min
      elsif !opentagpos.nil?
        midpos = opentagpos
      elsif !@footerlen[startlinepage].nil? and !@in_footer
        @footerpos[startlinepage] = @pagelen[startlinepage] - @footerlen[startlinepage]
        midpos = @footerpos[startlinepage]
      else
        midpos = 0
      end
      if midpos > 0
        pmid = getPageBuffer(startlinepage)[startlinepos, midpos - startlinepos]
        pend = getPageBuffer(startlinepage)[midpos..-1]
      else
        pmid = getPageBuffer(startlinepage)[startlinepos..-1]
        pend = ""
      end
      if (!plalign.nil? and (((plalign == 'C') or ((plalign == 'R') and !@rtl) or ((plalign == 'L') and @rtl)))) or (yshift < 0)
        # calculate shifting amount
        tw = w
        if @l_margin != prevlMargin
          tw += prevlMargin - @l_margin
        end
        if @r_margin != prevrMargin
          tw += prevrMargin - @r_margin
        end
        one_space_width = GetStringWidth(32.chr)
        mdiff = (tw - linew).abs
        if plalign == 'C'
          if @rtl
            t_x = -(mdiff / 2.0)
          else
            t_x = (mdiff / 2.0)
          end
        elsif (plalign == 'R') and !@rtl
          # right alignment on LTR document
          if revstrpos(pmid, ')]').to_i == revstrpos(pmid, ' )]').to_i + 1
            # remove last space (if any)
            linew -= one_space_width
            mdiff = (tw - linew).abs
          end
          t_x = mdiff
        elsif (plalign == 'L') and @rtl
          # left alignment on RTL document
          if revstrpos(pmid, '[(') and ((revstrpos(pmid, '[( ').to_i == revstrpos(pmid, '[(').to_i) or (revstrpos(pmid, '[(' + 0.chr + 32.chr).to_i == revstrpos(pmid, '[(').to_i))
            # remove first space (if any)
            linew -= one_space_width
          end
          if pmid.index('[(') and (pmid.index('[(').to_i == revstrpos(pmid, '[(').to_i)
            # remove last space (if any)
            linew -= one_space_width
            if (@current_font['type'] == 'TrueTypeUnicode') or (@current_font['type'] == 'cidfont0')
              linew -= one_space_width
            end
          end
          mdiff = (tw - linew).abs
          t_x = -mdiff
        end
      end # end if startlinex
      if (t_x != 0) or (yshift < 0)
        # shift the line
        trx = sprintf('1 0 0 1 %.3f %.3f cm', t_x * @k, yshift * @k)
        setPageBuffer(startlinepage, pstart + "\nq\n" + trx + "\n" + pmid + "\nQ\n" + pend)
        endlinepos = (pstart + "\nq\n" + trx + "\n" + pmid + "\nQ\n").length

        # shift the annotations and links
        if !@page_annots[@page].nil?
          @page_annots[@page].each_with_index { |pac, pak|
            if pak >= pask
              @page_annots[@page][pak]['x'] += t_x
              @page_annots[@page][pak]['y'] -= yshift
            end
          }
        end
        @y -= yshift
      end
    end
    if ln and !(cell and (dom[key-1]['value'] == 'table'))
      Ln(@lasth)
      if @y < maxbottomliney
        @y = maxbottomliney
      end
    end
    # restore previous values
    setGraphicVars(gvars)
    if @page > prevPage
      @l_margin = @pagedim[@page]['olm']
      @r_margin = @pagedim[@page]['orm']
    end
    # restore previous list state
    @cell_height_ratio = prev_cell_height_ratio
    @listnum = prev_listnum
    @listordered = prev_listordered
    @listcount = prev_listcount
    @lispacer = prev_lispacer
    @li_position_x = prev_li_position_x
    dom = nil
  rescue => err
    Error('writeHTML Error.', err)
  end
  alias_method :write_html, :writeHTML

  #
  # Process opening tags.
  # [@param array :dom] html dom array
  # [@param int :key] current element id
  # [@param boolean :cell] if true add the default c_margin space to each new line (default false).
  # [@access protected]
  #
  def openHTMLTagHandler(dom, key, cell)
    tag = dom[key]
    parent = dom[(dom[key]['parent'])]
    firstorlast = (key == 1)
    # check for text direction attribute
    if !tag['attribute']['dir'].nil?
      setTempRTL(tag['attribute']['dir'])
    else
      @tmprtl = false
    end
    if tag['block']
      hbz = 0 # distance from y to line bottom
      hb = 0 # vertical space between block tags
      # calculate vertical space for block tags
      if @tagvspaces[tag['value']] and @tagvspaces[tag['value']][0] and @tagvspaces[tag['value']][0]['h'] and (@tagvspaces[tag['value']][0]['h'] >= 0)
        cur_h = @tagvspaces[tag['value']][0]['h']
      elsif !tag['fontsize'].nil?
        cur_h = (tag['fontsize'] / @k) * @cell_height_ratio
      else
        cur_h = @font_size * @cell_height_ratio
      end
      if @tagvspaces[tag['value']] and @tagvspaces[tag['value']][0] and @tagvspaces[tag['value']][0]['n']
        n = @tagvspaces[tag['value']][0]['n']
      elsif tag['value'] =~ /[h][0-9]/
        n = 0.6
      else
        n = 1
      end
      hb = n * cur_h
      if (@htmlvspace <= 0) and (n > 0)
        if parent['fontsize']
          hbz = (parent['fontsize'] / @k) * @cell_height_ratio
        else
          hbz = @font_size * @cell_height_ratio
        end
      end
    end
    #Opening tag
    case tag['value']
    when 'table'
      cp = 0
      cs = 0
      dom[key]['rowspans'] = []
      if dom[key]['attribute']['nested'].nil? or (dom[key]['attribute']['nested'] != 'true')
        # set table header
        if !empty_string(dom[key]['thead'])
          # set table header
          @thead = dom[key]['thead']
          if @thead_margins.nil? or @thead_margins.empty?
            @thead_margins ||= {}

            if dom[key]['attribute']['cellpadding']
              @thead_margins['cmargin'] = getHTMLUnitToUnits(dom[key]['attribute']['cellpadding'], 1, 'px')
            else
              @thead_margins['cmargin'] = @c_margin
            end
            if @thead_margins['cmargin'] < (@line_width / 2.0)
              @thead_margins['cmargin'] = @line_width / 2.0
            end
            if cell
              @thead_margins['lmargin'] = @l_margin + @c_margin
              @thead_margins['rmargin'] = @r_margin + @c_margin
            else
              @thead_margins['lmargin'] = @l_margin
              @thead_margins['rmargin'] = @r_margin
            end
          end
        end
      end
      if !tag['attribute']['cellpadding'].nil?
        cp = getHTMLUnitToUnits(tag['attribute']['cellpadding'], 1, 'px')
        if cp < (@line_width / 2.0)
          cp = @line_width / 2.0
        end
        @old_c_margin = @c_margin
        @c_margin = cp
      end
      if !tag['attribute']['cellspacing'].nil?
        cs = getHTMLUnitToUnits(tag['attribute']['cellspacing'], 1, 'px')
      end
      if checkPageBreak(((2 * cp) + (2 * cs) + @lasth), '', false)
        @in_thead = true
        # add a page (or trig AcceptPageBreak() for multicolumn mode)
        checkPageBreak(@page_break_trigger + 1)
      end
    when 'tr'
      # array of columns positions
      dom[key]['cellpos'] = []
    when 'hr'
      if !tag['height'].nil? and (tag['height'] != '')
        hrHeight = getHTMLUnitToUnits(tag['height'], 1, 'px')
      else
        hrHeight = GetLineWidth()
      end
      addHTMLVertSpace(hbz, (hrHeight / 2.0), cell, firstorlast)
      x = GetX()
      y = GetY()
      wtmp = @w - @l_margin - @r_margin
      if cell
        wtmp -= 2 * @c_margin
      end
      if tag['width'] and (tag['width'] != '')
        hrWidth = getHTMLUnitToUnits(tag['width'], wtmp, 'px')
      else
        hrWidth = wtmp
      end
      prevlinewidth = GetLineWidth()
      SetLineWidth(hrHeight)
      Line(x, y, x + hrWidth, y)
      SetLineWidth(prevlinewidth)
      Ln('', cell)
      addHTMLVertSpace(hrHeight / 2.0, 0, cell, dom[key + 1].nil?)
    when 'a'
      if tag['attribute'].key?('href')
        @href['url'] = get_sever_url(tag['attribute']['href'])
      elsif tag['attribute'].key?('id') || tag['attribute'].key?('name')
        @html_anchor = tag['attribute']['id'] || tag['attribute']['name']
      end
    when 'img'
      if !tag['attribute']['src'].nil?
        # replace relative path with real server path
        ### T.B.D ### TCPDF 5.0.000 ###
        #if tag['attribute']['src'][0] == '/'
        #  findroot = tag['attribute']['src'].index($_SERVER['DOCUMENT_ROOT'])
        #  if (findroot == nil) or (findroot.to_i > 1)
        #    tag['attribute']['src'] = Rails.root.join('public') + tag['attribute']['src']
        #  end
        #end
        ### T.B.D ### TCPDF 5.0.000 ###
        tag['attribute']['src'].gsub!(/%([0-9a-fA-F]{2})/){$1.hex.chr}

        img_name = tag['attribute']['src']
        type = getImageFileType(tag['attribute']['src'])
        tag['attribute']['src'] = get_image_filename(tag['attribute']['src'])
        if tag['width'].nil?
          tag['width'] = 0
        end
        if tag['height'].nil?
          tag['height'] = 0
        end
        #if tag['attribute']['align'].nil?
          # the only alignment supported is "bottom"
          # further development is required for other modes.
          tag['attribute']['align'] = 'bottom'
        #end
        case tag['attribute']['align']
        when 'top'
          align = 'T'
        when 'middle'
          align = 'M'
        when 'bottom'
          align = 'B'
        else
          align = 'B'
        end
        prevy = @y
        xpos = @x
        # eliminate marker spaces
        if !dom[key - 1].nil?
          if (dom[key - 1]['value'] == ' ') or !dom[key - 1]['trimmed_space'].nil?
            xpos -= GetStringWidth(32.chr)
          elsif @rtl and (dom[key - 1]['value'] == '  ')
            xpos += 2 * GetStringWidth(32.chr)
          end
        end

        imglink = ''
        if !@href['url'].nil? and !empty_string(@href['url'])
          imglink = @href['url']
          if imglink[0, 1] == '#'
            # convert url to internal link
            page = imglink.sub(/^#/, "").to_i
            imglink = AddLink()
            SetLink(imglink, 0, page)
          end
        end
        border = 0
        if !tag['attribute']['border'].nil? and !tag['attribute']['border'].empty?
          # currently only support 1 (frame) or a combination of 'LTRB'
          border = tag['attribute']['border']
          case tag['attribute']['border']
          when '0'
            border = 0
          when '1'
            border = 1
          else
            border = tag['attribute']['border']
          end
        end
        iw = 0
        if tag['width']
          iw = getHTMLUnitToUnits(tag['width'], 1, 'px', false)
        end
        ih = 0
        if tag['height']
          ih = getHTMLUnitToUnits(tag['height'], 1, 'px', false)
        end

        # store original margin values
        l_margin = @l_margin
        r_margin = @r_margin

        SetLeftMargin(@l_margin + @c_margin)
        SetRightMargin(@r_margin + @c_margin)

        result_img =
          proc_image_file(tag['attribute']['src']) do |img_file|
            Image(img_file, xpos, @y, iw, ih, '', imglink, align, false, 300, '', false, false, border, false, false, true)
          end

        if result_img or ih != 0
          case align
          when 'T'
            @y = prevy
          when 'M'
            @y = (@img_rb_y + prevy - (tag['fontsize'] / @k)) / 2
          when 'B'
            @y = @img_rb_y - (tag['fontsize'] / @k)
          end
        else
          @y = prevy
        end

        # restore original margin values
        SetLeftMargin(l_margin)
        SetRightMargin(r_margin)

        if result_img == false
          Write(@lasth, File::basename(img_name) + ' ', '', false, '', false, 0, false) unless img_name.nil?
        end
      end
    when 'dl'
      @listnum += 1
      if @listnum == 1
        addHTMLVertSpace(hbz, hb, cell, firstorlast)
      else
        addHTMLVertSpace(0, 0, cell, firstorlast)
      end
    when 'dt'
      Ln('', cell)
      addHTMLVertSpace(hbz, 0, cell, firstorlast)
    when 'dd'
      if @rtl
        @r_margin += @listindent
      else
        @l_margin += @listindent
      end
      @listindentlevel += 1
      addHTMLVertSpace(hbz, 0, cell, firstorlast)
    when 'ul', 'ol'
      @listnum += 1
      if tag['value'] == "ol"
        @listordered[@listnum] = true
      else
        @listordered[@listnum] = false
      end
      if !tag['attribute']['start'].nil?
        @listcount[@listnum] = tag['attribute']['start'].to_i - 1
      else
        @listcount[@listnum] = 0
      end
      if @rtl
        @r_margin += @listindent
        @x -= @listindent
      else
        @l_margin += @listindent
        @x += @listindent
      end
      @listindentlevel += 1
      if @listnum == 1
        addHTMLVertSpace(hbz, hb, cell, firstorlast)
      else
        addHTMLVertSpace(0, 0, cell, firstorlast)
      end
    when 'li'
      addHTMLVertSpace(hbz, 0, cell, firstorlast)
      if @listordered[@listnum]
        # ordered item
        if !empty_string(parent['attribute']['type'])
          @lispacer = parent['attribute']['type']
        elsif !empty_string(parent['listtype'])
          @lispacer = parent['listtype']
        elsif !empty_string(@lisymbol)
          @lispacer = @lisymbol
        else
          @lispacer = '#'
        end
        @listcount[@listnum] += 1
        if !tag['attribute']['value'].nil?
          @listcount[@listnum] = tag['attribute']['value'].to_i
        end
      else
        # unordered item
        if !empty_string(parent['attribute']['type'])
          @lispacer = parent['attribute']['type']
        elsif !empty_string(parent['listtype'])
          @lispacer = parent['listtype']
        elsif !empty_string(@lisymbol)
          @lispacer = @lisymbol
        else
          @lispacer = '!'
        end
      end
      @li_position_x = @x
    when 'blockquote'
      if @rtl
        @r_margin += @listindent
      else
        @l_margin += @listindent
      end
      @listindentlevel += 1
      addHTMLVertSpace(hbz, hb, cell, firstorlast)
    when 'br'
      addHTMLVertSpace(hbz, 0, cell, firstorlast)
    when 'div'
      addHTMLVertSpace(hbz, 0, cell, firstorlast)
    when 'p'
      addHTMLVertSpace(hbz, hb, cell, firstorlast)
    when 'pre'
      addHTMLVertSpace(hbz, hb, cell, firstorlast)
      @premode = true
    when 'sup'
      SetXY(GetX(), GetY() - ((0.7 * @font_size_pt) / @k))
    when 'sub'
      SetXY(GetX(), GetY() + ((0.3 * @font_size_pt) / @k))
    when 'h1', 'h2', 'h3', 'h4', 'h5', 'h6'
      addHTMLVertSpace(hbz, hb, cell, firstorlast)

    # Form fields (since 4.8.000 - 2009-09-07)
    when 'form'
      if tag['attribute']['action']
        @form_action = tag['attribute']['action']
      else
        @form_action = @@k_path_url + request&.base_url.to_s
      end
      if tag['attribute']['enctype']
        @form_enctype = tag['attribute']['enctype']
      else
        @form_enctype = 'application/x-www-form-urlencoded'
      end
      if tag['attribute']['method']
        @form_mode = tag['attribute']['method']
      else
        @form_mode = 'post'
      end
    when 'input'
      if tag['attribute']['type'] == 'checkbox' || (tag['attribute']['name'] && !empty_string(tag['attribute']['name']))
        name = tag['attribute']['name'] || rand.to_s
        prop = {}
        opt = {}
        if tag['attribute']['value'] && !empty_string(tag['attribute']['value'])
          value = tag['attribute']['value']
        end
        if tag['attribute']['maxlength'] && !empty_string(tag['attribute']['maxlength'])
          opt['maxlen'] = tag['attribute']['maxlength'].to_i
        end
        h = @font_size * @cell_height_ratio
        if tag['attribute']['size'] && !empty_string(tag['attribute']['size'])
          w = tag['attribute']['size'].to_i * GetStringWidth(32.chr) * 2
        else
          w = h
        end
        if tag['attribute'].key? 'disabled'
          prop['readonly'] = 'true'
        end
        if tag['attribute'].key? 'checked'
          checked = true
        else
          checked = false
        end

        case tag['attribute']['type']
        when 'text'
          opt['v'] = value if value
          TextField(name, w, h, prop, opt, '', '', false)
        when 'password'
          opt['v'] = value if value
          prop['password'] = 'true'
          TextField(name, w, h, prop, opt, '', '', false)
        when 'checkbox'
          CheckBox(name, w, checked, prop, opt, value, '', '', false)
        when 'radio'
          RadioButton(name, w, prop, opt, value, checked, '', '', false)
        when 'submit'
          w = GetStringWidth(value) * 1.5
          h *= 1.6
          prop = {'lineWidth'=>1, 'borderStyle'=>'beveled', 'fillColor'=>[196, 196, 196], 'strokeColor'=>[255, 255, 255]}
          action = {}
          action['S'] = 'SubmitForm'
          action['F'] = @form_action
          action['Flags'] = ['ExportFormat'] unless @form_enctype == 'FDF'
          action['Flags'] = ['GetMethod'] if @form_mode == 'get'
          Button(name, w, h, value, action, prop, opt, '', '', false)
        when 'reset'
          w = GetStringWidth(value) * 1.5
          h *= 1.6
          prop = {'lineWidth'=>1, 'borderStyle'=>'beveled', 'fillColor'=>[196, 196, 196], 'strokeColor'=>[255, 255, 255]}
          Button(name, w, h, value, {'S'=>'ResetForm'}, prop, opt, '', '', false)
        when 'file'
          prop['fileSelect'] = 'true'
          TextField(name, w, h, prop, opt, '', '', false)
          value ||= '*'
          w = GetStringWidth(value) * 2
          h *= 1.2
          prop = {'lineWidth'=>1, 'borderStyle'=>'beveled', 'fillColor'=>[196, 196, 196], 'strokeColor'=>[255, 255, 255]}
          jsaction = "var f=this.getField('#{name}'); f.browseForFileToSubmit();"
          Button('FB_' + name, w, h, value, jsaction, prop, opt, '', '', false)
        when 'hidden'
          opt['v'] = value if value
          opt['f'] = ['invisible', 'hidden']
          TextField(name, 0, 0, prop, opt, '', '', false)
        when 'image'
          # THIS TYPE MUST BE FIXED
          if tag['attribute']['src'] && !empty_string(tag['attribute']['src'])
            img = tag['attribute']['src']
            value = 'img'
            #opt['mk'] = {'i'=>img, 'tp'=>1, 'if'=>{'sw'=>'A', 's'=>'A', 'fb'=>false}}
            if tag['attribute']['onclick'] && !tag['attribute']['onclick'].empty?
              jsaction = tag['attribute']['onclick']
            else
              jsaction = ''
            end
            Button(name, w, h, value, jsaction, prop, opt, '', '', false)
          end
        when 'button'
          w = GetStringWidth(value) * 1.5
          h *= 1.6
          prop = {'lineWidth'=>1, 'borderStyle'=>'beveled', 'fillColor'=>[196, 196, 196], 'strokeColor'=>[255, 255, 255]}
          if tag['attribute']['onclick'] && !tag['attribute']['onclick'].empty?
            jsaction = tag['attribute']['onclick']
          else
            jsaction = ''
          end
          Button(name, w, h, value, jsaction, prop, opt, '', '', false)
        end
      end
    when 'textarea'
      if tag['attribute']['name'] && !empty_string(tag['attribute']['name'])
        prop = {}
        opt = {}
        name = tag['attribute']['name']
        if tag['attribute']['value'] && !empty_string(tag['attribute']['value'])
          opt['v'] = tag['attribute']['value']
        end
        if tag['attribute']['cols'] && !empty_string(tag['attribute']['cols'])
          w = tag['attribute']['cols'].to_i * GetStringWidth(32.chr) * 2
        else
          w = 40
        end
        if tag['attribute']['rows'] && !empty_string(tag['attribute']['rows'])
          h = tag['attribute']['rows'].to_i * @font_size * @cell_height_ratio
        else
          h = 10
        end
        prop['multiline'] = 'true'
        TextField(name, w, h, prop, opt, '', '', false)
      end
    when 'select'
      if tag['attribute']['name'] && !empty_string(tag['attribute']['name']) && tag['attribute']['opt'] && !empty_string(tag['attribute']['opt'])
        h = @font_size * @cell_height_ratio
        if tag['attribute']['size'] && !empty_string(tag['attribute']['size'])
          h *= (tag['attribute']['size'].to_i + 1)
        end
        prop = {}
        opt = {}
        name = tag['attribute']['name']
        w = 0
        options = tag['attribute']['opt'].split("\r")
        values = []
        options.each {|val|
          if val.index("\t")
            opts = val.split("\t")
            values << opts
            w = [w, GetStringWidth(opts[1])].max
          else
            values << val
            w = [w, GetStringWidth(val)].max
          end
        }
        w *= 2
        if tag['attribute'].key? 'multiple'
          prop['multipleSelection'] = 'true'
          ListBox(name, w, h, values, prop, opt, '', '', false)
        else
          ComboBox(name, w, h, values, prop, opt, '', '', false)
        end
      end
    end

    if dom[key]['self'] and dom[key]['attribute']['pagebreakafter']
      pba = dom[key]['attribute']['pagebreakafter']
      # check for pagebreak
      if (pba == 'true') or (pba == 'left') or (pba == 'right')
        # add a page (or trig AcceptPageBreak() for multicolumn mode)
        checkPageBreak(@page_break_trigger + 1)
      end
      if ((pba == 'left') and ((!@rtl and (@page % 2 == 0)) or (@rtl and (@page % 2 != 0)))) or ((pba == 'right') and ((!@rtl and (@page % 2 != 0)) or (@rtl and (@page % 2 == 0))))
        # add a page (or trig AcceptPageBreak() for multicolumn mode)
        checkPageBreak(@page_break_trigger + 1)
      end
    end
    dom
  end
  protected :openHTMLTagHandler

  def proc_image_file(src, &block)
    tmpFile = nil
    img_file =
      if src =~ /^http/
        tmpFile = get_image_file(src)
        tmpFile.path
      else
        src
      end
    yield img_file
  rescue => err
    logger.error "pdf: Image: error: #{err.message}"
    false
  ensure
    # remove temp files
    tmpFile.close(true) if tmpFile
  end
  private :proc_image_file

  #
  # Process closing tags.
  # [@param array :dom] html dom array
  # [@param int :key] current element id
  # [@param boolean :cell] if true add the default c_margin space to each new line (default false).
  # [@param int :maxbottomliney] maximum y value of current line
  # [@access protected]
  #
  def closeHTMLTagHandler(dom, key, cell, maxbottomliney=0)
    tag = dom[key].dup
    parent = dom[(dom[key]['parent'])].dup
    firstorlast = dom[key + 1].nil? or (dom[key + 2].nil? and (dom[key + 1]['value'] == 'marker'))
    in_table_head = false
    if tag['block']
      hbz = 0 # distance from y to line bottom
      hb = 0 # vertical space between block tags
      # calculate vertical space for block tags
      if @tagvspaces[tag['value']] and @tagvspaces[tag['value']][1] and @tagvspaces[tag['value']][1]['h'] and (@tagvspaces[tag['value']][1]['h'] >= 0)
        pre_h = @tagvspaces[tag['value']][1]['h']
      elsif parent['fontsize']
        pre_h = (parent['fontsize'] / @k) * @cell_height_ratio
      else
        pre_h = @font_size * @cell_height_ratio
      end
      if @tagvspaces[tag['value']] and @tagvspaces[tag['value']][1] and @tagvspaces[tag['value']][1]['n']
        n = @tagvspaces[tag['value']][1]['n']
      elsif tag['value'] =~ /[h][0-9]/
        n = 0.6
      else
        n = 1
      end
      hb = n * pre_h
      if @y < maxbottomliney
        hbz = maxbottomliney - @y
      end
    end
    # Closing tag
    case (tag['value'])
    when 'tr'
      table_el = dom[(dom[key]['parent'])]['parent']
      if parent['endy'].nil?
        dom[(dom[key]['parent'])]['endy'] = @y
        parent['endy'] = @y
      end
      if parent['endpage'].nil?
        dom[(dom[key]['parent'])]['endpage'] = @page
        parent['endpage'] = @page
      end
      # update row-spanned cells
      if !dom[table_el]['rowspans'].nil?
        dom[table_el]['rowspans'].each_with_index { |trwsp, k|
          dom[table_el]['rowspans'][k]['rowspan'] -= 1
          if dom[table_el]['rowspans'][k]['rowspan'] == 0
            if dom[table_el]['rowspans'][k]['endpage'] == parent['endpage']
              dom[(dom[key]['parent'])]['endy'] = [dom[table_el]['rowspans'][k]['endy'], parent['endy']].max
            elsif dom[table_el]['rowspans'][k]['endpage'] > parent['endpage']
              dom[(dom[key]['parent'])]['endy'] = dom[table_el]['rowspans'][k]['endy']
              dom[(dom[key]['parent'])]['endpage'] = dom[table_el]['rowspans'][k]['endpage']
            end
          end
        }
        # report new endy and endpage to the rowspanned cells
        dom[table_el]['rowspans'].each_with_index { |trwsp, k|
          if dom[table_el]['rowspans'][k]['rowspan'] == 0
            dom[table_el]['rowspans'][k]['endpage'] = [dom[table_el]['rowspans'][k]['endpage'], dom[(dom[key]['parent'])]['endpage']].max
            dom[(dom[key]['parent'])]['endpage'] = dom[table_el]['rowspans'][k]['endpage']
            dom[table_el]['rowspans'][k]['endy'] = [dom[table_el]['rowspans'][k]['endy'], dom[(dom[key]['parent'])]['endy']].max
            dom[(dom[key]['parent'])]['endy'] = dom[table_el]['rowspans'][k]['endy']
          end
        }
        # update remaining rowspanned cells
        dom[table_el]['rowspans'].each_with_index { |trwsp, k|
          if dom[table_el]['rowspans'][k]['rowspan'] == 0
            dom[table_el]['rowspans'][k]['endpage'] = dom[(dom[key]['parent'])]['endpage']
            dom[table_el]['rowspans'][k]['endy'] = dom[(dom[key]['parent'])]['endy']
          end
        }
      end
      if (@num_columns > 1) and (dom[(dom[key]['parent'])]['endy'] >= (@page_break_trigger - @lasth)) and (@y < dom[(dom[key]['parent'])]['endy'])
        Ln(0, cell)
      else
        setPage(dom[(dom[key]['parent'])]['endpage']);
        @y = dom[(dom[key]['parent'])]['endy']
        if !dom[table_el]['attribute']['cellspacing'].nil?
          cellspacing = getHTMLUnitToUnits(dom[table_el]['attribute']['cellspacing'], 1, 'px')
          @y += cellspacing
        end
        Ln(0, cell)
        @x = parent['startx']
        # account for booklet mode
        if parent['startpage'] and @page > parent['startpage']
          if @rtl and (@pagedim[@page]['orm'] != @pagedim[parent['startpage']]['orm'])
            @x -= @pagedim[@page]['orm'] - @pagedim[parent['startpage']]['orm']
          elsif !@rtl and (@pagedim[@page]['olm'] != @pagedim[parent['startpage']]['olm'])
            @x += @pagedim[@page]['olm'] - @pagedim[parent['startpage']]['olm']
          end
        end
      end
    when 'table'
      if dom[(dom[key]['parent'])]['attribute']['tablehead'] and dom[(dom[key]['parent'])]['attribute']['tablehead'] == "1"
        # closing tag used for the thead part
        in_table_head = true
        @in_thead = false
      end

      table_el = parent
      # draw borders
      if (!table_el['attribute']['border'].nil? and (table_el['attribute']['border'].to_i > 0)) or (!table_el['style'].nil? and !table_el['style']['border'].nil? and (table_el['style']['border'].to_i > 0))
        border = 1
      else
        border = 0
      end

      startpage = 0
      end_page = 0
      # fix bottom line alignment of last line before page break
      dom[(dom[key]['parent'])]['trids'].each_with_index { |trkey, j|
        # update row-spanned cells
        if !dom[(dom[key]['parent'])]['rowspans'].nil?
          dom[(dom[key]['parent'])]['rowspans'].each_with_index { |trwsp, k|
            if trwsp['trid'] == trkey
              dom[(dom[key]['parent'])]['rowspans'][k]['mrowspan'] -= 1
            end
            if defined?(prevtrkey) and (trwsp['trid'] == prevtrkey) and (trwsp['mrowspan'] >= 0)
              dom[(dom[key]['parent'])]['rowspans'][k]['trid'] = trkey
            end
          }
        end
        if defined?(prevtrkey) and (dom[trkey]['startpage'] > dom[prevtrkey]['endpage'])
          pgendy = @pagedim[dom[prevtrkey]['endpage']]['hk'] - @pagedim[dom[prevtrkey]['endpage']]['bm']
          dom[prevtrkey]['endy'] = pgendy
          # update row-spanned cells
          if !dom[(dom[key]['parent'])]['rowspans'].nil?
            dom[(dom[key]['parent'])]['rowspans'].each_with_index { |trwsp, k|
              if (trwsp['trid'] == trkey) and (trwsp['mrowspan'] > 1) and (trwsp['endpage'] == dom[prevtrkey]['endpage'])
                dom[(dom[key]['parent'])]['rowspans'][k]['endy'] = pgendy
                dom[(dom[key]['parent'])]['rowspans'][k]['mrowspan'] = -1
              end
            }
          end
        end
        prevtrkey = trkey
        table_el = dom[(dom[key]['parent'])].dup
      }
      # for each row
      table_el['trids'].each_with_index { |trkey, j|
        parent = dom[trkey]
        # for each cell on the row
        parent['cellpos'].each_with_index { |cellpos, k|
          if !cellpos['rowspanid'].nil? and (cellpos['rowspanid'] >= 0)
            cellpos['startx'] = table_el['rowspans'][(cellpos['rowspanid'])]['startx']
            cellpos['endx'] = table_el['rowspans'][(cellpos['rowspanid'])]['endx']
            endy = table_el['rowspans'][(cellpos['rowspanid'])]['endy']
            startpage = table_el['rowspans'][(cellpos['rowspanid'])]['startpage']
            end_page = table_el['rowspans'][(cellpos['rowspanid'])]['endpage']
          else
            endy = parent['endy']
            startpage = parent['startpage']
            end_page = parent['endpage']
          end
          cellpos['startx'] ||= 0
          if end_page > startpage
            # design borders around HTML cells.
            startpage.upto(end_page) do |page|
              setPage(page)
              if page == startpage
                @y = parent['starty'] # put cursor at the beginning of row on the first page
                ch = getPageHeight() - parent['starty'] - getBreakMargin()
                cborder = getBorderMode(border, position='start')
              elsif page == end_page
                @y = @t_margin # put cursor at the beginning of last page
                ch = endy - @t_margin
                cborder = getBorderMode(border, position='end')
              else
                @y = @t_margin # put cursor at the beginning of the current page
                ch = getPageHeight() - @t_margin - getBreakMargin()
                cborder = getBorderMode(border, position='middle')
              end
              if !cellpos['bgcolor'].nil? and (cellpos['bgcolor'] != false)
                SetFillColorArray(cellpos['bgcolor'])
                fill = 1
              else
                fill = 0
              end
              cw = (cellpos['endx'] - cellpos['startx']).abs
              @x = cellpos['startx']
              # account for margin changes
              if page > startpage
                if @rtl and (@pagedim[page]['orm'] != @pagedim[startpage]['orm'])
                  @x -= @pagedim[page]['orm'] - @pagedim[startpage]['orm']
                elsif !@rtl and (@pagedim[page]['lm'] != @pagedim[startpage]['olm'])
                  @x += @pagedim[page]['olm'] - @pagedim[startpage]['olm']
                end
              end

              prevLastH = @lasth
              # design a cell around the text
              ccode = @fill_color + "\n" + getCellCode(cw, ch, '', cborder, 1, '', fill, '', 0, true)
              @lasth = prevLastH

              if (cborder != 0) or (fill == 1)
                pagebuff = getPageBuffer(@page)
                pstart = pagebuff[0, @intmrk[@page]]
                pend = pagebuff[@intmrk[@page]..-1]
                setPageBuffer(@page, pstart + ccode + "\n" + pend)
                @intmrk[@page] += (ccode + "\n").length
              end
            end
          else
            setPage(startpage)
            if !cellpos['bgcolor'].nil? and (cellpos['bgcolor'] != false)
              SetFillColorArray(cellpos['bgcolor'])
              fill = 1
            else
              fill = 0
            end
            @x = cellpos['startx']
            @y = parent['starty']
            cw = (cellpos['endx'] - cellpos['startx']).abs
            ch = endy - parent['starty']

            prevLastH = @lasth
            # design a cell around the text
            ccode = @fill_color + "\n" + getCellCode(cw, ch, '', border, 1, '', fill, '', 0, true)
            @lasth = prevLastH

            if (border != 0) or (fill == 1)
              if !@transfmrk[@page].nil?
                pagemark = @transfmrk[@page]
                @transfmrk[@page] += (ccode + "\n").length
              elsif @in_footer
                pagemark = @footerpos[@page]
                @footerpos[@page] += (ccode + "\n").length
              else
                pagemark = @intmrk[@page]
                @intmrk[@page] += (ccode + "\n").length
              end
              pagebuff = getPageBuffer(@page)
              pstart = pagebuff[0, pagemark]
              pend = pagebuff[pagemark..-1]
              setPageBuffer(@page, pstart + ccode + "\n" + pend)
            end
          end
        }
        if !table_el['attribute']['cellspacing'].nil?
          cellspacing = getHTMLUnitToUnits(table_el['attribute']['cellspacing'], 1, 'px')
          @y += cellspacing
        end
        Ln(0, cell)
        @x = parent['startx']
        if end_page > startpage
          if @rtl and (@pagedim[end_page]['orm'] != @pagedim[startpage]['orm'])
            @x += @pagedim[end_page]['orm'] - @pagedim[startpage]['orm']
          elsif !@rtl and (@pagedim[end_page]['olm'] != @pagedim[startpage]['olm'])
            @x += @pagedim[end_page]['olm'] - @pagedim[startpage]['olm']
          end
        end
      }
      if !in_table_head
        # we are not inside a thead section
        if dom[(parent['parent'])]['attribute']['cellpadding'] ### fix ###
          @c_margin = @old_c_margin
        end
        @lasth = @font_size * @cell_height_ratio
        if (@page == @numpages - 1) and @pageopen[@numpages]
          # remove last blank page
          deletePage(@numpages)
        end
        if !@thead_margins['top'].nil?
          # restore top margin
          @t_margin = @thead_margins['top']
          @pagedim[@page]['tm'] = @t_margin
        end
        if table_el['attribute']['nested'].nil? or (table_el['attribute']['nested'] != 'true')
          # reset main table header
          @thead = ''
          @thead_margins = {}
        end
      end
      if tag['block']
        unless dom[(dom[key]['parent'])]['attribute']['tablehead'] and dom[(dom[key]['parent'])]['attribute']['tablehead'] == "1" ### fix ###
          addHTMLVertSpace(hbz / 2, 0, cell, (dom[key+1].nil? or (dom[key+1]['value'] != 'table'))) ### fix ###
        end
      end
    when 'a'
      @href = {}
      @html_anchor = nil
    when 'sup'
      SetXY(GetX(), GetY() + (0.7 * parent['fontsize'] / @k))
    when 'sub'
      SetXY(GetX(), GetY() - (0.3 * parent['fontsize'] / @k))
    when 'div'
      addHTMLVertSpace(hbz, 0, cell, firstorlast)
    when 'blockquote'
      if @rtl
        @r_margin -= @listindent
      else
        @l_margin -= @listindent
      end
      @listindentlevel -= 1
      addHTMLVertSpace(hbz, hb, cell, firstorlast)
    when 'p'
      addHTMLVertSpace(hbz, hb, cell, firstorlast)
    when 'pre'
      addHTMLVertSpace(hbz, hb, cell, firstorlast)
      @premode = false
    when 'dl'
      @listnum -= 1
      if @listnum <= 0
        @listnum = 0
        addHTMLVertSpace(hbz, hb, cell, firstorlast)
      else
        addHTMLVertSpace(0, 0, cell, firstorlast)
      end
      @lasth = @font_size * @cell_height_ratio
    when 'dt'
      @lispacer = ''
      @li_position_x = nil
      addHTMLVertSpace(0, 0, cell, firstorlast)
    when 'dd'
      @lispacer = ''
      @li_position_x = nil
      if @rtl
        @r_margin -= @listindent
      else
        @l_margin -= @listindent
      end
      @listindentlevel -= 1
      addHTMLVertSpace(0, 0, cell, firstorlast)
    when 'ul', 'ol'
      @listnum -= 1
      @lispacer = ''
      @li_position_x = nil
      if @rtl
        @r_margin -= @listindent
      else
        @l_margin -= @listindent
      end
      @listindentlevel -= 1
      if @listnum <= 0
        @listnum = 0
        addHTMLVertSpace(hbz, hb, cell, firstorlast)
      else
        addHTMLVertSpace(0, 0, cell, firstorlast)
      end
      @lasth = @font_size * @cell_height_ratio
    when 'li'
      @lispacer = ''
      @li_position_x = nil
      addHTMLVertSpace(0, 0, cell, firstorlast)
    when 'h1', 'h2', 'h3', 'h4', 'h5', 'h6'
      addHTMLVertSpace(hbz, hb, cell, firstorlast)
    when 'form' # Form fields (since 4.8.000 - 2009-09-07)
      @form_action = ''
      @form_enctype = 'application/x-www-form-urlencoded'
    end

    if dom[(dom[key]['parent'])]['attribute']['pagebreakafter']
      pba = dom[(dom[key]['parent'])]['attribute']['pagebreakafter']
      # check for pagebreak
      if (pba == 'true') or (pba == 'left') or (pba == 'right')
        # add a page (or trig AcceptPageBreak() for multicolumn mode)
        checkPageBreak(@page_break_trigger + 1)
      end
      if ((pba == 'left') and ((!@rtl and (@page % 2 == 0)) or (@rtl and (@page % 2 != 0)))) or ((pba == 'right') and ((!@rtl and (@page % 2 != 0)) or (@rtl and (@page % 2 == 0))))
        # add a page (or trig AcceptPageBreak() for multicolumn mode)
        checkPageBreak(@page_break_trigger + 1)
      end
    end
    @tmprtl = false
    dom
  end
  protected :closeHTMLTagHandler

  #
  # Add vertical spaces if needed.
  # [@param string :hbz] Distance between current y and line bottom.
  # [@param string :hb] The height of the break.
  # [@param boolean :cell] if true add the default cMargin space to each new line (default false).
  # [@param boolean :firstorlast] if true do not print additional empty lines.
  # [@access protected]
  #
  def addHTMLVertSpace(hbz=0, hb=0, cell=false, firstorlast=false)
    if firstorlast
      Ln(0, cell)
      @htmlvspace = 0
      return
    end

    if hb < @htmlvspace
      hd = 0
    else
      hd = hb - @htmlvspace
      @htmlvspace = hb
    end
    Ln(hbz + hd, cell)
  end
  protected :addHTMLVertSpace

  #
  # Set the booklet mode for double-sided pages.
  # [@param boolean :booklet] true set the booklet mode on, fals eotherwise.
  # [@param float :inner] Inner page margin.
  # [@param float :outer] Outer page margin.
  # [@access public]
  # [@since 4.2.000 (2008-10-29)]
  #
  def SetBooklet(booklet=true, inner=-1, outer=-1)
    @booklet = booklet
    if inner >= 0
      @l_margin = inner
    end
    if outer >= 0
      @r_margin = outer
    end
  end
  alias_method :set_booklet, :SetBooklet

  #
  # Swap the left and right margins.
  # [@param boolean :reverse] if true swap left and right margins.
  # [@access protected]
  # [@since 4.2.000 (2008-10-29)]
  #
  def swapMargins(reverse=true)
    if reverse
      # swap left and right margins
      mtemp = @original_l_margin
      @original_l_margin = @original_r_margin
      @original_r_margin = mtemp
      deltam = @original_l_margin - @original_r_margin
      @l_margin += deltam
      @r_margin -= deltam
    end
  end
  protected :swapMargins

  #
  # Set the vertical spaces for HTML tags.
  # The array must have the following structure (example):
  #   :tagvs = {'h1' => [{'h' => '', 'n' => 2}, {'h' => 1.3, 'n' => 1}]}
  # The first array level contains the tag names,
  # the second level contains 0 for opening tags or 1 for closing tags,
  # the third level contains the vertical space unit (h) and the number spaces to add (n).
  # If the h parameter is not specified, default values are used.
  # [@param array :tagvs] array of tags and relative vertical spaces.
  # [@access public]
  # [@since 4.2.001 (2008-10-30)]
  #
  def setHtmlVSpace(tagvs)
    @tagvspaces = tagvs
  end
  alias_method :set_html_v_space, :setHtmlVSpace

  #
  # convert HTML string containing value and unit of measure to user's units or points.
  # [@param string :htmlval] string containing values and unit
  # [@param string :refsize] reference value in points
  # [@param string :defaultunit] default unit (can be one of the following: %, em, ex, px, in, mm, pc, pt).
  # [@param boolean :point] if true returns points, otherwise returns value in user's units
  # [@return float] value in user's unit or point if :points=true
  # [@access public]
  # [@since 4.4.004 (2008-12-10)]
  #
  def getHTMLUnitToUnits(htmlval, refsize=1, defaultunit='px', points=false)
    supportedunits = ['%', 'em', 'ex', 'px', 'in', 'cm', 'mm', 'pc', 'pt']
    retval = 0
    value = 0
    unit = 'px'
    k = @k
    if points
      k = 1
    end
    if supportedunits.include?(defaultunit)
      unit = defaultunit
    end
    if htmlval.is_a?(Numeric)
      value = htmlval.to_f
    else
      mnum = htmlval.scan(/[0-9\.\-\+]+/)
      unless mnum.empty?
        value = mnum[0].to_f
        munit = htmlval.scan(/[a-z%]+/)
        unless munit.empty?
          if supportedunits.include?(munit[0])
            unit = munit[0]
          end
        end
      end
    end
    case unit
    when '%' # percentage
      retval = (value * refsize) / 100.0
    when 'em' # relative-size
      retval = value * refsize
    when 'ex' # height of lower case 'x' (about half the font-size)
      retval = value * (refsize / 2.0)
    when 'in' # absolute-size
      retval = (value * @dpi) / k
    when 'cm' # centimeters
      retval = (value / 2.54 * @dpi) / k
    when 'mm' # millimeters
      retval = (value / 25.4 * @dpi) / k
    when 'pc' # one pica is 12 points
      retval = (value * 12) / k
    when 'pt' # points
      retval = value / k
    when 'px' # pixels
      retval = pixelsToUnits(value)
    end
    return retval
  end
  alias_method :get_html_unit_to_units, :getHTMLUnitToUnits

  #
  # Returns the Roman representation of an integer number
  # [@param int :number] to convert
  # [@return string] roman representation of the specified number
  # [@access public]
  # [@since 4.4.004 (2008-12-10)]
  #
  def intToRoman(number)
    roman = ''
    while number >= 1000
      roman << 'M'
      number -= 1000
    end
    while number >= 900
      roman << 'CM'
      number -= 900
    end
    while number >= 500
      roman << 'D'
      number -= 500
    end
    while number >= 400
      roman << 'CD'
      number -= 400
    end
    while number >= 100
      roman << 'C'
      number -= 100
    end
    while number >= 90
      roman << 'XC'
      number -= 90
    end
    while number >= 50
      roman << 'L'
      number -= 50
    end
    while number >= 40
      roman << 'XL'
      number -= 40
    end
    while number >= 10
      roman << 'X'
      number -= 10
    end
    while number >= 9
      roman << 'IX'
      number -= 9
    end
    while number >= 5
      roman << 'V'
      number -= 5
    end
    while number >= 4
      roman << 'IV'
      number -= 4
    end
    while number >= 1
      roman << 'I'
      number -= 1
    end
    return roman
  end
  alias_method :int_to_roman, :intToRoman

protected

  #
  # Output an HTML list bullet or ordered item symbol
  # [@param int :listdepth] list nesting level
  # [@param string :listtype] type of list
  # [@param float :size] current font size
  # [@access protected]
  # [@since 4.4.004 (2008-12-10)]
  #
  def putHtmlListBullet(listdepth, listtype='', size=10)
    size /= @k
    fill = ''
    color = @fgcolor
    width = 0
    textitem = ''
    tmpx = @x
    @x = @li_position_x
    lspace = GetStringWidth('  ')
    if listtype == '!'
      # set default list type for unordered list
      deftypes = ['disc', 'circle', 'square']
      listtype = deftypes[(listdepth - 1) % 3]
    elsif listtype == '#'
      # set default list type for ordered list
      listtype = 'decimal'
    end
    case listtype
      # unordered types
    when 'none'
    when 'disc', 'circle'
      fill = 'F' if listtype == 'disc'
      fill << 'D'
      r = size / 6.0
      lspace += 2 * r
      if @rtl
        @x += lspace
      else
        @x -= lspace
      end
      Circle(@x + r, @y + @lasth / 2.0, r, 0, 360, fill, {'color'=>color}, color, 8)
    when 'square'
      l = size / 3.0
      lspace += l
      if @rtl
        @x += lspace
      else
        @x -= lspace
      end
      Rect(@x, @y + (@lasth - l)/ 2.0, l, l, 'F', {}, color)

    # ordered types
    # listcount[@listnum]
    # textitem
    when '1', 'decimal'
      textitem = @listcount[@listnum].to_s
    when 'decimal-leading-zero'
      textitem = sprintf("%02d", @listcount[@listnum])
    when 'i', 'lower-roman'
      textitem = (intToRoman(@listcount[@listnum])).downcase
    when 'I', 'upper-roman'
      textitem = intToRoman(@listcount[@listnum])
    when 'a', 'lower-alpha', 'lower-latin'
      textitem = (97 + @listcount[@listnum] - 1).chr
    when 'A', 'upper-alpha', 'upper-latin'
      textitem = (65 + @listcount[@listnum] - 1).chr
    when 'lower-greek'
      textitem = unichr(945 + @listcount[@listnum] - 1)
    else
      textitem = @listcount[@listnum].to_s
    end

    if !empty_string(textitem)
      # print ordered item
      if @rtl
        textitem = '.' + textitem
      else
        textitem = textitem + '.'
      end
      lspace += GetStringWidth(textitem)
      if @rtl
        @x += lspace
      else
        @x -= lspace
      end
      Write(@lasth, textitem, '', false, '', false, 0, false)
    end
    @x = tmpx
    @lispacer = ''
    @li_position_x = nil
  end

  #
  # Returns current graphic variables as array.
  # [@return array] graphic variables
  # [@access protected]
  # [@since 4.2.010 (2008-11-14)]
  #
  def getGraphicVars()
    grapvars = {
      'FontFamily' => @font_family,
      'FontStyle' => @font_style,
      'FontSizePt' => @font_size_pt,
      'rMargin' => @r_margin,
      'lMargin' => @l_margin,
      'cMargin' => @c_margin,
      'tMargin' => @t_margin,
      'LineWidth' => @line_width,
      'linestyleWidth' => @linestyle_width,
      'linestyleCap' => @linestyle_cap,
      'linestyleJoin' => @linestyle_join,
      'linestyleDash' => @linestyle_dash,
      'textrendermode' => @textrendermode,
      'textstrokewidth' => @textstrokewidth,
      'DrawColor' => @draw_color,
      'FillColor' => @fill_color,
      'TextColor' => @text_color,
      'ColorFlag' => @color_flag,
      'bgcolor' => @bgcolor,
      'fgcolor' => @fgcolor,
      'htmlvspace' => @htmlvspace,
      'listindent' => @listindent,
      'listindentlevel' => @listindentlevel,
      'listnum' => @listnum,
      'listordered' => @listordered,
      'listcount' => @listcount,
      'lispacer' => @lispacer,
      'li_position_x' => @li_position_x,
      'lasth' => @lasth,
      'h' => @h,
      'w' => @w,
      'x' => @x,
      'y' => @y,
    }
    return grapvars
  end

  #
  # Set graphic variables.
  # [@param array :gvars] graphic variables
  # [@param bool :option] set additional parameters
  # [@access protected]
  # [@since 4.2.010 (2008-11-14)]
  #
  def setGraphicVars(gvars, option = false)
    @font_family = gvars['FontFamily']
    @font_style = gvars['FontStyle']
    @font_size_pt = gvars['FontSizePt']
    @r_margin = gvars['rMargin']
    @l_margin = gvars['lMargin']
    @c_margin = gvars['cMargin']
    @t_margin = gvars['tMargin']
    @line_width = gvars['LineWidth']
    @linestyle_width = gvars['linestyleWidth']
    @linestyle_cap = gvars['linestyleCap']
    @linestyle_join = gvars['linestyleJoin']
    @linestyle_dash = gvars['linestyleDash']
    @textrendermode = gvars['textrendermode']
    @textstrokewidth = gvars['textstrokewidth']
    @draw_color = gvars['DrawColor']
    @fill_color = gvars['FillColor']
    @text_color = gvars['TextColor']
    @color_flag = gvars['ColorFlag']
    @bgcolor = gvars['bgcolor']
    @fgcolor = gvars['fgcolor']
    @htmlvspace = gvars['htmlvspace']
    @listindent = gvars['listindent']
    @listindentlevel = gvars['listindentlevel']
    @listnum = gvars['listnum']
    @listordered = gvars['listordered']
    @listcount = gvars['listcount']
    @lispacer = gvars['lispacer']
    @li_position_x = gvars['li_position_x']
    if option
      @lasth = gvars['lasth']
      @h = gvars['h']
      @w = gvars['w']
      @x = gvars['x']
      @y = gvars['y']
    end
    out('' + @linestyle_width + ' ' + @linestyle_cap + ' ' + @linestyle_join + ' ' + @linestyle_dash + ' ' + @draw_color + ' ' + @fill_color + '')
    unless empty_string(@font_family)
      SetFont(@font_family, @font_style, @font_size_pt)
    end
  end

  # --- END OF HTML PARSER FUNCTIONS ---
  # --- BUFFER FUNCTIONS ---

  #
  # Returns a temporary filename for caching object on filesystem.
  # [@param string :name] prefix to add to filename
  # [@return string] filename.
  # [@access protected]
  # [@since 4.5.000 (2008-12-31)]
  #
  def getObjFilename(name)
    tmpFile = Tempfile.new(name + '_', @@k_path_cache)
    tmpFile.binmode
    tmpFile
  end

  #
  # Writes data to a temporary file on filesystem.
  # [@param string :filename] file name
  # [@param mixed :data] data to write on file
  # [@param boolean :append] if true append data, false replace.
  # [@access protected]
  # [@since 4.5.000 (2008-12-31)]
  #
  def writeDiskCache(filename, data, append=false)
    filename = filename.path
    if append
      fmode = 'a+b'
    else
      fmode = 'w+b'
    end
    f = open(filename, fmode)
    if !f
      Error('Unable to write cache file: ' + filename)
    else
      f.write(data)
      f.close
    end

    # update file length (needed for transactions)
    if @cache_file_length[filename].nil?
      @cache_file_length[filename] = data.length
    elsif append == false
      @cache_file_length[filename] = data.length
    else
      @cache_file_length[filename] += data.length
    end
  end

  #
  # Read data from a temporary file on filesystem.
  # [@param string :filename] file name
  # [@return mixed] retrieved data
  # [@access protected]
  # [@since 4.5.000 (2008-12-31)]
  #
  def readDiskCache(filename)
    filename = filename.path
    data = ''
    open( filename,'rb') do |f|
      data << f.read()
    end
    return data
  end

  #
  # Set buffer content (always append data).
  # [@param string :data] data
  # [@access protected]
  # [@since 4.5.000 (2009-01-02)]
  #
  def setBuffer(data)
    @bufferlen += data.length
    if @diskcache
      if @buffer.nil? or empty_string(@buffer.path)
        @buffer = getObjFilename('buffer')
      end
      writeDiskCache(@buffer, data, true)
    else
      @buffer << data
    end
  end

  #
  # Get buffer content.
  # [@return string] buffer content
  # [@access protected]
  # [@since 4.5.000 (2009-01-02)]
  #
  def getBuffer
    if @diskcache
      return readDiskCache(@buffer)
    else
      return @buffer
    end
  end

  #
  # Set page buffer content.
  # [@param int :page] page number
  # [@param string :data] page data
  # [@param boolean :append] if true append data, false replace.
  # [@access protected]
  # [@since 4.5.000 (2008-12-31)]
  #
  def setPageBuffer(page, data, append=false)
    if @diskcache
      if @pages[page].nil?
        @pages[page] = getObjFilename('page' + page.to_s)
      elsif (@objcopy and !append and @prev_pages[page].nil?)
        @prev_pages[page] = @pages[page]
        @pages[page] = getObjFilename('page' + page.to_s)
      end
      writeDiskCache(@pages[page], data, append)
    else
      if append
        @pages[page] << data
      else
        @pages[page] = data
      end
    end
    if append and !@pagelen[page].nil?
      @pagelen[page] += data.length
    else
      @pagelen[page] = data.length
    end
  end

  #
  # Get page buffer content.
  # [@param int :page] page number
  # [@return string] page buffer content or false in case of error
  # [@access protected]
  # [@since 4.5.000 (2008-12-31)]
  #
  def getPageBuffer(page)
    if @diskcache
      return readDiskCache(@pages[page])
    elsif !@pages[page].nil?
      return @pages[page]
    end
    return false
  end

  #
  # Set image buffer content.
  # [@param string :image] image key
  # [@param array :data] image data
  # [@access protected]
  # [@since 4.5.000 (2008-12-31)]
  #
  def setImageBuffer(image, data)
    if @diskcache
      if @images[image].nil?
        @images[image] = getObjFilename('image' + File::basename(image))
      end
      writeDiskCache(@images[image], Marshal.dump(data))
    else
      @images[image] = data
    end
    if !@imagekeys.include?(image)
      @imagekeys.push image
      @numimages += 1
    end
  end

  #
  # Set image buffer content for a specified sub-key.
  # [@param string :image] image key
  # [@param string :key] image sub-key
  # [@param hash :data] image data
  # [@access protected]
  # [@since 4.5.000 (2008-12-31)]
  #
  def setImageSubBuffer(image, key, data)
    if @images[image].nil?
        setImageBuffer(image, {})
    end
    if @diskcache
      tmpimg = getImageBuffer(image)
      tmpimg[key] = data
      writeDiskCache(@images[image], Marshal.dump(tmpimg))
    else
      @images[image][key] = data
    end
  end

  #
  # Get image buffer content.
  # [@param string :image] image key
  # [@return string image] buffer content or false in case of error
  # [@access protected]
  # [@since 4.5.000 (2008-12-31)]
  #
  def getImageBuffer(image)
    if @diskcache and !@images[image].nil?
      return Marshal.load(readDiskCache(@images[image]))
    elsif !@images[image].nil?
      return @images[image]
    end
    return false
  end

  #
  # Set font buffer content.
  # [@param string :font] font key
  # [@param hash :data] font data
  # [@access protected]
  # [@since 4.5.000 (2009-01-02)]
  #
  def setFontBuffer(font, data)
    if @diskcache
      if @fonts[font].nil?
        @fonts[font] = getObjFilename('font')
      end
      writeDiskCache(@fonts[font], Marshal.dump(data))
    else
      @fonts[font] = data
    end
    if !@fontkeys.include?(font)
      @fontkeys.push font
    end
  end

  #
  # Set font buffer content.
  # [@param string :font] font key
  # [@param string :key] font sub-key
  # [@param array :data] font data
  # [@access protected]
  # [@since 4.5.000 (2009-01-02)]
  #
  def setFontSubBuffer(font, key, data)
    if @fonts[font].nil?
      setFontBuffer(font, {})
    end
    if @diskcache
      tmpfont = getFontBuffer(font)
      tmpfont[key] = data
      writeDiskCache(@fonts[font], Marshal.dump(tmpfont))
    else
      @fonts[font][key] = data
    end
  end


  #
  # Reset all links that points to pages after current
  # [@access protected]
  #
  def resetLinksAfterCurrentPage()
    @links.each do |link|
      link[0] = @page if link.present? && link[0] > @page
    end
  end

  #
  # Get font buffer content.
  # [@param string :font] font key
  # [@return string font] buffer content or false in case of error
  # [@access protected]
  # [@since 4.5.000 (2009-01-02)]
  #
  def getFontBuffer(font)
    if @diskcache and !@fonts[font].nil?
      return Marshal.load(readDiskCache(@fonts[font]))
    elsif !@fonts[font].nil?
      return @fonts[font]
    end
    return false
  end

  # --- END OF BUFFER FUNCTIONS ---
  # --- PAGE OPERATION FUNCTIONS ---

public

  #
  # Move a page to a previous position.
  # [@param int :frompage] number of the source page
  # [@param int :topage] number of the destination page (must be less than :frompage)
  # [@return] true in case of success, false in case of error.
  # [@access public]
  # [@since 4.5.000 (2009-01-02)]
  #
  def movePage(frompage, topage)
    if (frompage > @numpages) or (frompage <= topage)
      return false
    end
    if frompage == @page
      # close the page before moving it
      endPage()
    end
    # move all page-related states
    tmppage = @pages[frompage]
    tmppagedim = @pagedim[frompage]
    tmppagelen = @pagelen[frompage]
    tmpintmrk = @intmrk[frompage]
    if @footerpos[frompage]
      tmpfooterpos = @footerpos[frompage]
    end
    if @footerlen[frompage]
      tmpfooterlen = @footerlen[frompage]
    end
    if @transfmrk[frompage]
      tmptransfmrk = @transfmrk[frompage]
    end
    if @page_annots[frompage]
      tmpannots = @page_annots[frompage]
    end
    if @newpagegroup[frompage]
      tmpnewpagegroup = @newpagegroup[frompage]
    end
    frompage.downto(topage + 1) do |i|
      j = i - 1
      # shift pages down
      @pages[i] = @pages[j]
      @pagedim[i] = @pagedim[j]
      @pagelen[i] = @pagelen[j]
      @intmrk[i] = @intmrk[j]
      if @footerpos[j]
        @footerpos[i] = @footerpos[j]
      elsif footerpos[i]
        @footerpos[i] = nil
      end
      if @footerlen[j]
        @footerlen[i] = @footerlen[j]
      elsif @footerlen[i]
        @footerlen[i] = nil
      end
      if @transfmrk[j]
        @transfmrk[i] = @transfmrk[j]
      elsif @transfmrk[i]
        @transfmrk[i] = nil
      end
      if @page_annots[j]
        @page_annots[i] = @page_annots[j]
      elsif @page_annots[i]
        @page_annots[i] = nil
      end
      if @newpagegroup[j]
        @newpagegroup[i] = @newpagegroup[j]
      elsif @newpagegroup[i]
        @newpagegroup[i] = nil
      end
    end
    @pages[topage] = tmppage
    @pagedim[topage] = tmppagedim
    @pagelen[topage] = tmppagelen
    @intmrk[topage] = tmpintmrk
    if tmpfooterpos
      @footerpos[topage] = tmpfooterpos
    elsif @footerpos[topage]
      @footerpos[topage] = nil
    end
    if tmpfooterlen
      @footerlen[topage] = tmpfooterlen
    elsif @footerlen[topage]
      @footerlen[topage] = nil
    end
    if tmptransfmrk
      @transfmrk[topage] = tmptransfmrk
    elsif @transfmrk[topage]
      @transfmrk[topage] = nil
    end
    if tmpannots
      @page_annots[topage] = tmpannots
    elsif @page_annots[topage]
      @page_annots[topage] = nil
    end
    if tmpnewpagegroup
      @newpagegroup[topage] = tmpnewpagegroup
    elsif @newpagegroup[topage]
      @newpagegroup[topage] = nil
    end
    # adjust outlines
    tmpoutlines = @outlines
    tmpoutlines.each_with_index do |outline, key|
      if (outline[:p] >= topage) and (outline[:p] < frompage)
        @outlines[key][:p] = outline[:p] + 1
      elsif outline[:p] == frompage
        @outlines[key][:p] = topage
      end
    end
    # adjust links
    tmplinks = @links
    tmplinks.each_with_index do |link, key|
      next if link.nil?
      if (link[0] >= topage) and (link[0] < frompage)
        @links[key][0] = link[0] + 1
      elsif link[0] == frompage
        @links[key][0] = topage
      end
    end
    ### T.B.D ### TCPDF 5.0.001 ###
    # adjust javascript
    #tmpjavascript = @javascript
    #global jfrompage, jtopage
    #jfrompage = frompage
    #jtopage = topage
    #tmpjavascript =~ /this\.addField\(\'([^\']*)\',\'([^\']*)\',([0-9]+)/
    #pagenum = $3.to_i + 1
    #if (pagenum >= jtopage) && (pagenum < jfrompage)
    #  newpage = pagenum + 1
    #elsif pagenum == jfrompage
    #  newpage = jtopage
    #else
    #  newpage = pagenum
    #end
    #newpage -= 1
    #@javascript = "this.addField(\'" + $1 + "\',\'" + $2 + "\'," + newpage + ""

    # return to last page
    lastPage(true)
    return true
  end
  alias_method :move_page, :movePage

  #
  # Remove the specified page.
  # [@param int :page] page to remove
  # [@return] true in case of success, false in case of error.
  # [@access public]
  # [@since 4.6.004 (2009-04-23)]
  #
  def deletePage(page)
    if page > @numpages
      return false
    end
    # delete current page
    @pages[page] = nil
    @pagedim[page] = nil
    @pagelen[page] = nil
    @intmrk[page] = nil
    if @footerpos[page]
      @footerpos[page] = nil
    end
    if @footerlen[page]
      @footerlen[page] = nil
    end
    if @transfmrk[page]
      @transfmrk[page] = nil
    end
    if @page_annots[page]
      @page_annots[page] = nil
    end
    if @newpagegroup[page]
      @newpagegroup[page] = nil
    end
    if @pageopen[page]
      @pageopen[page] = nil
    end
    # update remaining pages
    page.upto(@numpages - 1) do |i|
      j = i + 1
      # shift pages
      @pages[i] = @pages[j]
      @pagedim[i] = @pagedim[j]
      @pagelen[i] = @pagelen[j]
      @intmrk[i] = @intmrk[j]
      if @footerpos[j]
        @footerpos[i] = @footerpos[j]
      elsif @footerpos[i]
        @footerpos[i] = nil
      end
      if @footerlen[j]
        @footerlen[i] = @footerlen[j]
      elsif @footerlen[i]
        @footerlen[i] = nil
      end
      if @transfmrk[j]
        @transfmrk[i] = @transfmrk[j]
      elsif @transfmrk[i]
        @transfmrk[i] = nil
      end
      if @page_annots[j]
        @page_annots[i] = page_annots[j]
      elsif @page_annots[i]
        @page_annots[i] = nil
      end
      if @newpagegroup[j]
        @newpagegroup[i] = @newpagegroup[j]
      elsif @newpagegroup[i]
        @newpagegroup[i] = nil
      end
      if @pageopen[j]
        @pageopen[i] = @pageopen[j]
      elsif @pageopen[i]
        @pageopen[i] = nil
      end
    end
    # remove last page
    @pages[@numpages] = nil
    @pagedim[@numpages] = nil
    @pagelen[@numpages] = nil
    @intmrk[@numpages] = nil
    if @footerpos[@numpages]
      @footerpos[@numpages] = nil
    end
    if @footerlen[@numpages]
      @footerlen[@numpages] = nil
    end
    if @transfmrk[@numpages]
      @transfmrk[@numpages] = nil
    end
    if @page_annots[@numpages]
      @page_annots[@numpages] = nil
    end
    if @newpagegroup[@numpages]
      @newpagegroup[@numpages] = nil
    end
    if @pageopen[@numpages]
      @pageopen[@numpages] = nil
    end
    @numpages -= 1
    @page = @numpages
    # adjust outlines
    tmpoutlines = @outlines
    tmpoutlines.each_with_index do |outline, key|
      if outline[:p] > page
        @outlines[key][:p] = outline[:p] - 1
      elsif outline[:p] == page
        @outlines[key] = nil
      end
    end
    # adjust links
    tmplinks = @links
    tmplinks.each_with_index do |link, key|
      next if link.nil?
      if link[0] > page
        @links[key][0] = link[0] - 1
      elsif link[0] == page
        @links[key] = nil
      end
    end

    #### PDF javascript code does not implement, yet. ###
    # adjust javascript
    #tmpjavascript = @javascript
    #jpage = page
    #tmpjavascript =~ /this\.addField\(\'([^\']*)\',\'([^\']*)\',([0-9]+)/
    #pagenum = $3.to_i + 1
    #if pagenum >= jpage
    #  newpage = pagenum - 1
    #elsif pagenum == jpage
    #  newpage = 1
    #else
    #  newpage = pagenum
    #end
    #newpage -= 1
    #@javascript = "this.addField(\'" + $1 + "\',\'" + $2 + "\'," + newpage + ""

    # return to last page
    lastPage(true)
    return true
  end
  alias_method :delete_page, :deletePage

  #
  # Output a Table of Content Index (TOC).
  # Before calling this method you have to open the page using the addTOCPage() method.
  # After calling this method you have to call endTOCPage() to close the TOC page.
  # You can override this method to achieve different styles.
  # [@param int :page] page number where this TOC should be inserted (leave empty for current page).
  # [@param string :numbersfont] set the font for page numbers (please use monospaced font for better alignment).
  # [@param string :filler] string used to fill the space between text and page number.
  # [@param string :toc_name] name to use for TOC bookmark.
  # [@access public]
  # [@author] Nicola Asuni
  # [@since 4.5.000 (2009-01-02)]
  # [@see] addTOCPage(), endTOCPage(), addHTMLTOC()
  #
  def addTOC(page='', numbersfont='', filler='.', toc_name='TOC')
    fontsize = @font_size_pt
    fontfamily = @font_family
    fontstyle = @font_style
    w = @w - @l_margin - @r_margin
    spacer = GetStringWidth(32.chr) * 4
    page_first = getPage()
    lmargin = @l_margin
    rmargin = @r_margin
    x_start = GetX()
    if empty_string(numbersfont)
      numbersfont = @default_monospaced_font
    end
    if empty_string(filler)
      filler = ' '
    end
    if empty_string(page)
      gap = ' '
    else
      gap = ''
    end
    # sort outlines by page and original position
    @outlines = @outlines.sort_by {|x| [x[:p], x[:y]] }
    @outlines.each_with_index do |outline, key|
      if @rtl
        aligntext = 'R'
        alignnum = 'L'
      else
        aligntext = 'L'
        alignnum = 'R'
      end
      if outline[:l] == 0
        SetFont(fontfamily, fontstyle + 'B', fontsize)
      else
        SetFont(fontfamily, fontstyle, fontsize - outline[:l])
      end
      indent = spacer * outline[:l]
      if @rtl
        @r_margin += indent
        @x -= indent
      else
        @l_margin += indent
        @x += indent
      end
      link = AddLink()
      SetLink(link, 0, outline[:p])
      # write the text
      Write(0, outline[:t], link, 0, aligntext, false, 0, false, false, 0)
      SetFont(numbersfont, fontstyle, fontsize)
      if empty_string(page)
        pagenum = outline[:p]
      else
        # placemark to be replaced with the correct number
        pagenum = '{#' + outline[:p].to_s + '}'
        if (@current_font['type'] == 'TrueTypeUnicode') or (@current_font['type'] == 'cidfont0')
          pagenum = '{' + pagenum + '}'
        end
      end
      numwidth = GetStringWidth(pagenum)
      if @rtl
        tw = @x - @l_margin
      else
        tw = @w - @r_margin - @x
      end
      fw = tw - numwidth - GetStringWidth(32.chr)
      numfills = (fw / GetStringWidth(filler)).floor
      if numfills > 0
        rowfill = filler * numfills
      else
        rowfill = ''
      end
      if @rtl
        pagenum = pagenum + gap + rowfill + ' '
      else
        pagenum = ' ' + rowfill + gap + pagenum
      end
      # write the number
      Cell(tw, 0, pagenum, 0, 1, alignnum, 0, link, 0)
      SetX(x_start)
      @l_margin = lmargin
      @r_margin = rmargin
    end
    page_last = getPage()
    numpages = page_last - page_first + 1
    if !empty_string(page)
      page_first.upto(page_last) do |p|
        # get page data
        temppage = getPageBuffer(p)
        1.upto(@numpages) do |n|
          # update page numbers
          k = '{#' + n.to_s + '}'
          ku = '{' + k + '}'
          alias_a = escape(k)
          alias_au = escape('{' + k + '}')
          if @is_unicode
            alias_b = escape(UTF8ToLatin1(k))
            alias_bu = escape(UTF8ToLatin1(ku))
            alias_c = escape(utf8StrRev(k, false, rtl_text_dir))
            alias_cu = escape(utf8StrRev(ku, false, rtl_text_dir))
          end
          if n >= page
            np = n + numpages
          else
            np = n
          end
          ns = formatTOCPageNumber(np)
          nu = ns
          sdiff = k.length - ns.length - 1
          sdiffu = ku.length - ns.length - 1
          sfill = filler * sdiff
          sfillu = filler * sdiffu
          if @rtl
            ns = ns + ' ' + sfill
            nu = nu + ' ' + sfillu
          else
            ns = sfill + ' ' + ns
            nu = sfillu + ' ' + nu
          end
          nu = UTF8ToUTF16BE(nu, false)
          temppage = temppage.gsub(alias_au, nu)
          if @is_unicode
            temppage = temppage.gsub(alias_bu, nu)
            temppage = temppage.gsub(alias_cu, nu)
            temppage = temppage.gsub(alias_b, ns)
            temppage = temppage.gsub(alias_c, ns)
          end
          temppage = temppage.gsub(alias_a, ns)
        end
        # save changes
        setPageBuffer(p, temppage)
      end
      # move pages
      Bookmark(toc_name, 0, 0, page_first)
      0.upto(numpages - 1) do |i|
        movePage(page_last, page)
      end
    end
  rescue => err
    Error('addTOC Error.', err)
  end
  alias_method :add_toc, :addTOC

  #
  # Output a Table Of Content Index (TOC) using HTML templates.
  # Before calling this method you have to open the page using the addTOCPage() method.
  # After calling this method you have to call endTOCPage() to close the TOC page.
  # [@param int :page] page number where this TOC should be inserted (leave empty for current page).
  # [@param string :toc_name] name to use for TOC bookmark.
  # [@param array :templates] array of html templates. Use: #TOC_DESCRIPTION# for bookmark title, #TOC_PAGE_NUMBER# for page number.
  # [@parma boolean :correct_align] if true correct the number alignment (numbers must be in monospaced font like courier and right aligned on LTR, or left aligned on RTL)
  # [@access public]
  # [@author] Nicola Asuni
  # [@since 5.0.001 (2010-05-06)]
  # [@see] addTOCPage(), endTOCPage(), addTOC()
  #
  def addHTMLTOC(page='', toc_name='TOC', templates=[], correct_align=true)
    prev_htmlLinkColorArray = @html_link_color_array
    prev_htmlLinkFontStyle = @html_link_font_style
    # set new style for link
    @html_link_color_array = []
    @html_link_font_style = ''
    page_first = getPage()
    # sort outlines by page and original position
    @outlines = @outlines.sort_by {|x| [x[:p], x[:y]] }
    @outlines.each_with_index do |outline, key|
      if empty_string(page)
        pagenum = outline[:p].to_s
      else
        # placemark to be replaced with the correct number
        pagenum = '{#' + outline[:p].to_s + '}'
        if (@current_font['type'] == 'TrueTypeUnicode') or (@current_font['type'] == 'cidfont0')
          pagenum = '{' + pagenum + '}'
        end
      end
      # get HTML template
      row = templates[outline[:l]]
      # replace templates with current values
      row = row.gsub('#TOC_DESCRIPTION#', outline[:t])
      row = row.gsub('#TOC_PAGE_NUMBER#', pagenum)
      # add link to page
      row = '<a href="#' + outline[:p].to_s + '">' + row + '</a>'
      # write bookmark entry
      writeHTML(row, false, false, true, false, '')
    end
    # restore link styles
    @html_link_color_array = prev_htmlLinkColorArray
    @html_link_font_style = prev_htmlLinkFontStyle
    # move TOC page and replace numbers
    page_last = getPage()
    numpages = page_last - page_first + 1
    if !empty_string(page)
      page_first.upto(page_last) do |p|
        # get page data
        temppage = getPageBuffer(p)
        1.upto(@numpages) do |n|
          # update page numbers
          k = '{#' + n.to_s + '}'
          ku = '{' + k + '}'
          alias_a = escape(k)
          alias_au = escape('{' + k + '}')
          if @is_unicode
            alias_b = escape(UTF8ToLatin1(k))
            alias_bu = escape(UTF8ToLatin1(ku))
            alias_c = escape(utf8StrRev(k, false, rtl_text_dir))
            alias_cu = escape(utf8StrRev(ku, false, rtl_text_dir))
          end
          if n >= page
            np = n + numpages
          else
            np = n
          end
          ns = formatTOCPageNumber(np)
          nu = ns
          if correct_align
            sdiff = k.length - ns.length
            sdiffu = ku.length - ns.length
            sfill = ' ' * sdiff
            sfillu = ' ' * sdiffu
            if @rtl
              ns = ns + sfill
              nu = nu + sfillu
            else
              ns = sfill + ns
              nu = sfillu + nu
            end
          end
          nu = UTF8ToUTF16BE(nu, false)
          temppage = temppage.gsub(alias_au, nu)
          if @is_unicode
            temppage = temppage.gsub(alias_bu, nu)
            temppage = temppage.gsub(alias_cu, nu)
            temppage = temppage.gsub(alias_b, ns)
            temppage = temppage.gsub(alias_c, ns)
          end
          temppage = temppage.gsub(alias_a, ns)
        end
        # save changes
        setPageBuffer(p, temppage)
      end
      # move pages
      Bookmark(toc_name, 0, 0, page_first)
      0.upto(numpages - 1) do |i|
        movePage(page_last, page)
      end
    end
  rescue => err
    Error('addHTMLTOC Error.', err)
  end
  alias_method :add_html_toc, :addHTMLTOC

  #
  # Stores a copy of the current RBPDF object used for undo operation.
  # [@access public]
  # [@since 4.5.029 (2009-03-19)]
  #
  def startTransaction()
    if @objcopy
      # remove previous copy
      commitTransaction()
    end
    # record current page number and Y position
    @start_transaction_page = @page
    @start_transaction_y = @y
    # clone current object
    @objcopy = objclone(self)
  end
  alias_method :start_transaction, :startTransaction

  #
  # Delete the copy of the current RBPDF object used for undo operation.
  # [@access public]
  # [@since 4.5.029 (2009-03-19)]
  #
  def commitTransaction()
    if @objcopy
      if @objcopy.diskcache
        @prev_pages.compact.each do |file|
          File.delete(file.path)
        end
        @prev_pages = []
      end

      @objcopy.destroy(true, true)
      @objcopy = nil
    end
  end
  alias_method :commit_transaction, :commitTransaction

  #
  # This method allows to undo the latest transaction by returning the latest saved RBPDF object with startTransaction().
  # [@param boolean :this_self] if true restores current class object to previous state without the need of reassignment via the returned value.
  # [@return] RBPDF object.
  # [@access public]
  # [@since 4.5.029 (2009-03-19)]
  #
  def rollbackTransaction(this_self=false)
    if @objcopy
      if @objcopy.diskcache
        # truncate files to previous values
        @objcopy.cache_file_length.each { |file, length|
          File.truncate(file, length) if File.exist?(file)
        }
        @pages.each_with_index do |file, i|
          if @prev_pages[i] and File.exist?(@prev_pages[i].path)
            File.delete(file.path)
          end
        end
      end
      destroy(true, true)
      if this_self
        objvars = @objcopy.instance_variables
        objvars.each {|key|
          eval("#{key} = @objcopy.instance_variable_get(key)") if key.to_s != '@objcopy'
        }
      end
      return @objcopy
    end
    return self
  end
  alias_method :rollback_transaction, :rollbackTransaction

  #
  # Creates a copy of a class object
  # [@param object :object] class object to be cloned
  # [@return] cloned object
  # [@access public]
  # [@since 4.5.029 (2009-03-19)]
  #
  def objclone(object)
    if @diskcache
      newobj = object.dup
      newobj.cache_file_length = object.cache_file_length.dup
      newobj.prev_pages = object.prev_pages.dup
      newobj.pages = object.pages.dup
      return newobj
    else
      return Marshal.load(Marshal.dump(object))
    end
  end

  # --- END OF PAGE OPERATION FUNCTIONS ---
  # --- STRING FUNCTIONS ---

  #
  # Determine whether a string is empty.
  # [@param string :str] string to be checked
  # [@return boolean] true if string is empty
  # [@access public]
  # [@since 4.5.044 (2009-04-16)]
  #
  def empty_string(str)
    return (str.nil? or (str.is_a?(String) and (str.length == 0)))
  end

  #
  # Find position of last occurrence of a substring in a string
  # [@param string :haystack] The string to search in.
  # [@param string :needle] substring to search.
  # [@param int :offset] May be specified to begin searching an arbitrary number of characters into the string.
  # [@return] Returns the position where the needle exists. Returns FALSE if the needle was not found.
  # [@access public]
  # [@since 4.8.038 (2010-03-13)]
  #
  def revstrpos(haystack, needle, offset = 0)
    length = haystack.length
    offset = (offset > 0) ? (length - offset) : offset.abs
    pos = haystack.reverse.index(needle.reverse, offset)

    return (pos.nil? ? nil : length - pos - needle.length)
  end

  # --- END OF STRING FUNCTIONS ---

  #
  # Set Text rendering mode.
  # [@param int :stroke] outline size in user units (0 = disable).
  # [@param boolean :fill] if true fills the text (default).
  # [@param boolean :clip] if true activate clipping mode
  # [@access public]
  # [@since 4.9.008 (2009-04-02)]
  #
  def setTextRenderingMode(stroke=0, fill=true, clip=false)
    # Ref.: PDF 32000-1:2008 - 9.3.6 Text Rendering Mode
    # convert text rendering parameters
    if stroke < 0
      stroke = 0
    end
    if fill == true
      if stroke > 0
        if clip == true
          # Fill, then stroke text and add to path for clipping
          textrendermode = 6
        else
          # Fill, then stroke text
          textrendermode = 2
        end
        textstrokewidth = stroke
      else
        if clip == true
          # Fill text and add to path for clipping
          textrendermode = 4
        else
          # Fill text
          textrendermode = 0
        end
      end
    else
      if stroke > 0
        if clip == true
          # Stroke text and add to path for clipping
          textrendermode = 5
        else
          # Stroke text
          textrendermode = 1
        end
        textstrokewidth = stroke
      else
        if clip == true
          # Add text to path for clipping
          textrendermode = 7
        else
          # Neither fill nor stroke text (invisible)
          textrendermode = 3
        end
      end
    end
    @textrendermode = textrendermode
    @textstrokewidth = stroke * @k
  end
  alias_method :set_text_rendering_mode, :setTextRenderingMode

  #
  # Get the Path-Painting Operators.
  # [@param string :style]
  #   Style of rendering. Possible values are:
  #   * S or D: Stroke the path.
  #   * s or d: Close and stroke the path.
  #   * f or F: Fill the path, using the nonzero winding number rule to determine the region to fill.
  #   * f* or F*: Fill the path, using the even-odd rule to determine the region to fill.
  #   * B or FD or DF: Fill and then stroke the path, using the nonzero winding number rule to determine the region to fill.
  #   * B* or F*D or DF*: Fill and then stroke the path, using the even-odd rule to determine the region to fill.
  #   * b or fd or df: Close, fill, and then stroke the path, using the nonzero winding number rule to determine the region to fill.
  #   * b or f*d or df*: Close, fill, and then stroke the path, using the even-odd rule to determine the region to fill.
  #   * CNZ: Clipping mode using the even-odd rule to determine which regions lie inside the clipping path.
  #   * CEO: Clipping mode using the nonzero winding number rule to determine which regions lie inside the clipping path
  #   * n: End the path object without filling or stroking it.
  # [@param string :default] default style
  # [@param boolean :mode] if true enable rasterization, false otherwise.
  # [@author] Nicola Asuni
  # [@access protected:
  # [@since 5.0.000 (2010-04-30)]
  #
  def getPathPaintOperator(style, default='S')
    op = ''
    case style
    when 'S', 'D'
      op = 'S'
    when 's', 'd'
      op = 's'
    when 'f', 'F'
      op = 'f'
    when 'f*', 'F*'
      op = 'f*'
    when 'B', 'FD', 'DF'
      op = 'B'
    when 'B*', 'F*D', 'DF*'
      op = 'B*'
    when 'b', 'fd', 'df'
      op = 'b'
    when 'b*', 'f*d', 'df*'
      op = 'b*'
    when 'CNZ'
      op = 'W n'
    when 'CEO'
      op = 'W* n'
    when 'n'
      op = 'n'
    else
      if !default.empty?
        op = getPathPaintOperator(default, '')
      else
        op = ''
      end
    end
    return op
  end
  protected :getPathPaintOperator

  # -.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-
  # SVG METHODS (not implement, yet.)
  # -.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-
end # END OF RBPDF CLASS

#TODO 2007-05-25 (EJM) Level=0 -
#Handle special IE contype request
# if (!_SERVER['HTTP_USER_AGENT'].nil? and (_SERVER['HTTP_USER_AGENT']=='contype'))
#   header('Content-Type: application/pdf');
#   exit;
# }
