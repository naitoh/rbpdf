# coding: UTF-8
# frozen_string_literal: true
#============================================================+
# Begin       : 2008-03-04
# Last Update : 2010-05-20
#
# Description : Example 024 for RBPDF class
#               Object Visibility
#
# Author: Jun NAITOH
# License: LGPL 2.1 or later
#============================================================+

require("example_common.rb")

class Example024Controller < ApplicationController
  def index
    # create new PDF document
    pdf = RBPDF.new(PDF_PAGE_ORIENTATION, PDF_UNIT, PDF_PAGE_FORMAT, true, 'UTF-8', false)
    
    # set document information
    pdf.set_creator(PDF_CREATOR)
    pdf.set_author(PDF_AUTHOR)
    pdf.set_title('RBPDF Example 024')
    pdf.set_subject('RBPDF Tutorial')
    pdf.set_keywords('RBPDF, PDF, example, test, guide')
    
    # set default header data
    pdf.set_header_data(PDF_HEADER_LOGO, PDF_HEADER_LOGO_WIDTH, PDF_HEADER_TITLE + ' 024', PDF_HEADER_STRING)
    
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
    pdf.set_font('times', '', 18)
    
    # add a page
    pdf.add_page()
    
    #
    # set_visibility() allows to restrict the rendering of some
    # elements to screen or printout. This can be useful, for
    # instance, to put a background image or color that will
    # show on screen but won't print.
    #
    
    txt = 'You can limit the visibility of PDF objects to screen or printer by using the set_visibility() method.
Check the print preview of this document to display the alternative text.'
    
    pdf.write(0, txt, '', 0, '', true, 0, false, false, 0)
    
    # change font size
    pdf.set_font_size(40)
    
    # change text color
    pdf.set_text_color(0,63,127)
    
    # set visibility only for screen
    pdf.set_visibility('screen')
    
    # write something only for screen
    pdf.write(0, '[This line is for display]', '', 0, 'C', true, 0, false, false, 0)
    
    # set visibility only for print
    pdf.set_visibility('print')
    
    # change text color
    pdf.set_text_color(127,0,0)
    
    # write something only for print
    pdf.write(0, '[This line is for printout]', '', 0, 'C', true, 0, false, false, 0)
    
    # restore visibility
    pdf.set_visibility('all')
    
    # ---------------------------------------------------------
    
    # Close and output PDF document
    send_data pdf.output(), :type => "application/pdf", :disposition => "inline"
  end
end

#============================================================+
# END OF FILE                                                
#============================================================+
