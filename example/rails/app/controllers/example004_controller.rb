# coding: UTF-8
#============================================================+
# Begin       : 2008-03-04
# Last Update : 2010-05-20
#
# Description : Example 004 for RBPDF class
#               Cell stretching
#
# Author: Jun NAITOH
# License: LGPL 2.1 or later
#============================================================+

require("example_common.rb")
    
class Example004Controller < ApplicationController
  def index
    # create new PDF document
    pdf = RBPDF.new(PDF_PAGE_ORIENTATION, PDF_UNIT, PDF_PAGE_FORMAT, true, 'UTF-8', false)
    
    # set document information
    pdf.set_creator(PDF_CREATOR)
    pdf.set_author(PDF_AUTHOR)
    pdf.set_title('RBPDF Example 004')
    pdf.set_subject('RBPDF Tutorial')
    pdf.set_keywords('RBPDF, PDF, example, test, guide')
    
    # set default header data
    pdf.set_header_data(PDF_HEADER_LOGO, PDF_HEADER_LOGO_WIDTH, PDF_HEADER_TITLE + ' 004', PDF_HEADER_STRING)
    
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
    
    # set font
    pdf.set_font('times', 'B', 12)
    
    # add a page
    pdf.add_page()
    
    #cell(w, h=0, txt='', border=0, ln=0, align='', fill=0, link='', stretch=0, ignore_min_height=false, calign='T', valign='M')
    
    # test Cell stretching
    pdf.cell(0, 10, 'TEST CELL STRETCH: no stretch', 1, 1, 'C', 0, '', 0)
    pdf.cell(0, 10, 'TEST CELL STRETCH: scaling', 1, 1, 'C', 0, '', 1)
    pdf.cell(0, 10, 'TEST CELL STRETCH: force scaling', 1, 1, 'C', 0, '', 2)
    pdf.cell(0, 10, 'TEST CELL STRETCH: spacing', 1, 1, 'C', 0, '', 3)
    pdf.cell(0, 10, 'TEST CELL STRETCH: force spacing', 1, 1, 'C', 0, '', 4)
    
    pdf.ln(10)
    
    pdf.cell(60, 10, 'TEST CELL STRETCH: scaling', 1, 1, 'C', 0, '', 1)
    pdf.cell(60, 10, 'TEST CELL STRETCH: force scaling', 1, 1, 'C', 0, '', 2)
    pdf.cell(60, 10, 'TEST CELL STRETCH: spacing', 1, 1, 'C', 0, '', 3)
    pdf.cell(60, 10, 'TEST CELL STRETCH: force spacing', 1, 1, 'C', 0, '', 4)
    
    # ---------------------------------------------------------
    
    # Close and output PDF document
    send_data pdf.output(), :type => "application/pdf", :disposition => "inline"
  end
end

#============================================================+
# END OF FILE                                                
#============================================================+
