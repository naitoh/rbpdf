# coding: ASCII-8BIT
#
# Copyright (c) 2011-2017 NAITOH Jun
# Released under the MIT license
# http://www.opensource.org/licenses/MIT

require 'test_helper'

class RbpdfHtmlTest < Test::Unit::TestCase
  class MYPDF < RBPDF
    def getPageBuffer(page)
      super
    end

    # get text count and x_pos from pdf page
    def get_html_text_position_x(page, regrep_text, x_pos_exp=nil)
      count_line, count_text, x_pos, y_pos = get_html_text_position(page, regrep_text, x_pos_exp)
      return count_line, count_text, x_pos
    end

    # get text count and y_pos from pdf page
    def get_html_text_position_y(page, regrep_text)
      count_line, count_text, x_pos, y_pos = get_html_text_position(page, regrep_text)
      return count_line, count_text, y_pos
    end

    # get text count and pos from pdf page
    def get_html_text_position(page, regrep_text, x_pos_exp=nil)
      content = []
      contents = getPageBuffer(page)
      contents.each_line {|line| content.push line.chomp }
      count_line = count_text = 0
      x_pos = y_pos = -1
      content.each do |line|
        count_line += 1 if line =~ /TJ ET Q$/ # Text Line Count
        if line =~ regrep_text
          count_text += 1
          line =~ /BT ([0-9.]+) ([0-9.]+) Td/
          x_pos = $1
          y_pos = $2 if y_pos == -1 # y first position only

          if x_pos.nil? or y_pos.nil? # Error
            return count_line, count_text, nil, nil
          end
          if !x_pos_exp.nil? and x_pos != x_pos_exp # Error
            return count_line, count_text, x_pos, y_pos
          end
        end
      end
      return count_line, count_text, x_pos, y_pos
    end

    # get text from pdf page
    def get_html_text(page)
      content = []
      contents = getPageBuffer(page)
      contents.each_line {|line| content.push line.chomp }
      pdf_text = ''
      content.each do |line|
        if line =~ /\[\((.*)\)\] TJ ET/
          pdf_text << $1
        end
      end
      return pdf_text
    end
  end

  test "write_html Basic test" do
    pdf = RBPDF.new
    pdf.add_page()

    htmlcontent = '<h1>HTML Example</h1>'
    pdf.write_html(htmlcontent, true, 0, true, 0)

    htmlcontent = 'abcdefghijklmnopgrstuvwxyz01234567890 abcdefghijklmnopgrstuvwxyz01234567890 abcdefghijklmnopgrstuvwxyz01234567890 abcdefghijklmnopgrstuvwxyz01234567890 abcdefghijklmnopgrstuvwxyz01234567890'
    pdf.write_html(htmlcontent, true, 0, true, 0)

    htmlcontent = '1<br><br><br><br><br><br><br><br><br><br> 2<br><br><br><br><br><br><br><br><br><br> 3<br><br><br><br><br><br><br><br><br><br> 4<br><br><br><br><br><br><br><br><br><br> 5<br><br><br><br><br><br><br><br><br><br> 6<br><br><br><br><br><br><br><br><br><br> 7<br><br><br><br><br><br><br><br><br><br> 8<br><br><br><br><br><br><br><br><br><br> 9<br><br><br><br><br><br><br><br><br><br> 10<br><br><br><br><br><br><br><br><br><br> 11<br><br><br><br><br><br><br><br><br><br>'
    pdf.write_html(htmlcontent, true, 0, true, 0)

    pno = pdf.get_page
    assert_equal 3, pno
  end

  test "write_html Table test 1" do
    pdf = RBPDF.new
    pdf.add_page()

    tablehtml = '<table border="1" cellspacing="1" cellpadding="1"><tr><td>a</td><td>b</td></tr><tr><td>c</td><td>d</td></tr></table>'
    pdf.write_html(tablehtml, true, 0, true, 0)

    htmlcontent = '1<br><br><br><br><br><br><br><br><br><br> 2<br><br><br><br><br><br><br><br><br><br> 3<br><br><br><br><br><br><br><br><br><br> 4<br><br><br><br><br><br><br><br><br><br> 5<br><br><br><br><br><br><br><br><br><br> 6<br><br><br><br><br><br><br><br><br><br> 7<br><br><br><br><br><br><br><br><br><br> 8<br><br><br><br><br><br><br><br><br><br> 9<br><br><br><br><br><br><br><br><br><br> 10<br><br><br><br><br><br><br><br><br><br> 11<br><br><br><br><br><br><br><br><br><br>'

    tablehtml = '<table border="1" cellspacing="1" cellpadding="1"><tr><td>a</td><td>b</td></tr><tr><td>c</td><td>' + htmlcontent + '</td></tr></table>'
    pdf.write_html(tablehtml, true, 0, true, 0)

    pno = pdf.get_page
    assert_equal 3, pno
  end

  test "write_html Table test 2" do
    pdf = MYPDF.new
    pdf.add_page()

    htmlcontent = '1<br><br><br><br><br><br><br><br><br><br> 2<br><br><br><br><br><br><br><br><br><br> 3<br><br><br><br><br><br><br><br><br><br> 4<br><br><br><br><br><br><br><br><br><br> 5<br><br><br><br><br><br><br><br><br><br> 6<br><br><br><br><br><br><br><br><br><br> 7<br><br><br><br><br><br><br><br><br><br> 8<br><br><br><br><br><br><br><br><br><br> 9<br><br><br><br><br><br><br><br><br><br> 10<br><br><br><br><br><br><br><br><br><br> 11<br><br><br><br><br><br><br><br><br><br>'

    tablehtml = '<table border="1"><tr><td>ABCD</td><td>EFGH</td><td>IJKL</td></tr>
                 <tr><td>abcd</td><td>efgh</td><td>ijkl</td></tr>
                 <tr><td>' + htmlcontent + '</td></tr></table>'
    pdf.write_html(tablehtml, true, 0, true, 0)

    pno = pdf.get_page
    assert_equal 3, pno

    # Page 1
    count_line, count_text, xpos1 = pdf.get_html_text_position_x(1, /ABCD/) # Header
    assert_not_nil xpos1
    assert_equal 1, count_text
    assert_equal 13, count_line
    count_line, count_text, xpos2 = pdf.get_html_text_position_x(1, /abcd/)
    assert_not_nil xpos2
    assert_equal 1, count_text
    assert_equal xpos1, xpos2
    assert_equal 13, count_line

    # Page 2
    count_line, count_text, xpos2 = pdf.get_html_text_position_x(2, /\([6-9]\)/, xpos1)
    assert_not_nil xpos2
    assert_equal xpos1, xpos2
    assert_equal 7, count_line
  end

  test "write_html Table thead tag test 1" do
    pdf = MYPDF.new
    pdf.add_page()

    tablehtml = '<table border="1" cellpadding="1" cellspacing="1">
    <thead><tr><td>ABCD</td><td>EFGH</td><td>IJKL</td></tr></thead>
    <tr><td>abcd</td><td>efgh</td><td>ijkl</td></tr>
    </table>'

    pdf.write_html(tablehtml, true, 0, true, 0)
    page = pdf.get_page
    assert_equal 1, page

    count_line, count_text, xpos = pdf.get_html_text_position_x(1, /ABCD/) # Header
    assert_equal 1, count_text
  end

  test "write_html Table thead tag test 2" do
    pdf = MYPDF.new
    pdf.add_page()

    htmlcontent = '1<br><br><br><br><br><br><br><br><br><br> 2<br><br><br><br><br><br><br><br><br><br> 3<br><br><br><br><br><br><br><br><br><br> 4<br><br><br><br><br><br><br><br><br><br> 5<br><br><br><br><br><br><br><br><br><br> 6<br><br><br><br><br><br><br><br><br><br> 7<br><br><br><br><br><br><br><br><br><br> 8<br><br><br><br><br><br><br><br><br><br> 9<br><br><br><br><br><br><br><br><br><br> 10<br><br><br><br><br><br><br><br><br><br> 11<br><br><br><br><br><br><br><br><br><br>'

    tablehtml = '<table><thead><tr><td>ABCD</td><td>EFGH</td><td>IJKL</td></tr></thead>
                 <tr><td>abcd</td><td>efgh</td><td>ijkl</td></tr>
                 <tr><td>' + htmlcontent + '</td></tr></table>'

    pdf.write_html(tablehtml, true, 0, true, 0)
    page = pdf.get_page
    assert_equal 3, page

    # Page 1
    count_line, count_text, xpos1 = pdf.get_html_text_position_x(1, /ABCD/) # Header
    assert_not_nil xpos1
    assert_equal 1, count_text
    assert_equal 13, count_line
    count_line, count_text, xpos2 = pdf.get_html_text_position_x(1, /abcd/)
    assert_not_nil xpos2
    assert_equal 1, count_text
    assert_equal xpos1, xpos2
    assert_equal 13, count_line

    # Page 2
    count_line, count_text, xpos2 = pdf.get_html_text_position_x(2, /ABCD/, xpos1) # Header
    assert_not_nil xpos2
    assert_equal 1, count_text
    assert_equal xpos1, xpos2
    assert_equal 10, count_line
    count_line, count_text, xpos2 = pdf.get_html_text_position_x(2, /abcd/)
    assert_equal 0, count_text
    assert_equal 10, count_line
    count_line, count_text, xpos2 = pdf.get_html_text_position_x(2, /\([6-9]\)/, xpos1)
    assert_not_nil xpos2
    assert_equal xpos1, xpos2
    assert_equal 10, count_line

    # Page 3
    count_line, count_text, xpos2 = pdf.get_html_text_position_x(3, /ABCD/, xpos1) # Header
    assert_not_nil xpos2
    assert_equal 1, count_text
    assert_equal xpos1, xpos2
    assert_equal 5, count_line
    count_line, count_text, xpos2 = pdf.get_html_text_position_x(3, /abcd/)
    assert_equal 0, count_text
    assert_equal 5, count_line
    count_line, count_text, xpos2 = pdf.get_html_text_position_x(3, /\(11\)/, xpos1)
    assert_not_nil xpos2
    assert_equal 1, count_text
    assert_equal xpos1, xpos2
    assert_equal 5, count_line
  end

  test "write_html_cell Table thead tag test" do
    pdf = MYPDF.new
    pdf.add_page()

    htmlcontent = '<br>1<br><br><br><br><br><br><br><br><br><br> 2<br><br><br><br><br><br><br><br><br><br> 3<br><br><br><br><br><br><br><br><br><br> 4<br>
