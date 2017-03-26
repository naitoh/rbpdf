# Copyright (c) 2011-2017 NAITOH Jun
# Released under the MIT license
# http://www.opensource.org/licenses/MIT

require 'test_helper'

class RbpdfTest < Test::Unit::TestCase
  class MYPDF < RBPDF
    def getHtmlDomArray(html)
      super
    end
    def openHTMLTagHandler(dom, key, cell)
      super
    end
    def get_temp_rtl
      @tmprtl
    end
  end

  test "Dom Basic" do
    pdf = MYPDF.new

    # Simple Text
    dom = pdf.getHtmlDomArray('abc')
    assert_equal 0,     dom[0]['parent'] # Root
    assert_equal false, dom[0]['tag']
    assert_equal({'tag'=>false, 'value'=>'abc', 'elkey'=>0, 'parent'=>0, 'block'=>false}, dom[1])

    # Back Slash Text
    dom = pdf.getHtmlDomArray("a\\bc")
    assert_equal 0,     dom[0]['parent'] # Root
    assert_equal false, dom[0]['tag']
    assert_equal({'tag'=>false, 'value'=>"a\\bc", 'elkey'=>0, 'parent'=>0, 'block'=>false}, dom[1])

    # Simple Tag
    dom = pdf.getHtmlDomArray('<b>abc</b>')
    assert_equal 4,     dom.length

    assert_equal 0,     dom[0]['parent']  # Root
    assert_equal false, dom[0]['tag']
    assert_equal({},    dom[0]['attribute'])

    assert_equal 0,     dom[1]['parent'] # parent -> parent tag key
    assert_equal 0,     dom[1]['elkey']
    assert_equal true,  dom[1]['tag']
    assert_equal true,  dom[1]['opening']
    assert_equal 'b',   dom[1]['value']
    assert_equal({},    dom[1]['attribute'])

    assert_equal({'tag' => false, 'value'=>'abc', 'elkey'=>1, 'parent'=>1, 'block'=>false}, dom[2])  # parent -> open tag key

    assert_equal 1,     dom[3]['parent'] # parent -> open tag key
    assert_equal 2,     dom[3]['elkey']
    assert_equal true,  dom[3]['tag']
    assert_equal false, dom[3]['opening']
    assert_equal 'b',   dom[3]['value']

    # Error Tag (doble colse tag)
    dom = pdf.getHtmlDomArray('</ul></div>')

    assert_equal 0,     dom[0]['parent']  # Root
    assert_equal false, dom[0]['tag']
    assert_equal({},    dom[0]['attribute'])

    if dom.length == 3 # for Rails 3.x/4.0/4.1 (no use Rails 4.2 later)
      assert_equal 0,     dom[1]['parent'] # parent -> Root key
      assert_equal 0,     dom[1]['elkey']
      assert_equal true,  dom[1]['tag']
      assert_equal false, dom[1]['opening']
      assert_equal 'ul',  dom[1]['value']

      assert_equal 0,     dom[2]['parent'] # parent -> Root key
      assert_equal 1,     dom[2]['elkey']
      assert_equal true,  dom[2]['tag']
      assert_equal false, dom[2]['opening']
      assert_equal 'div', dom[2]['value']
    end

    # Attribute
    dom = pdf.getHtmlDomArray('<p style="text-align:justify">abc</p>')
    assert_equal 4,     dom.length

    assert_equal 0,     dom[0]['parent'] # Root
    assert_equal false, dom[0]['tag']
    assert_equal({},    dom[0]['attribute'])

    assert_equal 0,     dom[1]['parent'] # parent -> parent tag key
    assert_equal 0,     dom[1]['elkey']
    assert_equal true,  dom[1]['tag']
    assert_equal true,  dom[1]['opening']
    assert_equal 'p',   dom[1]['value']
    assert_not_nil dom[1]['attribute']
    assert_equal 'text-align:justify;', dom[1]['attribute']['style'].gsub(' ', '')
    assert_equal 'J',   dom[1]['align']

    # Table border
    dom = pdf.getHtmlDomArray('<table border="1"><tr><td>abc</td></tr></table>')
    ## added marker tag (by getHtmlDomArray()) ##
    # '<table border="1"><tr><td>abc<marker style="font-size:0"/></td></tr></table>'
    assert_equal 9,             dom.length

    assert_equal 0,             dom[1]['parent'] # parent -> parent tag key
    assert_equal 0,             dom[1]['elkey']
    assert_equal true,          dom[1]['tag']
    assert_equal true,          dom[1]['opening']
    assert_equal 'table',       dom[1]['value']
    assert_equal '1',           dom[1]['attribute']['border']

    ## marker tag (by getHtmlDomArray())
    assert_equal 3,             dom[5]['parent'] # parent -> parent tag key
    assert_equal 4,             dom[5]['elkey']
    assert_equal true,          dom[5]['tag']
    assert_equal true,          dom[5]['opening']
    assert_equal 'marker',      dom[5]['value']
    assert_equal 'font-size:0', dom[5]['attribute']['style']

    # Table td Width
    dom = pdf.getHtmlDomArray('<table><tr><td width="10">abc</td></tr></table>')
    ## added marker tag (by getHtmlDomArray()) ##
    # '<table><tr><td width="10">abc<marker style="font-size:0"/></td></tr></table>'
    assert_equal 9,    dom.length

    assert_equal 2,     dom[3]['parent'] # parent -> parent tag key
    assert_equal 2,     dom[3]['elkey']
    assert_equal true,  dom[3]['tag']
    assert_equal true,  dom[3]['opening']
    assert_equal 'td',  dom[3]['value']
    assert_equal '10',  dom[3]['width']
  end

  test "Dom self close tag test" do
    pdf = MYPDF.new

    # Simple Tag
    dom = pdf.getHtmlDomArray('<b>ab<br>c</b>')
    assert_equal 6,     dom.length

    assert_equal 0,     dom[0]['parent'] # Root
    assert_equal false, dom[0]['tag']
    assert_equal({},    dom[0]['attribute'])

    # <b>
    assert_equal 0,     dom[1]['parent'] # parent -> parent tag key
    assert_equal 0,     dom[1]['elkey']
    assert_equal true,  dom[1]['tag']
    assert_equal true,  dom[1]['opening']
    assert_equal 'b',   dom[1]['value']
    assert_equal({},    dom[1]['attribute'])

    # ab
    assert_equal({'tag' => false, 'value'=>'ab', 'elkey'=>1, 'parent'=>1, 'block'=>false}, dom[2])  # parent -> open tag key

    # <br>
    assert_equal 1,     dom[3]['parent'] # parent -> open tag key
    assert_equal 2,     dom[3]['elkey']
    assert_equal true,  dom[3]['tag']
    assert_equal true,  dom[3]['opening']
    assert_equal 'br',  dom[3]['value']
    assert_equal({},    dom[3]['attribute'])

    # c
    assert_equal({'tag' => false, 'value'=>'c', 'elkey'=>3, 'parent'=>1, 'block'=>false}, dom[4])  # parent -> open tag key

    # </b>
    assert_equal 1,     dom[5]['parent'] # parent -> open tag key
    assert_equal 4,     dom[5]['elkey']
    assert_equal true,  dom[5]['tag']
    assert_equal false, dom[5]['opening']
    assert_equal 'b',   dom[5]['value']

    dom2 = pdf.getHtmlDomArray('<b>ab<br/>c</b>')
    assert_equal dom, dom2

    htmlcontent = '<b><img src="/public/ng.png" alt="test alt attribute" width="30" height="30" border="0"/></b>'
    dom1 = pdf.getHtmlDomArray(htmlcontent)
    htmlcontent = '<b><img src="/public/ng.png" alt="test alt attribute" width="30" height="30" border="0"></b>'
    dom2 = pdf.getHtmlDomArray(htmlcontent)
    assert_equal dom1, dom2

    dom1 = pdf.getHtmlDomArray('<b>ab<hr/>c</b>')
    dom2 = pdf.getHtmlDomArray('<b>ab<hr>c</b>')
    assert_equal dom1, dom2
  end

  test "Dom HTMLTagHandler Basic test" do
    pdf = MYPDF.new
    pdf.add_page

    # Simple HTML
    htmlcontent = '<h1>HTML Example</h1>'
    dom1 = pdf.getHtmlDomArray(htmlcontent)
    dom2 = pdf.openHTMLTagHandler(dom1, 1, false)
    assert_equal dom1, dom2
  end

  test "Dom HTMLTagHandler DIR RTL test" do
    pdf = MYPDF.new
    pdf.add_page
    temprtl = pdf.get_temp_rtl
    assert_equal false, temprtl

    # LTR, ltr
    htmlcontent = '<p dir="ltr">HTML Example</p>'
    dom = pdf.getHtmlDomArray(htmlcontent)
    dom = pdf.openHTMLTagHandler(dom, 1, false)

    assert_equal true,  dom[1]['tag']
    assert_equal true,  dom[1]['opening']
    assert_equal 'p',   dom[1]['value']
    assert_equal 'ltr', dom[1]['attribute']['dir']

    temprtl = pdf.get_temp_rtl
    assert_equal false, temprtl

    # LTR, rtl
    htmlcontent = '<p dir="rtl">HTML Example</p>'
    dom = pdf.getHtmlDomArray(htmlcontent)
    dom = pdf.openHTMLTagHandler(dom, 1, false)
    assert_equal 4,     dom.length

    assert_equal true,  dom[1]['tag']
    assert_equal true,  dom[1]['opening']
    assert_equal 'p',   dom[1]['value']
    assert_equal 'rtl', dom[1]['attribute']['dir']

    temprtl = pdf.get_temp_rtl
    assert_equal 'R',   temprtl

    # LTR, ltr
    htmlcontent = '<p dir="ltr">HTML Example</p>'
    dom = pdf.getHtmlDomArray(htmlcontent)
    dom = pdf.openHTMLTagHandler(dom, 1, false)

    assert_equal true,  dom[1]['tag']
    assert_equal true,  dom[1]['opening']
    assert_equal 'p',   dom[1]['value']
    assert_equal 'ltr', dom[1]['attribute']['dir']

    temprtl = pdf.get_temp_rtl
    assert_equal false, temprtl
  end

  test "Dom HTMLTagHandler DIR LTR test" do
    pdf = MYPDF.new
    pdf.add_page
    temprtl = pdf.get_temp_rtl
    assert_equal false, temprtl
    pdf.set_rtl(true)

    # RTL, ltr
    htmlcontent = '<p dir="ltr">HTML Example</p>'
    dom = pdf.getHtmlDomArray(htmlcontent)
    dom = pdf.openHTMLTagHandler(dom, 1, false)
    assert_equal 4,     dom.length

    assert_equal true,  dom[1]['tag']
    assert_equal true,  dom[1]['opening']
    assert_equal 'p',   dom[1]['value']
    assert_equal 'ltr', dom[1]['attribute']['dir']

    temprtl = pdf.get_temp_rtl
    assert_equal 'L',   temprtl

    # RTL, rtl
    htmlcontent = '<p dir="rtl">HTML Example</p>'
    dom = pdf.getHtmlDomArray(htmlcontent)
    dom = pdf.openHTMLTagHandler(dom, 1, false)
    assert_equal 4,     dom.length

    assert_equal true,  dom[1]['tag']
    assert_equal true,  dom[1]['opening']
    assert_equal 'p',   dom[1]['value']
    assert_equal 'rtl', dom[1]['attribute']['dir']

    temprtl = pdf.get_temp_rtl
    assert_equal false, temprtl
  end

  test "Dom HTMLTagHandler img y position with height attribute test" do
    pdf = MYPDF.new
    pdf.add_page

    # Image Error HTML
    htmlcontent = '<img src="/public/ng.png" alt="test alt attribute" width="30" height="30" border="0"/>'
    dom1 = pdf.getHtmlDomArray(htmlcontent)
    #y1 = pdf.get_y

    dom2 = pdf.openHTMLTagHandler(dom1, 1, false)
    y2 = pdf.get_y
    assert_equal dom1, dom2
    assert_equal pdf.get_image_rby - (12 / pdf.get_scale_factor) , y2
  end

  test "Dom HTMLTagHandler img y position without height attribute test" do
    pdf = MYPDF.new
    pdf.add_page

    # Image Error HTML
    htmlcontent = '<img src="/public/ng.png" alt="test alt attribute" border="0"/>'
    dom1 = pdf.getHtmlDomArray(htmlcontent)
    y1 = pdf.get_y

    dom2 = pdf.openHTMLTagHandler(dom1, 1, false)
    y2 = pdf.get_y
    assert_equal dom1, dom2
    assert_equal y1, y2
  end

  test "Dom open angled bracket '<' test" do
    pdf = MYPDF.new
    pdf.add_page

    htmlcontent = "<p>AAA '<'-BBB << <<< '</' '<//' '<///' CCC.</p>"
    dom = pdf.getHtmlDomArray(htmlcontent)
    assert_equal 4,     dom.length

    assert_equal 0,     dom[0]['parent']  # Root
    assert_equal false, dom[0]['tag']
    assert_equal({},    dom[0]['attribute'])

    assert_equal 0,     dom[1]['parent']   # parent -> parent tag key
    assert_equal 0,     dom[1]['elkey']
    assert_equal true,  dom[1]['tag']
    assert_equal true,  dom[1]['opening']
    assert_equal 'p',   dom[1]['value']
    assert_equal({},    dom[1]['attribute'])

    assert_equal 1,     dom[2]['parent']   # parent -> open tag key
    assert_equal 1,     dom[2]['elkey']
    assert_equal false, dom[2]['tag']
    assert_equal "AAA '<'-BBB << <<< '</' '<//' '<///' CCC.", dom[2]['value']

    assert_equal 1,     dom[3]['parent']   # parent -> open tag key
    assert_equal 2,     dom[3]['elkey']
    assert_equal true,  dom[3]['tag']
    assert_equal false, dom[3]['opening']
    assert_equal 'p',   dom[3]['value']
  end

  test "getHtmlDomArray encoding test" do
    return unless 'test'.respond_to?(:force_encoding)

    pdf = MYPDF.new('P', 'mm', 'A4', true, "UTF-8", true)
    htmlcontent = 'test'.force_encoding('ASCII-8BIT')
    pdf.getHtmlDomArray(htmlcontent)
    assert_equal 'ASCII-8BIT', htmlcontent.encoding.to_s
  end
end
