# coding: UTF-8
#============================================================+
# Begin       : 2008-06-09
# Last Update : 2010-05-20
#
# Description : Example 031 for RBPDF class
#               Pie Chart
#
# Author: Jun NAITOH
# License: LGPL 2.1 or later
#============================================================+

require("example_common.rb")

class Example031Controller < ApplicationController
  def index
    # create new PDF document
    pdf = RBPDF.new(PDF_PAGE_ORIENTATION, PDF_UNIT, PDF_PAGE_FORMAT, true, 'UTF-8', false)
    
    # set document information
    pdf.set_creator(PDF_CREATOR)
    pdf.set_author(PDF_AUTHOR)
    pdf.set_title('RBPDF Example 031')
    pdf.set_subject('RBPDF Tutorial')
    pdf.set_keywords('RBPDF, PDF, example, test, guide')
    
    # set default header data
    pdf.set_header_data(PDF_HEADER_LOGO, PDF_HEADER_LOGO_WIDTH, PDF_HEADER_TITLE + ' 031', PDF_HEADER_STRING)
    
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
    pdf.set_font('helvetica', 'B', 20)
    
    # add a page
    pdf.add_page()
    
    pdf.write(0, 'Example of pie_sector() method.')
    
    xc = 105
    yc = 100
    r = 50
    
    pdf.set_fill_color(0, 0, 255)
    pdf.pie_sector(xc, yc, r, 20, 120, 'FD', false, 0)
    
    pdf.set_fill_color(0, 255, 0)
    pdf.pie_sector(xc, yc, r, 120, 250, 'FD', false, 0)
    
    pdf.set_fill_color(255, 0, 0)
    pdf.pie_sector(xc, yc, r, 250, 20, 'FD', false, 0)
    
    # write labels
    pdf.set_text_color(255,255,255)
    pdf.text(105, 65, 'BLUE')
    pdf.text(60, 95, 'GREEN')
    pdf.text(120, 115, 'RED')
    
    # ---------------------------------------------------------
    
    # Close and output PDF document
    send_data pdf.output(), :type => "application/pdf", :disposition => "inline"
  end
end

#============================================================+
# END OF FILE
#============================================================+
