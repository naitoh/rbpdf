# coding: UTF-8
# frozen_string_literal: true
#============================================================+
# Begin       : 2008-03-04
# Last Update : 2010-05-20
#
# Description : Example 028 for RBPDF class
#               Changing page formats
#
# Author: Jun NAITOH
# License: LGPL 2.1 or later
#============================================================+

require("example_common.rb")

class Example028Controller < ApplicationController
  def index
    # create new PDF document
    pdf = RBPDF.new(PDF_PAGE_ORIENTATION, PDF_UNIT, PDF_PAGE_FORMAT, true, 'UTF-8', false)
    
    # set document information
    pdf.set_creator(PDF_CREATOR)
    pdf.set_author(PDF_AUTHOR)
    pdf.set_title('RBPDF Example 028')
    pdf.set_subject('RBPDF Tutorial')
    pdf.set_keywords('RBPDF, PDF, example, test, guide')
    
    # remove default header/footer
    pdf.set_print_header(false)
    pdf.set_print_footer(false)
    
    # set default monospaced font
    pdf.set_default_monospaced_font(PDF_FONT_MONOSPACED)
    
    # set margins
    pdf.set_margins(10, PDF_MARGIN_TOP, 10)
    
    # set auto page breaks
    pdf.set_auto_page_break(true, PDF_MARGIN_BOTTOM)
    
    # set image scale factor
    pdf.set_image_scale(PDF_IMAGE_SCALE_RATIO)
    
    # set some language-dependent strings
    pdf.set_language_array($l)
    
    # ---------------------------------------------------------
    
    pdf.set_display_mode('fullpage', 'SinglePage', 'UseNone')
    
    # set font
    pdf.set_font('times', 'B', 20)
    
    pdf.add_page('P', 'A4')
    pdf.cell(0, 0, 'A4 PORTRAIT', 1, 1, 'C')
    
    pdf.add_page('L', 'A4')
    pdf.cell(0, 0, 'A4 LANDSCAPE', 1, 1, 'C')
    
    pdf.add_page('P', 'A5')
    pdf.cell(0, 0, 'A5 PORTRAIT', 1, 1, 'C')
    
    pdf.add_page('L', 'A5')
    pdf.cell(0, 0, 'A5 LANDSCAPE', 1, 1, 'C')
    
    pdf.add_page('P', 'A6')
    pdf.cell(0, 0, 'A6 PORTRAIT', 1, 1, 'C')
    
    pdf.add_page('L', 'A6')
    pdf.cell(0, 0, 'A6 LANDSCAPE', 1, 1, 'C')
    
    pdf.add_page('P', 'A7')
    pdf.cell(0, 0, 'A7 PORTRAIT', 1, 1, 'C')
    
    pdf.add_page('L', 'A7')
    pdf.cell(0, 0, 'A7 LANDSCAPE', 1, 1, 'C')
    
    
    # --- test backward editing ---
    
    
    pdf.set_page(1, true)
    pdf.set_y(50)
    pdf.cell(0, 0, 'A4 test', 1, 1, 'C')
    
    pdf.set_page(2, true)
    pdf.set_y(50)
    pdf.cell(0, 0, 'A4 test', 1, 1, 'C')
    
    pdf.set_page(3, true)
    pdf.set_y(50)
    pdf.cell(0, 0, 'A5 test', 1, 1, 'C')
    
    pdf.set_page(4, true)
    pdf.set_y(50)
    pdf.cell(0, 0, 'A5 test', 1, 1, 'C')
    
    pdf.set_page(5, true)
    pdf.set_y(50)
    pdf.cell(0, 0, 'A6 test', 1, 1, 'C')
    
    pdf.set_page(6, true)
    pdf.set_y(50)
    pdf.cell(0, 0, 'A6 test', 1, 1, 'C')
    
    pdf.set_page(7, true)
    pdf.set_y(40)
    pdf.cell(0, 0, 'A7 test', 1, 1, 'C')
    
    pdf.set_page(8, true)
    pdf.set_y(40)
    pdf.cell(0, 0, 'A7 test', 1, 1, 'C')
    
    pdf.last_page()
    
    # ---------------------------------------------------------
    
    # Close and output PDF document
    send_data pdf.output(), :type => "application/pdf", :disposition => "inline"
  end
end

#============================================================+
# END OF FILE                                                
#============================================================+
