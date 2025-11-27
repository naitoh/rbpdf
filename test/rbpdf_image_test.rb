# coding: ASCII-8BIT
# frozen_string_literal: true
# Copyright (c) 2011-2025 NAITOH Jun
# Released under the MIT license
# http://www.opensource.org/licenses/MIT

require 'test_helper'

class RbpdfTest < Test::Unit::TestCase
  test "Image basic func extension test" do
    pdf = RBPDF.new

    type = pdf.get_image_file_type("/tmp/rbpdf_logo.gif")
    assert_equal 'gif', type

    type = pdf.get_image_file_type("/tmp/rbpdf_logo.PNG")
    assert_equal 'png', type

    type = pdf.get_image_file_type("/tmp/rbpdf_logo.jpg")
    assert_equal 'jpeg', type

    type = pdf.get_image_file_type("/tmp/rbpdf_logo.jpeg")
    assert_equal 'jpeg', type

    type = pdf.get_image_file_type("/tmp/rbpdf_logo")
    assert_equal '', type

    type = pdf.get_image_file_type("")
    assert_equal '', type

    type = pdf.get_image_file_type(nil)
    assert_equal '', type
  end

  test "Image basic func mime type test" do
    pdf = RBPDF.new

    type = pdf.get_image_file_type(nil, {})
    assert_equal '', type

    type = pdf.get_image_file_type(nil, {'mime' => 'image/gif'})
    assert_equal 'gif', type

    type = pdf.get_image_file_type(nil, {'mime' => 'image/jpeg'})
    assert_equal 'jpeg', type

    type = pdf.get_image_file_type('/tmp/rbpdf_logo.gif', {'mime' => 'image/png'})
    assert_equal 'png', type

    type = pdf.get_image_file_type('/tmp/rbpdf_logo.gif', {})
    assert_equal 'gif', type

    type = pdf.get_image_file_type(nil, {'mime' => 'text/html'})
    assert_equal '', type

    type = pdf.get_image_file_type(nil, [])
    assert_equal '', type
  end

  test "Image basic ascii filename test" do
    pdf = RBPDF.new
    pdf.add_page
    img_file = File.join(File.dirname(__FILE__), 'logo_rbpdf_8bit.png')
    assert_nothing_raised(RBPDFError) { 
      pdf.image(img_file)
    }

    img_file = File.join(File.dirname(__FILE__), 'logo_rbpdf_8bit .png')
    assert_nothing_raised(RBPDFError) { 
      pdf.image(img_file)
    }
  end

  # no use
  #test "Image basic non ascii filename test" do
  #  pdf = RBPDF.new
  #  pdf.add_page

  #  utf8_japanese_aiueo_str  = "\xe3\x81\x82\xe3\x81\x84\xe3\x81\x86\xe3\x81\x88\xe3\x81\x8a"
  #  img_file = File.join(File.dirname(__FILE__), 'logo_rbpdf_8bit_' + utf8_japanese_aiueo_str + '.png')
  #  assert_nothing_raised(RBPDFError) { 
  #    pdf.image(img_file)
  #  }
  #end

  test "Image basic filename error test" do
    pdf = RBPDF.new
    err = assert_raise(RBPDFError) { 
      pdf.image(nil)
    }
    assert_equal 'RBPDF error: Image filename is empty.', err.message

    err = assert_raises(RBPDFError) { 
      pdf.image('')
    }
    assert_equal 'RBPDF error: Image filename is empty.', err.message

    err = assert_raises(RBPDFError) { 
      pdf.image('foo.png')
    }
    assert_equal 'RBPDF error: Image file is not found. : foo.png', err.message
  end

  test "Image basic test" do
    pdf = RBPDF.new
    pdf.add_page
    img_file = File.join(File.dirname(__FILE__), '..', 'logo_example.png')

    result_img = pdf.image(img_file, 50, 0, 0, '', '', '', '', false, 300, '', true)

    no = pdf.get_num_pages
    assert_equal 1, no
    assert_equal 1, result_img
  end

  test "Image fitonpage test 1" do
    pdf = RBPDF.new
    pdf.add_page
    img_file = File.join(File.dirname(__FILE__), '..', 'logo_example.png')

    result_img = pdf.image(img_file, 50, 140, 100, '', '', '', '', false, 300, '', true, false, 0, false, false, true)

    no = pdf.get_num_pages
    assert_equal 1, no
    assert_equal 1, result_img
  end

  test "Image fitonpage test 2" do
    pdf = RBPDF.new
    pdf.add_page
    img_file = File.join(File.dirname(__FILE__), '..', 'logo_example.png')

    y = 100
    w = pdf.get_page_width * 2
    h = pdf.get_page_height
    result_img = pdf.image(img_file, '', y, w, h, '', '', '', false, 300, '', true, false, 0, false, false, true)

    no = pdf.get_num_pages
    assert_equal 1, no
    assert_equal 1, result_img
  end

  test "Image proc_image_file test" do
    pdf = RBPDF.new
    pdf.add_page
    img_file = File.join(File.dirname(__FILE__), '..', 'logo_example.png')

    result_img = pdf.send(:proc_image_file, img_file) do |f|
      pdf.image(f, 50, 0, 0, '', '', '', '', false, 300, '', true)
    end

    no = pdf.get_num_pages
    assert_equal 1, no
    assert_equal 1, result_img
  end

  images = {
    'DeviceGray'           => {:cs => 0, :file => 'png_test_msk_alpha.png'},
    'DeviceRGB'            => {:cs => 2, :file => 'logo_rbpdf_8bit.png'},
    'Indexed'              => {:cs => 3, :file => 'gif_test_non_alpha.png'},
    'Indexed transparency' => {:cs => 3, :file => 'gif_test_alpha.png',  :trns => [0]},
  }
  data(images)
  test "Image parsepng test" do |data|
    pdf = RBPDF.new
    pdf.add_page
    img_file = File.join(File.dirname(__FILE__), data[:file])
    info = pdf.send(:parsepng, img_file)
    if data[:cs] == 4 or data[:cs] == 6
      assert_equal "#{data[:file]} pngalpha", "#{data[:file]} #{info}"
    else
      assert_not_equal "#{data[:file]} pngalpha", "#{data[:file]} #{info}"
      assert_equal "#{data[:file]} 8", "#{data[:file]} #{info['bpc']}"
      case data[:cs]
      when 0
        assert_equal "#{data[:file]} DeviceGray", "#{data[:file]} #{info['cs']}"
      when 2
        assert_equal "#{data[:file]} DeviceRGB", "#{data[:file]} #{info['cs']}"
      when 3
        assert_equal "#{data[:file]} Indexed", "#{data[:file]} #{info['cs']}"
      end
      assert_equal "#{data[:file]} #{data[:trns]}", "#{data[:file]} #{info['trns']}"
    end
  end

  images = {
    'png_test_msk_alpha.png'    => {file: 'png_test_msk_alpha.png',    x: 188,  y: 34.8},
    'png_test_non_alpha.png'    => {file: 'png_test_non_alpha.png',    x: 188,  y: 34.8},
    'logo_rbpdf_8bit.png'       => {file: 'logo_rbpdf_8bit.png',       x: 84.7, y: 31.4},
    'logo_rbpdf_8bit+ .png'     => {file: 'logo_rbpdf_8bit+ .png',     x: 84.7, y: 31.4},
  }

  data(images)
  test "HTML Image test without RMagick or MiniMagick" do
    return if Object.const_defined?(:Magick) or Object.const_defined?(:MiniMagick)

    pdf = RBPDF.new
    pdf.add_page
    c_margin = pdf.get_margins['cell']

    x_org = pdf.get_x
    y_org = pdf.get_y
    pdf.write_html("<img src='#{File.join(File.dirname(__FILE__), data[:file])}'/>")
    x = pdf.get_image_rbx
    y = pdf.get_image_rby

    assert_in_delta data[:x], x - x_org - c_margin, 0.1
    assert_in_delta data[:y], y - y_org, 0.1
  end

  image_sizes = {
    # writeHTML() : not !@rtl and (@x + imgw > @w - @r_margin - @c_margin) case
    w10_h20_cell0_over0: {width: 10, height: 20, cell: false, over: false},
    w100_h100_cell0_over0: {width: 100, height: 100, cell: false, over: false},
    w100_h100_cell1_over0: {width: 100, height: 100, cell: true, over: false},
    w500_h100_cell0_over0: {width: 500, height: 100, cell: false, over: false},
    # writeHTML() : !@rtl and (@x + imgw > @w - @r_margin - @c_margin) case
    w600_h10_cell0_over1: {width: 600, height: 10, cell: false, over: true},
    w600_h10_cell1_over1: {width: 600, height: 10, cell: true, over: true},
    w600_h13_cell0_over1: {width: 600, height: 13, cell: false, over: true},
  }

  data(image_sizes)
  test "HTML Image vertically align image in line test without RMagick or MiniMagick" do
    return if Object.const_defined?(:Magick) or Object.const_defined?(:MiniMagick)

    img_file = File.join(File.dirname(__FILE__), 'logo_rbpdf_8bit.png')
    pdf = RBPDF.new
    pdf.add_page
    htmlcontent = "<img src='#{img_file}' width='#{data[:width]}' height='#{data[:height]}'/>"

    x_org = pdf.get_x
    y_org = pdf.get_y

    imgw = pdf.getHTMLUnitToUnits(data[:width])
    imgh = pdf.getHTMLUnitToUnits(data[:height])
    pdf.write_html(htmlcontent, true, 0, true, data[:cell])
    x = pdf.get_image_rbx
    y = pdf.get_image_rby
    w = pdf.get_page_width
    r_margin = pdf.get_margins['right']
    c_margin = pdf.get_margins['cell']

    unless data[:over] == true
      assert_in_delta imgw, x - (x_org + c_margin), 0.1
      assert_in_delta imgh, y - y_org, 0.1
    else
      assert_in_delta w - r_margin - (x_org + c_margin), x - x_org, 0.1
      ratio_wh = imgw / imgh
      assert_in_delta (w - r_margin - x_org)/ ratio_wh, y - y_org, 0.1
    end
  end

  test "HTML Image vertically align image in line and shift the annotations and links test without RMagick or MiniMagick" do
    return if Object.const_defined?(:Magick) or Object.const_defined?(:MiniMagick)

    img_file = File.join(File.dirname(__FILE__), 'logo_rbpdf_8bit.png')
    width = 300
    height = 600
    pdf = RBPDF.new
    pdf.add_page
    htmlcontent = "<body><img src='#{img_file}' width='#{width}' height='#{height}'/><img src='#{img_file}' width='#{width}' height='#{height}'/></body>"
    x_org = pdf.get_x
    y_org = pdf.get_y
    imgh = pdf.getHTMLUnitToUnits(height)

    opt = {'Subtype'=>'Text', 'Name' => 'Comment', 'T' => 'title example', 'Subj' => 'example', 'C' => [255, 255, 0]}
    pdf.annotation('', '', 20, 30, 'Text annotation', opt)

    pdf.write_html(htmlcontent, true, 0, true, false)
    x = pdf.get_x
    y = pdf.get_y
    lasth = pdf.get_font_size * pdf.get_cell_height_ratio
    result = lasth + imgh - pdf.get_font_size_pt / pdf.get_scale_factor

    assert_equal x_org.to_s, x.to_s
    assert_equal (y_org + result).round(2), y.round(2)
  end
end
