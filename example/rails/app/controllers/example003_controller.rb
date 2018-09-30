# coding: UTF-8
#============================================================+
# Begin       : 2008-03-04
# Last Update : 2010-05-20
#
# Description : Example 003 for RBPDF class
#               Custom Header and Footer
#
# Author: Jun NAITOH
# License: LGPL 2.1 or later
#============================================================+

require("example_common.rb")
    
class Example003Controller < ApplicationController
  # Extend the RBPDF class to create custom Header and Footer
  class MYPDF < RBPDF
    # Page header
    def Header()
      # Logo
      image_file = PDF_EXAMPLE_LOGO
      Image(image_file, 10, 10, 15, '', 'PNG', '', 'T', false, 300, '', false, false, 0, false, false, false)
      # Set font
      set_font('helvetica', 'B', 20)
      # Title
      cell(0, 15, '<< RBPDF Example 003 >>', 0, 0, 'C', 0, '', 0, false, 'M', 'M')
    end
  
    # Page footer
    def Footer()
      # Position at 15 mm from bottom
      set_y(-15)
      # Set font
      set_font('helvetica', 'I', 8)
      # Page number
      cell(0, 10, 'Page ' + getAliasNumPage() + '/' + getAliasNbPages(), 0, 0, 'C', 0, '', 0, false, 'T', 'M')
    end
  end
    
  def index
    # create new PDF document
    pdf = MYPDF.new(PDF_PAGE_ORIENTATION, PDF_UNIT, PDF_PAGE_FORMAT, true, 'UTF-8', false)
    
    # set document information
    pdf.set_creator(PDF_CREATOR)
    pdf.set_author(PDF_AUTHOR)
    pdf.set_title('RBPDF Example 003')
    pdf.set_subject('RBPDF Tutorial')
    pdf.set_keywords('RBPDF, PDF, example, test, guide')
    
    # set default header data
    pdf.set_header_data(PDF_HEADER_LOGO, PDF_HEADER_LOGO_WIDTH, PDF_HEADER_TITLE +  PDF_HEADER_STRING)
    
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
    pdf.set_font('times', 'BI', 12)
    
    # add a page
    pdf.add_page()
    
    # set some text to print
    txt = <<EOD
RBPDF Example 003
    
Custom page header and footer are defined by extending the RBPDF class and overriding the Header() and Footer() methods.
EOD
    
    # print a block of text using write()
    pdf.write(h=0, txt, link='', fill=0, align='C', ln=true, stretch=0, firstline=false, firstblock=false, maxh=0)
    
    # ---------------------------------------------------------
    
    # Close and output PDF document
    send_data pdf.output(), :type => "application/pdf", :disposition => "inline"
  end
end

#============================================================+
# END OF FILE                                                
#============================================================+
