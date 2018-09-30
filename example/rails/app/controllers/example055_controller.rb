# coding: UTF-8
#============================================================+
# Begin       : 2009-10-21
# Last Update : 2010-05-20
#
# Description : Example 055 for RBPDF class
#               Display all characters available on core fonts.
#
# Author: Jun NAITOH
# License: LGPL 2.1 or later
#============================================================+

require("example_common.rb")

class Example055Controller < ApplicationController
  def index
    # create new PDF document
    pdf = RBPDF.new(PDF_PAGE_ORIENTATION, PDF_UNIT, PDF_PAGE_FORMAT, true, 'UTF-8', false)
    
    # set document information
    pdf.set_creator(PDF_CREATOR)
    pdf.set_author(PDF_AUTHOR)
    pdf.set_title('RBPDF Example 055')
    pdf.set_subject('RBPDF Tutorial')
    pdf.set_keywords('RBPDF, PDF, example, test, guide')
    
    # set default header data
    pdf.set_header_data(PDF_HEADER_LOGO, PDF_HEADER_LOGO_WIDTH, PDF_HEADER_TITLE + ' 055', PDF_HEADER_STRING)
    
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
    pdf.set_font('helvetica', '', 10)
    
    # add a page
    pdf.add_page()
    
    # array of core font names
    core_fonts = ['courier', 'helvetica', 'times', 'symbol', 'zapfdingbats']
    
    html = '<h1>Core Fonts Dump</h1>'
    
    # create one HTML table for each core font
    core_fonts.each { |font|
      # create HTML content
      html << '<table cellpadding="1" cellspacing="0" border="1" nobr="true" style="font-family:' + font + ';text-align:center;">'
      html << '<tr style="background-color:yellow;"><td colspan="16" style="font-family:helvetica;font-weight:bold">' + font.upcase + '</td></tr><tr>'
      # print each character
      256.times do |i|
        if (i > 0) and (i % 16 == 0)
          html << '</tr><tr>'
        end
        if i != 0
          chr = pdf.unichr(i)
        else
          chr = ''
        end
        # replace special characters
        chr.gsub!('<', '&lt;')
        chr.gsub!('>', '&gt;')
        html << '<td>' + chr + '</td>'
      end
      html << '</tr></table><br />&nbsp;<br />'
    }
    
    # output the HTML content
    pdf.write_html(html, true, false, true, false, '')
    
    # ---------------------------------------------------------
    
    # Close and output PDF document
    send_data pdf.output(), :type => "application/pdf", :disposition => "inline"
  end
end

#============================================================+
# END OF FILE                                                
#============================================================+
