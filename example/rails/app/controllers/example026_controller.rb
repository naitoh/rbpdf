# coding: UTF-8
#============================================================+
# Begin       : 2008-03-04
# Last Update : 2010-05-20
#
# Description : Example 026 for RBPDF class
#               Text Rendering Modes and Text Clipping
#
# Author: Jun NAITOH
# License: LGPL 2.1 or later
#============================================================+

require("example_common.rb")

class Example026Controller < ApplicationController
  def index
    # create new PDF document
    pdf = RBPDF.new(PDF_PAGE_ORIENTATION, PDF_UNIT, PDF_PAGE_FORMAT, true, 'UTF-8', false)
    
    # set document information
    pdf.set_creator(PDF_CREATOR)
    pdf.set_author(PDF_AUTHOR)
    pdf.set_title('RBPDF Example 026')
    pdf.set_subject('RBPDF Tutorial')
    pdf.set_keywords('RBPDF, PDF, example, test, guide')
    
    # set default header data
    pdf.set_header_data(PDF_HEADER_LOGO, PDF_HEADER_LOGO_WIDTH, PDF_HEADER_TITLE + ' 026', PDF_HEADER_STRING)
    
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
    pdf.set_font('helvetica', '', 22)
    
    # add a page
    pdf.add_page()
    
    # set color for text stroke
    pdf.set_draw_color(255,0,0)
    
    
    pdf.set_text_rendering_mode(stroke=0, fill=true, clip=false)
    pdf.write(0, 'Fill text', '', 0, '', true, 0, false, false, 0)
    
    pdf.set_text_rendering_mode(stroke=0.2, fill=false, clip=false)
    pdf.write(0, 'Stroke text', '', 0, '', true, 0, false, false, 0)
    
    pdf.set_text_rendering_mode(stroke=0.2, fill=true, clip=false)
    pdf.write(0, 'Fill, then stroke text', '', 0, '', true, 0, false, false, 0)
    
    pdf.set_text_rendering_mode(stroke=0, fill=false, clip=false)
    pdf.write(0, 'Neither fill nor stroke text (invisible)', '', 0, '', true, 0, false, false, 0)
    
    
    # * * * CLIPPING MODES  * * * * * * * * * * * * * * * * * *
    
    pdf.start_transform()
    pdf.set_text_rendering_mode(stroke=0, fill=true, clip=true)
    pdf.write(0, 'Fill text and add to path for clipping', '', 0, '', true, 0, false, false, 0)
    pdf.image(PDF_IMAGE_DEMO_PNG, 15, 65, 170, 10, '', '', '', true, 72)
    pdf.stop_transform()
    
    pdf.start_transform()
    pdf.set_text_rendering_mode(stroke=0.3, fill=false, clip=true)
    pdf.write(0, 'Stroke text and add to path for clipping', '', 0, '', true, 0, false, false, 0)
    pdf.image(PDF_IMAGE_DEMO_PNG, 15, 75, 170, 10, '', '', '', true, 72)
    pdf.stop_transform()
    
    pdf.start_transform()
    pdf.set_text_rendering_mode(stroke=0.3, fill=true, clip=true)
    pdf.write(0, 'Fill, then stroke text and add to path for clipping', '', 0, '', true, 0, false, false, 0)
    pdf.image(PDF_IMAGE_DEMO_PNG, 15, 85, 170, 10, '', '', '', true, 72)
    pdf.stop_transform()
    
    pdf.start_transform()
    pdf.set_text_rendering_mode(stroke=0, fill=false, clip=true)
    pdf.write(0, 'Add text to path for clipping', '', 0, '', true, 0, false, false, 0)
    pdf.image(PDF_IMAGE_DEMO_PNG, 15, 95, 170, 10, '', '', '', true, 72)
    pdf.stop_transform()
    
    # reset text rendering mode
    pdf.set_text_rendering_mode(stroke=0, fill=true, clip=false)
    
    # * * * HTML MODE * * * * * * * * * * * * * * * * * * * * *
    
    # The following attributes were added to HTML:
    # stroke : stroke width
    # strokecolor : stroke color
    # fill : true (default) to fill the font, false otherwise
    
    
    # create some HTML content with text rendering modes
    html  = '<span stroke="0" fill="true">HTML Fill text</span><br />'
    html << '<span stroke="0.2" fill="false">HTML Stroke text</span><br />'
    html << '<span stroke="0.2" fill="true" strokecolor="#FF0000" color="#FFFF00">HTML Fill, then stroke text</span><br />'
    html << '<span stroke="0" fill="false">HTML Neither fill nor stroke text (invisible)</span><br />'
    
    # output the HTML content
    pdf.write_html(html, true, 0, true, 0)
    
    # ---------------------------------------------------------
    
    # Close and output PDF document
    send_data pdf.output(), :type => "application/pdf", :disposition => "inline"
  end
end

#============================================================+
# END OF FILE
#============================================================+
