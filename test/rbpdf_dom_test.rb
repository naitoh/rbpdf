# Copyright (c) 2011-2017 NAITOH Jun
# Released under the MIT license
# http://www.opensource.org/licenses/MIT

require 'test_helper'

class RbpdfTest < Test::Unit::TestCase
  class MYPDF < RBPDF
    def get_temp_rtl
      @tmprtl
    end
  end

  htmls = {
    'Simple Text'     => {:html => 'abc', :length => 2,
                          :params => [{:parent => 0, :tag => false}, # parent -> Root
                                      {:parent => 0, :tag => false, :value => 'abc',   :elkey => 0, :block => false}]},
    'Back Slash Text' => {:html => 'a\\bc', :length => 2,
                          :params => [{:parent => 0, :tag => false}, # parent -> Root
                                      {:parent => 0, :tag => false, :value => 'a\\bc', :elkey => 0, :block => false}]},
    'Simple Tag'      => {:html => '<b>abc</b>', :length => 4,
                          :params => [{:parent => 0, :tag => false, :attribute => {}}, # parent -> Root
                                      {:parent => 0, :tag => true,  :value => 'b',     :elkey => 0, :opening => true, :attribute => {}},
                                      {:parent => 1, :tag => false, :value => 'abc',   :elkey => 1, :block => false},     # parent -> open tag key
                                      {:parent => 1, :tag => true,  :value => 'b',     :elkey => 2, :opening => false}]}, # parent -> open tag key
    'Error Tag (doble colse tag)' => {:html => '</ul></div>',
                                      :validated_length => 1, # for Rails 4.2 later (no use Rails 3.x/4.0/4.1)
                          :params => [{:parent => 0, :tag => false, :attribute => {}}, # parent -> Root
                                      {:parent => 0, :tag => true,  :value => 'ul',    :elkey => 0, :opening => false},   # parent -> Root key
                                      {:parent => 0, :tag => true,  :value => 'div',   :elkey => 1, :opening => false}]}, # parent -> Root key
    'Attribute'       => {:html => '<p style="text-align:justify">abc</p>', :length => 4,
                          :params => [{:parent => 0, :tag => false, :attribute => {}}, # parent -> Root
                                      {:parent => 0, :tag => true,  :value => 'p',     :elkey => 0, :opening => true, :align => 'J', :attribute => {:style => 'text-align:justify;'}}]},
    'Table border'    => {:html => '<table border="1"><tr><td>abc</td></tr></table>', :length => 9,
                              # -> '<table border="1"><tr><td>abc<marker style="font-size:0"/></td></tr></table>' ## added marker tag (by getHtmlDomArray()) ##
                          :params => [{:parent => 0, :tag => false, :attribute => {}}, # parent -> Root
                                      {:parent => 0, :tag => true,  :value => 'table', :elkey => 0, :opening => true, :attribute => {:border => 1}},
                                      {},
                                      {},
                                      {},
                                      # marker tag (by getHtmlDomArray())
                                      {:parent => 3, :tag => true,  :value => 'marker', :elkey => 4, :opening => true, :attribute => {:style => 'font-size:0'}}]},
    'Table td Width'  => {:html => '<table><tr><td width="10">abc</td></tr></table>', :length => 9,
                              # -> '<table><tr><td width="10">abc<marker style="font-size:0"/></td></tr></table>' ## added marker tag (by getHtmlDomArray()) ##
                          :params => [{},
                                      {},
                                      {},
                                      {:parent => 2, :tag => true,  :value => 'td',    :elkey => 2, :opening => true, :width => '10'}]},
    'Dom open angled bracket "<"' => {:html => "<p>AAA '<'-BBB << <<< '</' '<//' '<///' CCC.</p>", :length => 4,
                          :params => [{:parent => 0, :tag => false, :attribute => {}}, # parent -> Root
                                      {:parent => 0, :tag => true,  :value => 'p',    :elkey => 0, :opening => true, :attribute => {}},
                                      {:parent => 1, :tag => false, :value => "AAA '<'-BBB << <<< '</' '<//' '<///' CCC.",   :elkey => 1},
                                      {:parent => 1, :tag => true,  :value => 'p',    :elkey => 2, :opening => false}]},
    'Dom self close tag' => {:html => '<b>ab<br>c</b>', :length => 6, # See. 'Dom self close tag test (Simple Tag)'
                          :params => [{:parent => 0, :tag => false, :attribute => {}}, # parent -> Root
                                      {:parent => 0, :tag => true,  :value => 'b',    :elkey => 0, :opening => true, :attribute => {}}, # <b>
                                      {:parent => 1, :tag => false, :value => 'ab',   :elkey => 1, :block => false},                    # ab
                                      {:parent => 1, :tag => true,  :value => 'br',   :elkey => 2, :opening => true, :attribute => {}}, # <br>
                                      {:parent => 1, :tag => false, :value => 'c',    :elkey => 3, :block => false},                    # c
                                      {:parent => 1, :tag => true,  :value => 'b',    :elkey => 4, :opening => false}]},                # </b>
  }

  data(htmls)
  test "Dom Basic test" do |data|
    pdf = RBPDF.new
    dom = pdf.send(:getHtmlDomArray, data[:html])
    assert_equal data[:length], dom.length if data[:length]
    data[:params].each_with_index {|param, i|
      # validated length check (for Rails 4.2 later)
      if dom[i].nil? and i >= data[:validated_length]
        break
      end

      param.each {|key, val|
        if (key == :attribute) and !val.empty?
          val.each {|k, v|
            if (k == :style) and !v.empty?
              assert_equal("dom[#{i}][attribute]: #{k} => #{v}", "dom[#{i}][attribute]: #{k} => #{dom[i][key.to_s][k.to_s].gsub(' ', '')}")
            else
              assert_equal("dom[#{i}][attribute]: #{k} => #{v}", "dom[#{i}][attribute]: #{k} => #{dom[i][key.to_s][k.to_s]}")
            end
          }
        else
          assert_equal("dom[#{i}]: #{key} => #{val}", "dom[#{i}]: #{key} => #{dom[i][key.to_s]}")
        end
      }
    }
  end

  test "Dom self close tag test" do
    pdf = RBPDF.new

    # Simple Tag
    dom = pdf.send(:getHtmlDomArray, '<b>ab<br>c</b>')
    dom2 = pdf.send(:getHtmlDomArray, '<b>ab<br/>c</b>')
    assert_equal dom, dom2

    htmlcontent = '<b><img src="/public/ng.png" alt="test alt attribute" width="30" height="30" border="0"/></b>'
    dom1 = pdf.send(:getHtmlDomArray, htmlcontent)
    htmlcontent = '<b><img src="/public/ng.png" alt="test alt attribute" width="30" height="30" border="0"></b>'
    dom2 = pdf.send(:getHtmlDomArray, htmlcontent)
    assert_equal dom1, dom2

    dom1 = pdf.send(:getHtmlDomArray, '<b>ab<hr/>c</b>')
    dom2 = pdf.send(:getHtmlDomArray, '<b>ab<hr>c</b>')
    assert_equal dom1, dom2
  end

  test "Dom HTMLTagHandler Basic test" do
    pdf = RBPDF.new
    pdf.add_page

    # Simple HTML
    htmlcontent = '<h1>HTML Example</h1>'
    dom1 = pdf.send(:getHtmlDomArray, htmlcontent)
    dom2 = pdf.send(:openHTMLTagHandler, dom1, 1, false)
    assert_equal dom1, dom2
  end

  htmls = {
    'LTR' => {:lines => [{:html => '<p dir="ltr">HTML Example</p>', :length => 4,
                          :params => [{}, {:tag => true,  :value => 'p',     :opening => true, :attribute => {:dir => 'ltr'}, :temprtl => false}]},
                         {:html => '<p dir="rtl">HTML Example</p>', :length => 4,
                          :params => [{}, {:tag => true,  :value => 'p',     :opening => true, :attribute => {:dir => 'rtl'}, :temprtl => 'R'}]},
                         {:html => '<p dir="ltr">HTML Example</p>', :length => 4,
                          :params => [{}, {:tag => true,  :value => 'p',     :opening => true, :attribute => {:dir => 'ltr'}, :temprtl => false}]}
                        ]},
    'RTL' => {:rtl => true, 
              :lines => [{:html => '<p dir="ltr">HTML Example</p>', :length => 4,
                          :params => [{}, {:tag => true,  :value => 'p',     :opening => true, :attribute => {:dir => 'ltr'}, :temprtl => 'L'}]},
                         {:html => '<p dir="rtl">HTML Example</p>', :length => 4,
                          :params => [{}, {:tag => true,  :value => 'p',     :opening => true, :attribute => {:dir => 'rtl'}, :temprtl => false}]}
                        ]},
  }

  data(htmls)
  test "Dom HTMLTagHandler DIR test" do |data|
    pdf = MYPDF.new
    pdf.add_page
    temprtl = pdf.get_temp_rtl
    assert_equal false, temprtl
    pdf.set_rtl(true) if data[:rtl]

    data[:lines].each_with_index {|line, l|
      dom = pdf.send(:getHtmlDomArray, line[:html])
      dom = pdf.send(:openHTMLTagHandler, dom, 1, false)

      assert_equal line[:length], dom.length if line[:length]
      line[:params].each_with_index {|param, i|
        param.each {|key, val|
          if (key == :attribute) and !val.empty?
            val.each {|k, v|
              assert_equal("#{l}: dom[#{i}][attribute]: #{k} => #{v}", "#{l}: dom[#{i}][attribute]: #{k} => #{dom[i][key.to_s][k.to_s]}")
            }
          elsif (key == :temprtl)
            temprtl = pdf.get_temp_rtl
            assert_equal("#{l}: dom[#{i}]: temprtl => #{val}", "#{l}: dom[#{i}]: temprtl => #{temprtl.to_s}")
          else
            assert_equal("#{l}: dom[#{i}]: #{key} => #{val}", "#{l}: dom[#{i}]: #{key} => #{dom[i][key.to_s]}")
          end
        }
      }
    }
  end

  test "Dom HTMLTagHandler img y position with height attribute test" do
    pdf = RBPDF.new
    pdf.add_page

    # Image Error HTML
    htmlcontent = '<img src="/public/ng.png" alt="test alt attribute" width="30" height="30" border="0"/>'
    dom1 = pdf.send(:getHtmlDomArray, htmlcontent)
    #y1 = pdf.get_y

    dom2 = pdf.send(:openHTMLTagHandler, dom1, 1, false)
    y2 = pdf.get_y
    assert_equal dom1, dom2
    assert_equal pdf.get_image_rby - (12 / pdf.get_scale_factor) , y2
  end

  test "Dom HTMLTagHandler img y position without height attribute test" do
    pdf = RBPDF.new
    pdf.add_page

    # Image Error HTML
    htmlcontent = '<img src="/public/ng.png" alt="test alt attribute" border="0"/>'
    dom1 = pdf.send(:getHtmlDomArray, htmlcontent)
    y1 = pdf.get_y

    dom2 = pdf.send(:openHTMLTagHandler, dom1, 1, false)
    y2 = pdf.get_y
    assert_equal dom1, dom2
    assert_equal y1, y2
  end

  test "getHtmlDomArray encoding test" do
    return unless 'test'.respond_to?(:force_encoding)

    pdf = RBPDF.new('P', 'mm', 'A4', true, "UTF-8", true)
    htmlcontent = 'test'.force_encoding('ASCII-8BIT')
    pdf.send(:getHtmlDomArray, htmlcontent)
    assert_equal 'ASCII-8BIT', htmlcontent.encoding.to_s
  end
end
