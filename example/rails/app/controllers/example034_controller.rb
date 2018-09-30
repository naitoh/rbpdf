# coding: UTF-8
#============================================================+
# Begin       : 2008-07-18
# Last Update : 2010-05-20
#
# Description : Example 034 for RBPDF class
#               Clipping
#
# Author: Jun NAITOH
# License: LGPL 2.1 or later
#============================================================+

require("example_common.rb")

class Example034Controller < ApplicationController
  def index
    # create new PDF document
    pdf = RBPDF.new(PDF_PAGE_ORIENTATION, PDF_UNIT, PDF_PAGE_FORMAT, true, 'UTF-8', false)
    
    # set document information
    pdf.set_creator(PDF_CREATOR)
    pdf.set_author(PDF_AUTHOR)
    pdf.set_title('RBPDF Example 034')
    pdf.set_subject('RBPDF Tutorial')
    pdf.set_keywords('RBPDF, PDF, example, test, guide')
    
    # set default header data
    pdf.set_header_data(PDF_HEADER_LOGO, PDF_HEADER_LOGO_WIDTH, PDF_HEADER_TITLE + ' 034', PDF_HEADER_STRING)
    
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
    
    pdf.write(0, 'Image Clipping using geometric functions', '', 0, 'C', 1, 0, false, false, 0)
    
    # Start Graphic Transformation
    pdf.start_transform()
    
    # set clipping mask
    pdf.star_polygon(105, 100, 30, 10, 3, 0, 1, 'CNZ')
    
    # draw jpeg image to be clipped
    pdf.image(PDF_IMAGE_DEMO_JPG, 75, 70, 60, 60, '', 'https://github.com/naitoh/rbpdf', '', true, 72)
    
    # Stop Graphic Transformation
    pdf.stop_transform()
    
    # ---------------------------------------------------------
    
    # Close and output PDF document
    send_data pdf.output(), :type => "application/pdf", :disposition => "inline"
  end
end
    
#============================================================+
# END OF FILE                                                
#============================================================+
