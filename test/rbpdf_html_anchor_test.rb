# Copyright (c) 2011-2017 NAITOH Jun
# Released under the MIT license
# http://www.opensource.org/licenses/MIT

require 'test_helper'

class RbpdfTest < Test::Unit::TestCase
  test "anchor with text inside" do
    pdf = RBPDF.new
    pdf.add_page()

    htmlcontent = '<a name="foo">HTML Example</a>'
    pdf.write_html(htmlcontent, true, 0, true, 0)

    position = pdf.get_html_anchor_position('foo')
    assert_equal [1, 10.001249999999999], position
  end

  test "anchor with id" do
    pdf = RBPDF.new
    pdf.add_page()

    htmlcontent = '<a id="foo">HTML Example</a>'
    pdf.write_html(htmlcontent, true, 0, true, 0)

    position = pdf.get_html_anchor_position('foo')
    assert_equal [1, 10.001249999999999], position
  end

  test "empty anchor" do
    pdf = RBPDF.new
    pdf.add_page()

    htmlcontent = '<a id="foo"></a>'
    pdf.write_html(htmlcontent, true, 0, true, 0)

    position = pdf.get_html_anchor_position('foo')
    assert_equal [1, 10.001249999999999], position
  end


  test "anchor with overtical offset" do
    pdf = RBPDF.new
    pdf.add_page()

    htmlcontent = '<br><br><br><br><br><br><br><br><br><br><a id="foo"></a>'
    pdf.write_html(htmlcontent, true, 0, true, 0)

    position = pdf.get_html_anchor_position('foo')
    assert_equal [1, 57.626249999999985], position
  end


  test "on the second page" do
    pdf = RBPDF.new
    pdf.add_page()
    htmlcontent = '1<br><br><br><br><br><br><br><br><br><br> 2<br><br><br><br><br><br><br><br><br><br> 3<br><br><br><br><br><br><br><br><br><br> 4<br><br><br><br><br><br><br><br><br><br> 5<br><br><br><br><br><br><br><br><br><br> 6<br><br><br><br><br><br><br><br><br><br> 7<br><br><br><br><br><br><br><br><br><br> 8<br><br><br><br><br><br><br><br><br><br> 9<br><br><br><br><br><br><br><br><br><br> 10<br><br><br><br><br><br><br><br><br><br> 11<br><br><br><br><br><br><br><br><br><br>'
    pdf.write_html(htmlcontent, true, 0, true, 0)

    htmlcontent = '<a id="foo"></a>'
    pdf.write_html(htmlcontent, true, 0, true, 0)

    position = pdf.get_html_anchor_position('foo')
    assert_equal [3, 68.20958333333331], position
  end


  test "maps when anchor after link" do
    pdf = RBPDF.new
    pdf.add_page()

    htmlcontent = '<a href="#foo">FooLink</a>'
    pdf.write_html(htmlcontent, true, 0, true, 0)

    htmlcontent = '1<br><br><br><br><br><br><br><br><br><br> 2<br><br><br><br><br><br><br><br><br><br> 3<br><br><br><br><br><br><br><br><br><br> 4<br><br><br><br><br><br><br><br><br><br> 5<br><br><br><br><br><br><br><br><br><br> 6<br><br><br><br><br><br><br><br><br><br> 7<br><br><br><br><br><br><br><br><br><br> 8<br><br><br><br><br><br><br><br><br><br> 9<br><br><br><br><br><br><br><br><br><br> 10<br><br><br><br><br><br><br><br><br><br> 11<br><br><br><br><br><br><br><br><br><br>'
    pdf.write_html(htmlcontent, true, 0, true, 0)

    htmlcontent = '<a id="foo"></a>'
    pdf.write_html(htmlcontent, true, 0, true, 0)

    pdf.send(:mapLinksToHtmlAnchors)
    link_position = pdf.instance_variable_get(:@links)[0]
    assert_equal [3, 73.50124999999998], link_position
  end

  test "maps when anchor before link" do
    pdf = RBPDF.new
    pdf.add_page()

    htmlcontent = '<a id="foo"></a>'
    pdf.write_html(htmlcontent, true, 0, true, 0)

    htmlcontent = '1<br><br><br><br><br><br><br><br><br><br> 2<br><br><br><br><br><br><br><br><br><br> 3<br><br><br><br><br><br><br><br><br><br> 4<br><br><br><br><br><br><br><br><br><br> 5<br><br><br><br><br><br><br><br><br><br> 6<br><br><br><br><br><br><br><br><br><br> 7<br><br><br><br><br><br><br><br><br><br> 8<br><br><br><br><br><br><br><br><br><br> 9<br><br><br><br><br><br><br><br><br><br> 10<br><br><br><br><br><br><br><br><br><br> 11<br><br><br><br><br><br><br><br><br><br>'
    pdf.write_html(htmlcontent, true, 0, true, 0)

    htmlcontent = '<a href="#foo">FooLink</a>'
    pdf.write_html(htmlcontent, true, 0, true, 0)

    pdf.send(:mapLinksToHtmlAnchors)

    link_position = pdf.instance_variable_get(:@links)[0]
    assert_equal [1, 10.001249999999999], link_position
  end

end
