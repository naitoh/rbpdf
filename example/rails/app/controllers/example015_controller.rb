# coding: UTF-8
# frozen_string_literal: true
#============================================================+
# Begin       : 2008-03-04
# Last Update : 2010-05-20
#
# Description : Example 015 for RBPDF class
#               Bookmarks (Table of Content)
#
# Author: Jun NAITOH
# License: LGPL 2.1 or later
#============================================================+

require("example_common.rb")

class Example015Controller < ApplicationController
  def index
    # create new PDF document
    pdf = RBPDF.new(PDF_PAGE_ORIENTATION, PDF_UNIT, PDF_PAGE_FORMAT, true, 'UTF-8', false)
    
    # set document information
    pdf.set_creator(PDF_CREATOR)
    pdf.set_author(PDF_AUTHOR)
    pdf.set_title('RBPDF Example 015')
    pdf.set_subject('RBPDF Tutorial')
    pdf.set_keywords('RBPDF, PDF, example, test, guide')
    
    # set default header data
    pdf.set_header_data(PDF_HEADER_LOGO, PDF_HEADER_LOGO_WIDTH, PDF_HEADER_TITLE + ' 015', PDF_HEADER_STRING)
    
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
    
    # bookmark(txt, level=0, y=-1, page='')
    
    # set font
    pdf.set_font('times', 'B', 20)
    
    # add a page
    pdf.add_page()
    
    # set a bookmark for the current position
    pdf.bookmark('Chapter 1', 0, 0)
    
    # print a line using cell()
    pdf.cell(0, 10, 'Chapter 1', 0, 1, 'L')
    
    pdf.set_font('times', 'I', 14)
    pdf.write(0, 'You can set PDF Bookmarks using the bookmark() method.')
    
    pdf.set_font('times', 'B', 20)
    
    # add other pages and bookmarks
    
    pdf.add_page()
    pdf.bookmark('Paragraph 1.1', 1, 0)
    pdf.cell(0, 10, 'Paragraph 1.1', 0, 1, 'L')
    
    pdf.add_page()
    pdf.bookmark('Paragraph 1.2', 1, 0)
    pdf.cell(0, 10, 'Paragraph 1.2', 0, 1, 'L')
    
    pdf.add_page()
    pdf.bookmark('Sub-Paragraph 1.2.1', 2, 0)
    pdf.cell(0, 10, 'Sub-Paragraph 1.2.1', 0, 1, 'L')
    
    pdf.add_page()
    pdf.bookmark('Paragraph 1.3', 1, 0)
    pdf.cell(0, 10, 'Paragraph 1.3', 0, 1, 'L')
    
    pdf.add_page()
    pdf.bookmark('Chapter 2', 0, 0)
    pdf.cell(0, 10, 'Chapter 2', 0, 1, 'L')
    
    pdf.add_page()
    pdf.bookmark('Chapter 3', 0, 0)
    pdf.cell(0, 10, 'Chapter 3', 0, 1, 'L')
    
    # ---------------------------------------------------------
    
    # Close and output PDF document
    send_data pdf.output(), :type => "application/pdf", :disposition => "inline"
  end
end

#============================================================+
# END OF FILE                                                
#============================================================+
