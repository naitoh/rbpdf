# coding: ASCII-8BIT
# frozen_string_literal: true
# Copyright (c) 2011-2025 NAITOH Jun
# Released under the MIT license
# http://www.opensource.org/licenses/MIT

require 'test_helper'

class RbpdfTest < Test::Unit::TestCase
  images = {
    'PNG'                => {:file => 'logo_rbpdf_8bit.png',       :type => 'PNG',  :mime => 'image/png',  :use_magick => false},
    'PNG monotone'       => {:file => 'logo_rbpdf_mono_rgb.png',   :type => 'PNG',  :mime => 'image/png',  :use_magick => false},
    'WEBP'               => {:file => 'logo_rbpdf_8bit.webp',      :type => 'WEBP', :mime => 'image/webp', :use_magick => true, :channels => 3, :bits => 8},
    'GIF'                => {:file => 'logo_rbpdf_8bit.gif',       :type => 'GIF',  :mime => 'image/gif',  :use_magick => true, :channels => 3, :bits => 8},
    'GIF alpha'          => {:file => 'logo_rbpdf_8bit_alpha.gif', :type => 'GIF',  :mime => 'image/gif',  :use_magick => true, :channels => 3, :bits => 8},
    'JPEG RGB'           => {:file => 'logo_rbpdf_8bit.jpg',       :type => 'JPEG', :mime => 'image/jpeg', :use_magick => true, :channels => 3, :bits => 8},
    'JPEG monotone RGB'  => {:file => 'logo_rbpdf_mono_rgb.jpg',   :type => 'JPEG', :mime => 'image/jpeg', :use_magick => true, :channels => 3, :bits => 8},
    'JPEG monotone Gray' => {:file => 'logo_rbpdf_mono_gray.jpg',  :type => 'JPEG', :mime => 'image/jpeg', :use_magick => true, :channels => 0, :bits => 8},
  }

  data(images)
  test "image getimagesize test" do |data|
    return if data[:use_magick] and !Object.const_defined?(:Magick) and !Object.const_defined?(:MiniMagick)

    pdf = RBPDF.new
    pdf.add_page
    img_file = File.join(File.dirname(__FILE__), data[:file])

    info = pdf.getimagesize(img_file)
    assert_equal 240,                       info[0] # width
    assert_equal 89,                        info[1] # height
    assert_equal data[:type],               info[2] # Image Type
    assert_equal 'height="89" width="240"', info[3]
    assert_equal data[:mime],               info['mime']
    assert_equal data[:channels],           info['channels'] if data[:channels] # RGB
    assert_equal data[:bits],               info['bits']     if data[:bits]     # depth
  end

  images = {
    'PNG alpha'          => {:file => 'png_test_alpha.png',        :cs => 'DeviceRGB'},
    'WebP alpha'         => {:file => 'webp_test_alpha.webp',      :cs => 'DeviceRGB'},
    'GIF'                => {:file => 'logo_rbpdf_8bit.gif',       :cs => 'Indexed'},
    'GIF alpha'          => {:file => 'logo_rbpdf_8bit_alpha.gif', :cs => 'Indexed'},
  }

  data(images)
  test "imageToPNG delete test" do |data|
    return unless Object.const_defined?(:Magick) or Object.const_defined?(:MiniMagick)

    pdf = RBPDF.new
    pdf.add_page
    img_file = File.join(File.dirname(__FILE__), data[:file])

    tempfile = pdf.send(:imageToPNG, img_file)
    assert_not_equal false,      tempfile

    info = pdf.send(:parsepng, tempfile.path)

    assert_not_equal 'pngalpha', info
    assert_equal     8,          info['bpc']
    assert_equal     data[:cs],  info['cs']
  end

  images = {
    'PNG alpha'          => {:file => 'png_test_alpha.png',        :cs => 'DeviceRGB'},
    'WebP alpha'         => {:file => 'webp_test_alpha.webp',      :cs => 'DeviceRGB'},
    'GIF alpha'          => {:file => 'logo_rbpdf_8bit_alpha.gif', :cs => 'Indexed'},
  }

  data(images)
  test "Magick::ImageList delete alpha channel test" do |data|
    return unless Object.const_defined?(:Magick)

    img_file = File.join(File.dirname(__FILE__), data[:file])
    img = Magick::ImageList.new(img_file)
    img.format = 'PNG' unless File::extname(data[:file]) == '.png' # convert to PNG

    assert_equal true,   img.alpha?

    # PNG alpha channel delete
    if Magick.const_defined?(:OffAlphaChannel) # RMagick 5.2.0 and later
      img.alpha Magick::OffAlphaChannel
    else # RMagick 5.1.0 and before for ImageMagick 6.x
      img.alpha Magick::DeactivateAlphaChannel
    end
    assert_equal false,   img.alpha?

    tmpFile = Tempfile.new(['', '_' + File::basename(img_file) + '.png'])
    tmpFile.binmode
    tmpFile.print img.to_blob
    tmpFile.fsync

    img = Magick::ImageList.new(tmpFile.path)
    assert_equal false,   img.alpha?

    f=open(tmpFile,'rb');
    #Check signature
    assert_equal 137.chr + 'PNG' + 13.chr + 10.chr + 26.chr + 10.chr, f.read(8)
    f.read(4);
    assert_equal 'IHDR',                                              f.read(4)
    f.read(4) # w
    f.read(4) # h
    f.read(1) # bpc
    case data[:cs]
    when 'DeviceRGB'; ct = 2
    when 'Indexed';   ct = 3
    end
    assert_equal ct,                                                  f.read(1).unpack('C')[0] # ct
  end

  images = {
    'PNG alpha'          => {:file => 'png_test_alpha.png',        :cs => 'DeviceRGB'},
    'WebP alpha'         => {:file => 'webp_test_alpha.webp',      :cs => 'DeviceRGB'},
    'GIF alpha'          => {:file => 'logo_rbpdf_8bit_alpha.gif', :cs => 'Indexed'},
  }

  test "image_alpha_mask DeviceGray test" do |data|
    return unless Object.const_defined?(:Magick) or Object.const_defined?(:MiniMagick)

    pdf = RBPDF.new
    pdf.add_page
    img_file = File.join(File.dirname(__FILE__),  data[:file])

    tempfile = pdf.send(:image_alpha_mask, img_file)
    assert_not_equal false,      tempfile

    info = pdf.send(:parsepng, tempfile.path)

    assert_not_equal 'pngalpha',   info
    assert_equal      8,           info['bpc']
    assert_equal     'DeviceGray', info['cs']

    # embed mask image test
    imgmask = pdf.image(tempfile.path, 10, 10, 100, '', 'PNG', '', '', false, 300, '', true, false)
    assert_equal 1, imgmask
  end

  images = {
    'PNG alpha'          => {:file => 'png_test_alpha.png',        :info => true},
    'GIF alpha'          => {:file => 'gif_test_alpha.gif',        :info => true},
    'WebP alpha'         => {:file => 'webp_test_alpha.webp',      :info => true},
    #'PNG alpha Error'    => {:file => 'png_test_alpha.png',        :info => false, :png_alpha_error => true}, # no use
  }

  data(images)
  test "ImagePngAlpha test" do |data|
    return unless Object.const_defined?(:Magick) or Object.const_defined?(:MiniMagick)

    pdf = RBPDF.new
    pdf.add_page
    img_file = File.join(File.dirname(__FILE__), data[:file])
    #pdf.singleton_class.send(:define_method, :parsepng){|*args| {:cs => 'Indexed'}} if data[:png_alpha_error] # no use
    info = pdf.send(:ImagePngAlpha, img_file, 10, 10, 100, '', 'PNG', 'https://rubygems.org/gems/rbpdf')
    assert_equal "#{data[:file]} #{data[:info]}", "#{data[:file]} #{info}"
  end

  images = {
    'PNG'                => {:file => 'logo_rbpdf_8bit.png',       :info => 1,    :use_magick => false},
    'PNG alpha'          => {:file => 'png_test_alpha.png',        :info => true, :use_magick => true},
    #'PNG alpha Error'    => {:file => 'png_test_alpha.png',        :info => 1,    :use_magick => true, :png_alpha_error => true}, # no use
    'WebP'               => {:file => 'logo_rbpdf_8bit.webp',      :info => 1,    :use_magick => true},
    'WebP alpha'         => {:file => 'webp_test_alpha.webp',      :info => true, :use_magick => true},
    'GIF'                => {:file => 'logo_rbpdf_8bit.gif',       :info => 1,    :use_magick => true},
    'GIF alpha'          => {:file => 'logo_rbpdf_8bit_alpha.gif', :info => 1,    :use_magick => true},
    'JPEG'               => {:file => 'logo_rbpdf_8bit.jpg',       :info => 1,    :use_magick => true},
  }

  data(images)
  test "Image test" do |data|
    return if data[:use_magick] and !Object.const_defined?(:Magick) and !Object.const_defined?(:MiniMagick)

    pdf = RBPDF.new
    pdf.add_page
    img_file = File.join(File.dirname(__FILE__), data[:file])
    #pdf.singleton_class.send(:define_method, :parsepng){|*args| {:cs => 'Indexed'}} if data[:png_alpha_error] # no use
    info = pdf.image(img_file, 10, 10, 100, '', '', 'https://rubygems.org/gems/rbpdf', '', false, 300)
    assert_equal "#{data[:file]} #{data[:info]}", "#{data[:file]} #{info}"
  end

  images = {
    'png_test_alpha.png'        => {file: 'png_test_alpha.png',        x: 188,  y: 34.8},
    'png_test_msk_alpha.png'    => {file: 'png_test_msk_alpha.png',    x: 188,  y: 34.8},
    'png_test_non_alpha.png'    => {file: 'png_test_non_alpha.png',    x: 188,  y: 34.8},
    'webp_test_alpha.webp'      => {file: 'webp_test_alpha.webp',      x: 188,  y: 34.8},
    'logo_rbpdf_8bit.png'       => {file: 'logo_rbpdf_8bit.png',       x: 84.7, y: 31.4},
    'logo_rbpdf_8bit.webp'      => {file: 'logo_rbpdf_8bit.webp',      x: 84.7, y: 31.4},
    'logo_rbpdf_8bit.gif'       => {file: 'logo_rbpdf_8bit.gif',       x: 84.7, y: 31.4},
    'logo_rbpdf_8bit_alpha.gif' => {file: 'logo_rbpdf_8bit_alpha.gif', x: 84.7, y: 31.4},
    'logo_rbpdf_8bit.jpg'       => {file: 'logo_rbpdf_8bit.jpg',       x: 84.7, y: 31.4},
    'logo_rbpdf_mono_gray.jpg'  => {file: 'logo_rbpdf_mono_gray.jpg',  x: 84.7, y: 31.4},
    'logo_rbpdf_mono_gray.png'  => {file: 'logo_rbpdf_mono_gray.png',  x: 84.7, y: 31.4},
    'logo_rbpdf_mono_rgb.jpg'   => {file: 'logo_rbpdf_mono_rgb.jpg',   x: 84.7, y: 31.4},
    'logo_rbpdf_mono_rgb.png'   => {file: 'logo_rbpdf_mono_rgb.png',   x: 84.7, y: 31.4},
  }

  data(images)
  test "HTML Image test" do
    return unless Object.const_defined?(:Magick) or Object.const_defined?(:MiniMagick)

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
end
