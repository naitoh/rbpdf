# coding: UTF-8
#============================================================+
# Begin       : 2008-10-16
# Last Update : 2010-05-20
#
# Description : Example 039 for RBPDF class
#               HTML justification
#
# Author: Jun NAITOH
# License: LGPL 2.1 or later
#============================================================+

require("example_common.rb")

class Example039Controller < ApplicationController
  def index
    # create new PDF document
    pdf = RBPDF.new(PDF_PAGE_ORIENTATION, PDF_UNIT, PDF_PAGE_FORMAT, true, 'UTF-8', false)
    
    # set document information
    pdf.set_creator(PDF_CREATOR)
    pdf.set_author(PDF_AUTHOR)
    pdf.set_title('RBPDF Example 039')
    pdf.set_subject('RBPDF Tutorial')
    pdf.set_keywords('RBPDF, PDF, example, test, guide')
    
    # set default header data
    pdf.set_header_data(PDF_HEADER_LOGO, PDF_HEADER_LOGO_WIDTH, PDF_HEADER_TITLE + ' 039', PDF_HEADER_STRING)
    
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
    
    # add a page
    pdf.add_page()
    
    # set font
    pdf.set_font('helvetica', 'B', 20)
    
    pdf.write(0, 'Example of HTML Justification', '', 0, 'L', true, 0, false, false, 0)
    
    # create some HTML content
    html = '<span style="text-align:justify;">a <u>abc</u> abcdefghijkl abcdef abcdefg <b>abcdefghi</b> a abc abcd <img src="' + PDF_EXAMPLE_LOGO + '" border="0" height="41" width="41" /> <img src="' + PDF_TIGER_AI + '" alt="test alt attribute" width="100" height="100" border="0" /> abcdef abcdefg <b>abcdefghi</b> a abc abcd abcdef abcdefg <b>abcdefghi</b> a abc abcd abcdef abcdefg <b>abcdefghi</b> a <u>abc</u> abcd abcdef abcdefg <b>abcdefghi</b> a abc abcd abcdef abcdefg <b>abcdefghi</b> a abc abcd abcdef abcdefg <b>abcdefghi</b> a abc abcd abcdef abcdefg <b>abcdefghi</b> a abc abcd abcdef abcdefg <b>abcdefghi</b> a abc abcd abcdef abcdefg abcdefghi a abc abcd <a href="https://github.com/naitoh/rbpdf">abcdef abcdefg</a> start a abc before <span style="background-color:yellow">yellow color</span> after a abc abcd abcdef abcdefg abcdefghi a abc abcd end abcdefg abcdefghi a abc abcd abcdef abcdefg abcdefghi a abc abcd abcdef abcdefg abcdefghi a abc abcd abcdef abcdefg abcdefghi a abc abcd abcdef abcdefg abcdefghi a abc abcd abcdef abcdefg abcdefghi a abc abcd abcdef abcdefg abcdefghi a abc abcd abcdef abcdefg abcdefghi<br />abcd abcdef abcdefg abcdefghi<br />abcd abcde abcdef</span>'
    
    # set core font
    pdf.set_font('helvetica', '', 10)
    
    # output the HTML content
    pdf.write_html(html, true, 0, true, true)
    
    pdf.ln()
    
    # set UTF-8 Unicode font
    pdf.set_font('dejavusans', '', 10)
    
    # output the HTML content
    pdf.write_html(html, true, 0, true, true)
    
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
