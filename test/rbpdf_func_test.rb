# Copyright (c) 2011-2017 NAITOH Jun
# Released under the MIT license
# http://www.opensource.org/licenses/MIT

require 'test_helper'

class RbpdfTest < Test::Unit::TestCase
  class MYPDF < RBPDF
    def getSpaceString
      super
    end
  end

  test "get_html_unit_to_units test" do
    pdf = RBPDF.new
    unit = pdf.get_html_unit_to_units("100", 1)
    assert_in_delta 35.27, unit, 0.01

    unit = pdf.get_html_unit_to_units("100px", 1, 'px', false)
    assert_in_delta 35.27, unit, 0.01

    unit = pdf.get_html_unit_to_units(100, 1, 'pt', false)
    assert_in_delta 35.27, unit, 0.01

    unit = pdf.get_html_unit_to_units(100.0, 1, 'pt', false)
    assert_in_delta 35.27, unit, 0.01

    unit = pdf.get_html_unit_to_units("100.0", 1, 'pt', false)
    assert_in_delta 35.27, unit, 0.01

    unit = pdf.get_html_unit_to_units("200", 1, '%', false)
    assert_equal 2.0, unit

    unit = pdf.get_html_unit_to_units("400%", 1, '%', false)
    assert_equal 4.0, unit

    unit = pdf.get_html_unit_to_units("10", 1, '%', false)
    assert_equal 0.1, unit

    unit = pdf.get_html_unit_to_units("10mm", 1, '%', false)
    assert_in_delta 10, unit, 0.01

    unit = pdf.get_html_unit_to_units("10", 1, 'mm', false)
    assert_in_delta 10, unit, 0.01

    unit = pdf.get_html_unit_to_units(10, 1, 'mm', false)
    assert_in_delta 10, unit, 0.01

    unit = pdf.get_html_unit_to_units("1", 1, 'cm', false)
    assert_in_delta 10, unit, 0.01

    unit = pdf.get_html_unit_to_units(10, 1, 'em', false)
    assert_equal 10, unit

    unit = pdf.get_html_unit_to_units(10, 2, 'em', false)
    assert_equal 20, unit
  end

  test "getSpaceString test" do
    pdf = MYPDF.new
    spacestr = pdf.getSpaceString()
    assert_equal 32.chr, spacestr

    pdf.set_font('freesans', '', 18)
    spacestr = pdf.getSpaceString()
    assert_equal 0.chr + 32.chr, spacestr
  end

  test "revstrpos test" do
    pdf = RBPDF.new
    pos = pdf.revstrpos('abcd efgh ', 'cd')
    assert_equal 2, pos

    pos = pdf.revstrpos('abcd efgh ', 'cd ')
    assert_equal 2, pos

    pos = pdf.revstrpos('abcd efgh abcd efg', 'cd')
    assert_equal 12, pos

    pos = pdf.revstrpos('abcd efgh abcd efg', 'zy')
    assert_equal nil, pos
  end

  test "revstrpos offset test 1" do
    pdf = RBPDF.new

    pos = pdf.revstrpos('abcd efgh ', 'cd', 3)          # 'abc'
    assert_equal pos, nil

    pos = pdf.revstrpos('abcd efgh ', 'cd', 4)          # 'abcd'
    assert_equal pos, 2

    pos = pdf.revstrpos('abcd efgh abcd efg', 'cd', 3)  # 'abc'
    assert_equal pos, nil

    pos = pdf.revstrpos('abcd efgh abcd efg', 'cd', 4)  # 'abcd'
    assert_equal pos, 2

    pos = pdf.revstrpos('abcd efgh abcd efg', 'cd', 13) # 'abcd efgh abc'
    assert_equal pos, 2 

    pos = pdf.revstrpos('abcd efgh abcd efg', 'cd', 14) # 'abcd efgh abcd'
    assert_equal pos, 12
  end

  test "revstrpos offset test 2" do
    pdf = RBPDF.new

    pos = pdf.revstrpos('abcd efgh ', 'cd', -6)         # 'abcd'
    assert_equal pos, 2

    pos = pdf.revstrpos('abcd efgh ', 'cd', -7)         # 'abc'
    assert_equal pos, nil

    pos = pdf.revstrpos('abcd efgh abcd efg', 'cd', -4) # 'abcd efgh abcd'
    assert_equal pos, 12

    pos = pdf.revstrpos('abcd efgh abcd efg', 'cd', -5) # 'abcd efgh abc'
    assert_equal pos, 2
  end

  test "set_line_style Basic test" do
    pdf = RBPDF.new

    pdf.set_line_style({'width' => 0.1, 'cap' => 'butt', 'join' => 'miter', 'dash' => 0, 'color' => [0, 0, 0]})
    pdf.set_line_style({'width' => 0.1, 'cap' => 'butt', 'join' => 'miter', 'dash' => '', 'phase' => 0, 'color' => [255, 0, 0]})
    pdf.set_line_style({'width' => 0.1, 'cap' => 'butt', 'join' => 'miter', 'dash' => '1,2,3,4', 'phase' => 0, 'color' => [255, 0, 0]})
    pdf.set_line_style({'width' => 0.1, 'cap' => 'butt', 'join' => 'miter', 'dash' => 'a', 'phase' => 0, 'color' => [255, 0, 0]}) # Invalid
  end

  test "get_string_width encoding test" do
    return unless 'test'.respond_to?(:force_encoding)

    pdf = RBPDF.new
    str = 'test'.force_encoding('UTF-8')
    pdf.get_string_width(str)
    assert_equal 'UTF-8', str.encoding.to_s
  end
end
