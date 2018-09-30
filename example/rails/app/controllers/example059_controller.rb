# coding: UTF-8
#============================================================+
# Begin       : 2010-05-06
# Last Update : 2010-05-20
#
# Description : Example 059 for RBPDF class
#               Table Of Content using HTML templates.
#
# Author: Jun NAITOH
# License: LGPL 2.1 or later
#============================================================+

require("example_common.rb")

class Example059Controller < ApplicationController
  class TOC_RBPDF < RBPDF
    #
    # Overwrite Header() method.
    # @access public
    #
    def Header()
      if @tocpage
        # *** replace the following super() with your code for TOC page
        super()
      else
        # *** replace the following super() with your code for normal pages
        super()
      end
    end

    #
    # Overwrite Footer() method.
    # @access public
    #
    def Footer()
      if @tocpage
        # *** replace the following super() with your code for TOC page
        super()
      else
        # *** replace the following super() with your code for normal pages
        super()
      end
    end
  end # end of class
    
  def index
    # create new PDF document
    pdf = TOC_RBPDF.new(PDF_PAGE_ORIENTATION, PDF_UNIT, PDF_PAGE_FORMAT, true, 'UTF-8', false)
    
    # set document information
    pdf.set_creator(PDF_CREATOR)
    pdf.set_author(PDF_AUTHOR)
    pdf.set_title('RBPDF Example 059')
    pdf.set_subject('RBPDF Tutorial')
    pdf.set_keywords('RBPDF, PDF, example, test, guide')
    
    # set default header data
    pdf.set_header_data(PDF_HEADER_LOGO, PDF_HEADER_LOGO_WIDTH, PDF_HEADER_TITLE + ' 059', PDF_HEADER_STRING)
    
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
    
    # set font
    pdf.set_font('helvetica', '', 10)
    
    # ---------------------------------------------------------
    
    # create some content ...
    
    # add a page
    pdf.add_page()
    
    # set a bookmark for the current position
    pdf.bookmark('Chapter 1', 0, 0)
    
    # print a line using cell()
    pdf.cell(0, 10, 'Chapter 1', 0, 1, 'L')
    
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
    
    2.upto(11) do |i|
      pdf.add_page()
      pdf.bookmark('Chapter ' + i.to_s, 0, 0)
      pdf.cell(0, 10, 'Chapter ' + i.to_s, 0, 1, 'L')
    end
    
    # . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .
    
    
    # add a new page for TOC
    pdf.add_toc_page()
    
    # write the TOC title and/or other elements on the TOC page
    pdf.set_font('times', 'B', 16)
    pdf.multi_cell(0, 0, 'Table Of Content', 0, 'C', 0, 1, '', '', true, 0)
    pdf.ln()
    pdf.set_font('helvetica', '', 10)
    
    # define styles for various bookmark levels
    bookmark_templates = []
    
    #
    # The key of the bookmark_templates array represent the bookmark level (from 0 to n).
    # The following templates will be replaced with proper content:
    #     #TOC_DESCRIPTION#    this will be replaced with the bookmark description;
    #     #TOC_PAGE_NUMBER#    this will be replaced with page number.
    #
    # NOTES:
    #     If you want to align the page number on the right you have to use a monospaced font like courier, otherwise you can left align using any font type.
    #     The following is just an example, you can get various styles by combining various HTML elements.
    #
    
    # A monospaced font for the page number is mandatory to get the right alignment
    bookmark_templates[0] = '<table border="0" cellpadding="0" cellspacing="0" style="background-color:#EEFAFF"><tr><td width="165mm"><span style="font-family:times;font-weight:bold;font-size:12pt;color:black;">#TOC_DESCRIPTION#</span></td><td width="15mm"><span style="font-family:courier;font-weight:bold;font-size:12pt;color:black;" align="right">#TOC_PAGE_NUMBER#</span></td></tr></table>'
    bookmark_templates[1] = '<table border="0" cellpadding="0" cellspacing="0"><tr><td width="5mm">&nbsp;</td><td width="160mm"><span style="font-family:times;font-size:11pt;color:green;">#TOC_DESCRIPTION#</span></td><td width="15mm"><span style="font-family:courier;font-weight:bold;font-size:11pt;color:green;" align="right">#TOC_PAGE_NUMBER#</span></td></tr></table>'
    bookmark_templates[2] = '<table border="0" cellpadding="0" cellspacing="0"><tr><td width="10mm">&nbsp;</td><td width="155mm"><span style="font-family:times;font-size:10pt;color:#666666;"><i>#TOC_DESCRIPTION#</i></span></td><td width="15mm"><span style="font-family:courier;font-weight:bold;font-size:10pt;color:#666666;" align="right">#TOC_PAGE_NUMBER#</span></td></tr></table>'
    # add other bookmark level templates here ...
    
    # add table of content at page 1
    # (check the example n. 45 for a text-only TOC
    pdf.add_html_toc(1, 'INDEX', bookmark_templates, true)
    
    # end of TOC page
    pdf.end_toc_page()
    
    # . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .
    
    # ---------------------------------------------------------
    
    # Close and output PDF document
    send_data pdf.output(), :type => "application/pdf", :disposition => "inline"
  end
end

#============================================================+
# END OF FILE
#============================================================+
