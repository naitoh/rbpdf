# Copyright (c) 2011-2017 NAITOH Jun
# Released under the MIT license
# http://www.opensource.org/licenses/MIT

require 'test_helper'

class RbpdfTest < Test::Unit::TestCase
  test "write_html_cell Basic test" do
    pdf = RBPDF.new
    pdf.add_page()

    htmlcontent = '<p>foo</p>'
    pdf.write_html_cell(0, 5, 10, '', htmlcontent, 0, 1)

    pno = pdf.get_page
    assert_equal 1, pno

    y = pdf.get_y
    assert_in_delta 17.3, y, 0.1

    no = pdf.get_num_pages
    assert_equal 1, no
  end

  test "write_html_cell Page Break test 1" do
    pdf = RBPDF.new
    pdf.add_page()

    pdf.set_top_margin(30)

    h = pdf.get_page_height
    pdf.set_y(h - 15)

    htmlcontent = '<p>foo</p>'
    pdf.write_html_cell(0, 5, 10, '', htmlcontent, 0, 1)

    pno = pdf.get_page
    assert_equal 2, pno

    y = pdf.get_y
    assert_in_delta 40.0, y, 0.1

    no = pdf.get_num_pages
    assert_equal 2, no
  end

  test "write_html_cell Page Break test 2" do
    pdf = RBPDF.new
    pdf.add_page()

    pdf.set_top_margin(30)

    h = pdf.get_page_height
    pdf.set_y(h - 15)

    htmlcontent = '<p>foo</p>'
    pdf.write_html_cell(0, 5, 10, '', htmlcontent, "LRBT", 1)

    pno = pdf.get_page
    assert_equal 2, pno

    y = pdf.get_y
    assert_in_delta 40.0, y, 0.1

    no = pdf.get_num_pages
    assert_equal 2, no
  end
end
