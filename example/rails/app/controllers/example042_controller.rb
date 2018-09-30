# coding: UTF-8
#============================================================+
# Begin       : 2008-12-23
# Last Update : 2010-05-20
#
# Description : Example 042 for RBPDF class
#               Test Image with alpha channel
#
# Author: Jun NAITOH
# License: LGPL 2.1 or later
#============================================================+

require("example_common.rb")

class Example042Controller < ApplicationController
  def index
    # create new PDF document
    pdf = RBPDF.new(PDF_PAGE_ORIENTATION, PDF_UNIT, PDF_PAGE_FORMAT, true, 'UTF-8', false)
    
    # set document information
    pdf.set_creator(PDF_CREATOR)
    pdf.set_author(PDF_AUTHOR)
    pdf.set_title('RBPDF Example 042')
    pdf.set_subject('RBPDF Tutorial')
    pdf.set_keywords('RBPDF, PDF, example, test, guide')
    
    # set default header data
    pdf.set_header_data(PDF_HEADER_LOGO, PDF_HEADER_LOGO_WIDTH, PDF_HEADER_TITLE + ' 042', PDF_HEADER_STRING)
    
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
    
    # set JPEG quality
    #pdf.set_jpeg_quality(75)
    
    pdf.set_font('helvetica', '', 18)
    
    # add a page
    pdf.add_page()
    
    # create background text
    background_text = 'RBPDF test PNG Alpha Channel ' * 50
    
    pdf.multi_cell(0, 5, background_text, 0, 'J', 0, 2, '', '', true, 0, false)
    
    # --- Method (A) ------------------------------------------
    # the image() method recognizes the alpha channel embedded on the image:
    
    pdf.image(PDF_PNG_TEST_ALPHA_PNG, 50, 50, 100, '', '', 'https://github.com/naitoh/rbpdf', '', false, 300)
    
    # --- Method (B) ------------------------------------------
    # provide image + separate 8-bit mask
    
    # first embed mask image (w, h, x and y will be ignored, the image will be scaled to the target image's size)
    mask = pdf.image(PDF_PNG_TEST_MSK_ALPHA_PNG, 50, 140, 100, '', '', '', '', false, 300, '', true)
    
    # embed image, masked with previously embedded mask
    pdf.image(PDF_PNG_TEST_NON_ALPHA_PNG, 50, 140, 100, '', '', 'https://github.com/naitoh/rbpdf', '', false, 300, '', false, mask)
    
    # ---------------------------------------------------------
    
    # Close and output PDF document
    send_data pdf.output(), :type => "application/pdf", :disposition => "inline"
  end
end

#============================================================+
# END OF FILE                                                
#============================================================+
