# frozen_string_literal: true
# Copyright (c) 2011-2023 NAITOH Jun
# Released under the MIT license
# http://www.opensource.org/licenses/MIT

require 'test_helper'

class RbpdfPageTest < Test::Unit::TestCase
  class MYPDF < RBPDF
    def putshaders
      super
    end

    def getPageBuffer(page)
      super
    end
  end

  test "set_line_style test" do
    pdf = MYPDF.new
    pdf.add_page()
    page = pdf.get_page
    contents = pdf.getPageBuffer(page)
    before_size = contents.split("\n").size
    pdf.putshaders
    pdf.set_line_style({'width' => 0.1, 'cap' => 'butt', 'join' => 'miter', 'dash' => '1,2,3,4', 'phase' => 1, 'color' => [255, 0, 0]})

    content = []
    contents = pdf.getPageBuffer(page)
    contents.each_line {|line| content.push line.chomp }

    assert_equal "0.28 w", content[before_size] # 'width' => 0.1
    assert_equal "0 J", content[before_size + 1] # 'cap' => 'butt'
    assert_equal "0 j", content[before_size + 2] # 'join' => 'miter
    assert_equal "[1.00 2.00 3.00 4.00] 1.00 d", content[before_size + 3] #  'dash' => '1,2,3,4', 'phase' => 1
    assert_equal "1.000 0.000 0.000 RG ", content[before_size + 4] # 'color' => [255, 0, 0]
  end

  test "line without style test" do
    pdf = MYPDF.new
    pdf.add_page()
    page = pdf.get_page
    contents = pdf.getPageBuffer(page)
    before_size = contents.split("\n").size
    pdf.putshaders
    pdf.line(5, 10, 80, 30)
    content = []
    contents = pdf.getPageBuffer(page)
    contents.each_line {|line| content.push line.chomp }

    assert_equal "14.17 813.54 m", content[before_size] # outPoint(x1, y1)
    assert_equal "226.77 756.85 l", content[before_size + 1] # outLine(x2, y2)
    assert_equal "S", content[before_size + 2]
  end

  test "line with style test" do
    pdf = MYPDF.new
    pdf.add_page()
    page = pdf.get_page
    contents = pdf.getPageBuffer(page)
    before_size = contents.split("\n").size
    pdf.putshaders
    style = {'width' => 0.1, 'cap' => 'round', 'join' => 'bevel', 'dash' => 0, 'color' => [0, 255, 0]}
    pdf.line(5, 10, 80, 30, style)
    content = []
    contents = pdf.getPageBuffer(page)
    contents.each_line {|line| content.push line.chomp }

    # set_line_style start
    assert_equal "0.28 w", content[before_size] # 'width' => 0.1
    assert_equal "1 J", content[before_size + 1] # 'cap' => 'round'
    assert_equal "2 j", content[before_size + 2] # 'join' => 'bevel
    assert_equal "[] 0.00 d", content[before_size + 3] #  'dash' => 0
    assert_equal "0.000 1.000 0.000 RG ", content[before_size + 4] # 'color' => [0, 255, 0]
    # set_line_style end

    assert_equal "14.17 813.54 m", content[before_size + 5] # outPoint(x1, y1)
    assert_equal "226.77 756.85 l", content[before_size + 6] # outLine(x2, y2)
    assert_equal "S", content[before_size + 7]
  end

  test "rect basic test" do
    pdf = MYPDF.new
    pdf.add_page()
    page = pdf.get_page
    contents = pdf.getPageBuffer(page)
    before_size = contents.split("\n").size
    pdf.putshaders
    style = { 'L' => nil, 'T' => nil, 'R' => nil, 'B' => nil }
    pdf.rect(30, 40, 60, 60, '', style)

    content = []
    contents = pdf.getPageBuffer(page)
    contents.each_line {|line| content.push line.chomp }

    assert_equal "85.04 728.50 170.08 -170.08 re S", content[before_size] # outRect(x, y, w, h, op)
  end

  test "rect with style & fill_color test" do
    pdf = MYPDF.new
    pdf.add_page()
    page = pdf.get_page
    contents = pdf.getPageBuffer(page)
    before_size = contents.split("\n").size
    pdf.putshaders
    pdf.rect(30, 40, 60, 60, 'F', {}, [220, 220, 200])

    content = []
    contents = pdf.getPageBuffer(page)
    contents.each_line {|line| content.push line.chomp }
    assert_equal "0.863 0.863 0.784 rg", content[before_size] # SetFillColorArray(fill_color)
    assert_equal "85.04 728.50 170.08 -170.08 re f", content[before_size + 1] # outRect(x, y, w, h, op)
  end

  test "rect with border_style 'all' test" do
    pdf = MYPDF.new
    pdf.add_page()
    page = pdf.get_page
    contents = pdf.getPageBuffer(page)
    before_size = contents.split("\n").size
    pdf.putshaders

    style = {'width' => 0.1, 'cap' => 'square', 'join' => 'round', 'dash' => 0, 'color' => [0, 64, 128]}
    pdf.rect(30, 40, 60, 60, '', { 'all' => style })

    content = []
    contents = pdf.getPageBuffer(page)
    contents.each_line {|line| content.push line.chomp }

    # set_line_style start
    assert_equal "0.28 w", content[before_size] # 'width' => 0.1
    assert_equal "2 J", content[before_size + 1] # 'cap' => 'square'
    assert_equal "1 j", content[before_size + 2] # 'join' => 'round'
    assert_equal "[] 0.00 d", content[before_size + 3] #  'dash' => 0
    assert_equal "0.000 0.251 0.502 RG ", content[before_size + 4] # 'color' => [0, 255, 0]
    # set_line_style end

    assert_equal "85.04 728.50 170.08 -170.08 re S", content[before_size + 5] # outRect(x, y, w, h, op)
  end

  test "rect with border_style 'LTRB' test" do
    pdf = MYPDF.new
    pdf.add_page()
    page = pdf.get_page
    contents = pdf.getPageBuffer(page)
    before_size = contents.split("\n").size
    pdf.putshaders

    style = { 'L' => {'width' => 0.1}, 'T' => {'width' => 0.1}, 'R' => {'width' => 0.1}, 'B' => {'width' => 0.1} }
    pdf.rect(30, 40, 60, 60, '', style)

    content = []
    contents = pdf.getPageBuffer(page)
    contents.each_line {|line| content.push line.chomp }

    assert_equal "85.04 728.50 170.08 -170.08 re S", content[before_size] # outRect(x, y, w, h, op)

    # line start
    assert_equal "0.28 w", content[before_size + 1] # 'width' => 0.1
    assert_equal "85.04 728.50 m", content[before_size + 2] # outPoint(x1, y1)
    assert_equal "85.04 558.43 l", content[before_size + 3] # outLine(x2, y2)
    assert_equal "S", content[before_size + 4]

    assert_equal "0.28 w", content[before_size + 5] # 'width' => 0.1
    assert_equal "85.04 728.50 m", content[before_size + 6] # outPoint(x1, y1)
    assert_equal "255.12 728.50 l", content[before_size + 7] # outLine(x2, y2)
    assert_equal "S", content[before_size + 8]

    assert_equal "0.28 w", content[before_size + 9] # 'width' => 0.1
    assert_equal "255.12 728.50 m", content[before_size + 10] # outPoint(x1, y1)
    assert_equal "255.12 558.43 l", content[before_size + 11] # outLine(x2, y2)
    assert_equal "S", content[before_size + 12]

    assert_equal "0.28 w", content[before_size + 13] # 'width' => 0.1
    assert_equal "85.04 558.43 m", content[before_size + 14] # outPoint(x1, y1)
    assert_equal "255.12 558.43 l", content[before_size + 15] # outLine(x2, y2)
    assert_equal "S", content[before_size + 16]
    # line end
  end

  test "rounded_rect basic test" do
    pdf = MYPDF.new
    pdf.add_page()
    page = pdf.get_page
    contents = pdf.getPageBuffer(page)
    before_size = contents.split("\n").size
    pdf.putshaders
    style = { 'L' => nil, 'T' => nil, 'R' => nil, 'B' => nil }
    pdf.rounded_rect(50, 255, 40, 30, 6.50)

    content = []
    contents = pdf.getPageBuffer(page)
    contents.each_line {|line| content.push line.chomp }

    assert_equal "160.16 119.06 m", content[before_size] # outPoint(x + rx, y)
    assert_equal "236.69 119.06 l", content[before_size + 1] # outLine(xc, y)
    assert_equal "246.87 119.06 255.12 110.81 255.12 100.63 c", content[before_size + 2] # outCurve(xc + (rx * myArc), yc - ry, xc + rx, yc - (ry * myArc), xc + rx, yc)
    assert_equal "255.12 52.44 l", content[before_size + 3] # outLine(x + w, yc)
    assert_equal "255.12 42.27 246.87 34.02 236.69 34.02 c", content[before_size + 4] # outCurve(xc + rx, yc + (ry * myArc), xc + (rx * myArc), yc + ry, xc, yc + ry)
    assert_equal "160.16 34.02 l", content[before_size + 5] # outLine(xc, y + h)
    assert_equal "149.98 34.02 141.73 42.27 141.73 52.44 c", content[before_size + 6] # outCurve(xc - (rx * myArc), yc + ry, xc - rx, yc + (ry * myArc), xc - rx, yc)
    assert_equal "141.73 100.63 l", content[before_size + 7] # outLine(x, yc)
    assert_equal "141.73 110.81 149.98 119.06 160.16 119.06 c", content[before_size + 8] # outCurve(xc - rx, yc - (ry * myArc), xc - (rx * myArc), yc - ry, xc, yc - ry)
    assert_equal "S", content[before_size + 9]
  end

  test "polygon basic test" do
    pdf = MYPDF.new
    pdf.add_page()
    page = pdf.get_page
    contents = pdf.getPageBuffer(page)
    before_size = contents.split("\n").size
    pdf.putshaders
    style = { 'L' => nil, 'T' => nil, 'R' => nil, 'B' => nil }
    pdf.polygon([5,135,45,135,15,165])

    content = []
    contents = pdf.getPageBuffer(page)
    contents.each_line {|line| content.push line.chomp }

    # draw = true
    assert_equal "14.17 459.21 m", content[before_size] # outPoint(p[0], p[1])
    assert_equal "127.56 459.21 l", content[before_size + 1] # outLine(p[i], p[i + 1])
    assert_equal "42.52 374.17 l", content[before_size + 2] # outLine(p[i], p[i + 1])
    assert_equal "14.17 459.21 l", content[before_size + 3] # outLine(p[i], p[i + 1])
    assert_equal "127.56 459.21 l", content[before_size + 4] # outLine(p[i], p[i + 1])
    assert_equal "S", content[before_size + 5]
  end

  test "polygon line_style test" do
    pdf = MYPDF.new
    pdf.add_page()
    page = pdf.get_page
    contents = pdf.getPageBuffer(page)
    before_size = contents.split("\n").size
    pdf.putshaders
    style = { 'L' => nil, 'T' => nil, 'R' => nil, 'B' => nil }
    style6 = {'width' => 0.5}
    pdf.polygon([5,135,45,135,15,165], 'D', [style6, 0, 0])

    content = []
    contents = pdf.getPageBuffer(page)
    contents.each_line {|line| content.push line.chomp }
    # draw = true
    assert_equal "14.17 459.21 m", content[before_size] # outPoint(p[0], p[1])
    assert_equal "S", content[before_size + 1]

    assert_equal "1.42 w", content[before_size + 2]
    assert_equal "14.17 459.21 m", content[before_size + 3] # outLine(p[i], p[i + 1])
    assert_equal "127.56 459.21 l", content[before_size + 4] # outLine(p[i], p[i + 1])
    assert_equal "S", content[before_size + 5]
    assert_equal "127.56 459.21 m", content[before_size + 6] # outLine(p[i], p[i + 1])
    assert_equal "S", content[before_size + 7]

    assert_equal "1.42 w", content[before_size + 8]
    assert_equal "14.17 459.21 m", content[before_size + 9] # outLine(p[i], p[i + 1])
    assert_equal "127.56 459.21 l", content[before_size + 10] # outLine(p[i], p[i + 1])
    assert_equal "S", content[before_size + 11]

    assert_equal "127.56 459.21 m", content[before_size + 12] # outLine(p[i], p[i + 1])
    assert_equal "S", content[before_size + 13]
  end
end
