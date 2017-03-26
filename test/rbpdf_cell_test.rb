# Copyright (c) 2011-2017 NAITOH Jun
# Released under the MIT license
# http://www.opensource.org/licenses/MIT

require 'test_helper'

class RbpdfTest < Test::Unit::TestCase
  test "getCellCode basic test" do
    pdf = RBPDF.new('P', 'mm', 'A4', true, "UTF-8", true)
    pdf.add_page()
    code = pdf.send(:getCellCode, 10)
    assert_equal "0.57 w 0 J 0 j [] 0 d 0 G 0 g\n", code
    # 0.57 w 0 J 0 j [] 0 d 0 G 0 rg       # getCellCode
  end

  test "getCellCode text test" do
    pdf = RBPDF.new('P', 'mm', 'A4', true, "UTF-8", true)
    pdf.add_page()
    content = []
    contents = pdf.send(:getCellCode, 10, 10, 'abc')
    contents.each_line {|line| content.push line.chomp }

    assert_equal 2, content.length
    assert_equal "0.57 w 0 J 0 j [] 0 d 0 G 0 g", content[0]
    assert_match(/BT 31.1[89] 795.17 Td 0 Tr 0.00 w \[\(abc\)\] TJ ET/, content[1])
    # BT
    #    31.19 795.17 Td
    #    0 Tr 0.00 w
    #    [(abc)] TJ
    # ET
  end

  test "getCellCode back slash text test" do
    pdf = RBPDF.new('P', 'mm', 'A4', true, "UTF-8", true)
    pdf.add_page()
    content = []
    contents = pdf.send(:getCellCode, 10, 10, "a\\bc") # use escape() method
    contents.each_line {|line| content.push line.chomp }

    assert_equal 2, content.length
    assert_equal "0.57 w 0 J 0 j [] 0 d 0 G 0 g", content[0]
    assert_match(/BT 31.1[89] 795.17 Td 0 Tr 0.00 w \[\(a\\\\bc\)\] TJ ET/, content[1])
    # BT
    #    31.19 795.17 Td
    #    0 Tr 0.00 w
    #    [(a\\bc)] TJ
    # ET
  end

  test "getCellCode text align test" do
    pdf = RBPDF.new('P', 'mm', 'A4', true, "UTF-8", true)
    pdf.add_page()
    content = []
    contents = pdf.send(:getCellCode, 10, 10, 'abc', 'LTRB')
    contents.each_line {|line| content.push line.chomp }

    assert_equal 2, content.length
    assert_equal "0.57 w 0 J 0 j [] 0 d 0 G 0 g", content[0]
    assert_match(/28.35 813.8[23] m 28.35 784.91 l S 28.0[67] 813.54 m 56.98 813.54 l S 56.70 813.8[32] m 56.70 784.91 l S 28.0[67] 785.19 m 56.98 785.19 l S BT 31.1[89] 795.17 Td 0 Tr 0.00 w \[\(abc\)\] TJ ET/, content[1])
    # 28.35 813.82 m 28.35 784.91 l S
    # 28.07 813.54 m 56.98 813.54 l S
    # 56.70 813.82 m 56.70 784.91 l S
    # 28.07 785.19 m 56.98 785.19 l S
    # BT
    #   31.19 795.17 Td
    #   0 Tr 0.00 w 
    #   [(abc)] TJ
    # ET
  end

  test "getCellCode link url test" do
    pdf = RBPDF.new('P', 'mm', 'A4', true, "UTF-8", true)
    pdf.add_page()

    # Check Initialize Values
    page_annots = pdf.instance_variable_get('@page_annots')
    assert_equal 0, page_annots.length
    annots = pdf.send(:getannotsrefs, 1)
    assert_equal '', annots

    content = []
    contents = pdf.send(:getCellCode, 10, 10, 'abc', '', 0, '', 0, 'http://example.com')
    contents.each_line {|line| content.push line.chomp }

    assert_equal 2, content.length
    assert_match(/BT 31.1[89] 795.17 Td 0 Tr 0.00 w \[\(abc\)\] TJ ET/, content[1])
    # BT
    #    31.19 795.17 Td
    #    0 Tr 0.00 w
    #    [(abc)] TJ
    # ET

    # Check Annots
    page_annots = pdf.instance_variable_get('@page_annots')
    assert_equal 2, page_annots.length
    assert_equal nil, page_annots[0]
    assert_equal 1, page_annots[1].length
    assert_equal 0,                    page_annots[1][0]['numspaces']
    assert_equal({"Subtype"=>"Link"},  page_annots[1][0]['opt'])
    assert_equal 'http://example.com', page_annots[1][0]['txt']

    annots = pdf.send(:getannotsrefs, 1)
    assert_equal " /Annots [ 200001 0 R ]", annots
  end

  test "getCellCode link page test" do
    pdf = RBPDF.new('P', 'mm', 'A4', true, "UTF-8", true)
    pdf.add_page()
    content = []
    contents = pdf.send(:getCellCode, 10, 10, 'abc', 0, 0, '', 0, 1)
    contents.each_line {|line| content.push line.chomp }

    assert_equal 2, content.length
    assert_match(/BT 31.1[89] 795.17 Td 0 Tr 0.00 w \[\(abc\)\] TJ ET/, content[1])
    # BT
    #    31.19 795.17 Td
    #    0 Tr 0.00 w
    #    [(abc)] TJ
    # ET

    # Check Annots
    page_annots = pdf.instance_variable_get('@page_annots')
    assert_equal 2, page_annots.length
    assert_equal nil, page_annots[0]
    assert_equal 1, page_annots[1].length
    assert_equal 0,                    page_annots[1][0]['numspaces']
    assert_equal({"Subtype"=>"Link"},  page_annots[1][0]['opt'])
    assert_equal 1,                    page_annots[1][0]['txt']

    annots = pdf.send(:getannotsrefs, 1)
    assert_equal " /Annots [ 200001 0 R ]", annots
  end

  test "getStringHeight Basic test" do
    pdf = RBPDF.new('P', 'mm', 'A4', true, "UTF-8", true)
    pdf.add_page

    txt = 'abcdefg'

    w = 50
    y1 = pdf.get_y
    pdf.multi_cell(w, 0, txt)
    pno = pdf.get_page
    assert_equal 1, pno
    y2 = pdf.get_y
    h1 = y2 - y1

    h2 = pdf.getStringHeight(w, txt)
    assert_in_delta h1, h2, 0.01

    line = pdf.get_num_lines(txt, w)
    assert_equal 1, line

    w = 20
    y1 = pdf.get_y
    pdf.multi_cell(w, 0, txt)
    pno = pdf.get_page
    assert_equal 1, pno
    y2 = pdf.get_y
    h1 = y2 - y1

    h2 = pdf.getStringHeight(w, txt)
    assert_in_delta h1, h2, 0.01

    line = pdf.get_num_lines(txt, w)
    assert_equal 1, line
  end

  test "getStringHeight Line Break test" do
    pdf = RBPDF.new('P', 'mm', 'A4', true, "UTF-8", true)
    pdf.add_page

    txt = 'abcdefg'

    w = 10
    y1 = pdf.get_y
    pdf.multi_cell(w, 0, txt)
    pno = pdf.get_page
    assert_equal 1, pno
    y2 = pdf.get_y
    h1 = y2 - y1

    h2 = pdf.getStringHeight(w, txt)
    assert_in_delta h1, h2, 0.01

    line = pdf.get_num_lines(txt, w)
    assert_equal 3, line


    w = 5
    y1 = pdf.get_y
    pdf.multi_cell(w, 0, txt)
    pno = pdf.get_page
    assert_equal 1, pno
    y2 = pdf.get_y
    h1 = y2 - y1

    h2 = pdf.getStringHeight(w, txt)
    assert_in_delta h1, h2, 0.01

    line = pdf.get_num_lines(txt, w)
    assert_equal 7, line
  end

  test "getStringHeight Multi Line test" do
    pdf = RBPDF.new('P', 'mm', 'A4', true, "UTF-8", true)
    pdf.add_page

    txt = "abc\ndif\nhij"

    w = 100
    y1 = pdf.get_y
    pdf.multi_cell(w, 0, txt)
    pno = pdf.get_page
    assert_equal 1, pno
    y2 = pdf.get_y
    h1 = y2 - y1

    h2 = pdf.getStringHeight(w, txt)
    assert_in_delta h1, h2, 0.01

    line = pdf.get_num_lines(txt, w)
    assert_equal 3, line
  end

  test "getStringHeight Minimum Width test 1" do
    pdf = RBPDF.new('P', 'mm', 'A4', true, "UTF-8", true)
    pdf.add_page

    w = pdf.get_string_width('OO')

    txt = "Export to PDF: align is Good."

    y1 = pdf.get_y
    pdf.multi_cell(w, 0, txt)
    pno = pdf.get_page
    assert_equal 1, pno
    y2 = pdf.get_y
    h1 = y2 - y1

    h2 = pdf.getStringHeight(w, txt)
    assert_in_delta h1, h2, 0.01

    line = pdf.get_num_lines(txt, w)
    assert_equal 16, line
  end

 test "getStringHeight Minimum Width test 2" do
    pdf = RBPDF.new('L', 'mm', 'A4', true, "UTF-8", true)
    pdf.set_font('kozminproregular', '', 8)
    pdf.add_page

    margins = pdf.get_margins
    w = pdf.get_string_width('20') + margins['cell'] * 2

    txt = "20"

    y1 = pdf.get_y
    pdf.multi_cell(w, 0, txt)
    pno = pdf.get_page
    assert_equal 1, pno
    y2 = pdf.get_y
    h1 = y2 - y1

    h2 = pdf.getStringHeight(w, txt)
    assert_in_delta h1, h2, 0.01

    line = pdf.get_num_lines(txt, w)
    assert_equal 2, line
  end

  test "getStringHeight Minimum Bidi test 1" do
    pdf = RBPDF.new('P', 'mm', 'A4', true, "UTF-8", true)
    pdf.add_page

    w = pdf.get_string_width('OO')

    txt  = "\xd7\xa2\xd7\x91\xd7\xa8\xd7\x99\xd7\xaa"
    y1 = pdf.get_y
    pdf.multi_cell(w, 0, txt)
    pno = pdf.get_page
    assert_equal 1, pno
    y2 = pdf.get_y
    h1 = y2 - y1
    h2 = pdf.getStringHeight(w, txt)
    assert_in_delta h1, h2, 0.01

    line = pdf.get_num_lines(txt, w)
    assert_equal 5, line

    txt = "? \xd7\x93\xd7\x92 \xd7\xa1\xd7\xa7\xd7\xa8\xd7\x9f \xd7\xa9\xd7\x98 \xd7\x91\xd7\x99\xd7\x9d \xd7\x9e\xd7\x90\xd7\x95\xd7\x9b\xd7\x96\xd7\x91 \xd7\x95\xd7\x9c\xd7\xa4\xd7\xaa\xd7\xa2 \xd7\x9e\xd7\xa6\xd7\x90 \xd7\x9c\xd7\x95 \xd7\x97\xd7\x91\xd7\xa8\xd7\x94 \xd7\x90\xd7\x99\xd7\x9a \xd7\x94\xd7\xa7\xd7\x9c\xd7\x99\xd7\x98\xd7\x94"

    y1 = pdf.get_y
    pdf.multi_cell(w, 0, txt)
    pno = pdf.get_page
    assert_equal 1, pno
    y2 = pdf.get_y
    h1 = y2 - y1

    h2 = pdf.getStringHeight(w, txt)
    assert_in_delta h1, h2, 0.01

    line = pdf.get_num_lines(txt, w)
    assert_equal 41, line
  end

  test "getStringHeight Minimum Bidi test 2" do
    pdf = RBPDF.new('P', 'mm', 'A4', true, "UTF-8", true)
    pdf.set_font('freesans', '')
    pdf.set_rtl(true)
    pdf.set_temp_rtl('R')
    pdf.add_page

    margins = pdf.get_margins
    w = pdf.get_string_width('OO') + margins['cell'] * 2

    txt =  "\xd7\x9c 000"

    y1 = pdf.get_y
    pdf.multi_cell(w, 0, txt)
    pno = pdf.get_page
    assert_equal 1, pno
    y2 = pdf.get_y
    h1 = y2 - y1

    h2 = pdf.getStringHeight(w, txt)
    assert_in_delta h1, h2, 0.01

    line = pdf.get_num_lines(txt, w)
    assert_equal 3, line
  end

  test "removeSHY encoding test" do
    return unless 'test'.respond_to?(:force_encoding)

    pdf = RBPDF.new('P', 'mm', 'A4', true, "UTF-8", true)

    str = 'test'.force_encoding('UTF-8')
    txt = pdf.removeSHY(str)
    assert_equal 'UTF-8', str.encoding.to_s

    str = 'test'.force_encoding('ASCII-8BIT')
    txt = pdf.removeSHY(str)
    assert_equal 'ASCII-8BIT', str.encoding.to_s
  end
end
