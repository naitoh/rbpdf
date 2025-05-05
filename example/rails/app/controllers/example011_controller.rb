# coding: UTF-8
# frozen_string_literal: true
#============================================================+
# Begin       : 2008-03-04
# Last Update : 2010-05-20
#
# Description : Example 011 for RBPDF class
#               Colored Table
#
# Author: Jun NAITOH
# License: LGPL 2.1 or later
#============================================================+

require("example_common.rb")

class Example011Controller < ApplicationController
  # extend TCPF with custom functions
  class MYPDF < RBPDF
    # Load table data from file
    def LoadData(file)
      # Read file lines
      lines = File.open(file).readlines
      data = []
      lines.each {|line|
        data.push line.rstrip.split(';')
      }
      return data
    end
  
    # Colored table
    def ColoredTable(header,data)
      # Colors, line width and bold font
      set_fill_color(255, 0, 0)
      set_text_color(255)
      set_draw_color(128, 0, 0)
      set_line_width(0.3)
      set_font('', 'B')
      # Header
      w = [40, 35, 40, 45]
      num_headers = header.length
      num_headers.times do |i|
        cell(w[i], 7, header[i], 1, 0, 'C', 1)
      end
      ln()
      # Color and font restoration
      set_fill_color(224, 235, 255)
      set_text_color(0)
      set_font('')
      # Data
      fill = 0
      data.each {|row|
        cell(w[0], 6, row[0], 'LR', 0, 'L', fill)
        cell(w[1], 6, row[1], 'LR', 0, 'L', fill)
        cell(w[2], 6, number_with_delimiter(row[2], :delimiter => ","), 'LR', 0, 'R', fill)
        cell(w[3], 6, number_with_delimiter(row[3], :delimiter => ","), 'LR', 0, 'R', fill)
        ln()
        fill = fill == 0 ? 1 : 0
      }
      ww = w.inject {|sum,x| sum ? sum + x : x }
      cell(ww, 0, '', 'T')
    end
  end
    
  def index
    # create new PDF document
    pdf = MYPDF.new(PDF_PAGE_ORIENTATION, PDF_UNIT, PDF_PAGE_FORMAT, true, 'UTF-8', false)
    
    # set document information
    pdf.set_creator(PDF_CREATOR)
    pdf.set_author(PDF_AUTHOR)
    pdf.set_title('RBPDF Example 011')
    pdf.set_subject('RBPDF Tutorial')
    pdf.set_keywords('RBPDF, PDF, example, test, guide')
    
    # set default header data
    pdf.set_header_data(PDF_HEADER_LOGO, PDF_HEADER_LOGO_WIDTH, PDF_HEADER_TITLE + ' 011', PDF_HEADER_STRING)
    
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
    pdf.set_font('helvetica', '', 12)
    
    # add a page
    pdf.add_page()
    
    # Column titles
    header = ['Country', 'Capital', 'Area (sq km)', 'Pop. (thousands)']
    
    # Data loading
    data = pdf.LoadData(PDF_TABLE_DATA_DEMO_TXT)
    
    # print colored table
    pdf.ColoredTable(header, data)
    
    # ---------------------------------------------------------
    
    # Close and output PDF document
    send_data pdf.output(), :type => "application/pdf", :disposition => "inline"
  end
end

#============================================================+
# END OF FILE                                                
#============================================================+
