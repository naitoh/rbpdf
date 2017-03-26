require 'test_helper'

class RbpdfTest < Test::Unit::TestCase
  class MYPDF < RBPDF
    def imageToPNG(file)
      super
    end
    def parsepng(file)
      super
    end
  end

  test "image getimagesize PNG test" do
    pdf = RBPDF.new
    pdf.add_page
    img_file = File.join(File.dirname(__FILE__), 'logo_rbpdf_8bit.png')

    info = pdf.getimagesize(img_file)
    assert_equal 240,                       info[0] # width
    assert_equal 89,                        info[1] # height
    assert_equal 'PNG',                     info[2] # Image Type
    assert_equal 'height="89" width="240"', info[3]
    assert_equal 'image/png',               info['mime']
  end

  test "image getimagesize GIF test" do
    return unless Object.const_defined?(:Magick)

    pdf = RBPDF.new
    pdf.add_page
    img_file = File.join(File.dirname(__FILE__), 'logo_rbpdf_8bit.gif')

    info = pdf.getimagesize(img_file)
    assert_equal 240,                       info[0] # width
    assert_equal 89,                        info[1] # height
    assert_equal 'GIF',                     info[2] # Image Type
    assert_equal 'height="89" width="240"', info[3]
    assert_equal 'image/gif',               info['mime']
    assert_equal 3,                         info['channels'] # RGB
    assert_equal 8,                         info['bits']     # depth
  end

  test "image getimagesize GIF alpha test" do
    return unless Object.const_defined?(:Magick)

    pdf = RBPDF.new
    pdf.add_page
    img_file = File.join(File.dirname(__FILE__), 'logo_rbpdf_8bit_alpha.gif')

    info = pdf.getimagesize(img_file)
    assert_equal 240,                       info[0] # width
    assert_equal 89,                        info[1] # height
    assert_equal 'GIF',                     info[2] # Image Type
    assert_equal 'height="89" width="240"', info[3]
    assert_equal 'image/gif',               info['mime']
    assert_equal 3,                         info['channels'] # RGB
    assert_equal 8,                         info['bits']     # depth
  end

  test "image getimagesize JPEG RGB test" do
    return unless Object.const_defined?(:Magick)

    pdf = RBPDF.new
    pdf.add_page
    img_file = File.join(File.dirname(__FILE__), 'logo_rbpdf_8bit.jpg')

    info = pdf.getimagesize(img_file)
    assert_equal 240,                       info[0] # width
    assert_equal 89,                        info[1] # height
    assert_equal 'JPEG',                    info[2] # Image Type
    assert_equal 'height="89" width="240"', info[3]
    assert_equal 'image/jpeg',              info['mime']
    assert_equal 3,                         info['channels'] # RGB
    assert_equal 8,                         info['bits']     # depth
  end

  test "image getimagesize JPEG monotone RGB test" do
    return unless Object.const_defined?(:Magick)

    pdf = RBPDF.new
    pdf.add_page
    img_file = File.join(File.dirname(__FILE__), 'logo_rbpdf_mono_rgb.jpg')

    info = pdf.getimagesize(img_file)
    assert_equal 240,                       info[0] # width
    assert_equal 89,                        info[1] # height
    assert_equal 'JPEG',                    info[2] # Image Type
    assert_equal 'height="89" width="240"', info[3]
    assert_equal 'image/jpeg',              info['mime']
    assert_equal 3,                         info['channels'] # RGB
    assert_equal 8,                         info['bits']     # depth
  end

  test "image getimagesize JPEG monotone Gray test" do
    return unless Object.const_defined?(:Magick)

    pdf = RBPDF.new
    pdf.add_page
    img_file = File.join(File.dirname(__FILE__), 'logo_rbpdf_mono_gray.jpg')

    info = pdf.getimagesize(img_file)
    assert_equal 240,                       info[0] # width
    assert_equal 89,                        info[1] # height
    assert_equal 'JPEG',                    info[2] # Image Type
    assert_equal 'height="89" width="240"', info[3]
    assert_equal 'image/jpeg',              info['mime']
    assert_equal 0,                         info['channels'] # Gray
    assert_equal 8,                         info['bits']     # depth
  end

  test "image getimagesize PNG monotone test" do
    pdf = RBPDF.new
    pdf.add_page
    img_file = File.join(File.dirname(__FILE__), 'logo_rbpdf_mono_rgb.png')

    info = pdf.getimagesize(img_file)
    assert_equal 240,                       info[0] # width
    assert_equal 89,                        info[1] # height
    assert_equal 'PNG',                     info[2] # Image Type
    assert_equal 'height="89" width="240"', info[3]
    assert_equal 'image/png',               info['mime']
  end

  test "imageToPNG delete GIF test" do
    pdf = MYPDF.new
    pdf.add_page
    img_file = File.join(File.dirname(__FILE__), 'logo_rbpdf_8bit.gif')

    if Object.const_defined?(:Magick)
      tempfile = pdf.imageToPNG(img_file)
      assert_not_equal false,      tempfile

      info = pdf.parsepng(tempfile.path)

      assert_not_equal 'pngalpha', info
      assert_equal     8,          info['bpc']
      assert_equal     'Indexed',  info['cs']
    end
  end

  test "imageToPNG delete GIF alpha channel test" do
    pdf = MYPDF.new
    pdf.add_page
    img_file = File.join(File.dirname(__FILE__), 'logo_rbpdf_8bit_alpha.gif')

    if Object.const_defined?(:Magick)
      tempfile = pdf.imageToPNG(img_file)
      assert_not_equal false,      tempfile

      info = pdf.parsepng(tempfile.path)

      assert_not_equal 'pngalpha', info
      assert_equal     8,          info['bpc']
      assert_equal     'Indexed',  info['cs']
    end
  end

  test "imageToPNG delete PNG alpha channel test" do
    pdf = MYPDF.new
    pdf.add_page
    img_file = File.join(File.dirname(__FILE__), 'png_test_alpha.png')

    if Object.const_defined?(:Magick)
      tempfile = pdf.imageToPNG(img_file)
      assert_not_equal  false,       tempfile

      info = pdf.parsepng(tempfile.path)

      assert_not_equal 'pngalpha',   info
      assert_equal      8,           info['bpc']
      assert_equal      'DeviceRGB', info['cs']
    end
  end

  test "image_alpha_mask DeviceGray test" do
    pdf = MYPDF.new
    pdf.add_page
    img_file = File.join(File.dirname(__FILE__), 'png_test_alpha.png')

    if Object.const_defined?(:Magick)
      tempfile = pdf.send(:image_alpha_mask, img_file)

      info = pdf.parsepng(tempfile.path)

      assert_not_equal 'pngalpha',    info
      assert_equal      8,            info['bpc']
      assert_equal      'DeviceGray', info['cs']
    end
  end

  test "Image PNG test" do
    pdf = RBPDF.new
    pdf.add_page
    img_file = File.join(File.dirname(__FILE__), 'logo_rbpdf_8bit.png')
    info = pdf.image(img_file, 10, 10, 100, '', '', 'https://rubygems.org/gems/rbpdf', '', false, 300)
    assert_equal 1, info
  end

  test "Image PNG alpha test" do
    return unless Object.const_defined?(:Magick)

    pdf = RBPDF.new
    pdf.add_page
    img_file = File.join(File.dirname(__FILE__), 'png_test_alpha.png')
    info = pdf.image(img_file, 10, 10, 100, '', '', 'https://rubygems.org/gems/rbpdf', '', false, 300)
    assert_equal true, info
  end

  test "Image GIF test" do
    return unless Object.const_defined?(:Magick)

    pdf = RBPDF.new
    pdf.add_page
    img_file = File.join(File.dirname(__FILE__), 'logo_rbpdf_8bit.gif')
    info = pdf.image(img_file, 10, 10, 100, '', '', 'https://rubygems.org/gems/rbpdf', '', false, 300)
    assert_equal 1, info
  end

  test "Image GIF alpha test" do
    return unless Object.const_defined?(:Magick)

    pdf = RBPDF.new
    pdf.add_page
    img_file = File.join(File.dirname(__FILE__), 'logo_rbpdf_8bit_alpha.gif')
    info = pdf.image(img_file, 10, 10, 100, '', '', 'https://rubygems.org/gems/rbpdf', '', false, 300)
    assert_equal 1, info
  end

  test "Image JPEG test" do
    return unless Object.const_defined?(:Magick)

    pdf = RBPDF.new
    pdf.add_page
    img_file = File.join(File.dirname(__FILE__), 'logo_rbpdf_8bit.jpg')
    info = pdf.image(img_file, 10, 10, 100, '', '', 'https://rubygems.org/gems/rbpdf', '', false, 300)
    assert_equal 1, info
  end

  test "HTML Image test" do
    return unless Object.const_defined?(:Magick)

    images = {
      'png_test_alpha.png'        => 40.11,
      'png_test_msk_alpha.png'    => 40.11,
      'png_test_non_alpha.png'    => 40.11,
      'logo_rbpdf_8bit.png'       => 36.58,
      'logo_rbpdf_8bit.gif'       => 36.58,
      'logo_rbpdf_8bit_alpha.gif' => 36.58,
      'logo_rbpdf_8bit.jpg'       => 36.58,
      'logo_rbpdf_mono_gray.jpg'  => 36.58,
      'logo_rbpdf_mono_gray.png'  => 36.58,
      'logo_rbpdf_mono_rgb.jpg'   => 36.58,
      'logo_rbpdf_mono_rgb.png'   => 36.58,
      'ng.png'                    => 9.42
    }

    pdf = RBPDF.new
    images.each {|image, h|
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
end
