# coding: UTF-8
# frozen_string_literal: true
#============================================================+
# Begin       : 2008-03-04
# Last Update : 2010-05-20
#
# Description : Example 006 for RBPDF class
#               write_html and RTL support
#
# Author: Jun NAITOH
# License: LGPL 2.1 or later
#============================================================+

require("example_common.rb")
    
class Example006Controller < ApplicationController
  require 'htmlcolors.rb'
  include Html_colors
  def index
    # create new PDF document
    pdf = RBPDF.new(PDF_PAGE_ORIENTATION, PDF_UNIT, PDF_PAGE_FORMAT, true, 'UTF-8', false)
    
    # set document information
    pdf.set_creator(PDF_CREATOR)
    pdf.set_author(PDF_AUTHOR)
    pdf.set_title('RBPDF Example 006')
    pdf.set_subject('RBPDF Tutorial')
    pdf.set_keywords('RBPDF, PDF, example, test, guide')
    
    # set default header data
    pdf.set_header_data(PDF_HEADER_LOGO, PDF_HEADER_LOGO_WIDTH, PDF_HEADER_TITLE + ' 006', PDF_HEADER_STRING)
    
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
    pdf.set_font('dejavusans', '', 10)
    
    # add a page
    pdf.add_page()
    
    # write_html(html, ln=true, fill=false, reseth=false, cell=false, align='')
    # write_html_cell(w, h, x, y, html='', border=0, ln=0, fill=0, reseth=true, align='', autopadding=true)
    
    # create some HTML content
    html = '<h1>HTML Example</h1>
    Some special characters: &lt; € &euro; &#8364; &amp; è &egrave; &copy; &gt; \\slash \\\\double-slash \\\\\\triple-slash
    <h2>List</h2>
    List example:
    <ol>
    	<li><img src="' + PDF_EXAMPLE_LOGO + '" alt="test alt attribute" width="30" height="30" border="0" /> test image</li>
    	<li><b>bold text</b></li>
    	<li><i>italic text</i></li>
    	<li><u>underlined text</u></li>
    	<li><b>b<i>bi<u>biu</u>bi</i>b</b></li>
    	<li><a href="https://github.com/naitoh/rbpdf" dir="ltr">link to https://github.com/naitoh/rbpdf</a></li>
    	<li>Sed ut perspiciatis unde omnis iste natus error sit voluptatem accusantium doloremque laudantium, totam rem aperiam, eaque ipsa quae ab illo inventore veritatis et quasi architecto beatae vitae dicta sunt explicabo.<br />Nemo enim ipsam voluptatem quia voluptas sit aspernatur aut odit aut fugit, sed quia consequuntur magni dolores eos qui ratione voluptatem sequi nesciunt.</li>
    	<li>SUBLIST
    		<ol>
    			<li>row one
    				<ul>
    					<li>sublist</li>
    				</ul>
    			</li>
    			<li>row two</li>
    		</ol>
    	</li>
    	<li><b>T</b>E<i>S</i><u>T</u> <del>line through</del></li>
    	<li><font size="+3">font + 3</font></li>
    	<li><small>small text</small> normal <small>small text</small> normal <sub>subscript</sub> normal <sup>superscript</sup> normal</li>
    </ol>
    <dl>
    	<dt>Coffee</dt>
    	<dd>Black hot drink</dd>
    	<dt>Milk</dt>
    	<dd>White cold drink</dd>
    </dl>
    <div style="text-align:center">IMAGES<br />
    <img src="' + PDF_EXAMPLE_LOGO + '" alt="test alt attribute" width="100" height="100" border="0" /><img src="' + PDF_TIGER_AI + '" alt="test alt attribute" width="100" height="100" border="0" /><img src="' + PDF_EXAMPLE_LOGO+ '" alt="test alt attribute" width="100" height="100" border="0" />
    </div>'
    
    # output the HTML content
    pdf.write_html(html, true, false, true, false, '')
    
    
    # output some RTL HTML content
    html = '<div style="text-align:center">The words &#8220;<span dir="rtl">&#1502;&#1494;&#1500; [mazel] &#1496;&#1493;&#1489; [tov]</span>&#8221; mean &#8220;Congratulations!&#8221;</div>'
    pdf.write_html(html, true, false, true, false, '')
    
    # test some inline CSS
    html = '<p>This is just an example of html code to demonstrate some supported CSS inline styles.
    <span style="font-weight: bold;">bold text</span>
    <span style="text-decoration: line-through;">line-trough</span>
    <span style="text-decoration: underline line-through;">underline and line-trough</span>
    <span style="color: rgb(0, 128, 64);">color</span>
    <span style="background-color: rgb(255, 0, 0); color: rgb(255, 255, 255);">background color</span>
    <span style="font-weight: bold;">bold</span>
    <span style="font-size: xx-small;">xx-small</span>
    <span style="font-size: x-small;">x-small</span>
    <span style="font-size: small;">small</span>
    <span style="font-size: medium;">medium</span>
    <span style="font-size: large;">large</span>
    <span style="font-size: x-large;">x-large</span>
    <span style="font-size: xx-large;">xx-large</span>
    </p>'
    
    pdf.write_html(html, true, false, true, false, '')
    
    # reset pointer to the last page
    pdf.last_page()
    
    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    # Print a table
    
    # add a page
    pdf.add_page()
    
    # create some HTML content
    subtable = '<table border="1" cellspacing="1" cellpadding="1"><tr><td>a</td><td>b</td></tr><tr><td>c</td><td>d</td></tr></table>'
    
    html = '<h2>HTML TABLE:</h2>
    <table border="1" cellspacing="2" cellpadding="2">
    	<tr>
    		<th>#</th>
    		<th align="right">RIGHT align</th>
    		<th align="left">LEFT align</th>
    		<th>4A</th>
    	</tr>
    	<tr>
    		<td>1</td>
    		<td bgcolor="#cccccc" align="center" colspan="2">A1 ex<i>amp</i>le <a href="https://github.com/naitoh/rbpdf">link</a> column span. One two tree four five six seven eight nine ten.<br />line after br<br /><small>small text</small> normal <sub>subscript</sub> normal <sup>superscript</sup> normal  bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla<ol><li>first<ol><li>sublist</li><li>sublist</li></ol></li><li>second</li></ol><small color="#FF0000" bgcolor="#FFFF00">small small small small small small small small small small small small small small small small small small small small</small></td>
    		<td>4B</td>
    	</tr>
    	<tr>
    		<td>' + subtable + '</td>
    		<td bgcolor="#0000FF" color="yellow" align="center">A2 € &euro; &#8364; &amp; è &egrave;<br/>A2 € &euro; &#8364; &amp; è &egrave;</td>
    		<td bgcolor="#FFFF00" align="left"><font color="#FF0000">Red</font> Yellow BG</td>
    		<td>4C</td>
    	</tr>
    	<tr>
    		<td>1A</td>
    		<td rowspan="2" colspan="2" bgcolor="#FFFFCC">2AA<br />2AB<br />2AC</td>
    		<td bgcolor="#FF0000">4D</td>
    	</tr>
    	<tr>
    		<td>1B</td>
    		<td>4E</td>
    	</tr>
    	<tr>
    		<td>1C</td>
    		<td>2C</td>
    		<td>3C</td>
    		<td>4F</td>
    	</tr>
    </table>'
    
    # output the HTML content
    pdf.write_html(html, true, false, true, false, '')
    
    # Print some HTML Cells
    
    html = '<span color="red">red</span> <span color="green">green</span> <span color="blue">blue</span><br /><span color="red">red</span> <span color="green">green</span> <span color="blue">blue</span>'
    
    pdf.set_fill_color(255,255,0)
    
    pdf.write_html_cell(0, 0, '', '', html, 'LRTB', 1, 0, true, 'L', true)
    pdf.write_html_cell(0, 0, '', '', html, 'LRTB', 1, 1, true, 'C', true)
    pdf.write_html_cell(0, 0, '', '', html, 'LRTB', 1, 0, true, 'R', true)
    
    # reset pointer to the last page
    pdf.last_page()
    
    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    # Print a table
    
    # add a page
    pdf.add_page()
    
    # create some HTML content
    html = '<h1>Image alignments on HTML table</h1>
    <table cellpadding="1" cellspacing="1" border="1" style="text-align:center;">
    <tr><td><img src="' + PDF_EXAMPLE_LOGO + '" border="0" height="41" width="41" /></td></tr>
    <tr style="text-align:left;"><td><img src="' + PDF_EXAMPLE_LOGO + '" border="0" height="41" width="41" align="top" /></td></tr>
    <tr style="text-align:center;"><td><img src="' + PDF_EXAMPLE_LOGO + '" border="0" height="41" width="41" align="middle" /></td></tr>
    <tr style="text-align:right;"><td><img src="' + PDF_EXAMPLE_LOGO + '" border="0" height="41" width="41" align="bottom" /></td></tr>
    <tr><td style="text-align:left;"><img src="' + PDF_EXAMPLE_LOGO + '" border="0" height="41" width="41" align="top" /></td></tr>
    <tr><td style="text-align:center;"><img src="' + PDF_EXAMPLE_LOGO + '" border="0" height="41" width="41" align="middle" /></td></tr>
    <tr><td style="text-align:right;"><img src="' + PDF_EXAMPLE_LOGO + '" border="0" height="41" width="41" align="bottom" /></td></tr>
    </table>'
    
    # output the HTML content
    pdf.write_html(html, true, false, true, false, '')
    
    # reset pointer to the last page
    pdf.last_page()
    
    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    # Print all HTML colors
    
    # add a page
    pdf.add_page()
    
    textcolors = +'<h1>HTML Text Colors</h1>'
    bgcolors = +'<hr /><h1>HTML Background Colors</h1>'
    
    @@webcolor.each{|k,v|
    	textcolors << '<span color="#' + v + '">' + v + '</span> '
    	bgcolors << '<span bgcolor="#' + v + '" color="#333333">' + v + '</span> '
    }
    
    # output the HTML content
    pdf.write_html(textcolors, true, false, true, false, '')
    pdf.write_html(bgcolors, true, false, true, false, '')
    
    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    
    # Test word-wrap
    
    # create some HTML content
    html = '<hr />
    <h1>Various tests</h1>
    <a href="#2">link to page 2</a><br />
    <font face="courier"><b>thisisaverylongword</b></font> <font face="helvetica"><i>thisisanotherverylongword</i></font> <font face="times"><b>thisisaverylongword</b></font> thisisanotherverylongword <font face="times">thisisaverylongword</font> <font face="courier"><b>thisisaverylongword</b></font> <font face="helvetica"><i>thisisanotherverylongword</i></font> <font face="times"><b>thisisaverylongword</b></font> thisisanotherverylongword <font face="times">thisisaverylongword</font> <font face="courier"><b>thisisaverylongword</b></font> <font face="helvetica"><i>thisisanotherverylongword</i></font> <font face="times"><b>thisisaverylongword</b></font> thisisanotherverylongword <font face="times">thisisaverylongword</font> <font face="courier"><b>thisisaverylongword</b></font> <font face="helvetica"><i>thisisanotherverylongword</i></font> <font face="times"><b>thisisaverylongword</b></font> thisisanotherverylongword <font face="times">thisisaverylongword</font> <font face="courier"><b>thisisaverylongword</b></font> <font face="helvetica"><i>thisisanotherverylongword</i></font> <font face="times"><b>thisisaverylongword</b></font> thisisanotherverylongword <font face="times">thisisaverylongword</font>'
    
    # output the HTML content
    pdf.write_html(html, true, false, true, false, '')
    
    # Test fonts nesting
    html1 = 'Default <font face="courier">Courier <font face="helvetica">Helvetica <font face="times">Times <font face="dejavusans">dejavusans </font>Times </font>Helvetica </font>Courier </font>Default'
    html2 = '<small>small text</small> normal <small>small text</small> normal <sub>subscript</sub> normal <sup>superscript</sup> normal'
    html3 = '<font size="10" color="#ff7f50">The</font> <font size="10" color="#6495ed">quick</font> <font size="14" color="#dc143c">brown</font> <font size="18" color="#008000">fox</font> <font size="22"><a href="https://github.com/naitoh/rbpdf">jumps</a></font> <font size="22" color="#a0522d">over</font> <font size="18" color="#da70d6">the</font> <font size="14" color="#9400d3">lazy</font> <font size="10" color="#4169el">dog</font>.'
    
    html = html1 + '<br />' + html2 + '<br />' + html3 + '<br />' + html3 + '<br />' + html2
    
    # output the HTML content
    pdf.write_html(html, true, false, true, false, '')
    
    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    # test pre tag
    
    # add a page
    pdf.add_page()
    
    html = <<EOF
<div style="background-color:#880000;color:white;">
Hello World!<br />
Hello
</div>
<pre style="background-color:#336699;color:white;">
int main() {
    printf("HelloWorld")
    return 0
}
</pre>
<tt>Monospace font</tt>, normal font, <tt>monospace font</tt>, normal font.
<br />
<div style="background-color:#880000;color:white;">DIV LEVEL 1<div style="background-color:#008800;color:white;">DIV LEVEL 2</div>DIV LEVEL 1</div>
<br />
<span style="background-color:#880000;color:white;">SPAN LEVEL 1 <span style="background-color:#008800;color:white;">SPAN LEVEL 2</span> SPAN LEVEL 1</span>
EOF
    
    # output the HTML content
    pdf.write_html(html, true, false, true, false, '')
    
    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    
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