<br><br><br><br><br><br><br><br><br> 5<br><br><br><br><br><br><br><br><br><br> 6<br><br><br><br><br><br><br><br><br><br> 7<br><br><br><br><br><br><br>
<br><br><br> 8<br><br><br><br><br><br><br><br><br><br> 9<br><br><br><br><br><br><br><br><br><br> 10<br><br><br><br><br><br><br><br><br><br> 11<br><br>
<br><br><br><br><br><br><br><br>'

    tablehtml ='<table><thead><tr>
    <th style="text-align: left">Left align</th>
    <th style="text-align: right">Right align</th>
    <th style="text-align: center">Center align</th>
    </tr> </thead><tbody> <tr>
    <td style="text-align: left">left' + htmlcontent + '</td>
    <td style="text-align: right">right</td>
    <td style="text-align: center">center</td>
    </tr> </tbody></table>'

    pdf.write_html_cell(0, 0, '', '',tablehtml)

    page = pdf.get_page
    assert_equal 1, page

    # Page 1
    count_line, count_text, xpos1 = pdf.get_html_text_position_x(1, /Left align/) # Header
    assert_not_nil xpos1
    assert_equal 1, count_text
    assert_equal 13, count_line
    count_line, count_text, xpos2 = pdf.get_html_text_position_x(1, /left/)
    assert_not_nil xpos2
    assert_equal 1, count_text
    assert_equal 13, count_line
    assert_equal xpos1, xpos2

    # Page 2
    count_line, count_text, xpos2 = pdf.get_html_text_position_x(2, /Left align/, xpos1) # Header
    assert_not_nil xpos2
    assert_equal 1, count_text
    assert_equal xpos1, xpos2
    assert_equal 10, count_line
    count_line, count_text, xpos2 = pdf.get_html_text_position_x(2, /\(6\)/, xpos1)
    assert_not_nil xpos2
    assert_equal 1, count_text
    assert_equal xpos1, xpos2
    assert_equal 10, count_line

    # Page 3
    count_line, count_text, xpos2 = pdf.get_html_text_position_x(3, /Left align/, xpos1) # Header
    assert_not_nil xpos2
    assert_equal 1, count_text
    assert_equal xpos1, xpos2
    assert_equal 5, count_line
    count_line, count_text, xpos2 = pdf.get_html_text_position_x(3, /\(11\)/, xpos1)
    assert_not_nil xpos2
    assert_equal 1, count_text
    assert_equal xpos1, xpos2
    assert_equal 5, count_line
  end

  test "write_html_cell Table thead tag  cellpadding x position test" do
    pdf = MYPDF.new
    pdf.add_page()

    htmlcontent = '<br>1<br><br><br><br><br><br><br><br><br><br> 2<br><br><br><br><br><br><br><br><br><br> 3<br><br><br><br><br><br><br><br><br><br> 4<br>
