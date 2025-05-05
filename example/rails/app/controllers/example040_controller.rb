# coding: UTF-8
# frozen_string_literal: true
#============================================================+
# Begin       : 2008-10-28
# Last Update : 2010-05-20
#
# Description : Example 040 for RBPDF class
#               Booklet mode (double-sided pages)
#
# Author: Jun NAITOH
# License: LGPL 2.1 or later
#============================================================+

require("example_common.rb")

class Example040Controller < ApplicationController
  def index
    # create new PDF document
    pdf = RBPDF.new(PDF_PAGE_ORIENTATION, PDF_UNIT, PDF_PAGE_FORMAT, true, 'UTF-8', false)
    
    # set document information
    pdf.set_creator(PDF_CREATOR)
    pdf.set_author(PDF_AUTHOR)
    pdf.set_title('RBPDF Example 040')
    pdf.set_subject('RBPDF Tutorial')
    pdf.set_keywords('RBPDF, PDF, example, test, guide')
    
    # set default header data
    pdf.set_header_data(PDF_HEADER_LOGO, PDF_HEADER_LOGO_WIDTH, PDF_HEADER_TITLE + ' 040', PDF_HEADER_STRING)
    
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
    
    # set display mode
    pdf.set_display_mode('fullpage', 'TwoColumnRight', 'UseNone')
    
    # set pdf viewer preferences
    pdf.set_viewer_preferences({'Duplex' => 'DuplexFlipLongEdge'})
    
    # set booklet mode
    pdf.set_booklet(true, 10, 30)
    
    # set core font
    pdf.set_font('helvetica', '', 18)
    
    # add a page (left page)
    pdf.add_page()
    
    pdf.write(0, 'Example of booklet mode', '', 0, 'L', true, 0, false, false, 0)
    
    # print a line using cell()
    pdf.cell(0, 0, 'LEFT PAGE 1', 1, 1, 'C')
    
    
    # add a page (right page)
    pdf.add_page()
    
    # print a line using cell()
    pdf.cell(0, 0, 'RIGHT PAGE 2', 1, 1, 'C')
    
    
    # add a page (left page)
    pdf.add_page()
    
    # print a line using cell()
    pdf.cell(0, 0, 'LEFT PAGE 3', 1, 1, 'C')
    
    # add a page (right page)
    pdf.add_page()
    
    # print a line using cell()
    pdf.cell(0, 0, 'RIGHT PAGE 4', 1, 1, 'C')
    
    # ---------------------------------------------------------
    
    # Close and output PDF document
    send_data pdf.output(), :type => "application/pdf", :disposition => "inline"
  end
end

#============================================================+
# END OF FILE                                                
#============================================================+
