# coding: UTF-8
# frozen_string_literal: true
#============================================================+
# Begin       : 2010-04-22
# Last Update : 2010-05-20
#
# Description : Example 058 for RBPDF class
#               SVG Image
#
# Author: Jun NAITOH
# License: LGPL 2.1 or later
#============================================================+

require("example_common.rb")

class Example058Controller < ApplicationController
  def index
    # create new PDF document
    pdf = RBPDF.new(PDF_PAGE_ORIENTATION, PDF_UNIT, PDF_PAGE_FORMAT, true, 'UTF-8', false)

    # set document information
    pdf.set_creator(PDF_CREATOR)
    pdf.set_author(PDF_AUTHOR)
    pdf.set_title('RBPDF Example 058')
    pdf.set_subject('RBPDF Tutorial')
    pdf.set_keywords('RBPDF, PDF, example, test, guide')

    # set default header data
    pdf.set_header_data(PDF_HEADER_LOGO, PDF_HEADER_LOGO_WIDTH, PDF_HEADER_TITLE + ' 058', PDF_HEADER_STRING)

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
    pdf.set_font('helvetica', '', 20)

    # add a page
    pdf.add_page()

    # NOTE: Uncomment the following line to rasterize SVG image using the ImageMagick library.
    # pdf.setRasterizeVectorImages(true);

    pdf.image_svg(PDF_SVG_TEST_TESTSVG, 15, 30, 0, 0, 'https://github.com/naitoh/rbpdf', '', '', 1, false)
    pdf.image_svg(PDF_SVG_TEST_TUX, 30, 100, 0, 100, '', '', '', 0, false)

    pdf.set_font('helvetica', '', 8)
    pdf.set_y(195)
    txt = '© The copyright holder of the above Tux image is Larry Ewing, allows anyone to use it for any purpose, provided that the copyright holder is properly attributed. Redistribution, derivative work, commercial use, and all other use is permitted.'
    pdf.write(0, txt, '', 0, 'L', true, 0, false, false, 0)

    # ---------------------------------------------------------

    # Close and output PDF document
    send_data pdf.output(), :type => "application/pdf", :disposition => "inline"
  end
end

#============================================================+
# END OF FILE
#============================================================+
