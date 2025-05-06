# coding: ASCII-8BIT
# Copyright (c) 2011-2023 NAITOH Jun
# Released under the MIT license
# http://www.opensource.org/licenses/MIT

require 'test_helper'

class RbpdfTest < Test::Unit::TestCase
  class MYPDF < RBPDF
    def startSVGElementHandler(name, attribs, clipping = false)
      super
    end
  end

  test "SVG basic test" do
    pdf = RBPDF.new
    pdf.add_page
    img_file = File.join(File.dirname(__FILE__), 'testsvg.svg')

    pdf.image_svg(img_file, 15, 30, 0, 0, '', '', '', 1, false)

    no = pdf.get_num_pages
    assert_equal 1, no
  end

  test "SVG basic rect test" do
    tf = Tempfile.open(['test', '.svg']) do |fp|
      fp.puts '<svg xmlns="http://www.w3.org/2000/svg" width="200" height="200">
        <rect x="10" y="10" width="50" height="30" style="stroke: black; fill: none"/>
      </svg>'
      fp
    end

    pdf = RBPDF.new
    pdf.image_svg(tf.path, 15, 30, 0, 0, '', '', '', 1, false)
  end

  test "SVG basic polyline & viewBox test" do
    tf = Tempfile.open(['test', '.svg']) do |fp|
      fp.puts '<svg xmlns="http://www.w3.org/2000/svg" width="4cm" height="5cm" viewBox="0 0 64 80">
        <polyline points="10 35, 30 7.68, 50 35" style="stroke: black; fill: none"/>
      </svg>'
      fp
    end

    pdf = RBPDF.new
    pdf.image_svg(tf.path, 15, 30, 0, 0, '', '', '', 1, false)
  end

  test "SVG basic circle & viewBox test" do
    tf = Tempfile.open(['test', '.svg']) do |fp|
      fp.puts '<svg xmlns="http://www.w3.org/2000/svg" width="4cm" height="5cm" viewBox="0 0 164 180">
        <circle cx="42" cy="57" r="30" stroke="black" fill="none"/>
      </svg>'
      fp
    end

    pdf = RBPDF.new
    pdf.image_svg(tf.path, 15, 30, 0, 0, '', '', '', 1, false)
  end
end
