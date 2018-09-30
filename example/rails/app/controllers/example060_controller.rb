# coding: UTF-8
#============================================================+
# Begin       : 2010-05-17
# Last Update : 2010-05-20
#
# Description : Example 060 for RBPDF class
#               Advanced page settings.
#
# Author: Jun NAITOH
# License: LGPL 2.1 or later
#============================================================+

require("example_common.rb")

class Example060Controller < ApplicationController
  def index
    # create new PDF document
    pdf = RBPDF.new(PDF_PAGE_ORIENTATION, PDF_UNIT, PDF_PAGE_FORMAT, true, 'UTF-8', false)
    
    # set document information
    pdf.set_creator(PDF_CREATOR)
    pdf.set_author(PDF_AUTHOR)
    pdf.set_title('RBPDF Example 060')
    pdf.set_subject('RBPDF Tutorial')
    pdf.set_keywords('RBPDF, PDF, example, test, guide')
    
    # set default header data
    pdf.set_header_data(PDF_HEADER_LOGO, PDF_HEADER_LOGO_WIDTH, PDF_HEADER_TITLE + ' 060', PDF_HEADER_STRING)
    
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
    
    # set font
    pdf.set_font('helvetica', '', 20)
    
    # ---------------------------------------------------------
    
    # set page format (read source code documentation for further information)
    page_format = {
    	'MediaBox' => {'llx' => 0, 'lly' => 0, 'urx' => 210, 'ury' => 297},
    	'CropBox' => {'llx' => 0, 'lly' => 0, 'urx' => 210, 'ury' => 297},
    	'BleedBox' => {'llx' => 5, 'lly' => 5, 'urx' => 205, 'ury' => 292},
    	'TrimBox' => {'llx' => 10, 'lly' => 10, 'urx' => 200, 'ury' => 287},
    	'ArtBox' => {'llx' => 15, 'lly' => 15, 'urx' => 195, 'ury' => 282},
    	'Dur' => 3,
    	'trans' => {
    		'D' => 1.5,
    		'S' => 'Split',
    		'Dm' => 'V',
    		'M' => 'O'
    	},
    	'Rotate' => 90,
    	'PZ' => 1,
    }
    
    # Check the example n. 29 for viewer preferences
    
    # add first page ---
    pdf.add_page('P', page_format, false, false)
    pdf.cell(0, 12, 'First Page', 1, 1, 'C')
    
    # add second page ---
    page_format['Rotate'] = 270
    pdf.add_page('P', page_format, false, false)
    pdf.cell(0, 12, 'Second Page', 1, 1, 'C')
    
    # ---------------------------------------------------------
    
    # Close and output PDF document
    send_data pdf.output(), :type => "application/pdf", :disposition => "inline"
  end
end

#============================================================+
# END OF FILE
#============================================================+
