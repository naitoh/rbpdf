# Copyright (c) 2011-2017 NAITOH Jun
# Released under the MIT license
# http://www.opensource.org/licenses/MIT

require 'test_helper'

class RbpdfTest < Test::Unit::TestCase
  test "write Basic test" do
    pdf = RBPDF.new

    line = pdf.write(0, "LINE 1")
    assert_equal 1, line

    line = pdf.write(0, "LINE 1\n")
    assert_equal 1, line

    line = pdf.write(0, "LINE 1\n2\n")
    assert_equal 2, line

    line = pdf.write(0, "")
    assert_equal 1, line

    line = pdf.write(0, "\n")
    assert_equal 1, line

    line = pdf.write(0, "abcdefghijklmnopgrstuvwxyz01234567890")
    assert_equal 1, line
    line = pdf.write(0, "abcdefghijklmnopgrstuvwxyz01234567890 abcdefghijklmnopgrstuvwxyz01234567890 abcdefghijklmnopgrstuvwxyz01234567890")
    assert_equal 2, line
    line = pdf.write(0, "abcdefghijklmnopgrstuvwxyz01234567890 abcdefghijklmnopgrstuvwxyz01234567890 abcdefghijklmnopgrstuvwxyz01234567890 abcdefghijklmnopgrstuvwxyz01234567890 abcdefghijklmnopgrstuvwxyz01234567890")
    assert_equal 3, line
  end

  test "write Break test single line 1" do
    pdf = RBPDF.new
    pdf.add_page()

    cell_hight = pdf.get_cell_height_ratio()
    fontsize = pdf.get_font_size()
    break_hight = pdf.set_auto_page_break(true)

    pno = pdf.get_page
    assert_equal 1, pno

    0.upto(60) do |i|
      y = pdf.get_y()
      old_pno = pno

      line = pdf.write(0, "LINE 1\n")
      assert_equal 1, line

      pno = pdf.get_page

      if y + fontsize * cell_hight < break_hight
        assert_equal old_pno, pno
      else
        assert_equal old_pno + 1, pno
      end
    end
  end

  test "write Break test single line 2" do
    pdf = RBPDF.new
    pdf.add_page()

    0.upto(49) do |i|
      line = pdf.write(0, "LINE 1\n")
      assert_equal 1, line

      pno = pdf.get_page
      assert_equal 1, pno
    end

    line = pdf.write(0, "abcdefghijklmnopgrstuvwxyz01234567890 abcdefghijklmnopgrstuvwxyz01234567890 abcdefghijklmnopgrstuvwxyz01234567890")
    assert_equal 2, line
    pno = pdf.get_page
    assert_equal 2, pno
  end

  test "write Break test multi line 1" do
    pdf = RBPDF.new
    pdf.add_page()
    pno = pdf.get_page
    assert_equal 1, pno

    line = pdf.write(0, "1\n\n\n\n\n\n\n\n\n\n 2\n\n\n\n\n\n\n\n\n\n 3\n\n\n\n\n\n\n\n\n\n 4\n\n\n\n\n\n\n\n\n\n")
    assert_equal 40, line 
    pno = pdf.get_page
    assert_equal 1, pno

    line = pdf.write(0, "1\n\n\n\n\n\n\n\n\n\n 2\n\n\n\n\n\n\n\n\n\n 3\n\n\n\n\n\n\n\n\n\n 4\n\n\n\n\n\n\n\n\n\n")
    assert_equal 40, line 
    pno = pdf.get_page
    assert_equal 2, pno
  end

  test "write Break test multi line 2" do
    pdf = RBPDF.new
    pdf.add_page()
    pno = pdf.get_page
    assert_equal 1, pno

    line = pdf.write(0, "1\n\n\n\n\n\n\n\n\n\n 2\n\n\n\n\n\n\n\n\n\n 3\n\n\n\n\n\n\n\n\n\n 4\n\n\n\n\n\n\n\n\n\n 5\n\n\n\n\n\n\n\n\n\n 6\n\n\n\n\n\n\n\n\n\n 7\n\n\n\n\n\n\n\n\n\n 8\n\n\n\n\n\n\n\n\n\n 9\n\n\n\n\n\n\n\n\n\n 10\n\n\n\n\n\n\n\n\n\n 11\n\n\n\n\n\n\n\n\n\n")
    assert_equal 110, line 
    pno = pdf.get_page
    assert_equal 3, pno
  end

  test "write firstline test" do
    pdf = RBPDF.new
    pdf.add_page()
    pno = pdf.get_page
    assert_equal 1, pno

    line = pdf.write(0, "\n", nil, 0, '', false, 0, true)
    assert_equal "\n", line

    line = pdf.write(0, "\n", nil, 0, '', false, 0, true)
    assert_equal "\n", line

    line = pdf.write(0, "12345\n", nil, 0, '', false, 0, true)
    assert_equal "\n", line

    line = pdf.write(0, "12345\nabcde", nil, 0, '', false, 0, true)
    assert_equal "\nabcde", line

    line = pdf.write(0, "12345\nabcde\n", nil, 0, '', false, 0, true)
    assert_equal "\nabcde\n", line

    line = pdf.write(0, "12345\nabcde\nefgh", nil, 0, '', false, 0, true)
    assert_equal "\nabcde\nefgh", line
  end

  class MYPDF < RBPDF
    def endlinex
      @endlinex
    end
    def r_margin
      @r_margin
    end
  end

  test "write endline x test 1" do
    pdf = MYPDF.new
    pdf.add_page()
    pdf.write(0, " cccccccccc cccccccccc ", nil, 0, '', false, 0, true)
    endlinex = pdf.endlinex()
    assert_not_equal 0, endlinex
  end

  test "write endline x test 2" do
    pdf = MYPDF.new
    pdf.add_page()

    r_margin = pdf.r_margin()
    width = pdf.getPageWidth()
    x = width - r_margin - 10
    pdf.SetX(x)
    pdf.write(0, " cccccccccc cccccccccc ", nil, 0, '', false, 0, true)
    endlinex = pdf.endlinex()
    assert_equal x, endlinex
  end

  test "write endline x test 3" do
    pdf = MYPDF.new
    pdf.add_page()

    r_margin = pdf.r_margin()
    width = pdf.getPageWidth()
    x = width - r_margin - 10
    pdf.SetX(x)
    pdf.write(0, "cccccccccc cccccccccc ", nil, 0, '', false, 0, true)
    endlinex = pdf.endlinex()
    assert_not_equal x, endlinex
  end

  test "write encoding test" do
    return unless 'test'.respond_to?(:force_encoding)

    pdf = RBPDF.new('P', 'mm', 'A4', true, "UTF-8", true)
    str = 'test'.force_encoding('UTF-8')
    pdf.write(0, str)
    assert_equal 'UTF-8', str.encoding.to_s
  end

  test "write Bidi arabic test" do
    pdf = RBPDF.new
    pdf.set_font('dejavusans', '', 18)
    pdf.add_page

    ascii_str   = "role"
    utf8_arabic_str_1  = "\xd8\xaf\xd9\x88\xd8\xb1"

    line = pdf.write(0, ascii_str)
    assert_equal 1, line
    line = pdf.write(0, utf8_arabic_str_1)
    assert_equal 1, line
  end

  test "write Bidi arabic set_rtl test" do
    pdf = RBPDF.new
    pdf.set_font('dejavusans', '', 18)
    pdf.set_rtl(true)
    pdf.add_page

    ascii_str   = "role"
    utf8_arabic_str_1  = "\xd8\xaf\xd9\x88\xd8\xb1"

    line = pdf.write(0, ascii_str)
    assert_equal 1, line
    line = pdf.write(0, utf8_arabic_str_1)
    assert_equal 1, line
  end

  test "write Bidi arabic set_temp_rtl test" do
    pdf = RBPDF.new
    pdf.set_font('dejavusans', '', 18)
    pdf.set_temp_rtl('rtl')
    pdf.add_page

    ascii_str   = "role"
    utf8_arabic_str_1  = "\xd8\xaf\xd9\x88\xd8\xb1"

    line = pdf.write(0, ascii_str)
    assert_equal 1, line
    line = pdf.write(0, utf8_arabic_str_1)
    assert_equal 1, line
  end
end
