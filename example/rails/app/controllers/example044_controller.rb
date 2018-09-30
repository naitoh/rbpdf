# coding: UTF-8
#============================================================+
# Begin       : 2009-01-02
# Last Update : 2010-05-20
#
# Description : Example 044 for RBPDF class
#               Move, copy and delete pages
#
# Author: Jun NAITOH
# License: LGPL 2.1 or later
#============================================================+

require("example_common.rb")

class Example044Controller < ApplicationController
  def index
    # create new PDF document
    pdf = RBPDF.new(PDF_PAGE_ORIENTATION, PDF_UNIT, PDF_PAGE_FORMAT, true, 'UTF-8', false)
    
    # set document information
    pdf.set_creator(PDF_CREATOR)
    pdf.set_author(PDF_AUTHOR)
    pdf.set_title('RBPDF Example 044')
    pdf.set_subject('RBPDF Tutorial')
    pdf.set_keywords('RBPDF, PDF, example, test, guide')
    
    # set default header data
    pdf.set_header_data(PDF_HEADER_LOGO, PDF_HEADER_LOGO_WIDTH, PDF_HEADER_TITLE + ' 044', PDF_HEADER_STRING)
    
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
    pdf.set_font('helvetica', 'B', 40)
    
    # print a line using cell()
    pdf.add_page()
    pdf.cell(0, 10, 'PAGE: A', 0, 1, 'L')
    
    # add some vertical space
    pdf.ln(10)
    
    # print some text
    pdf.set_font('times', 'I', 16)
    txt = 'RBPDF allows you to Move and Delete pages.'
    pdf.write(0, txt, '', 0, 'L', true, 0, false, false, 0)
    
    pdf.set_font('helvetica', 'B', 40)
    
    pdf.add_page()
    pdf.cell(0, 10, 'PAGE: B', 0, 1, 'L')
    
    pdf.add_page()
    pdf.cell(0, 10, 'PAGE: D', 0, 1, 'L')
    
    pdf.add_page()
    pdf.cell(0, 10, 'PAGE: E', 0, 1, 'L')
    
    pdf.add_page()
    pdf.cell(0, 10, 'PAGE: E-2', 0, 1, 'L')
    
    pdf.add_page()
    pdf.cell(0, 10, 'PAGE: F', 0, 1, 'L')
    
    pdf.add_page()
    pdf.cell(0, 10, 'PAGE: C', 0, 1, 'L')
    
    pdf.add_page()
    pdf.cell(0, 10, 'PAGE: G', 0, 1, 'L')
    
    # Move page 7 to page 3
    pdf.move_page(7, 3)
    
    # Delete page 6
    pdf.delete_page(6)
    
    pdf.add_page()
    pdf.cell(0, 10, 'PAGE: H', 0, 1, 'L')
    
    # copy the second page
    # pdf.copy_page(2)
    
    # NOTE: to insert a page to a previous position, you can add a new page to the end of document and then move it using move_page().
    
    # ---------------------------------------------------------
    
    # Close and output PDF document
    send_data pdf.output(), :type => "application/pdf", :disposition => "inline"
  end
end

#============================================================+
# END OF FILE
#============================================================+
