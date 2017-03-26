# Copyright (c) 2011-2017 NAITOH Jun
# Released under the MIT license
# http://www.opensource.org/licenses/MIT

require 'test_helper'

class RbpdfCssTest < Test::Unit::TestCase
  class MYPDF < RBPDF
    def extractCSSproperties(cssdata)
      super
    end
    def isValidCSSSelectorForTag(dom, key, selector)
      super
    end
    def getTagStyleFromCSS(dom, key, css)
      super
    end
    def getHtmlDomArray(html)
      super
    end
  end

  test "CSS Basic" do
    pdf = MYPDF.new

    # empty
    css = pdf.extractCSSproperties('')
    assert_equal({}, css)
    # empty blocks
    css = pdf.extractCSSproperties('h1 {}')
    assert_equal({}, css)
    # comment
    css = pdf.extractCSSproperties('/* comment */')
    assert_equal({}, css)

    css = pdf.extractCSSproperties('h1 { color: navy; font-family: times; }')
    assert_equal({"0001 h1"=>"color:navy;font-family:times;"}, css)

    css = pdf.extractCSSproperties('h1 { color: navy; font-family: times; } p.first { color: #003300; font-family: helvetica; font-size: 12pt; }')
    assert_equal({"0001 h1"=>"color:navy;font-family:times;", "0021 p.first"=>"color:#003300;font-family:helvetica;font-size:12pt;"}, css)

    css = pdf.extractCSSproperties('h1,h2,h3{background-color:#e0e0e0}')
    assert_equal({"0001 h1"=>"background-color:#e0e0e0", "0001 h2"=>"background-color:#e0e0e0", "0001 h3"=>"background-color:#e0e0e0"}, css)

    css = pdf.extractCSSproperties('p.second { color: rgb(00,63,127); font-family: times; font-size: 12pt; text-align: justify; }')
    assert_equal({"0011 p.second"=>"color:rgb(00,63,127);font-family:times;font-size:12pt;text-align:justify;"}, css)

    css = pdf.extractCSSproperties('p#second { color: rgb(00,63,127); font-family: times; font-size: 12pt; text-align: justify; }')
    assert_equal({"0101 p#second"=>"color:rgb(00,63,127);font-family:times;font-size:12pt;text-align:justify;"}, css)

    css = pdf.extractCSSproperties('p.first { color: rgb(00,63,127); } p.second { font-family: times; }')
    assert_equal({"0021 p.first"=>"color:rgb(00,63,127);", "0011 p.second"=>"font-family:times;"}, css)

    css = pdf.extractCSSproperties('p#first { color: rgb(00,63,127); } p#second { color: rgb(00,63,127); }')
    assert_equal({"0111 p#first"=>"color:rgb(00,63,127);", "0101 p#second"=>"color:rgb(00,63,127);"}, css)

    # media
    css = pdf.extractCSSproperties('@media print { body { font: 10pt serif } }')
    assert_equal({"0001 body"=>"font:10pt serif"}, css)
    css = pdf.extractCSSproperties('@media screen { body { font: 12pt sans-serif } }')
    assert_equal({}, css)
    css = pdf.extractCSSproperties('@media all { body { line-height: 1.2 } }')
    assert_equal({"0001 body"=>"line-height:1.2"}, css)

    css = pdf.extractCSSproperties('@media print {
                   #top-menu, #header, #main-menu, #sidebar, #footer, .contextual, .other-formats { display:none; }
                   #main { background: #fff; }
                   #content { width: 99%; margin: 0; padding: 0; border: 0; background: #fff; overflow: visible !important;}
                   #wiki_add_attachment { display:none; }
                   .hide-when-print { display: none; }
                   .autoscroll {overflow-x: visible;}
                   table.list {margin-top:0.5em;}
                   table.list th, table.list td {border: 1px solid #aaa;}
                 } @media all { body { line-height: 1.2 } }')
    assert_equal({"0100 #top-menu"=>"display:none;",
                  "0100 #header"=>"display:none;",
                  "0100 #main-menu"=>"display:none;",
                  "0100 #sidebar"=>"display:none;",
                  "0100 #footer"=>"display:none;",
                  "0010 .contextual"=>"display:none;",
                  "0010 .other-formats"=>"display:none;",
                  "0100 #main"=>"background:#fff;",
                  "0100 #content"=>"width:99%;margin:0;padding:0;border:0;background:#fff;overflow:visible !important;",
                  "0100 #wiki_add_attachment"=>"display:none;",
                  "0010 .hide-when-print"=>"display:none;",
                  "0010 .autoscroll"=>"overflow-x:visible;",
                  "0011 table.list"=>"margin-top:0.5em;",
                  "0012 table.list th"=>"border:1px solid #aaa;",
                  "0012 table.list td"=>"border:1px solid #aaa;",
                  "0001 body"=>"line-height:1.2"}, css)
  end

  test "CSS Selector Valid test" do
    pdf = MYPDF.new

    # Simple CSS
    dom = pdf.getHtmlDomArray('<p>abc</p>')
    assert_equal 4, dom.length
    valid = pdf.isValidCSSSelectorForTag(dom, 1, ' p') # dom, key, css selector
    assert_equal true, valid

    dom = pdf.getHtmlDomArray('<h1>abc</h1>')
    assert_equal 4, dom.length
    valid = pdf.isValidCSSSelectorForTag(dom, 1, ' h1') # dom, key, css selector
    assert_equal true, valid

    dom = pdf.getHtmlDomArray('<p class="first">abc</p>')
    assert_equal 4, dom.length
    valid = pdf.isValidCSSSelectorForTag(dom, 1, ' p.first') # dom, key, css selector
    assert_equal true, valid

    dom = pdf.getHtmlDomArray('<p class="first">abc<span>def</span></p>')
    assert_equal 7, dom.length
    valid = pdf.isValidCSSSelectorForTag(dom, 3, ' p.first span') # dom, key, css selector
    assert_equal true, valid

    dom = pdf.getHtmlDomArray('<p id="second">abc</p>')
    assert_equal 4, dom.length
    valid = pdf.isValidCSSSelectorForTag(dom, 1, ' p#second') # dom, key, css selector
    assert_equal true, valid

    dom = pdf.getHtmlDomArray('<p id="second">abc<span>def</span></p>')
    assert_equal 7, dom.length
    valid = pdf.isValidCSSSelectorForTag(dom, 3, ' p#second > span') # dom, key, css selector
    assert_equal true, valid
  end

  test "CSS Tag Sytle test 1" do
    pdf = MYPDF.new

    # Simple CSS
    dom = pdf.getHtmlDomArray('<h1>abc</h1>')
    assert_equal 4, dom.length

    tag = pdf.getTagStyleFromCSS(dom, 1, {'0001 h1'=>'color:navy;font-family:times;'}) # dom, key, css selector
    assert_equal ';color:navy;font-family:times;', tag

    tag = pdf.getTagStyleFromCSS(dom, 1, {'0001h1'=>'color:navy;font-family:times;'}) # dom, key, css selector
    assert_equal '', tag

    tag = pdf.getTagStyleFromCSS(dom, 1, {'0001 h2'=>'color:navy;font-family:times;'}) # dom, key, css selector
    assert_equal '', tag
  end

  test "CSS Tag Sytle test 2" do
    pdf = MYPDF.new

    dom = pdf.getHtmlDomArray('<p class="first">abc</p>')
    assert_equal 4, dom.length

    tag = pdf.getTagStyleFromCSS(dom, 1, {'0021 p.first'=>'color:rgb(00,63,127);'})
    assert_equal ';color:rgb(00,63,127);', tag

    dom = pdf.getHtmlDomArray('<p id="second">abc</p>')
    assert_equal 4, dom.length

    tag = pdf.getTagStyleFromCSS(dom, 1, {'0101 p#second'=>'color:rgb(00,63,127);font-family:times;font-size:12pt;text-align:justify;'})
    assert_equal ';color:rgb(00,63,127);font-family:times;font-size:12pt;text-align:justify;', tag
  end

  test "CSS Dom test" do
    pdf = MYPDF.new

    html = '<style> table, td { border: 2px #ff0000 solid; } </style>
            <h2>HTML TABLE:</h2>
            <table> <tr> <th>abc</th> </tr>
                    <tr> <td>def</td> </tr> </table>'
    dom = pdf.getHtmlDomArray(html)
    ## remove style tag block (by getHtmlDomArray()) ##
    ## added marker tag (by getHtmlDomArray())       ##
    # '<h2>HTML TABLE:</h2>
    #  <table><tr><th>abc<marker style="font-size:0"/></th></tr>
    #         <tr><td>def<marker style="font-size:0"/></td></tr></table>'
    assert_equal 18,    dom.length

    assert_equal 0,     dom[0]['parent']  # Root
    assert_equal false, dom[0]['tag']
    assert_equal({},    dom[0]['attribute'])

    # <h2>
    assert_equal 0,     dom[1]['elkey']
    assert_equal 0,     dom[1]['parent']   # parent -> parent tag key
    assert_equal true,  dom[1]['tag']
    assert_equal true,  dom[1]['opening']
    assert_equal 'h2',  dom[1]['value']

    # <table>
    assert_equal 3,                   dom[4]['elkey']
    assert_equal 'table',             dom[4]['value']
    assert_equal({'border'=>'2px #ff0000 solid', 'style'=>';border:2px #ff0000 solid;'}, dom[4]['attribute'])
    assert_equal '2px #ff0000 solid', dom[4]['style']['border']
    assert_equal '2px #ff0000 solid', dom[4]['attribute']['border']
  end

  test "CSS Dom table thead test" do
    pdf = MYPDF.new

    html = '<style> table, td { border: 2px #ff0000 solid; } </style>
            <h2>HTML TABLE THEAD:</h2>
            <table><thead>
            <tr> <th>abc</th> </tr>
            </thead>
            <tbody>
            <tr> <td>def</td> </tr>
            <tr> <td>ghi</td> </tr>
            </tbody></table>'

    dom = pdf.getHtmlDomArray(html)
    ## remove style tag block (by getHtmlDomArray())       ##
    ## remove thead/tbody tag block (by getHtmlDomArray()) ##
    ## added marker tag (by getHtmlDomArray())             ##
    # '<h2>HTML TABLE:</h2>
    #  <table><tr><th>abc<marker style="font-size:0"/></th></tr>
    #         <tr><td>def<marker style="font-size:0"/></td></tr></table>'
    assert_equal 24,    dom.length

    assert_equal 0,     dom[0]['parent']  # Root
    assert_equal false, dom[0]['tag']
    assert_equal({},    dom[0]['attribute'])

    # <h2>
    assert_equal 0,     dom[1]['elkey']
    assert_equal 0,     dom[1]['parent'] # parent -> parent tag key
    assert_equal true,  dom[1]['tag']
    assert_equal true,  dom[1]['opening']
    assert_equal 'h2',  dom[1]['value']

    # <table>
    assert_equal 3,                   dom[4]['elkey']
    assert_equal 'table',             dom[4]['value']
    assert_equal({'border'=>'2px #ff0000 solid', 'style'=>';border:2px #ff0000 solid;'}, dom[4]['attribute'])
    assert_equal '2px #ff0000 solid', dom[4]['style']['border']
    assert_equal '2px #ff0000 solid', dom[4]['attribute']['border']
    assert_equal '<style>table {;border:2px #ff0000 solid;}</style><table tablehead="1"><tr><th>abc<marker style="font-size:0"/></th></tr></table>', dom[4]['thead']
  end

  test "CSS Dom line-height test normal" do
    pdf = MYPDF.new

    html = '<style>  h2 { line-height: normal; } </style>
            <h2>HTML TEST</h2>'
    dom = pdf.getHtmlDomArray(html)
    ## remove style tag block (by getHtmlDomArray()) ##
    # '<h2>HTML TEST</h2>'
    assert_equal 4,    dom.length

    # <h2>
    assert_equal 0,    dom[1]['elkey']
    assert_equal 0,    dom[1]['parent']   # parent -> parent tag key
    assert_equal true, dom[1]['tag']
    assert_equal true, dom[1]['opening']
    assert_equal 'h2', dom[1]['value']
    assert_equal 1.25, dom[1]['line-height']
  end

  test "CSS Dom line-height test numeric" do
    pdf = MYPDF.new

    html = '<style>  h2 { line-height: 1.4; } </style>
            <h2>HTML TEST</h2>'
    dom = pdf.getHtmlDomArray(html)
    ## remove style tag block (by getHtmlDomArray()) ##
    # '<h2>HTML TEST</h2>'
    assert_equal dom.length, 4

    # <h2>
    assert_equal 0,    dom[1]['elkey']
    assert_equal 0,    dom[1]['parent']   # parent -> parent tag key
    assert_equal true, dom[1]['tag']
    assert_equal true, dom[1]['opening']
    assert_equal 'h2', dom[1]['value']
    assert_equal 1.4,  dom[1]['line-height']
  end

  test "CSS Dom line-height test percentage" do
    pdf = MYPDF.new

    html = '<style>  h2 { line-height: 10%; } </style>
            <h2>HTML TEST</h2>'
    dom = pdf.getHtmlDomArray(html)
    ## remove style tag block (by getHtmlDomArray()) ##
    # '<h2>HTML TEST</h2>'
    assert_equal dom.length, 4

    # <h2>
    assert_equal 0,    dom[1]['parent']   # parent -> parent tag key
    assert_equal 0,    dom[1]['elkey']
    assert_equal true, dom[1]['tag']
    assert_equal true, dom[1]['opening']
    assert_equal 'h2', dom[1]['value']
    assert_equal 0.1,  dom[1]['line-height']
  end

  test "CSS Dom class test" do
    pdf = MYPDF.new

    html = '<style>p.first { color: #003300; font-family: helvetica; font-size: 12pt; }
                   p.first span { color: #006600; font-style: italic; }</style>
            <p class="first">Example <span>Fusce</span></p>'
    dom = pdf.getHtmlDomArray(html)
    ## remove style tag block (by getHtmlDomArray()) ##
    # '<p class="first">Example <span>Fusce</span></p>'
    assert_equal dom.length, 7

    # <p class="first">
    assert_equal 0,           dom[1]['elkey']
    assert_equal 0,           dom[1]['parent'] # parent -> parent tag key
    assert_equal true,        dom[1]['tag']
    assert_equal true,        dom[1]['opening']
    assert_equal 'p',         dom[1]['value']
    assert_equal 'first',     dom[1]['attribute']['class']
    assert_equal '#003300',   dom[1]['style']['color']
    assert_equal 'helvetica', dom[1]['style']['font-family']
    assert_equal '12pt',      dom[1]['style']['font-size']

    # Example 
    assert_equal 1,          dom[2]['elkey']
    assert_equal 1,          dom[2]['parent']
    assert_equal false,      dom[2]['tag']
    assert_equal 'Example ', dom[2]['value']

    # <span>
    assert_equal 2,         dom[3]['elkey']
    assert_equal 1,         dom[3]['parent']
    assert_equal true,      dom[3]['tag']
    assert_equal true,      dom[3]['opening']
    assert_equal 'span',    dom[3]['value']
    assert_equal '#006600', dom[3]['style']['color']
    assert_equal 'italic',  dom[3]['style']['font-style']
  end

  test "CSS Dom height width test" do 
    pdf = MYPDF.new

    html = '<style> p.first { height: 60%; }
                    p.second { width: 70%; }</style>
            <p class="first">ABC</p><p class="second">DEF</p>'
    dom = pdf.getHtmlDomArray(html)
    assert_equal 7,     dom.length

    # <p class="first">
    assert_equal 0,     dom[1]['elkey']
    assert_equal 0,     dom[1]['parent'] # parent -> parent tag key
    assert_equal true,  dom[1]['tag']
    assert_equal true,  dom[1]['opening']
    assert_equal 'p',   dom[1]['value']
    assert_not_nil dom[1]['style']
    assert_equal '60%', dom[1]['style']['height']
    assert_equal '60%', dom[1]['height']

    # ABC
    assert_equal 1,     dom[2]['elkey']
    assert_equal 1,     dom[2]['parent']
    assert_equal false, dom[2]['tag']
    assert_equal 'ABC', dom[2]['value']

    # <p class="second">
    assert_equal 3,     dom[4]['elkey']
    assert_equal 0,     dom[4]['parent'] # parent -> parent tag key
    assert_equal true,  dom[4]['tag']
    assert_equal true,  dom[4]['opening']
    assert_equal 'p',   dom[4]['value']
    assert_not_nil dom[4]['style']
    assert_equal '70%', dom[4]['style']['width']
    assert_equal '70%', dom[4]['width']
  end

  test "CSS Dom font-weight test" do
    pdf = MYPDF.new

    html = '<style> p.first { font-weight: bold; }</style>
            <p class="first">ABC</p><p class="second">DEF</p>'
    dom = pdf.getHtmlDomArray(html)
    assert_equal 7,      dom.length

    # <p class="first">
    assert_equal 0,      dom[1]['elkey']
    assert_equal 0,      dom[1]['parent'] # parent -> parent tag key
    assert_equal true,   dom[1]['tag']
    assert_equal true,   dom[1]['opening']
    assert_equal 'p',    dom[1]['value']
    assert_not_nil dom[1]['style']
    assert_equal 'bold', dom[1]['style']['font-weight']
    assert_equal 'B',    dom[1]['fontstyle']

    # ABC
    assert_equal 1,      dom[2]['elkey']
    assert_equal 1,      dom[2]['parent']
    assert_equal false,  dom[2]['tag']
    assert_equal 'ABC',  dom[2]['value']
  end

  test "CSS Dom id test" do
    pdf = MYPDF.new

    html = '<style> p#second > span { background-color: #FFFFAA; }</style>
            <p id="second">Example <span>Fusce</span></p>'
    dom = pdf.getHtmlDomArray(html)
    ## remove style tag block (by getHtmlDomArray()) ##
    # '<p id="second">Example <span>Fusce</span></p>'
    assert_equal 7, dom.length

    # <p id="second">
    assert_equal 0,        dom[1]['elkey']
    assert_equal 0,        dom[1]['parent'] # parent -> parent tag key
    assert_equal true,     dom[1]['tag']
    assert_equal true,     dom[1]['opening']
    assert_equal 'p',      dom[1]['value']
    assert_equal 'second', dom[1]['attribute']['id']

    # Example 
    assert_equal 1,          dom[2]['elkey']
    assert_equal 1,          dom[2]['parent']
    assert_equal false,      dom[2]['tag']
    assert_equal 'Example ', dom[2]['value']

    # <span>
    assert_equal 2,         dom[3]['elkey']
    assert_equal 1,         dom[3]['parent']
    assert_equal true,      dom[3]['tag']
    assert_equal true,      dom[3]['opening']
    assert_equal 'span',    dom[3]['value']
    assert_equal '#FFFFAA', dom[3]['style']['background-color']
  end

  test "CSS Dom text-decoration test" do
    pdf = MYPDF.new

    html = '<style> p.first { text-decoration: none;}
                    p.second {text-decoration: underline;}
                    p.third {text-decoration: overline;}
                    p.fourth {text-decoration: line-through;}
                    p.fifth {text-decoration: underline overline line-through;}</style>
            <p class="first">ABC</p><p class="second">DEF</p><p class="third">GHI</p><p class="fourth">JKL</p><p class="fifth">MNO</p>'
    dom = pdf.getHtmlDomArray(html)
    assert_equal 16,     dom.length

    # <p class="first">
    assert_equal 0,      dom[1]['elkey']
    assert_equal 0,      dom[1]['parent'] # parent -> parent tag key
    assert_equal true,   dom[1]['tag']
    assert_equal true,   dom[1]['opening']
    assert_equal 'p',    dom[1]['value']
    assert_not_nil dom[1]['style']
    assert_equal 'none', dom[1]['style']['text-decoration']
    assert_equal '',     dom[1]['fontstyle']

    # ABC
    assert_equal 1,      dom[2]['elkey']
    assert_equal 1,      dom[2]['parent']
    assert_equal false,  dom[2]['tag']
    assert_equal 'ABC',  dom[2]['value']

    # <p class="second">
    assert_equal 3,           dom[4]['elkey']
    assert_equal 0,           dom[4]['parent'] # parent -> parent tag key
    assert_equal true,        dom[4]['tag']
    assert_equal true,        dom[4]['opening']
    assert_equal 'p',         dom[4]['value']
    assert_not_nil dom[1]['style']
    assert_equal 'underline', dom[4]['style']['text-decoration']
    assert_equal 'U',         dom[4]['fontstyle']

    # <p class="third">
    assert_equal 6,           dom[7]['elkey']
    assert_equal 0,           dom[7]['parent'] # parent -> parent tag key
    assert_equal true,        dom[7]['tag']
    assert_equal true,        dom[7]['opening']
    assert_equal 'p',         dom[7]['value']
    assert_not_nil dom[7]['style']
    assert_equal 'overline',  dom[7]['style']['text-decoration']
    assert_equal 'O',         dom[7]['fontstyle']

    # <p class="fourth">
    assert_equal 9,              dom[10]['elkey']
    assert_equal 0,              dom[10]['parent'] # parent -> parent tag key
    assert_equal true,           dom[10]['tag']
    assert_equal true,           dom[10]['opening']
    assert_equal 'p',            dom[10]['value']
    assert_not_nil dom[10]['style']
    assert_equal 'line-through', dom[10]['style']['text-decoration']
    assert_equal 'D',            dom[10]['fontstyle']

    # <p class="fifth">
    assert_equal 12,             dom[13]['elkey']
    assert_equal 0,              dom[13]['parent'] # parent -> parent tag key
    assert_equal true,           dom[13]['tag']
    assert_equal true,           dom[13]['opening']
    assert_equal 'p',            dom[13]['value']
    assert_not_nil dom[13]['style']
    assert_equal 'underline overline line-through', dom[13]['style']['text-decoration']
    assert_equal 'UOD',          dom[13]['fontstyle']
  end

  test "CSS Dom text-indent test" do
    pdf = MYPDF.new

    html = '<style> p.first { text-indent: 10px; }
                    p.second { text-indent: 5em; }
                    p.third { text-indent: 5ex; }
                    p.fourth { text-indent: 50%; }</style>
            <p class="first">ABC</p><p class="second">DEF</p><p class="third">GHI</p><p class="fourth">JKL</p>'
    dom = pdf.getHtmlDomArray(html)
    assert_equal 13,      dom.length

    # <p class="first">
    assert_equal 0,       dom[1]['elkey']
    assert_equal 0,       dom[1]['parent'] # parent -> parent tag key
    assert_equal true,    dom[1]['tag']
    assert_equal true,    dom[1]['opening']
    assert_equal 'p',     dom[1]['value']
    assert_not_nil dom[1]['style']
    assert_equal '10px',  dom[1]['style']['text-indent']
    assert_in_delta 3.53, dom[1]['text-indent'], 0.01

    # ABC
    assert_equal 1,     dom[2]['elkey']
    assert_equal 1,     dom[2]['parent']
    assert_equal false, dom[2]['tag']
    assert_equal 'ABC', dom[2]['value']

    # <p class="second">
    assert_equal 3,     dom[4]['elkey']
    assert_equal 0,     dom[4]['parent'] # parent -> parent tag key
    assert_equal true,  dom[4]['tag']
    assert_equal true,  dom[4]['opening']
    assert_equal 'p',   dom[4]['value']
    assert_not_nil dom[4]['style']
    assert_equal '5em', dom[4]['style']['text-indent']
    assert_equal 5.0,   dom[4]['text-indent']

    # <p class="third">
    assert_equal 6,     dom[7]['elkey']
    assert_equal 0,     dom[7]['parent'] # parent -> parent tag key
    assert_equal true,  dom[7]['tag']
    assert_equal true,  dom[7]['opening']
    assert_equal 'p',   dom[7]['value']
    assert_not_nil dom[7]['style']
    assert_equal '5ex', dom[7]['style']['text-indent']
    assert_equal 2.5,   dom[7]['text-indent']

    # <p class="fourth">
    assert_equal 9,     dom[10]['elkey']
    assert_equal 0,     dom[10]['parent'] # parent -> parent tag key
    assert_equal true,  dom[10]['tag']
    assert_equal true,  dom[10]['opening']
    assert_equal 'p',   dom[10]['value']
    assert_not_nil dom[10]['style']
    assert_equal '50%', dom[10]['style']['text-indent']
    assert_equal 0.5,   dom[10]['text-indent']
  end

  test "CSS Dom list-style-type test" do
    pdf = MYPDF.new

    html = '<style> p.first { list-style-type: none; }
                    p.second { list-style-type: disc; }
                    p.third { list-style-type: circle; }
                    p.fourth { list-style-type: square; }</style>
            <p class="first">ABC</p><p class="second">DEF</p><p class="third">GHI</p><p class="fourth">JKL</p>'
    dom = pdf.getHtmlDomArray(html)
    assert_equal 13,       dom.length

    # <p class="first">
    assert_equal 0,        dom[1]['elkey']
    assert_equal 0,        dom[1]['parent'] # parent -> parent tag key
    assert_equal true,     dom[1]['tag']
    assert_equal true,     dom[1]['opening']
    assert_equal 'p',      dom[1]['value']
    assert_not_nil dom[1]['style']
    assert_equal 'none',   dom[1]['style']['list-style-type']
    assert_equal 'none',   dom[1]['listtype']

    # ABC
    assert_equal 1,        dom[2]['elkey']
    assert_equal 1,        dom[2]['parent']
    assert_equal false,    dom[2]['tag']
    assert_equal 'ABC',    dom[2]['value']

    # <p class="second">
    assert_equal 3,        dom[4]['elkey']
    assert_equal 0,        dom[4]['parent'] # parent -> parent tag key
    assert_equal true,     dom[4]['tag']
    assert_equal true,     dom[4]['opening']
    assert_equal 'p',      dom[4]['value']
    assert_not_nil dom[4]['style']
    assert_equal 'disc',   dom[4]['style']['list-style-type']
    assert_equal 'disc',   dom[4]['listtype']

    # <p class="third">
    assert_equal 6,        dom[7]['elkey']
    assert_equal 0,        dom[7]['parent'] # parent -> parent tag key
    assert_equal true,     dom[7]['tag']
    assert_equal true,     dom[7]['opening']
    assert_equal 'p',      dom[7]['value']
    assert_not_nil dom[7]['style']
    assert_equal 'circle', dom[7]['style']['list-style-type']
    assert_equal 'circle', dom[7]['listtype']
  end

  test "CSS Dom page-break test" do
    pdf = MYPDF.new

    html = '<style> p.first { page-break-before: left; page-break-after: always; }
                    p.second { page-break-inside:avoid; }</style>
            <p class="first">ABC</p><p class="second">DEF</p>'
    dom = pdf.getHtmlDomArray(html)
    assert_equal 7,        dom.length

    # <p class="first">
    assert_equal 0,        dom[1]['elkey']
    assert_equal 0,        dom[1]['parent'] # parent -> parent tag key
    assert_equal true,     dom[1]['tag']
    assert_equal true,     dom[1]['opening']
    assert_equal 'p',      dom[1]['value']
    assert_not_nil dom[1]['style']
    assert_equal 'left',   dom[1]['style']['page-break-before']
    assert_equal 'always', dom[1]['style']['page-break-after']
    assert_not_nil dom[1]['attribute']
    assert_equal 'left',   dom[1]['attribute']['pagebreak']
    assert_equal 'true',   dom[1]['attribute']['pagebreakafter']

    # ABC
    assert_equal 1,        dom[2]['elkey']
    assert_equal 1,        dom[2]['parent']
    assert_equal false,    dom[2]['tag']
    assert_equal 'ABC',    dom[2]['value']

    # <p class="second">
    assert_equal 3,        dom[4]['elkey']
    assert_equal 0,        dom[4]['parent'] # parent -> parent tag key
    assert_equal true,     dom[4]['tag']
    assert_equal true,     dom[4]['opening']
    assert_equal 'p',      dom[4]['value']
    assert_not_nil dom[1]['style']
    assert_equal 'avoid',  dom[4]['style']['page-break-inside']
    assert_not_nil dom[4]['attribute']
    assert_equal 'true',   dom[4]['attribute']['nobr']
  end
end
