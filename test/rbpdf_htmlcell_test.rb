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
end
