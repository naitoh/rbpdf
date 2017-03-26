# Copyright (c) 2011-2017 NAITOH Jun
# Released under the MIT license
# http://www.opensource.org/licenses/MIT

require 'test_helper'

class RbpdfFontFuncTest < Test::Unit::TestCase
  class MYPDF < RBPDF
    def putAPXObject(w=0, h=0, stream='')
      super
    end
  end
  test "Font get_font_descent function test 1" do
    pdf = RBPDF.new
    fontdescent = pdf.get_font_descent('times', '', 18)
    assert_in_delta 0.95, fontdescent, 0.01
  end

  test "Font get_font_descent function test 2" do
    pdf = RBPDF.new
    fontdescent = pdf.get_font_descent('freesans', '', 18)
    assert_in_delta 1.91, fontdescent, 0.01
  end

  test "Font get_font_ascent function test 1" do
    pdf = RBPDF.new
    fontascent = pdf.get_font_ascent('times', '', 18)
    assert_in_delta 5.39, fontascent, 0.01
  end

  test "Font get_font_ascent function test 2" do
    pdf = RBPDF.new
    fontascent = pdf.get_font_ascent('freesans', '', 18)
    assert_in_delta 6.35, fontascent, 0.01
  end

  test "putAPXObject test" do
    pdf = MYPDF.new

    apxo_obj_id = pdf.putAPXObject
    assert_equal 400001, apxo_obj_id
    apxo_obj_id = pdf.putAPXObject
    assert_equal 400002, apxo_obj_id
  end
end
