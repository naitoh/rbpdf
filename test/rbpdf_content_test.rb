# coding: ASCII-8BIT
#
# Copyright (c) 2011-2017 NAITOH Jun
# Released under the MIT license
# http://www.opensource.org/licenses/MIT

require 'test_helper'

class RbpdfPageTest < Test::Unit::TestCase
  class MYPDF < RBPDF
    def getPageBuffer(page)
      super
    end
  end

  test "Basic Page content test" do
    pdf = MYPDF.new

    page = pdf.get_page
    assert_equal 0, page

    pdf.set_print_header(false)
    pdf.add_page
    page = pdf.get_page
    assert_equal 1, page

    content = []
    contents = pdf.getPageBuffer(page)
    contents.each_line {|line| content.push line.chomp }

    assert_equal 4, content.length
    assert_equal "0.57 w 0 J 0 j [] 0 d 0 G 0 g", content[0]
    assert_equal "BT /F1 12.00 Tf ET ",           content[1]
    assert_equal "0.57 w 0 J 0 j [] 0 d 0 G 0 g", content[2]
    assert_equal "BT /F1 12.00 Tf ET ",           content[3]

    ##################################
    #  0.57 w 0 J 0 j [] 0 d 0 G 0 g # add_page,start_page,setGraphicVars(set_fill_color)
    #  BT /F1 12.00 Tf ET            #
    #  0.57 w 0 J 0 j [] 0 d 0 G 0 g #
    #  BT /F1 12.00 Tf ET            #
    ##################################
    # 0.57 w               # @linestyle_width    : Line width.
    # 0 J                  # @linestyle_cap      : Type of cap to put on the line. [butt:0, round:1, square:2]
    # 0 j                  # @linestyle_join     : Type of join. [miter:0, round:1, bevel:2]
    # [] 0 d               # @linestyle_dash     : Line dash pattern. (see set_line_style)
    # 0 G                  # @draw_color         : Drawing color. (see set_draw_color)
    # 0 g                  # Set colors
    ########################
    # BT                   # Begin Text.
    #   /F1 12.00 Tf       # 12.00 point size font.
    # ET                   # End Text.
    ########################

    pdf.set_font('freesans', 'BI', 18)
    content = []
    contents = pdf.getPageBuffer(page)
    contents.each_line {|line| content.push line.chomp }

    assert_equal 5, content.length
    assert_equal "BT /F2 18.00 Tf ET ", content[4]

    ########################
    # BT                   # Begin Text.
    #   /F2 18.00 Tf       # 18.00 point size font.
    # ET                   # End Text.
    ########################
    pdf.set_font('freesans', 'B', 20)
    content = []
    contents = pdf.getPageBuffer(page)
    contents.each_line {|line| content.push line.chomp }

    assert_equal 6, content.length
    assert_equal "BT /F3 20.00 Tf ET ", content[5]

    pdf.cell(0, 10, 'Chapter', 0, 1, 'L')
    content = []
    contents = pdf.getPageBuffer(page)
    contents.each_line {|line| content.push line.chomp }

    assert_equal 8, content.length
    assert_equal "0.57 w 0 J 0 j [] 0 d 0 G 0 g", content[6]

    assert_match(/BT 31.1[89] 792.37 Td 0 Tr 0.00 w \[\(\x00C\x00h\x00a\x00p\x00t\x00e\x00r\)\] TJ ET/, content[7])

    #################################################
    # 0.57 w 0 J 0 j [] 0 d 0 G 0 g                 # getCellCode
    # BT
    #   31.19 792.37 Td                             # Set text offset.
    #   0 Tr 0.00 w                                 # Set stroke outline and clipping mode
    #   [(\x00C\x00h\x00a\x00p\x00t\x00e\x00r)] TJ  # Write array of characters.
    # ET
    #################################################
  end

  test "circle content" do
    pdf = MYPDF.new

    pdf.set_print_header(false)
    pdf.add_page
    pdf.circle(100, 200, 50)
    content = []
    contents = pdf.getPageBuffer(1)
    contents.each_line {|line| content.push line.chomp }

    assert_equal 15, content.length
    assert_equal "425.20 274.96 m"                            , content[4]  # start point : x0, y0

    assert_equal '425.20 308.27 413.45 340.54 392.04 366.06 c', content[5]  # 1/9 circle  : x1, y1(control point 1), x2, y2(control point 2), x3, y3(end point and next start point)
    assert_equal '370.62 391.58 340.88 408.76 308.08 414.54 c', content[6]  # 2/9 circle
    assert_equal '275.27 420.32 241.45 414.36 212.60 397.70 c', content[7]  # 3/9 circle
    assert_equal '183.75 381.05 161.67 354.74 150.28 323.44 c', content[8]  # 4/9 circle
    assert_equal '138.89 292.13 138.89 257.79 150.28 226.49 c', content[9]  # 5/9 circle
    assert_equal '161.67 195.18 183.75 168.87 212.60 152.22 c', content[10] # 6/9 circle
    assert_equal '241.45 135.56 275.27 129.60 308.08 135.38 c', content[11] # 7/9 circle
    assert_equal '340.88 141.17 370.62 158.34 392.04 183.86 c', content[12] # 8/9 circle
    assert_equal '413.45 209.38 425.20 241.65 425.20 274.96 c', content[13] # 9/9 circle
    assert_equal 'S'                                          , content[14]
  end

  test "write content test" do
    pdf = MYPDF.new
    pdf.add_page()
    page = pdf.get_page
    assert_equal 1, page

    content = []
    pdf.write(0, "abc def")
    contents = pdf.getPageBuffer(page)
    contents.each_line {|line| content.push line.chomp }
    assert_equal 22, content.length
    assert_match(/BT 31.1[89] 801.84 Td 0 Tr 0.00 w \[\(abc def\)\] TJ ET/, content[21])
  end

  test "write content RTL test" do
    pdf = MYPDF.new
    pdf.set_rtl(true)
    pdf.add_page()
    page = pdf.get_page
    assert_equal 1, page

    content = []
    pdf.write(0, "abc def")
    contents = pdf.getPageBuffer(page)
    contents.each_line {|line| content.push line.chomp }
    assert_equal 22, content.length
    assert_match(/BT 524.7[34] 801.84 Td 0 Tr 0.00 w \[\(abc def\)\] TJ ET/, content[21])
  end

  test "write content back slash test" do
    pdf = MYPDF.new
    pdf.add_page()
    page = pdf.get_page
    assert_equal 1, page

    content = []
    pdf.write(0, "abc \\def") # use escape() method in getCellCode()
    contents = pdf.getPageBuffer(page)
    contents.each_line {|line| content.push line.chomp }
    assert_equal 22, content.length
    assert_match(/BT 31.1[89] 801.84 Td 0 Tr 0.00 w \[\(abc \\\\def\)\] TJ ET/, content[21])
  end

  test "write Persian Sunday content test" do
    pdf = MYPDF.new
    pdf.set_font('dejavusans', '', 18)
    pdf.add_page()
    page = pdf.get_page
    assert_equal 1, page

    utf8_persian_str_sunday = "\xdb\x8c\xda\xa9\xe2\x80\x8c\xd8\xb4\xd9\x86\xd8\xa8\xd9\x87"
    content = []
    pdf.write(0, utf8_persian_str_sunday)
    contents = pdf.getPageBuffer(page)

    contents.each_line {|line| content.push line.chomp }
    assert_equal 22, content.length
    assert_match(/BT 31.1[89] 796.06 Td 0 Tr 0.00 w \[\(\xFE\xEA\xFE\x92\xFE\xE8\xFE\xB7 \f\xFB\x8F\xFB\xFE\)\] TJ ET/, content[21])

    pdf.set_rtl(true)
    pdf.write(0, utf8_persian_str_sunday)
    contents = pdf.getPageBuffer(page)

    contents.each_line {|line| content.push line.chomp }
    assert_equal 46, content.length
    assert_equal "BT 507.38 796.06 Td 0 Tr 0.00 w [(\xFE\xEA\xFE\x92\xFE\xE8\xFE\xB7 \f\xFB\x8F\xFB\xFE)] TJ ET", content[45]
  end

  test "write English and Persian Sunday content test" do
    pdf = MYPDF.new
    pdf.set_font('dejavusans', '', 18)
    pdf.add_page()
    page = pdf.get_page
    assert_equal 1, page

    utf8_persian_str_sunday = "\xdb\x8c\xda\xa9\xe2\x80\x8c\xd8\xb4\xd9\x86\xd8\xa8\xd9\x87"
    content = []
    pdf.write(0, 'abc def ' + utf8_persian_str_sunday)
    contents = pdf.getPageBuffer(page)

    contents.each_line {|line| content.push line.chomp }
    assert_equal 22, content.length
    assert_match(/BT 31.1[89] 796.06 Td 0 Tr 0.00 w \[\(\x00a\x00b\x00c\x00 \x00d\x00e\x00f\x00 \xFE\xEA\xFE\x92\xFE\xE8\xFE\xB7 \f\xFB\x8F\xFB\xFE\)\] TJ ET/, content[21])

    pdf.set_rtl(true)
    pdf.write(0, 'abc def ' + utf8_persian_str_sunday)
    contents = pdf.getPageBuffer(page)

    contents.each_line {|line| content.push line.chomp }
    assert_equal 46, content.length
    assert_equal "BT 434.73 796.06 Td 0 Tr 0.00 w [(\xFE\xEA\xFE\x92\xFE\xE8\xFE\xB7 \f\xFB\x8F\xFB\xFE\x00 \x00a\x00b\x00c\x00 \x00d\x00e\x00f)] TJ ET", content[45]
  end
end
