# coding: UTF-8
# frozen_string_literal: true
#============================================================+
# Begin       : 2008-03-04
# Last Update : 2010-05-20
#
# Description : Example 001 for RBPDF class
#               Default Header and Footer
#
# Author: Jun NAITOH
# License: LGPL 2.1 or later
#============================================================+

require("example_common.rb")

class Example001Controller < ApplicationController
  def index
    # create new PDF document
    pdf = RBPDF.new(PDF_PAGE_ORIENTATION, PDF_UNIT, PDF_PAGE_FORMAT, true, 'UTF-8', false)

    # set document information
    pdf.set_creator(PDF_CREATOR)
    pdf.set_author(PDF_AUTHOR)
    pdf.set_title('RBPDF Example 001')
    pdf.set_subject('RBPDF Tutorial')
    pdf.set_keywords('RBPDF, PDF, example, test, guide')

    # set default header data
    pdf.set_header_data(PDF_HEADER_LOGO, PDF_HEADER_LOGO_WIDTH, PDF_HEADER_TITLE + ' 001', PDF_HEADER_STRING)

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

    # Set font 
    # dejavusans is a UTF-8 Unicode font, if you only need to
    # print standard ASCII chars, you can use core fonts like
    # helvetica or times to reduce file size.
    pdf.set_font('dejavusans', '', 14)

    # Add a page
    # This method has several options, check the source code documentation for more information.
    pdf.add_page()

    # Set some content to print
    html = <<EOD
<h1>Welcome to <a href="https://github.com/naitoh/rbpdf" style="text-decoration:none;color:black;"><span style="background-color:#0099FF;"> RB<span style="color:white;">PDF</span> </span></a>!</h1>
<i>This is the first example of <a href="https://github.com/naitoh/rbpdf">RBPDF</a> library.</i>
<p>This text is printed using the <i>write_html_cell()</i> method but you can also use: <i>multi_cell(), write_html(), write(), cell() and text()</i>.</p>
<p style="color:#CC0000;">Please check the source code documentation and other examples for further information.</p>
EOD

    # Print text using write_html_cell()
    pdf.write_html_cell(0, 0, '', '', html, 0, 1, 0, true, '', true)

    # ---------------------------------------------------------

    # Close and output PDF document
    # This method has several options, check the source code documentation for more information.
    send_data pdf.output(), :type => "application/pdf", :disposition => "inline"
  end
end

#============================================================+
# END OF FILE                                                
#============================================================+
