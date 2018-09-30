# coding: UTF-8
#============================================================+
# Begin       : 2008-06-09
# Last Update : 2010-05-20
#
# Description : Example 029 for RBPDF class
#               Set PDF viewer display preferences.
#
# Author: Jun NAITOH
# License: LGPL 2.1 or later
#============================================================+

require("example_common.rb")

class Example029Controller < ApplicationController
  def index
    # create new PDF document
    pdf = RBPDF.new(PDF_PAGE_ORIENTATION, PDF_UNIT, PDF_PAGE_FORMAT, true, 'UTF-8', false)
    
    # set document information
    pdf.set_creator(PDF_CREATOR)
    pdf.set_author(PDF_AUTHOR)
    pdf.set_title('RBPDF Example 029')
    pdf.set_subject('RBPDF Tutorial')
    pdf.set_keywords('RBPDF, PDF, example, test, guide')
    
    # set default header data
    pdf.set_header_data(PDF_HEADER_LOGO, PDF_HEADER_LOGO_WIDTH, PDF_HEADER_TITLE + ' 029', PDF_HEADER_STRING)
    
    # set header and footer fonts
    pdf.set_header_font([PDF_FONT_NAME_MAIN, '', PDF_FONT_SIZE_MAIN])
    pdf.set_footer_font([PDF_FONT_NAME_DATA, '', PDF_FONT_SIZE_DATA])
    
    # set default monospaced font
    pdf.set_default_monospaced_font(PDF_FONT_MONOSPACED)
    
    # set margins
    pdf.set_margins(PDF_MARGIN_LEFT, PDF_MARGIN_TOP, PDF_MARGIN_RIGHT)
    pdf.set_header_margin(PDF_MARGIN_HEADER)
    pdf.set_footer_margin(PDF_MARGIN_FOOTER)
    
    # set auto page breaks
    pdf.set_auto_page_break(true, PDF_MARGIN_BOTTOM)
    
    # set image scale factor
    pdf.set_image_scale(PDF_IMAGE_SCALE_RATIO)
    
    # set some language-dependent strings
    pdf.set_language_array($l)
    
    # ---------------------------------------------------------
    
    # set array for viewer preferences
    preferences = {
    	'HideToolbar' => true,
    	'HideMenubar' => true,
    	'HideWindowUI' => true,
    	'FitWindow' => true,
    	'CenterWindow' => true,
    	'DisplayDocTitle' => true,
    	'NonFullScreenPageMode' => 'UseNone', # UseNone, UseOutlines, UseThumbs, UseOC
    	'ViewArea' => 'CropBox', # CropBox, BleedBox, TrimBox, ArtBox
    	'ViewClip' => 'CropBox', # CropBox, BleedBox, TrimBox, ArtBox
    	'PrintArea' => 'CropBox', # CropBox, BleedBox, TrimBox, ArtBox
    	'PrintClip' => 'CropBox', # CropBox, BleedBox, TrimBox, ArtBox
    	'PrintScaling' => 'AppDefault', # None, AppDefault
    	'Duplex' => 'DuplexFlipLongEdge', # Simplex, DuplexFlipShortEdge, DuplexFlipLongEdge
    	'PickTrayByPDFSize' => true,
    	'PrintPageRange' => [1,1,2,3],
    	'NumCopies' => 2
    }
    
    # Check the example n. 60 for advanced page settings
    
    # set pdf viewer preferences
    pdf.set_viewer_preferences(preferences)
    
    # set font
    pdf.set_font('times', '', 14)
    
    # add a page
    pdf.add_page()
    
    # print a line
    pdf.cell(0, 12, 'DISPLAY PREFERENCES - PAGE 1', 1, 1, 'C')
    
    pdf.ln(5)
    
    pdf.write(0, 'You can use the set_viewer_preferences() method to change viewer preferences.', '', 0, 'L', true, 0, false, false, 0)
    
    # add a page
    pdf.add_page()
    # print a line
    pdf.cell(0, 12, 'DISPLAY PREFERENCES - PAGE 2', 0, 0, 'C')
    
    # add a page
    pdf.add_page()
    # print a line
    pdf.cell(0, 12, 'DISPLAY PREFERENCES - PAGE 3', 0, 0, 'C')
    
    # ---------------------------------------------------------
    
    # Close and output PDF document
    send_data pdf.output(), :type => "application/pdf", :disposition => "inline"
  end
end

#============================================================+
# END OF FILE                                                
#============================================================+
