# coding: UTF-8
# frozen_string_literal: true
#============================================================+
# Begin       : 2008-03-04
# Last Update : 2010-05-20
#
# Description : Example 020 for RBPDF class
#               Two columns composed by MultiCell of different
#               heights
#
# Author: Jun NAITOH
# License: LGPL 2.1 or later
#============================================================+

require("example_common.rb")

class Example020Controller < ApplicationController
  # extend RBPDF with custom functions
  class MYPDF < RBPDF
    def multi_row(left, right)
      # multi_cell(w, h, txt, border=0, align='J', fill=0, ln=1, x='', y='', reseth=true, stretch=0)

      page_start = get_page()
      y_start = get_y()

      # write the left cell
      multi_cell(40, 0, left, 1, 'R', 1, 2, '', '', true, 0)

      page_end_1 = get_page()
      y_end_1 = get_y()

      set_page(page_start)

      # write the right cell
      multi_cell(0, 0, right, 1, 'J', 0, 1, get_x() ,y_start, true, 0)

      page_end_2 = get_page()
      y_end_2 = get_y()

      # set the new row position by case
      if [page_end_1,page_end_2].max == page_start
        ynew = [y_end_1, y_end_2].max
      elsif page_end_1 == page_end_2
        ynew = [y_end_1, y_end_2].max
      elsif page_end_1 > page_end_2
        ynew = y_end_1
      else
        ynew = y_end_2
      end

      set_page([page_end_1,page_end_2].max)
      set_xy(get_x(), ynew)
    end
  end
    
  def index
    # create new PDF document
    pdf = MYPDF.new(PDF_PAGE_ORIENTATION, PDF_UNIT, PDF_PAGE_FORMAT, true, 'UTF-8', false)
    
    # set document information
    pdf.set_creator(PDF_CREATOR)
    pdf.set_author(PDF_AUTHOR)
    pdf.set_title('RBPDF Example 020')
    pdf.set_subject('RBPDF Tutorial')
    pdf.set_keywords('RBPDF, PDF, example, test, guide')
    
    # set default header data
    pdf.set_header_data(PDF_HEADER_LOGO, PDF_HEADER_LOGO_WIDTH, PDF_HEADER_TITLE + ' 020', PDF_HEADER_STRING)
    
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
    
    pdf.write(0, 'Example of text layout using multi_cell()', '', 0, 'L', true, 0, false, false, 0)
    
    pdf.ln(5)
    
    pdf.set_font('times', '', 9)
    
    #pdf.set_cell_padding(0)
    #pdf.set_line_width(2)
    
    # set color for background
    pdf.set_fill_color(255, 255, 200)
    
    text = 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. In sed imperdiet lectus. Phasellus quis velit velit, non condimentum quam. Sed neque urna, ultrices ac volutpat vel, laoreet vitae augue. Sed vel velit erat. Class aptent taciti sociosqu ad litora torquent per conubia nostra, per inceptos himenaeos. Cras eget velit nila, eu sagittis elit. Nunc ac arcu est, in lobortis tellus. Praesent condimentum rhoncus sodales. In hac habitasse platea dictumst. Proin porta eros pharetra enim tincidunt dignissim nec vel dolor. Cras sapien elit, ornare ac dignissim eu, ultricies ac eros. Maecenas augue magna, ultrices a congue in, mollis eu nila. Nunc venenatis massa at est eleifend faucibus. Vivamus sed risus lectus, nec interdum nunc.

Fusce et felis vitae diam lobortis sollicitudin. Aenean tincidunt accumsan nisi, id vehicula quam laoreet elementum. Phasellus egestas interdum erat, et viverra ipsum ultricies ac. Praesent sagittis augue at augue volutpat eleifend. Cras nec orci neque. Mauris bibendum posuere blandit. Donec feugiat mollis dui sit amet pellentesque. Sed a enim justo. Donec tincidunt, nisl eget elementum aliquam, odio ipsum ultrices quam, eu porttitor ligula urna at lorem. Donec varius, eros et convallis laoreet, ligula tellus consequat felis, ut ornare metus tellus sodales velit. Duis sed diam ante. Ut rutrum malesuada massa, vitae consectetur ipsum rhoncus sed. Suspendisse potenti. Pellentesque a congue massa.'
    
    # print some rows just as example
    7.times do |i|
      pdf.multi_row('Row ' + (i+1).to_s, text + "\n")
    end
    
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
