# Copyright (c) 2011-2017 NAITOH Jun
# Released under the MIT license
# http://www.opensource.org/licenses/MIT

require 'test_helper'

class RbpdfTest < Test::Unit::TestCase
  test "set_x potision" do
    pdf = RBPDF.new
    width = pdf.get_page_width

    pdf.set_x(5)
    x     = pdf.get_x
    abs_x = pdf.get_abs_x
    assert_equal 5, x
    assert_equal 5, abs_x

    pdf.set_x(-4)
    x     = pdf.get_x
    abs_x = pdf.get_abs_x
    assert_equal width - 4, x
    assert_equal width - 4, abs_x

    pdf.set_rtl(true) # Right to Left

    pdf.set_x(5)
    x     = pdf.get_x
    abs_x = pdf.get_abs_x
    assert_equal 5, x
    assert_equal width - 5, abs_x

    pdf.set_x(-4)
    x     = pdf.get_x
    abs_x = pdf.get_abs_x
    assert_equal width - 4, x
    assert_equal 4, abs_x
  end

  test "set_y potision" do
    pdf = RBPDF.new
    width = pdf.get_page_width

    pdf.set_left_margin(10)
    pdf.set_y(20)
    x     = pdf.get_x
    abs_x = pdf.get_abs_x
    y     = pdf.get_y
    assert_equal 10, x
    assert_equal 10, abs_x
    assert_equal 20, y

    pdf.set_left_margin(30)
    pdf.set_y(20)
    x     = pdf.get_x
    abs_x = pdf.get_abs_x
    y     = pdf.get_y
    assert_equal 30, x
    assert_equal 30, abs_x
    assert_equal 20, y

    pdf.set_rtl(true) # Right to Left

    pdf.set_right_margin(10)
    pdf.set_y(20)
    x     = pdf.get_x
    abs_x = pdf.get_abs_x
    y     = pdf.get_y
    assert_equal 10, x
    assert_equal width - 10, abs_x
    assert_equal 20, y

    pdf.set_right_margin(30)
    pdf.set_y(20)
    x     = pdf.get_x
    abs_x = pdf.get_abs_x
    y     = pdf.get_y
    assert_equal 30, x
    assert_equal width - 30, abs_x
    assert_equal 20, y
  end

  test "add_page potision" do
    pdf = RBPDF.new
    width = pdf.get_page_width

    pdf.add_page
    x     = pdf.get_x
    abs_x = pdf.get_abs_x
    y     = pdf.get_y
    assert_in_delta 10.00125, x, 0.00001
    assert_in_delta 10.00125, abs_x, 0.00001
    assert_in_delta 10.00125, y, 0.00001

    pdf.set_rtl(true) # Right to Left

    pdf.add_page
    x     = pdf.get_x
    abs_x = pdf.get_abs_x
    y     = pdf.get_y
    assert_in_delta 10.00125, x, 0.00001
    assert_in_delta width - 10.00125, abs_x, 0.00001
    assert_in_delta 10.00125, y, 0.00001

    pdf.set_page(1)
    page = pdf.get_page
    assert_equal 1, page
    pdf.set_y(20)
    y     = pdf.get_y
    assert_equal 20, y
    pdf.add_page
    y     = pdf.get_y
    assert_in_delta 10.00125, y, 0.00001

  end

  test "add_page" do
    pdf = RBPDF.new

    page = pdf.get_page
    assert_equal 0, page
    pages = pdf.get_num_pages
    assert_equal 0, pages

    pdf.add_page
    page = pdf.get_page
    assert_equal 1, page
    pages = pdf.get_num_pages
    assert_equal 1, pages

    pdf.add_page
    page = pdf.get_page
    assert_equal 2, page
    pages = pdf.get_num_pages
    assert_equal 2, pages

    pdf.set_page(1)
    page = pdf.get_page
    assert_equal 1, page

    pdf.add_page
    page = pdf.get_page
    assert_equal 2, page
    pages = pdf.get_num_pages
    assert_equal 2, pages

    pdf.add_page
    page = pdf.get_page
    assert_equal 3, page
    pages = pdf.get_num_pages
    assert_equal 3, pages

    pdf.set_page(1)
    page = pdf.get_page
    assert_equal 1, page

    pdf.last_page
    page = pdf.get_page
    assert_equal 3, page
    pages = pdf.get_num_pages
    assert_equal 3, pages
  end

  test "add_page set_page Under Error" do
    pdf = RBPDF.new

    page = pdf.get_page
    assert_equal 0, page
    pages = pdf.get_num_pages
    assert_equal 0, pages

    pdf.add_page
    page = pdf.get_page
    assert_equal 1, page
    pages = pdf.get_num_pages
    assert_equal 1, pages

    assert_raise(RBPDFError) {pdf.set_page(0)} # Page under size
  end

  test "add_page set_page Over Error" do
    pdf = RBPDF.new

    page = pdf.get_page
    assert_equal 0, page
    pages = pdf.get_num_pages
    assert_equal 0, pages

    pdf.add_page
    page = pdf.get_page
    assert_equal 1, page
    pages = pdf.get_num_pages
    assert_equal 1, pages

    pdf.add_page
    page = pdf.get_page
    assert_equal 2, page
    pages = pdf.get_num_pages
    assert_equal 2, pages

    pdf.set_page(1)
    page = pdf.get_page
    assert_equal 1, page

    assert_raise(RBPDFError) {pdf.set_page(3)} # Page over size
  end

  test "deletePage test" do
    pdf = RBPDF.new

    pdf.add_page
    pdf.write(0, "Page 1")

    page = pdf.get_page
    assert_equal 1, page
    pages = pdf.get_num_pages
    assert_equal 1, pages

    contents1 = pdf.send(:getPageBuffer, 1)

    pdf.add_page
    pdf.write(0, "Page 2")

    page = pdf.get_page
    assert_equal 2, page
    pages = pdf.get_num_pages
    assert_equal 2, pages

    contents2 = pdf.send(:getPageBuffer, 2)

    pdf.deletePage(1)
    page = pdf.get_page
    assert_equal 1, page
    pages = pdf.get_num_pages
    assert_equal 1, pages

    contents3 = pdf.send(:getPageBuffer, 1)
    assert_not_equal contents1, contents3
    assert_equal contents2, contents3

    contents4 = pdf.send(:getPageBuffer, 2)
    assert_equal false, contents4
  end

  test "start_page_group test" do
    pdf = RBPDF.new
    pdf.add_page
    pdf.start_page_group
    pdf.start_page_group(1)
    pdf.start_page_group(nil)
    pdf.start_page_group('')
  end

  test "get_page_dimensions test" do
    pdf = RBPDF.new
    pdf.add_page

    pagedim = pdf.get_page_dimensions
    assert_equal 0.0, pagedim['CropBox']['llx']
    pagedim = pdf.get_page_dimensions(1)
    assert_equal 0.0, pagedim['CropBox']['llx']
    pagedim = pdf.get_page_dimensions(nil)
    assert_equal 0.0, pagedim['CropBox']['llx']
    pagedim = pdf.get_page_dimensions('')
    assert_equal 0.0, pagedim['CropBox']['llx']
  end

  test "Page Box A4 test 1" do
    pdf = RBPDF.new
    pagedim = pdf.get_page_dimensions
    assert_equal 0.0,    pagedim['MediaBox']['llx']
    assert_equal 0.0,    pagedim['MediaBox']['lly']
    assert_equal 595.28, pagedim['MediaBox']['urx']
    assert_equal 841.89, pagedim['MediaBox']['ury']
    assert_equal 0.0,    pagedim['CropBox']['llx']
    assert_equal 0.0,    pagedim['CropBox']['lly']
    assert_equal 595.28, pagedim['CropBox']['urx']
    assert_equal 841.89, pagedim['CropBox']['ury']
    assert_equal 0.0,    pagedim['BleedBox']['llx']
    assert_equal 0.0,    pagedim['BleedBox']['lly']
    assert_equal 595.28, pagedim['BleedBox']['urx']
    assert_equal 841.89, pagedim['BleedBox']['ury']
    assert_equal 0.0,    pagedim['TrimBox']['llx']
    assert_equal 0.0,    pagedim['TrimBox']['lly']
    assert_equal 595.28, pagedim['TrimBox']['urx']
    assert_equal 841.89, pagedim['TrimBox']['ury']
    assert_equal 0.0,    pagedim['ArtBox']['llx']
    assert_equal 0.0,    pagedim['ArtBox']['lly']
    assert_equal 595.28, pagedim['ArtBox']['urx']
    assert_equal 841.89, pagedim['ArtBox']['ury']
  end

  test "Page Box A4 test 2" do
    format = {}
    type = ['CropBox', 'BleedBox', 'TrimBox', 'ArtBox']
    type.each do |t|
      format[t] = {}
      format[t]['llx'] = 0
      format[t]['lly'] = 0
      format[t]['urx'] = 210
      format[t]['ury'] = 297
    end

    pdf = RBPDF.new('P', 'mm', format)
    pagedim = pdf.get_page_dimensions
    assert_equal    0.0,    pagedim['MediaBox']['llx']
    assert_equal    0.0,    pagedim['MediaBox']['lly']
    assert_in_delta 595.28, pagedim['MediaBox']['urx'], 0.1
    assert_in_delta 841.89, pagedim['MediaBox']['ury'], 0.1
    assert_equal    0.0,    pagedim['CropBox']['llx']
    assert_equal    0.0,    pagedim['CropBox']['lly']
    assert_in_delta 595.28, pagedim['CropBox']['urx'], 0.1
    assert_in_delta 841.89, pagedim['CropBox']['ury'], 0.1
    assert_equal    0.0,    pagedim['BleedBox']['llx']
    assert_equal    0.0,    pagedim['BleedBox']['lly']
    assert_in_delta 595.28, pagedim['BleedBox']['urx'], 0.1
    assert_in_delta 841.89, pagedim['BleedBox']['ury'], 0.1
    assert_equal    0.0,    pagedim['TrimBox']['llx']
    assert_equal    0.0,    pagedim['TrimBox']['lly']
    assert_in_delta 595.28, pagedim['TrimBox']['urx'], 0.1
    assert_in_delta 841.89, pagedim['TrimBox']['ury'], 0.1
    assert_equal    0.0,    pagedim['ArtBox']['llx']
    assert_equal    0.0,    pagedim['ArtBox']['lly']
    assert_in_delta 595.28, pagedim['ArtBox']['urx'], 0.1
    assert_in_delta 841.89, pagedim['ArtBox']['ury'], 0.1
  end

  test "Page Box A4 test 3" do
    format = {}
    type = ['MediaBox', 'CropBox', 'BleedBox', 'TrimBox', 'ArtBox']
    type.each do |t|
      format[t] = {}
      format[t]['llx'] = 0
      format[t]['lly'] = 0
      format[t]['urx'] = 210
      format[t]['ury'] = 297
    end

    pdf = RBPDF.new('P', 'mm', format)
    pagedim = pdf.get_page_dimensions
    assert_equal    0.0,    pagedim['MediaBox']['llx']
    assert_equal    0.0,    pagedim['MediaBox']['lly']
    assert_in_delta 595.28, pagedim['MediaBox']['urx'], 0.1
    assert_in_delta 841.89, pagedim['MediaBox']['ury'], 0.1
    assert_equal    0.0,    pagedim['CropBox']['llx']
    assert_equal    0.0,    pagedim['CropBox']['lly']
    assert_in_delta 595.28, pagedim['CropBox']['urx'], 0.1
    assert_in_delta 841.89, pagedim['CropBox']['ury'], 0.1
    assert_equal    0.0,    pagedim['BleedBox']['llx']
    assert_equal    0.0,    pagedim['BleedBox']['lly']
    assert_in_delta 595.28, pagedim['BleedBox']['urx'], 0.1
    assert_in_delta 841.89, pagedim['BleedBox']['ury'], 0.1
    assert_equal    0.0,    pagedim['TrimBox']['llx']
    assert_equal    0.0,    pagedim['TrimBox']['lly']
    assert_in_delta 595.28, pagedim['TrimBox']['urx'], 0.1
    assert_in_delta 841.89, pagedim['TrimBox']['ury'], 0.1
    assert_equal    0.0,    pagedim['ArtBox']['llx']
    assert_equal    0.0,    pagedim['ArtBox']['lly']
    assert_in_delta 595.28, pagedim['ArtBox']['urx'], 0.1
    assert_in_delta 841.89, pagedim['ArtBox']['ury'], 0.1
  end

  test "get_break_margin test" do
    pdf = RBPDF.new
    pdf.add_page

    b_margin = pdf.get_break_margin
    assert_in_delta b_margin, 20.0, 0.1
    b_margin = pdf.get_break_margin(1)
    assert_in_delta b_margin, 20.0, 0.1
    b_margin = pdf.get_break_margin(nil)
    assert_in_delta b_margin, 20.0, 0.1
    b_margin = pdf.get_break_margin('')
    assert_in_delta b_margin, 20.0, 0.1
  end
end
