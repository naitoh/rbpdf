# frozen_string_literal: true
# Copyright (c) 2011-2018 NAITOH Jun
# Released under the MIT license
# http://www.opensource.org/licenses/MIT

require 'test_helper'

class RbpdfTest < Test::Unit::TestCase
  htmls = {
    'Basic'                     => {:html => '<p>foo</p>', :line => 1,
                                    :border => 0,      :pno => 1, :no => 1},
    'Page Break no border'      => {:html => '<p>foo</p>', :margin => 30,
                                    :border => 0,      :pno => 2, :no => 2},
    'Page Break border'         => {:html => '<p>foo</p>', :margin => 30,
                                    :border => 'LRBT', :pno => 2, :no => 2},
    'Y position when there is no space between pre and p tags' =>
                                   {:html => "<p>test 0</p>\n <pre>test 1\ntest 2\ntest 3</pre><p>test 10</p>", :line => 7,
                                    :border => 0,      :pno => 1, :no => 1},
    'Y position when there is a space between pre and p tags' =>
                                   {:html => "<p>test 0</p>\n <pre>test 1\ntest 2\ntest 3</pre>\n <p>test 10</p>", :line => 7,
                                    :border => 0,      :pno => 1, :no => 1},
  }

  data(htmls)
  test "write_html_cell test" do |data|
    pdf = RBPDF.new
    pdf.add_page()
    t_margin = pdf.instance_variable_get('@t_margin')
    y0 = pdf.get_y
    assert_equal t_margin, y0

    if data[:margin]
      pdf.set_top_margin(data[:margin])
      y0 = pdf.get_y
      assert_equal data[:margin], y0

      h = pdf.get_page_height
      pdf.set_y(h - 15)
      y0 = pdf.get_y
    end

    font_size = pdf.get_font_size
    cell_height_ratio = pdf.get_cell_height_ratio
    min_cell_height = font_size * cell_height_ratio
    h = 5

    min_cell_height = h > min_cell_height ? h : min_cell_height

    pdf.write_html_cell(0, h, 10, '', data[:html], data[:border], 1, 0, true, '', false)

    pno = pdf.get_page
    assert_equal data[:pno], pno

    y1 = pdf.get_y
    if pno == 1
      assert_in_delta(y0 + min_cell_height * data[:line], y1, 0.1)
    else # pno 2, 1 line case only
      page_break_trigger = pdf.instance_variable_get('@page_break_trigger')
      assert_in_delta(data[:margin] + y0 + h - page_break_trigger, y1, 0.1)
    end

    no = pdf.get_num_pages
    assert_equal data[:no], no
  end

  htmls = {
    'rtl=false' => {html: '<p><img src="/dummy.png" style="width:2000px;height:563px;"></p>', rtl: false},
    'rtl=true' => {html: '<p><img src="/dummy.png" style="width:2000px;height:563px;"></p>', rtl: true},
  }

  data(htmls)
  test "write_html_cell Infinit loop check test with image size" do |data|
    pdf = RBPDF.new
    pdf.add_page()
    pdf.set_rtl(data[:rtl])
    pdf.write_html_cell(0, 0, '', '', data[:html])
    no = pdf.get_num_pages
    assert_equal 1, no
  end

  test "write_html_cell with image percentage width" do
    # Test that images with percentage-based width styles are actually embedded
    pdf = RBPDF.new
    pdf.add_page()

    # Test image path - using the logo_example.png from the repo
    img_path = File.join(File.dirname(__FILE__), '..', 'logo_example.png')

    # Create PDF with image using percentage width
    html_with_percentage = "<p>Image with percentage width:</p><img src='#{img_path}' style='width: 30%'>"
    pdf.write_html_cell(0, 0, '', '', html_with_percentage)

    # Check if the image was embedded
    images = pdf.instance_variable_get('@images')
    assert_equal 1, images.length, "Expected 1 image to be embedded in cache"

    # More importantly, check that the PDF actually contains image data
    # by verifying the PDF size is much larger than an empty PDF
    output = pdf.output('', 'S')

    # Create a reference PDF without any image
    pdf_no_img = RBPDF.new
    pdf_no_img.add_page()
    pdf_no_img.write_html_cell(0, 0, '', '', '<p>Image with percentage width:</p>')
    output_no_img = pdf_no_img.output('', 'S')

    # PDF with image should be significantly larger (image data embedded)
    assert output.length > output_no_img.length + 10000,
      "Expected PDF with image (#{output.length} bytes) to be much larger than PDF without image (#{output_no_img.length} bytes). Image may not have been embedded."
  end

  test "write_html_cell with image percentage width generates output" do
    pdf = RBPDF.new
    pdf.add_page()

    img_path = File.join(File.dirname(__FILE__), '..', 'logo_example.png')

    # Test both plain and percentage width styles
    html = <<-HTML
      <h3>Test: Image rendering with percentage width</h3>
      <p>Image without style (should work):</p>
      <img src='#{img_path}'>
      <p>Image with width=50 attribute (should work):</p>
      <img src='#{img_path}' width='50'>
      <p>Image with style width percentage (should work):</p>
      <img src='#{img_path}' style='width: 30%'>
      <p>Image with style width pixels (should work):</p>
      <img src='#{img_path}' style='width: 50px'>
    HTML

    pdf.write_html_cell(0, 0, '', '', html)

    # Generate PDF output to verify it doesn't crash
    output = pdf.output('', 'S')
    assert_not_nil output
    assert output.length > 0

    # Optionally write to file for manual inspection
    if ENV['OUTPUT']
      File.write('test_image_percentage_width.pdf', output)
      puts "Generated test_image_percentage_width.pdf for manual inspection"
    end
  end
end
