# coding: UTF-8
# frozen_string_literal: true
#============================================================+
# Begin       : 2009-04-16
# Last Update : 2010-05-20
#
# Description : Example 051 for RBPDF class
#               Full page background
#
# Author: Jun NAITOH
# License: LGPL 2.1 or later
#============================================================+

require("example_common.rb")

class Example051Controller < ApplicationController
  # Extend the RBPDF class to create custom Header and Footer
  class MYPDF < RBPDF
    # Page header
    def Header()
      # full background image
      # store current auto-page-break status
      bMargin = get_break_margin()
      auto_page_break = @auto_page_break
      set_auto_page_break(false, 0)
      img_file = "#{File.join(Rails.root, 'public')}/image_demo.png"
      image(img_file, 0, 0, 210, 297, '', '', '', false, 300, '', false, false, 0)
      # restore auto-page-break status
      set_auto_page_break(auto_page_break, bMargin)
    end
  end

  def index
    # create new PDF document
    pdf = MYPDF.new(PDF_PAGE_ORIENTATION, PDF_UNIT, PDF_PAGE_FORMAT, true, 'UTF-8', false)
    
    # set document information
    pdf.set_creator(PDF_CREATOR)
    pdf.set_author(PDF_AUTHOR)
    pdf.set_title('RBPDF Example 051')
    pdf.set_subject('RBPDF Tutorial')
    pdf.set_keywords('RBPDF, PDF, example, test, guide')
    
    # set header and footer fonts
    pdf.set_header_font([PDF_FONT_NAME_MAIN, '', PDF_FONT_SIZE_MAIN])
    
    # set default monospaced font
    pdf.set_default_monospaced_font(PDF_FONT_MONOSPACED)
    
    # set margins
    pdf.set_margins(PDF_MARGIN_LEFT, PDF_MARGIN_TOP, PDF_MARGIN_RIGHT)
    pdf.set_header_margin(0)
    pdf.set_footer_margin(0)
    
    # remove default footer
    pdf.set_print_footer(false)
    
    # set auto page breaks
    pdf.set_auto_page_break(TRUE, PDF_MARGIN_BOTTOM)
    
    # set image scale factor
    pdf.set_image_scale(PDF_IMAGE_SCALE_RATIO)
    
    # set some language-dependent strings
    pdf.set_language_array($l)
    
    # ---------------------------------------------------------
    
    # set font
    pdf.set_font('times', '', 48)
    
    # add a page
    pdf.add_page()
    
    # Print a text
    html = '<span style="background-color:yellow;color:blue;">&nbsp;PAGE 1&nbsp;</span>
    <p stroke="0.2" fill="true" strokecolor="yellow" color="blue" style="font-family:helvetica;font-weight:bold;font-size:26pt;">You can set a full page background.</p>'
    pdf.write_html(html, true, false, true, false, '')
    
    
    # add a page
    pdf.add_page()
    
    # Print a text
    html = '<span style="background-color:yellow;color:blue;">&nbsp;PAGE 2&nbsp;</span>'
    pdf.write_html(html, true, false, true, false, '')
    
    # ---------------------------------------------------------
    
    # Close and output PDF document
    send_data pdf.output(), :type => "application/pdf", :disposition => "inline"
  end
end

#============================================================+
# END OF FILE                                                
#============================================================+