<br><br><br><br><br><br><br><br><br> 5<br><br><br><br><br><br><br><br><br><br> 6<br><br><br><br><br><br><br><br><br><br> 7<br><br><br><br><br><br><br>
<br><br><br> 8<br><br><br><br><br><br><br><br><br><br> 9<br><br><br><br><br><br><br><br><br><br> 10<br><br><br><br><br><br><br><br><br><br> 11<br><br>
<br><br><br><br><br><br><br><br>'

    tablehtml ='<table cellpadding="10"><thead><tr>
    <th style="text-align: left">Left align</th>
    <th style="text-align: right">Center align</th>
    <th style="text-align: left">Right align</th>
    </tr> </thead><tbody> <tr>
    <td style="text-align: left">left</td>
    <td style="text-align: right">center</td>
    <td style="text-align: left">right' + htmlcontent + '</td>
    </tr> </tbody></table>'

    pdf.write_html_cell(0, 0, '', '',tablehtml)

    page = pdf.get_page
    assert_equal 1, page

    # Page 1
    count_line, count_text, xpos1 = pdf.get_html_text_position_x(1, /Right align/) # Header
    assert_not_nil xpos1
    assert_equal 1, count_text
    assert_equal 13, count_line
    count_line, count_text, xpos2 = pdf.get_html_text_position_x(1, /right/)
    assert_not_nil xpos2
    assert_equal 1, count_text
    assert_equal xpos1, xpos2
    assert_equal 13, count_line

    # Page 2
    count_line, count_text, xpos2 = pdf.get_html_text_position_x(2, /Right align/, xpos1) # Header
    assert_not_nil xpos2
    assert_equal 1, count_text
    assert_equal xpos1, xpos2
    assert_equal 10, count_line
    count_line, count_text, xpos2 = pdf.get_html_text_position_x(2, /\(6\)/, xpos1)
    assert_not_nil xpos2
    assert_equal 1, count_text
    assert_equal xpos1, xpos2
    assert_equal 10, count_line
  end

  test "write_html_cell Table thead tag cellpadding y position test 1" do
    pdf = MYPDF.new
    pdf.add_page()

    table_start='<table cellpadding="10"><thead><tr>
