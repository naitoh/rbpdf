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
end
