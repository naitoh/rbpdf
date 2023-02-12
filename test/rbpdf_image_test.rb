# Copyright (c) 2011-2017 NAITOH Jun
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

  test "HTML Image test without RMagick or MiniMagick" do
    return if Object.const_defined?(:Magick) or Object.const_defined?(:MiniMagick)

    # no use
    # utf8_japanese_aiueo_str  = "\xe3\x81\x82\xe3\x81\x84\xe3\x81\x86\xe3\x81\x88\xe3\x81\x8a"

    images = {
      'png_test_msk_alpha.png'    => 40.11,
      'png_test_non_alpha.png'    => 40.11,
      'logo_rbpdf_8bit.png'       => 36.58,
      'logo_rbpdf_8bit .png'       => 36.58,
      'logo_rbpdf_8bit+ .png'       => 36.58,
      # no use
      #'logo_rbpdf_8bit_' + utf8_japanese_aiueo_str + '.png'       => 36.58,
      'ng.png'                    => 9.42
    }

    images.each {|image, h|
      pdf = RBPDF.new
      pdf.add_page
      img_file = File.join(File.dirname(__FILE__), image)
      htmlcontent = '<img src="'+ img_file + '"/>'

      x_org = pdf.get_x
      y_org = pdf.get_y
      pdf.write_html(htmlcontent, true, 0, true, 0)
      x = pdf.get_x
      y = pdf.get_y

      assert_equal '[' + image + ']:' + x_org.to_s, '[' + image + ']:' + x.to_s
      assert_equal '[' + image + ']:' + (y_org + h).round(2).to_s, '[' + image + ']:' + y.round(2).to_s
    }
  end

  test "HTML Image vertically align image in line test without RMagick or MiniMagick" do
    return if Object.const_defined?(:Magick) or Object.const_defined?(:MiniMagick)

    image_sizes = [
      # writeHTML() : not !@rtl and (@x + imgw > @w - @r_margin - @c_margin) case
      {'width' => 10,  'height' => 20, 'cell' => false},
      {'width' => 100, 'height' => 100, 'cell' => false},
      {'width' => 100, 'height' => 100, 'cell' => true},
      {'width' => 500, 'height' => 100, 'cell' => false},
      # writeHTML() : !@rtl and (@x + imgw > @w - @r_margin - @c_margin) case
      {'width' => 600, 'height' => 10, 'cell' => false},
      {'width' => 600, 'height' => 10, 'cell' => true},
      {'width' => 600, 'height' => 13, 'cell' => false},
    ]

    img_file = File.join(File.dirname(__FILE__), 'logo_rbpdf_8bit.png')
    image_sizes.each {|size|
      pdf = RBPDF.new
      pdf.add_page
      htmlcontent = "<body><img src='#{img_file}' width='#{size['width']}' height='#{size['height']}'/></body>"

      x_org = pdf.get_x
      y_org = pdf.get_y

      imgw = pdf.getHTMLUnitToUnits(size['width'])
      imgh = pdf.getHTMLUnitToUnits(size['height'])
      pdf.write_html(htmlcontent, true, 0, true, size['cell'])
      x = pdf.get_x
      y = pdf.get_y
      w = pdf.get_page_width
      r_margin = pdf.instance_variable_get("@r_margin")
      lasth = pdf.get_font_size * pdf.get_cell_height_ratio
      if x + imgw > w - r_margin
        result = lasth * 2
      else
        result = lasth + imgh - pdf.get_font_size_pt / pdf.get_scale_factor
      end

      test_name = "[ width: #{size['width']} height: #{size['height']} cell: #{size['cell']}]:"
      assert_equal test_name + x_org.to_s, test_name + x.to_s
      assert_equal test_name + (y_org + result).round(2).to_s, test_name + y.round(2).to_s
    }
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