<th style="text-align: left">Left align</th><th style="text-align: center">Center align</th><th style="text-align: right">Right align</th>
</tr></thead><tbody>'
    table_col='<tr><td style="text-align: left">AAA</td><td style="text-align: center">BBB</td><td style="text-align: right">CCC</td></tr>'
    table_end='</tbody></table>'
    tablehtml= table_start + table_col * 30 + table_end

    pdf.write_html_cell(0, 0, '', '',tablehtml)

    # Page 1
    count_line, count_text, ypos1 = pdf.get_html_text_position_y(1, /Left align/) # Header
    assert_not_nil ypos1
    assert_equal 1, count_text
    assert_equal 65, count_line
    count_line, count_text, ypos2 = pdf.get_html_text_position_y(1, /AAA/)
    assert_not_nil ypos2
    assert_equal 20, count_text
    assert_equal 65, count_line
    base_pos = ypos1.to_i - ypos2.to_i

    # Page 2
    count_line, count_text, ypos1 = pdf.get_html_text_position_y(2, /Left align/) # Header
    assert_not_nil ypos2
    assert_equal 1, count_text
    assert_equal 34, count_line
    count_line, count_text, ypos2 = pdf.get_html_text_position_y(2, /AAA/)
    assert_not_nil ypos2
    assert_equal 10, count_text
    assert_equal 34, count_line
    assert_equal base_pos, ypos1.to_i - ypos2.to_i
  end

  test "write_html_cell Table thead tag cellpadding y position test 2" do
    pdf = MYPDF.new
    pdf.add_page()

    table_start='abc<br><table cellpadding="10"><thead><tr>
