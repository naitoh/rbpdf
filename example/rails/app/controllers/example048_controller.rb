# coding: UTF-8
# frozen_string_literal: true
#============================================================+
# Begin       : 2009-03-20
# Last Update : 2010-05-20
#
# Description : Example 048 for RBPDF class
#               HTML tables and table headers
#
# Author: Jun NAITOH
# License: LGPL 2.1 or later
#============================================================+

require("example_common.rb")

class Example048Controller < ApplicationController
  def index
    # create new PDF document
    pdf = RBPDF.new(PDF_PAGE_ORIENTATION, PDF_UNIT, PDF_PAGE_FORMAT, true, 'UTF-8', false)
    
    # set document information
    pdf.set_creator(PDF_CREATOR)
    pdf.set_author(PDF_AUTHOR)
    pdf.set_title('RBPDF Example 048')
    pdf.set_subject('RBPDF Tutorial')
    pdf.set_keywords('RBPDF, PDF, example, test, guide')
    
    # set default header data
    pdf.set_header_data(PDF_HEADER_LOGO, PDF_HEADER_LOGO_WIDTH, PDF_HEADER_TITLE + ' 048', PDF_HEADER_STRING)
    
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
    pdf.set_font('helvetica', 'B', 20)
    
    # add a page
    pdf.add_page()
    
    pdf.write(0, 'Example of HTML tables', '', 0, 'L', true, 0, false, false, 0)
    
    pdf.set_font('helvetica', '', 8)
    
    # -----------------------------------------------------------------------------
    
    tbl = <<EOD
    <table cellspacing="0" cellpadding="1" border="1">
        <tr>
            <td rowspan="3">COL 1 - ROW 1<br />COLSPAN 3</td>
            <td>COL 2 - ROW 1</td>
            <td>COL 3 - ROW 1</td>
        </tr>
        <tr>
        	<td rowspan="2">COL 2 - ROW 2 - COLSPAN 2<br />text line<br />text line<br />text line<br />text line</td>
        	<td>COL 3 - ROW 2</td>
        </tr>
        <tr>
           <td>COL 3 - ROW 3</td>
        </tr>
      
    </table>
EOD
    
    pdf.write_html(tbl, true, false, false, false, '')
    
    # -----------------------------------------------------------------------------
    
    tbl = <<EOD
    <table cellspacing="0" cellpadding="1" border="1">
        <tr>
            <td rowspan="3">COL 1 - ROW 1<br />COLSPAN 3<br />text line<br />text line<br />text line<br />text line<br />text line<br />text line</td>
            <td>COL 2 - ROW 1</td>
            <td>COL 3 - ROW 1</td>
        </tr>
        <tr>
        	<td rowspan="2">COL 2 - ROW 2 - COLSPAN 2<br />text line<br />text line<br />text line<br />text line</td>
        	 <td>COL 3 - ROW 2</td>
        </tr>
        <tr>
           <td>COL 3 - ROW 3</td>
        </tr>
      
    </table>
EOD
    
    pdf.write_html(tbl, true, false, false, false, '')
    
    # -----------------------------------------------------------------------------
    
    tbl = <<EOD
    <table cellspacing="0" cellpadding="1" border="1">
        <tr>
            <td rowspan="3">COL 1 - ROW 1<br />COLSPAN 3<br />text line<br />text line<br />text line<br />text line<br />text line<br />text line</td>
            <td>COL 2 - ROW 1</td>
            <td>COL 3 - ROW 1</td>
        </tr>
        <tr>
        	<td rowspan="2">COL 2 - ROW 2 - COLSPAN 2<br />text line<br />text line<br />text line<br />text line</td>
        	 <td>COL 3 - ROW 2<br />text line<br />text line</td>
        </tr>
        <tr>
           <td>COL 3 - ROW 3</td>
        </tr>
      
    </table>
EOD
    
    pdf.write_html(tbl, true, false, false, false, '')
    
    # -----------------------------------------------------------------------------
    
    tbl = <<EOD
    <table border="1">
    <tr>
    <th rowspan="3">Left column</th>
    <th colspan="5">Heading Column Span 5</th>
    <th colspan="9">Heading Column Span 9</th>
    </tr>
    <tr>
    <th rowspan="2">Rowspan 2<br />This is some text that fills the table cell.</th>
    <th colspan="2">span 2</th>
    <th colspan="2">span 2</th>
    <th rowspan="2">2 rows</th>
    <th colspan="8">Colspan 8</th>
    </tr>
    <tr>
    <th>1a</th>
    <th>2a</th>
    <th>1b</th>
    <th>2b</th>
    <th>1</th>
    <th>2</th>
    <th>3</th>
    <th>4</th>
    <th>5</th>
    <th>6</th>
    <th>7</th>
    <th>8</th>
    </tr>
    </table>
