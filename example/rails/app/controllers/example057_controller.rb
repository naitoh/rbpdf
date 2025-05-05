# coding: UTF-8
# frozen_string_literal: true
#============================================================+
# Begin       : 2010-04-03
# Last Update : 2010-05-20
#
# Description : Example 057 for RBPDF class
#               Cell vertical alignments
#
# Author: Jun NAITOH
# License: LGPL 2.1 or later
#============================================================+

require("example_common.rb")

class Example057Controller < ApplicationController
  def index
    # create new PDF document
    pdf = RBPDF.new(PDF_PAGE_ORIENTATION, PDF_UNIT, PDF_PAGE_FORMAT, true, 'UTF-8', false)
    
    # set document information
    pdf.set_creator(PDF_CREATOR)
    pdf.set_author(PDF_AUTHOR)
    pdf.set_title('RBPDF Example 057')
    pdf.set_subject('RBPDF Tutorial')
    pdf.set_keywords('RBPDF, PDF, example, test, guide')
    
    # set default header data
    pdf.set_header_data(PDF_HEADER_LOGO, PDF_HEADER_LOGO_WIDTH, PDF_HEADER_TITLE + ' 057', PDF_HEADER_STRING)
    
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
    
    pdf.write(0, 'Example of alignment options for cell()', '', 0, 'L', true, 0, false, false, 0)
    
    pdf.set_font('helvetica', '', 11)
    
    # set border width
    pdf.set_line_width(0.7)
    
    # set color for cell border
    pdf.set_draw_color(0,128,255)
    
    pdf.set_cell_height_ratio(3)
    
    pdf.set_xy(15, 60)
    
    # text on center
    pdf.cell(30, 0, 'Top-Center', 1, ln=0, 'C', 0, '', 0, false, 'T', 'C')
    pdf.cell(30, 0, 'Center-Center', 1, ln=0, 'C', 0, '', 0, false, 'C', 'C')
    pdf.cell(30, 0, 'Bottom-Center', 1, ln=0, 'C', 0, '', 0, false, 'B', 'C')
    pdf.cell(30, 0, 'Ascent-Center', 1, ln=0, 'C', 0, '', 0, false, 'A', 'C')
    pdf.cell(30, 0, 'Baseline-Center', 1, ln=0, 'C', 0, '', 0, false, 'L', 'C')
    pdf.cell(30, 0, 'Descent-Center', 1, ln=0, 'C', 0, '', 0, false, 'D', 'C')
    
    
    pdf.set_xy(15, 90)
    
    # text on top
    pdf.cell(30, 0, 'Top-Top', 1, ln=0, 'C', 0, '', 0, false, 'T', 'T')
    pdf.cell(30, 0, 'Center-Top', 1, ln=0, 'C', 0, '', 0, false, 'C', 'T')
    pdf.cell(30, 0, 'Bottom-Top', 1, ln=0, 'C', 0, '', 0, false, 'B', 'T')
    pdf.cell(30, 0, 'Ascent-Top', 1, ln=0, 'C', 0, '', 0, false, 'A', 'T')
    pdf.cell(30, 0, 'Baseline-Top', 1, ln=0, 'C', 0, '', 0, false, 'L', 'T')
    pdf.cell(30, 0, 'Descent-Top', 1, ln=0, 'C', 0, '', 0, false, 'D', 'T')
    
    
    pdf.set_xy(15, 120)
    
    # text on bottom
    pdf.cell(30, 0, 'Top-Bottom', 1, ln=0, 'C', 0, '', 0, false, 'T', 'B')
    pdf.cell(30, 0, 'Center-Bottom', 1, ln=0, 'C', 0, '', 0, false, 'C', 'B')
    pdf.cell(30, 0, 'Bottom-Bottom', 1, ln=0, 'C', 0, '', 0, false, 'B', 'B')
    pdf.cell(30, 0, 'Ascent-Bottom', 1, ln=0, 'C', 0, '', 0, false, 'A', 'B')
    pdf.cell(30, 0, 'Baseline-Bottom', 1, ln=0, 'C', 0, '', 0, false, 'L', 'B')
    pdf.cell(30, 0, 'Descent-Bottom', 1, ln=0, 'C', 0, '', 0, false, 'D', 'B')
    
    
    # draw some reference lines
    linestyle = {'width' => 0.1, 'cap' => 'butt', 'join' => 'miter', 'dash' => '', 'phase' => 0, 'color' => [255, 0, 0]}
    pdf.line(15, 60, 195, 60, linestyle)
    pdf.line(15, 90, 195, 90, linestyle)
    pdf.line(15, 120, 195, 120, linestyle)
    
    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    
    # reset pointer to the last page
    pdf.last_page()
    
    # ---------------------------------------------------------
    
    # Close and output PDF document
    send_data pdf.output(), :type => "application/pdf", :disposition => "inline"
  end
end

#============================================================+
# END OF FILE
#============================================================+
