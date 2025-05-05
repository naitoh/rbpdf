# coding: UTF-8
# frozen_string_literal: true
#============================================================+
# Begin       : 2008-07-22
# Last Update : 2010-05-20
#
# Description : Example 035 for RBPDF class
#               Line styles with cells and multicells
#
# Author: Jun NAITOH
# License: LGPL 2.1 or later
#============================================================+

require("example_common.rb")

class Example035Controller < ApplicationController
  def index
    # create new PDF document
    pdf = RBPDF.new(PDF_PAGE_ORIENTATION, PDF_UNIT, PDF_PAGE_FORMAT, true, 'UTF-8', false)
    
    # set document information
    pdf.set_creator(PDF_CREATOR)
    pdf.set_author(PDF_AUTHOR)
    pdf.set_title('RBPDF Example 035')
    pdf.set_subject('RBPDF Tutorial')
    pdf.set_keywords('RBPDF, PDF, example, test, guide')
    
    # set default header data
    pdf.set_header_data(PDF_HEADER_LOGO, PDF_HEADER_LOGO_WIDTH, PDF_HEADER_TITLE + ' 035', PDF_HEADER_STRING)
    
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
    pdf.set_font('times', 'BI', 16)
    
    # add a page
    pdf.add_page()
    
    pdf.write(0, 'Example of set_line_style() method', '', 0, 'L', true, 0, false, false, 0)
    
    pdf.ln()
    
    pdf.set_line_style({'width' => 0.5, 'cap' => 'butt', 'join' => 'miter', 'dash' => 4, 'color' => [255, 0, 0]})
    pdf.set_fill_color(255,255,128)
    pdf.set_text_color(0,0,128)
    
    text="DUMMY"
    
    pdf.cell(0, 0, text, 1, 1, 'L', 1, 0)
    
    pdf.ln()
    
    pdf.set_line_style({'width' => 0.5, 'cap' => 'butt', 'join' => 'miter', 'dash' => 0, 'color' => [0, 0, 255]})
    pdf.set_fill_color(255,255,0)
    pdf.set_text_color(0,0,255)
    pdf.multi_cell(60, 4, text, 1, 'C', 1, 0)
    
    pdf.set_line_style({'width' => 0.5, 'cap' => 'butt', 'join' => 'miter', 'dash' => 0, 'color' => [255, 255, 0]})
    pdf.set_fill_color(0,0,255)
    pdf.set_text_color(255,255,0)
    pdf.multi_cell(60, 4, text, 'TB', 'C', 1, 0)
    
    pdf.set_line_style({'width' => 0.5, 'cap' => 'butt', 'join' => 'miter', 'dash' => 0, 'color' => [255, 0, 255]})
    pdf.set_fill_color(0,255,0)
    pdf.set_text_color(255,0,255)
    pdf.multi_cell(60, 4, text, 1, 'C', 1, 1)
    
    # ---------------------------------------------------------
    
    # Close and output PDF document
    send_data pdf.output(), :type => "application/pdf", :disposition => "inline"
  end
end

#============================================================+
# END OF FILE                                                
#============================================================+
