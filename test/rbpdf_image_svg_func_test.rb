# coding: ASCII-8BIT
# Copyright (c) 2011-2023 NAITOH Jun
# Released under the MIT license
# http://www.opensource.org/licenses/MIT

require 'test_helper'

class RbpdfTest < Test::Unit::TestCase
  class MYPDF < RBPDF
    def parse_svg_tag_attributes(file, w, h)
      super
    end
  end

  test "SVG parse_svg_tag_attributes x y (no width height) test" do
    tf = Tempfile.open(['test', '.svg']) do |fp|
      fp.puts '<svg xmlns="http://www.w3.org/2000/svg" x="10" y="20"></svg>'
      fp
    end

    pdf = MYPDF.new
    w, h, ox, oy, ow, oh, aspect_ratio_align, aspect_ratio_ms = pdf.parse_svg_tag_attributes(tf.path, 0, 0)
    assert_equal 0, w
    assert_equal 0, h
    assert_equal 3.5277777777777772, ox
    assert_equal 7.0555555555555545, oy
    assert_equal nil, ow
    assert_equal nil, oh
    assert_equal "xMidYMid", aspect_ratio_align
    assert_equal "meet", aspect_ratio_ms
  end

  test "SVG parse_svg_tag_attributes x y (width height 100%) test" do
    tf = Tempfile.open(['test', '.svg']) do |fp|
      fp.puts '<svg xmlns="http://www.w3.org/2000/svg" x="10" y="20" width="100%" height="100%"></svg>'
      fp
    end

    pdf = MYPDF.new
    w, h, ox, oy, ow, oh, aspect_ratio_align, aspect_ratio_ms = pdf.parse_svg_tag_attributes(tf.path, 10, 20)
    assert_equal 10.0, w
    assert_equal 20.0, h
    assert_equal 3.5277777777777772, ox
    assert_equal 7.0555555555555545, oy
    assert_equal 10.0, ow
    assert_equal 20.0, oh
    assert_equal "xMidYMid", aspect_ratio_align
    assert_equal "meet", aspect_ratio_ms
  end

  test "SVG parse_svg_tag_attributes x y width height test" do
    tf = Tempfile.open(['test', '.svg']) do |fp|
      fp.puts '<svg xmlns="http://www.w3.org/2000/svg" x="10" y="20" width="200" height="200"></svg>'
      fp
    end

    pdf = MYPDF.new
    w, h, ox, oy, ow, oh, aspect_ratio_align, aspect_ratio_ms = pdf.parse_svg_tag_attributes(tf.path, 0, 0)
    assert_equal 70.55555555555554, w
    assert_equal 70.55555555555554, h
    assert_equal 3.5277777777777772, ox
    assert_equal 7.0555555555555545, oy
    assert_equal 70.55555555555554, ow
    assert_equal 70.55555555555554, oh
    assert_equal "xMidYMid", aspect_ratio_align
    assert_equal "meet", aspect_ratio_ms
  end

  test "SVG parse_svg_tag_attributes viewBox test" do
    datas = [
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 80"></svg>',
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox=" 0 ,0, 64,80 "></svg>',
    ]

    datas.each do |data|
      tf = Tempfile.open(['test', '.svg']) do |fp|
        fp.puts data
        fp
      end
      pdf = MYPDF.new
      w, h, ox, oy, ow, oh, aspect_ratio_align, aspect_ratio_ms = pdf.parse_svg_tag_attributes(tf.path, 0, 0)
      assert_equal 22.577777777777776, w
      assert_equal 28.222222222222218, h
      assert_equal 0, ox
      assert_equal 0, oy
      assert_equal 22.577777777777776, ow
      assert_equal 28.222222222222218, oh
      assert_equal "xMidYMid", aspect_ratio_align
      assert_equal "meet", aspect_ratio_ms
    end
  end
end