EOD
    
    pdf.write_html(tbl, true, false, false, false, '')
    
    # -----------------------------------------------------------------------------
    
    # Table with rowspans and THEAD
    tbl = <<EOD
    <table border="1" cellpadding="2" cellspacing="2">
    <thead>
     <tr style="background-color:#FFFF00;color:#0000FF;">
      <td width="30" align="center"><b>A</b></td>
      <td width="140" align="center"><b>XXXX</b></td>
      <td width="140" align="center"><b>XXXX</b></td>
      <td width="80" align="center"> <b>XXXX</b></td>
      <td width="80" align="center"><b>XXXX</b></td>
      <td width="45" align="center"><b>XXXX</b></td>
     </tr>
     <tr style="background-color:#FF0000;color:#FFFF00;">
      <td width="30" align="center"><b>B</b></td>
      <td width="140" align="center"><b>XXXX</b></td>
      <td width="140" align="center"><b>XXXX</b></td>
      <td width="80" align="center"> <b>XXXX</b></td>
      <td width="80" align="center"><b>XXXX</b></td>
      <td width="45" align="center"><b>XXXX</b></td>
     </tr>
    </thead>
     <tr>
      <td width="30" align="center">1.</td>
      <td width="140" rowspan="6">XXXX<br />XXXX<br />XXXX<br />XXXX<br />XXXX<br />XXXX<br />XXXX<br />XXXX</td>
      <td width="140">XXXX<br />XXXX</td>
      <td width="80">XXXX<br />XXXX</td>
      <td width="80">XXXX</td>
      <td align="center" width="45">XXXX<br />XXXX</td>
     </tr>
     <tr>
      <td width="30" align="center" rowspan="3">2.</td>
      <td width="140" rowspan="3">XXXX<br />XXXX</td>
      <td width="80">XXXX<br />XXXX</td>
      <td width="80">XXXX<br />XXXX</td>
      <td align="center" width="45">XXXX<br />XXXX</td>
     </tr>
     <tr>
      <td width="80">XXXX<br />XXXX<br />XXXX<br />XXXX</td>
      <td width="80">XXXX<br />XXXX</td>
      <td align="center" width="45">XXXX<br />XXXX</td>
     </tr>
     <tr>
      <td width="80" rowspan="2" >RRRRRR<br />XXXX<br />XXXX<br />XXXX<br />XXXX<br />XXXX<br />XXXX<br />XXXX</td>
      <td width="80">XXXX<br />XXXX</td>
      <td align="center" width="45">XXXX<br />XXXX</td>
     </tr>
     <tr>
      <td width="30" align="center">3.</td>
      <td width="140">XXXX1<br />XXXX</td>
      <td width="80">XXXX<br />XXXX</td>
      <td align="center" width="45">XXXX<br />XXXX</td>
     </tr>
     <tr>
      <td width="30" align="center">4.</td>
      <td width="140">XXXX<br />XXXX</td>
      <td width="80">XXXX<br />XXXX</td>
      <td width="80">XXXX<br />XXXX</td>
      <td align="center" width="45">XXXX<br />XXXX</td>
     </tr>
    </table>
EOD
    
    pdf.write_html(tbl, true, false, false, false, '')
    
    pdf.write_html(tbl, true, false, false, false, '')
    
    # -----------------------------------------------------------------------------
    
    # NON-BREAKING TABLE (nobr="true")
    
    tbl = <<EOD
    <table border="1" cellpadding="2" cellspacing="2" nobr="true">
     <tr>
      <th colspan="3" align="center">NON-BREAKING TABLE</th>
     </tr>
     <tr>
      <td>1-1</td>
      <td>1-2</td>
      <td>1-3</td>
     </tr>
     <tr>
      <td>2-1</td>
      <td>3-2</td>
      <td>3-3</td>
     </tr>
     <tr>
      <td>3-1</td>
      <td>3-2</td>
      <td>3-3</td>
     </tr>
    </table>
EOD
    
    pdf.write_html(tbl, true, false, false, false, '')
    
    # -----------------------------------------------------------------------------
    
    # NON-BREAKING ROWS (nobr="true")
    
    tbl = <<EOD
    <table border="1" cellpadding="2" cellspacing="2" align="center">
     <tr nobr="true">
      <th colspan="3">NON-BREAKING ROWS</th>
     </tr>
     <tr nobr="true">
      <td>ROW 1<br />COLUMN 1</td>
      <td>ROW 1<br />COLUMN 2</td>
      <td>ROW 1<br />COLUMN 3</td>
     </tr>
     <tr nobr="true">
      <td>ROW 2<br />COLUMN 1</td>
      <td>ROW 2<br />COLUMN 2</td>
      <td>ROW 2<br />COLUMN 3</td>
     </tr>
     <tr nobr="true">
      <td>ROW 3<br />COLUMN 1</td>
      <td>ROW 3<br />COLUMN 2</td>
      <td>ROW 3<br />COLUMN 3</td>
     </tr>
    </table>
EOD
    
    pdf.write_html(tbl, true, false, false, false, '')
    
    # -----------------------------------------------------------------------------
    
    # Close and output PDF document
    send_data pdf.output(), :type => "application/pdf", :disposition => "inline"
  end
end

#============================================================+
# END OF FILE                                                
#============================================================+
