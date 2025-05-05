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

  test "linear_gradient test" do
    # set colors for gradients (r,g,b) or (grey 0-255)
    red = [255, 0, 0]
    blue = [0, 0, 200]
    # set the coordinates x1,y1,x2,y2 of the gradient (see linear_gradient_coords.jpg)
    coords = [0, 0, 1, 0]

    pdf = MYPDF.new
    pdf.add_page()
    page = pdf.get_page
    pdf.linear_gradient(20, 45, 80, 80, red, blue, coords)

    contents = pdf.getPageBuffer(page)
    before_size = contents.split("\n").size
    pdf.putshaders

    content = []
    contents = pdf.getPageBuffer(page)
    contents.each_line {|line| content.push line.chomp }

    assert_equal "<< /FunctionType 3 /Domain [0 1] /Functions [4 0 R] /Bounds [] /Encode [0 1] >> endobj", content[before_size + 1]
    assert_equal "<< /FunctionType 2 /Domain [0 1] /C0 [1.000 0.000 0.000] /C1 [0.000 0.000 0.784] /N 1 >> endobj", content[before_size + 3]
    assert_equal "<< /ShadingType 2 /ColorSpace /DeviceRGB /Coords [0.000 0.000 1.000 0.000] /Domain [0 1] /Function 3 0 R /Extend [true true] >> endobj", content[before_size + 5]
    assert_equal "<< /Type /Pattern /PatternType 2 /Shading 5 0 R >> endobj", content[before_size + 7]
  end

  test "radial_gradient test" do
    # set colors for gradients (r,g,b) or (grey 0-255)
    white = [255]
    black = [0]
    # set the coordinates fx,fy,cx,cy,r of the gradient (see radial_gradient_coords.jpg)
    coords = [0.5, 0.5, 1, 1, 1.2]

    pdf = MYPDF.new
    pdf.add_page()
    page = pdf.get_page
    pdf.radial_gradient(110, 45, 80, 80, white, black, coords)

    contents = pdf.getPageBuffer(page)
    before_size = contents.split("\n").size
    pdf.putshaders

    content = []
    contents = pdf.getPageBuffer(page)
    contents.each_line {|line| content.push line.chomp }

    assert_equal "<< /FunctionType 3 /Domain [0 1] /Functions [4 0 R] /Bounds [] /Encode [0 1] >> endobj", content[before_size + 1]
    assert_equal "<< /FunctionType 2 /Domain [0 1] /C0 [1.000] /C1 [0.000] /N 1 >> endobj", content[before_size + 3]
    assert_equal "<< /ShadingType 3 /ColorSpace /DeviceGray /Coords [0.500 0.500 0 1.000 1.000 1.200] /Domain [0 1] /Function 3 0 R /Extend [true true] >> endobj", content[before_size + 5]
    assert_equal "<< /Type /Pattern /PatternType 2 /Shading 5 0 R >> endobj", content[before_size + 7]
  end

  test "coons_patch_mesh test" do
    # set colors for gradients (r,g,b) or (grey 0-255)
    red = [255, 0, 0]
    blue = [0, 0, 200]
    yellow = [255, 255, 0]
    green = [0, 255, 0]

    # set the coordinates for the cubic B�zier points x1,y1 ... x12, y12 of the patch (see coons_patch_mesh_coords.jpg)
    coords = [
      0.00, 0.00, 0.33, 0.20,             # lower left
      0.67, 0.00, 1.00, 0.00, 0.80, 0.33, # lower right
      0.80, 0.67, 1.00, 1.00, 0.67, 0.80, # upper right
      0.33, 1.00, 0.00, 1.00, 0.20, 0.67, # upper left
      0.00, 0.33]                         # lower left
    coords_min = 0 # minimum value of the coordinates
    coords_max = 1 # maximum value of the coordinates

    pdf = MYPDF.new
    pdf.add_page()
    page = pdf.get_page
    pdf.coons_patch_mesh(110, 155, 80, 80, yellow, blue, green, red, coords, coords_min, coords_max)

    contents = pdf.getPageBuffer(page)
    before_size = contents.split("\n").size
    pdf.putshaders

    content = []
    contents = pdf.getPageBuffer(page)
    contents.each_line {|line| content.push line.chomp }

    assert_equal "<< /ShadingType 6 /ColorSpace /DeviceRGB /BitsPerCoordinate 16 /BitsPerComponent 8 /Decode[0 1 0 1 0 1 0 1 0 1] /BitsPerFlag 8 /Length 61 >> stream", content[before_size + 1]
    assert_equal (+"\x00\x00\x00\x00\x00Tz33\xAB\x84\x00\x00\xFF\xFF\x00\x00\xCC\xCCTz\xCC\xCC\xAB\x84\xFF\xFF\xFF\xFF\xAB\x84\xCC\xCCTz\xFF\xFF\x00\x00\xFF\xFF33\xAB\x84\x00\x00Tz\xFF\xFF\x00\x00\x00\xC8\x00\xFF\x00\xFF\x00\x00").force_encoding('ASCII-8BIT'), content[before_size + 2]
    assert_equal "endstream endobj", content[before_size + 3]
    assert_equal "<< /Type /Pattern /PatternType 2 /Shading 3 0 R >> endobj", content[before_size + 5]
  end
end
