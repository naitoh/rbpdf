# coding: UTF-8
#============================================================+
# Begin       : 2008-03-04
# Last Update : 2010-05-20
#
# Description : Example 022 for RBPDF class
#               CMYK colors
#
# Author: Jun NAITOH
# License: LGPL 2.1 or later
#============================================================+

require("example_common.rb")

class Example022Controller < ApplicationController
  def index
    # create new PDF document
    pdf = RBPDF.new(PDF_PAGE_ORIENTATION, PDF_UNIT, PDF_PAGE_FORMAT, true, 'UTF-8', false)
    
    # set document information
    pdf.set_creator(PDF_CREATOR)
    pdf.set_author(PDF_AUTHOR)
    pdf.set_title('RBPDF Example 022')
    pdf.set_subject('RBPDF Tutorial')
    pdf.set_keywords('RBPDF, PDF, example, test, guide')
    
    # set default header data
    pdf.set_header_data(PDF_HEADER_LOGO, PDF_HEADER_LOGO_WIDTH, PDF_HEADER_TITLE + ' 022', PDF_HEADER_STRING)
    
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
    
    # check also the following methods:
    # set_draw_colorArray()
    # set_fill_colorArray()
    # set_text_colorArray()
    
    # set font
    pdf.set_font('helvetica', 'B', 18)
    
    # add a page
    pdf.add_page()
    
    pdf.write(0, 'Example of CMYK, RGB and Grayscale colours', '', 0, 'L', true, 0, false, false, 0)
    
    # define style for border
    border_style = {'all' => {'width' => 2, 'cap' => 'square', 'join' => 'miter', 'dash' => 0, 'phase' => 0}}
    
    # --- CMYK ------------------------------------------------
    
    pdf.set_draw_color(50, 0, 0, 0)
    pdf.set_fill_color(100, 0, 0, 0)
    pdf.set_text_color(100, 0, 0, 0)
    pdf.rect(30, 60, 30, 30, 'DF', border_style)
    pdf.text(30, 92, 'Cyan')
    
    pdf.set_draw_color(0, 50, 0, 0)
    pdf.set_fill_color(0, 100, 0, 0)
    pdf.set_text_color(0, 100, 0, 0)
    pdf.rect(70, 60, 30, 30, 'DF', border_style)
    pdf.text(70, 92, 'Magenta')
    
    pdf.set_draw_color(0, 0, 50, 0)
    pdf.set_fill_color(0, 0, 100, 0)
    pdf.set_text_color(0, 0, 100, 0)
    pdf.rect(110, 60, 30, 30, 'DF', border_style)
    pdf.text(110, 92, 'Yellow')
    
    pdf.set_draw_color(0, 0, 0, 50)
    pdf.set_fill_color(0, 0, 0, 100)
    pdf.set_text_color(0, 0, 0, 100)
    pdf.rect(150, 60, 30, 30, 'DF', border_style)
    pdf.text(150, 92, 'Black')
    
    # --- RGB -------------------------------------------------
    
    pdf.set_draw_color(255, 127, 127)
    pdf.set_fill_color(255, 0, 0)
    pdf.set_text_color(255, 0, 0)
    pdf.rect(30, 110, 30, 30, 'DF', border_style)
    pdf.text(30, 142, 'Red')
    
    pdf.set_draw_color(127, 255, 127)
    pdf.set_fill_color(0, 255, 0)
    pdf.set_text_color(0, 255, 0)
    pdf.rect(70, 110, 30, 30, 'DF', border_style)
    pdf.text(70, 142, 'Green')
    
    pdf.set_draw_color(127, 127, 255)
    pdf.set_fill_color(0, 0, 255)
    pdf.set_text_color(0, 0, 255)
    pdf.rect(110, 110, 30, 30, 'DF', border_style)
    pdf.text(110, 142, 'Blue')
    
    # --- GRAY ------------------------------------------------
    
    pdf.set_draw_color(191)
    pdf.set_fill_color(127)
    pdf.set_text_color(127)
    pdf.rect(30, 160, 30, 30, 'DF', border_style)
    pdf.text(30, 192, 'Gray')
    
    # ---------------------------------------------------------
    
    # Close and output PDF document
    send_data pdf.output(), :type => "application/pdf", :disposition => "inline"
  end
end

#============================================================+
# END OF FILE
#============================================================+
