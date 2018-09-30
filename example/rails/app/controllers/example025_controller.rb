# coding: UTF-8
#============================================================+
# Begin       : 2008-03-04
# Last Update : 2010-05-20
#
# Description : Example 025 for RBPDF class
#               Object Transparency
#
# Author: Jun NAITOH
# License: LGPL 2.1 or later
#============================================================+

require("example_common.rb")

class Example025Controller < ApplicationController
  def index
    # create new PDF document
    pdf = RBPDF.new(PDF_PAGE_ORIENTATION, PDF_UNIT, PDF_PAGE_FORMAT, true, 'UTF-8', false)
    
    # set document information
    pdf.set_creator(PDF_CREATOR)
    pdf.set_author(PDF_AUTHOR)
    pdf.set_title('RBPDF Example 025')
    pdf.set_subject('RBPDF Tutorial')
    pdf.set_keywords('RBPDF, PDF, example, test, guide')
    
    # set default header data
    pdf.set_header_data(PDF_HEADER_LOGO, PDF_HEADER_LOGO_WIDTH, PDF_HEADER_TITLE + ' 025', PDF_HEADER_STRING)
    
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
    pdf.set_auto_page_break(TRUE, PDF_MARGIN_BOTTOM)
    
    # set image scale factor
    pdf.set_image_scale(PDF_IMAGE_SCALE_RATIO)
    
    # set some language-dependent strings
    pdf.set_language_array($l)
    
    # ---------------------------------------------------------
    
    # set font
    pdf.set_font('helvetica', '', 12)
    
    # add a page
    pdf.add_page()
    
    txt = 'You can set the transparency of PDF objects using the set_alpha() method.'
    pdf.write(0, txt, '', 0, '', true, 0, false, false, 0)

    #
    # set_alpha() gives transparency support. You can set the
    # alpha channel from 0 (fully transparent) to 1 (fully
    # opaque). It applies to all elements (text, drawings, images).
    #

    pdf.set_line_width(2)
    
    # draw opaque red square
    pdf.set_fill_color(255, 0, 0)
    pdf.set_draw_color(127, 0, 0)
    pdf.rect(30, 40, 60, 60, 'DF')
    
    # set alpha to semi-transparency
    pdf.set_alpha(0.5)
    
    # draw green square
    pdf.set_fill_color(0, 255, 0)
    pdf.set_draw_color(0, 127, 0)
    pdf.rect(50, 60, 60, 60, 'DF')
    
    # draw blue square
    pdf.set_fill_color(0, 0, 255)
    pdf.set_draw_color(0, 0, 127)
    pdf.rect(70, 80, 60, 60, 'DF')
    
    # draw jpeg image
    pdf.image(PDF_IMAGE_DEMO_PNG, 90, 100, 60, 60, '', 'https://github.com/naitoh/rbpdf', '', true, 72)
    
    # restore full opacity
    pdf.set_alpha(1)
    
    # ---------------------------------------------------------
    
    # Close and output PDF document
    send_data pdf.output(), :type => "application/pdf", :disposition => "inline"
  end
end

#============================================================+
# END OF FILE
#============================================================+
