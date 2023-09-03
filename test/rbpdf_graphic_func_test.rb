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
end
