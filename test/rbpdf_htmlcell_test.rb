# Copyright (c) 2011-2018 NAITOH Jun
# Released under the MIT license
# http://www.opensource.org/licenses/MIT

require 'test_helper'

class RbpdfTest < Test::Unit::TestCase
  htmls = {
    'Basic'                => {:html => '<p>foo</p>',
                               :border => 0,      :pno => 1, :y => 17.3, :no => 1},
    'Page Break no border' => {:html => '<p>foo</p>', :margin => 30,
                               :border => 0,      :pno => 2, :y => 40.0, :no => 2},
    'Page Break border'    => {:html => '<p>foo</p>', :margin => 30,
                               :border => 'LRBT', :pno => 2, :y => 40.0, :no => 2},
    'pre tag y position'   => {:html => "<p>test 0</p>\n <pre>test 1\ntest 2\ntest 3</pre>\n <p>test 10</p>",
                               :border => 0,      :pno => 1, :y => 49.0, :no => 1},
  }

  data(htmls)
  test "write_html_cell test" do |data|
    pdf = RBPDF.new
    pdf.add_page()

    if data[:margin]
      pdf.set_top_margin(data[:margin])
      h = pdf.get_page_height
      pdf.set_y(h - 15)
    end

    pdf.write_html_cell(0, 5, 10, '', data[:html], data[:border], 1)

    pno = pdf.get_page
    assert_equal data[:pno], pno

    y = pdf.get_y
    assert_in_delta(data[:y], y, 0.1)

    no = pdf.get_num_pages
    assert_equal data[:no], no
  end
end
