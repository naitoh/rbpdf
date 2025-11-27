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

    def get_styling_properties(prev_svgstyle, attribs)
      super
    end

    def svg_path(d, style='')
      super
    end
  end

  test "SVG parse_svg_tag_attributes empty file test" do
    tf = Tempfile.open(['test', '.svg']) do |fp|
      fp.puts ''
      fp
    end

    pdf = MYPDF.new
    assert_raise(RBPDFError) {pdf.parse_svg_tag_attributes(tf.path, 0, 0)}
  end

  test "SVG parse_svg_tag_attributes (no x y width height viewBox) test" do
    tf = Tempfile.open(['test', '.svg']) do |fp|
      fp.puts '<svg xmlns="http://www.w3.org/2000/svg"></svg>'
      fp
    end

    pdf = MYPDF.new
    w, h, ox, oy, ow, oh, aspect_ratio_align, aspect_ratio_ms = pdf.parse_svg_tag_attributes(tf.path, 0, 0)
    assert_equal 0, w
    assert_equal 0, h
    assert_equal 0, ox
    assert_equal 0, oy
    assert_equal nil, ow
    assert_equal nil, oh
    assert_equal "xMidYMid", aspect_ratio_align
    assert_equal "meet", aspect_ratio_ms
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

  test "SVG get_styling_properties style test" do
    datas = [
      {input: {"style"=>"stroke: black; fill: none"},
       output: {"fill"=>"none", "stroke"=>"black"}},
      {input: {"style"=>"stop-color: rgb(83, 25, 113); stop-opacity: 1;"},
       output: {"stop-color"=>"rgb(83, 25, 113)", "stop-opacity"=>"1"}},
    ]

    datas.each do |data|
      pdf = MYPDF.new
      prev_svgstyle = pdf.instance_variable_get('@svgstyles').last
      attrs = data[:input]
      svgstyle = pdf.get_styling_properties(prev_svgstyle, attrs)

      diff = svgstyle.to_a - prev_svgstyle.to_a
      assert_equal(data[:output], Hash[*diff.flatten])
    end
  end

  test "SVG svg_path test" do
    pdf = MYPDF.new
    x, y, w, h = pdf.svg_path("M30,1h40l29,29v40l-29,29h-40l-29.0-29v-40z", "D")

    assert_equal 0.35277777777777963, x
    assert_equal 0.35277777777777775, y
    assert_equal 34.572222222222216, w
    assert_equal 34.57222222222222, h
  end
end
