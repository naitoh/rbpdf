# Copyright (c) 2011-2017 NAITOH Jun
# Released under the MIT license
# http://www.opensource.org/licenses/MIT

require 'test_helper'

class RbpdfFontStyleTest < Test::Unit::TestCase
  class MYPDF < RBPDF
    def dounderline(x, y, txt)
      super
    end
    def dolinethrough(x, y, txt)
      super
    end
    def dooverline(x, y, txt)
      super
    end
  end

  test "Font dounderline function test 1" do
    pdf = MYPDF.new
    line = pdf.dounderline(10, 10, "test")
    assert_equal '28.35 812.94 19.34 -0.60 re f', line
  end

  test "Font dolinethrough function test 1" do
    pdf = MYPDF.new
    line = pdf.dolinethrough(10, 10, "test")
    assert_equal '28.35 816.94 19.34 -0.60 re f', line
  end

  test "Font dooverline function test 1" do
    pdf = MYPDF.new
    line = pdf.dooverline(10, 10, "test")
    assert_equal '28.35 824.34 19.34 -0.60 re f', line
  end
end