<th style="text-align: left">Left align</th><th style="text-align: center">Center align</th><th style="text-align: right">Right align</th>
</tr></thead><tbody>'
    table_col='<tr><td style="text-align: left">AAA</td><td style="text-align: center">BBB</td><td style="text-align: right">CCC</td></tr>'
    table_end='</tbody></table>'
    tablehtml= table_start + table_col * 30 + table_end

    pdf.write_html_cell(0, 0, '', '',tablehtml)

    # Page 1
    count_line, count_text, ypos1 = pdf.get_html_text_position_y(1, /Left align/) # Header
    assert_not_nil ypos1
    assert_equal 1, count_text
    assert_equal 66, count_line
    count_line, count_text, ypos2 = pdf.get_html_text_position_y(1, /AAA/)
    assert_not_nil ypos2
    assert_equal 20, count_text
    assert_equal 66, count_line
    base_pos = ypos1.to_i - ypos2.to_i

    # Page 2
    count_line, count_text, ypos1 = pdf.get_html_text_position_y(2, /Left align/) # Header
    assert_not_nil ypos2
    assert_equal 1, count_text
    assert_equal 34, count_line
    count_line, count_text, ypos2 = pdf.get_html_text_position_y(2, /AAA/)
    assert_not_nil ypos2
    assert_equal 10, count_text
    assert_equal 34, count_line
    assert_equal base_pos, ypos1.to_i - ypos2.to_i
  end

  test "write_html ASCII text test" do
    pdf = MYPDF.new
    pdf.add_page()

    text = 'HTML Example'
    htmlcontent = '<h1>' + text + '</h1>'
    pdf.write_html(htmlcontent, true, 0, true, 0)
    page = pdf.get_page
    assert_equal 1, page

    content = []
    contents = pdf.getPageBuffer(1)
    contents.each_line {|line| content.push line.chomp }

    count_text = 0
    content.each do |line|
      count_text += 1 unless line.scan(text).empty?
    end
    assert_equal 1, count_text
  end

  test "write_html Non ASCII text test" do
    pdf = MYPDF.new
    pdf.add_page()

    text = 'HTML Example ' + "\xc2\x83\xc2\x86"

    htmlcontent = '<h1>' + text + '</h1>'
    pdf.write_html(htmlcontent, true, 0, true, 0)
    page = pdf.get_page
    assert_equal 1, page

    content = []
    contents = pdf.getPageBuffer(1)
    contents.each_line {|line| content.push line.chomp }

    text = 'HTML Example ' + "\x83\x86"
    text.force_encoding('ASCII-8BIT') if text.respond_to?(:force_encoding)
    count_text = 0
    content.each do |line|
      line.force_encoding('ASCII-8BIT') if line.respond_to?(:force_encoding)
      count_text += 1 unless line.scan(text).empty?
    end
    assert_equal 1, count_text
  end

  test "works internal links out of page range" do
    pdf = RBPDF.new
    pdf.add_page()

    htmlcontent = '<a href="#100400_somelink">FooLink</a>'
    pdf.write_html(htmlcontent, true, 0, true, 0)

    assert_nothing_raised do
      pdf.Close
    end

    assert_nothing_raised do
      pdf.Output
    end
  end

  test "write_html no tag text test" do
    pdf = MYPDF.new
    pdf.set_print_header(false)
    pdf.add_page()

    text = ' abc def '
    pdf.write_html(text, true, 0, true, 0)
    pdf_text = pdf.get_html_text(1)
    assert_equal 'abc def', pdf_text
  end

  test "write_html no tag back slash test" do
    pdf = MYPDF.new
    pdf.set_print_header(false)
    pdf.add_page()

    text = " abc \\def "
    pdf.write_html(text, true, 0, true, 0)  # use escape() method in getCellCode()
    pdf_text = pdf.get_html_text(1)
    assert_equal "abc \\\\def", pdf_text
  end

  test "write_html <b> tag test" do
    pdf = MYPDF.new
    pdf.set_print_header(false)
    pdf.add_page()

    text = ' ' + 'A' * 70
    htmlcontent = '<b>' + text + '</b>'

    pdf.write_html(htmlcontent, true, 0, true, 0)
    pdf_text = pdf.get_html_text(1)
    assert_equal 'A' * 70, pdf_text
  end

  test "write_html <i> tag test" do
    pdf = MYPDF.new
    pdf.set_print_header(false)
    pdf.add_page()

    text = ' ' + 'A' * 70
    htmlcontent = '<i>' + text + '</i>'

    pdf.write_html(htmlcontent, true, 0, true, 0)
    pdf_text = pdf.get_html_text(1)
    assert_equal 'A' * 70, pdf_text
  end

  test "write_html <u> tag test" do
    pdf = MYPDF.new
    pdf.set_print_header(false)
    pdf.add_page()

    text = ' ' + 'A' * 70
    htmlcontent = '<u>' + text + '</u>'

    pdf.write_html(htmlcontent, true, 0, true, 0)
    pdf_text = pdf.get_html_text(1)
    assert_equal 'A' * 70, pdf_text
  end

  test "write_html <pre> tag space 1 test" do
    pdf = MYPDF.new
    pdf.set_print_header(false)
    pdf.add_page()

    text = ' ' + 'A' * 70
    htmlcontent = '<pre>' + text + '</pre>'

    pdf.write_html(htmlcontent, true, 0, true, 0)
    pdf_text = pdf.get_html_text(1)
    assert_equal "\xa0" + 'A' * 70, pdf_text
  end

  test "write_html <pre> tag space 2 test" do
    pdf = MYPDF.new
    pdf.set_print_header(false)
    pdf.add_page()

    text = '  ' + 'A' * 70
    htmlcontent = '<pre>' + text + '</pre>'

    pdf.write_html(htmlcontent, true, 0, true, 0)
    pdf_text = pdf.get_html_text(1)
    assert_equal "\xa0" * 2 + 'A' * 70, pdf_text
  end

  test "write_html <table> tag text test" do
    pdf = MYPDF.new
    pdf.set_print_header(false)
    pdf.add_page()

    text = "abc"
    htmlcontent = '<table border="1"><tr><td>' + text + '</td></tr></table>'

    pdf.write_html(htmlcontent, true, 0, true, 0)
    pdf_text = pdf.get_html_text(1)
    assert_equal 'abc', pdf_text
  end

  test "write_html <table> tag back slash test" do
    pdf = MYPDF.new
    pdf.set_print_header(false)
    pdf.add_page()

    text = "a\\bc"
    htmlcontent = '<table border="1"><tr><td>' + text + '</td></tr></table>'

    pdf.write_html(htmlcontent, true, 0, true, 0) # use escape() method in getCellCode()
    pdf_text = pdf.get_html_text(1)
    assert_equal 'a\\\\bc', pdf_text
  end

  test "write_html Character Entities test" do
    pdf = MYPDF.new
    pdf.set_print_header(false)

    character_entities = {
      '&lt;'    => '<',
      '&gt;'    => '>',
      '&amp;'   => '&',
      '&quot;'  => '"',
      '&nbsp;'  => "\xa0",
      '&cent;'  => "\xa2",
      '&pound;' => "\xa3",
      '&yen;'   => "\xa5",
      '&copy;'  => "\xa9",
      '&reg;'   => "\xae",
      '&euro;'  => "\x80",
    }
    character_entities.each {|ce, c|
      pdf.add_page()
      page = pdf.get_page
      pdf.write_html(ce, true, 0, true, 0)
      pdf_text = pdf.get_html_text(page)
      assert_equal '[' + ce + ']:' + c, '[' + ce + ']:' + pdf_text
    }
  end

  test "write_html Character Entities test pre mode" do
    pdf = MYPDF.new
    pdf.set_print_header(false)

    character_entities = {
      '&lt;'    => '<',
      '&gt;'    => '>',
      '&amp;'   => '&',
      '&quot;'  => '"',
      '&nbsp;'  => "\xa0",
      '&cent;'  => "\xa2",
      '&pound;' => "\xa3",
      '&yen;'   => "\xa5",
      '&copy;'  => "\xa9",
      '&reg;'   => "\xae",
      '&euro;'  => "\x80",
    }
    character_entities.each {|ce, c|
      pdf.add_page()
      page = pdf.get_page
      pdf.write_html('<pre>' + ce + '</pre>', true, 0, true, 0)
      pdf_text = pdf.get_html_text(page)
      assert_equal '[' + ce + ']:' + c, '[' + ce + ']:' + pdf_text
    }
  end

  test "unhtmlentities test" do
    pdf = RBPDF.new
    character_entities = {
      '&lt;'    => '<',
      '&gt;'    => '>',
      '&amp;'   => '&',
      '&quot;'  => '"',
      '&nbsp;'  => "\xc2\xa0",
      '&cent;'  => "\xc2\xa2",
      '&pound;' => "\xc2\xa3",
      '&yen;'   => "\xc2\xa5",
      '&copy;'  => "\xc2\xa9",
      '&reg;'   => "\xc2\xae",
      '&euro;'  => "\xe2\x82\xac",
    }
    character_entities.each {|ce, c|
      text = pdf.unhtmlentities(ce)
      text.force_encoding('ASCII-8BIT') if text.respond_to?(:force_encoding)
      assert_equal '[' + ce + ']:' + c, '[' + ce + ']:' + text
    }
  end
end
