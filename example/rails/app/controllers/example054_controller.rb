# coding: UTF-8
# frozen_string_literal: true
#============================================================+
# Begin       : 2009-09-07
# Last Update : 2010-06-02
#
# Description : Example 054 for TCPDF class
#               XHTML Forms
#
# Author: Jun NAITOH
# License: LGPL 2.1 or later
#============================================================+

require("example_common.rb")

class Example054Controller < ApplicationController
  def index
    # create new PDF document
    pdf = RBPDF.new(PDF_PAGE_ORIENTATION, PDF_UNIT, PDF_PAGE_FORMAT, true, 'UTF-8', false)

    # set document information
    pdf.set_creator(PDF_CREATOR)
    pdf.set_author(PDF_AUTHOR)
    pdf.set_title('RBPDF Example 054')
    pdf.set_subject('RBPDF Tutorial')
    pdf.set_keywords('RBPDF, PDF, example, test, guide')

    # set default header data
    pdf.set_header_data(PDF_HEADER_LOGO, PDF_HEADER_LOGO_WIDTH, PDF_HEADER_TITLE + ' 054', PDF_HEADER_STRING)

    # set header and footer fonts
    pdf.set_header_font([PDF_FONT_NAME_MAIN, '', PDF_FONT_SIZE_MAIN])
    pdf.set_header_font([PDF_FONT_NAME_MAIN, '', PDF_FONT_SIZE_DATA])

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
    # IMPORTANT: disable font subsetting to allow users editing the document
    pdf.set_font('helvetica', '', 10)

    # add a page
    pdf.add_page()

    # create some HTML content
    html = <<~EOD
    <h1>XHTML Form Example</h1>
    <form method="post" action="http://localhost/printvars" enctype="multipart/form-data">
    <label for="name">name:</label> <input type="text" name="name" value="test@example.net" size="20" maxlength="30" /><br />
    <label for="password">password:</label> <input type="password" name="password" value="" size="20" maxlength="30" /><br /><br />
    <label for="infile">file:</label> <input type="file" name="userfile" size="20" /><br /><br />
    <input type="checkbox" name="agree" value="1" checked="checked"/> <label for="agree">I agree </label><br /><br />
    <input type="checkbox" name="consent" value="1"/> <label for="consent">I consent </label><br /><br />
    <input type="radio" name="radioquestion" id="rqa" value="1" /> <label for="rqa">one</label><br />
    <input type="radio" name="radioquestion" id="rqb" value="2" checked="checked"/> <label for="rqb">two</label><br />
    <input type="radio" name="radioquestion" id="rqc" value="3" /> <label for="rqc">three</label><br /><br />
    <label for="selection">select:</label>
    <select name="selection" size="0">
        <option value="0">zero</option>
        <option value="1">one</option>
        <option value="2">two</option>
        <option value="3">three</option>
    </select><br /><br />
    <label for="selection">select:</label>
    <select name="multiselection" size="2" multiple="multiple">
        <option value="0">zero</option>
        <option value="1">one</option>
        <option value="2">two</option>
        <option value="3">three</option>
    </select><br /><br /><br />
    <label for="text">text area:</label><br />
    <textarea cols="40" rows="3" name="text">line one
    line two</textarea><br />
    <br /><br /><br />
    <input type="reset" name="reset" value="Reset" />
    <input type="submit" name="submit" value="Submit" />
    <input type="button" name="print" value="Print" onclick="print()" />
    <input type="hidden" name="hiddenfield" value="OK" />
    <br />
    </form>
    EOD

    # output the HTML content
    pdf.write_html(html, true, 0, true, 0)

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
