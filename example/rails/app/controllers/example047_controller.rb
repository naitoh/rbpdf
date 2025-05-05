# coding: UTF-8
# frozen_string_literal: true
#============================================================+
# Begin       : 2009-03-19
# Last Update : 2010-05-20
#
# Description : Example 047 for RBPDF class
#               Transactions
#
# Author: Jun NAITOH
# License: LGPL 2.1 or later
#============================================================+

require("example_common.rb")

class Example047Controller < ApplicationController
  def index
    # create new PDF document
    pdf = RBPDF.new(PDF_PAGE_ORIENTATION, PDF_UNIT, PDF_PAGE_FORMAT, true, 'UTF-8', false)
    
    # set document information
    pdf.set_creator(PDF_CREATOR)
    pdf.set_author(PDF_AUTHOR)
    pdf.set_title('RBPDF Example 047')
    pdf.set_subject('RBPDF Tutorial')
    pdf.set_keywords('RBPDF, PDF, example, test, guide')
    
    # set default header data
    pdf.set_header_data(PDF_HEADER_LOGO, PDF_HEADER_LOGO_WIDTH, PDF_HEADER_TITLE + ' 047', PDF_HEADER_STRING)
    
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
    pdf.set_font('helvetica', '', 16)
    
    # add a page
    pdf.add_page()
    
    txt = 'Example of Transactions.
RBPDF allows you to undo some operations using the Transactions.
Check the source code for further information.'
    pdf.write(0, txt, '', 0, 'L', true, 0, false, false, 0)
    
    pdf.ln(5)
    
    pdf.set_font('times', '', 12)
    
    # start transaction
    pdf.start_transaction()
    
    pdf.write(0, "LINE 1\n")
    pdf.write(0, "LINE 2\n")
    
    # restarts transaction
    pdf.start_transaction()
    
    pdf.write(0, "LINE 3\n")
    pdf.write(0, "LINE 4\n")
    
    # rolls back to the last (re)start
    pdf = pdf.rollback_transaction()
    
    pdf.write(0, "LINE 5\n")
    pdf.write(0, "LINE 6\n")
    
    # start transaction
    pdf.start_transaction()
    
    pdf.write(0, "LINE 7\n")
    
    # commit transaction (actually just frees memory)
    pdf.commit_transaction(); 
    
    # ---------------------------------------------------------
    
    # Close and output PDF document
    send_data pdf.output(), :type => "application/pdf", :disposition => "inline"
  end
end

#============================================================+
# END OF FILE                                                
#============================================================+
