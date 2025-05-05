# frozen_string_literal: true
# coding: ASCII-8BIT
# Copyright (c) 2011-2023 NAITOH Jun
# Released under the MIT license
# http://www.opensource.org/licenses/MIT

require 'test_helper'

class RbpdfFormFuncTest < Test::Unit::TestCase
  test "JScolor test" do
    pdf = RBPDF.new
    pdf.add_page

    valid_color_code = '#ff0000'
    result = pdf.send(:JScolor, valid_color_code)
    assert_equal "['RGB',1.000,0.000,0.000]", result

    valid_color_name = 'black'
    result = pdf.send(:JScolor, valid_color_name)
    assert_equal 'color.black', result

    invalid_color_code = '#zzzzzz'
    result = pdf.send(:JScolor, invalid_color_code)
    assert_equal "['RGB',0.000,0.000,0.000]", result

    assert_raise(RBPDFError) {pdf.send(:JScolor, 'invalid_color_name')}
  end

  test "getAnnotOptFromJSProp test" do
    pdf = RBPDF.new
    pdf.add_page

    # the annotation options area already defined
    prop = { 'aopt' => ['foo', 'bar'] }
    result = pdf.send(:getAnnotOptFromJSProp, prop)
    assert_equal ['foo', 'bar'], result

    # the annotation options area not defined
    prop = {
      'alignment' => 'center',
      'border' => [0, 0, 3],
      'charLimit' => '20',
      'lineWidth' => 2,
      'borderStyle' => 'beveled',
      'buttonAlignX' => 0.7,
      'buttonAlignY' => 0.7,
      'buttonFitBounds' => 'true',
      'buttonPosition' => 'position.iconTextV',
      'buttonScaleHow' => 'scaleHow.proportional',
      'buttonScaleWhen' => 'scaleWhen.tooSmall',
      'fillColor' => [255, 255, 255],
      'rotation' => 90,
      'strokeColor'=>[128, 128, 128],
      'readonly' => 'true',
      'required' => 'true',
      'password' => 'true',
      'multiline' => 'true',
      'NoToggleToOff' => 'true',
      'Radio' => 'true',
      'Pushbutton' => 'true',
      'Combo' => 'true',
      'editable' => 'true',
      'Sort' => 'true',
      'fileSelect' => 'true',
      'multipleSelection' => 'true',
      'doNotSpellCheck' => 'true',
      'doNotScroll' => 'true',
      'comb' => 'true',
      'radiosInUnison' => 'true',
      'richText' => 'true',
      'commitOnSelChange' => 'true',
      'display' => 'display.noPrint',
      'currentValueIndices'=>[1, 3],
      'value' => [0, 0, 3, 4],
      'exportValues' => ['North', 'East', 'South', 'West'],
      'richValue' => [],
      'submitName' => 'submitName',
      'name' => 'name',
      'userName' => 'userName',
      'highlight' => 'highlight.n',
    }
    expected = {
      'border' => [0, 0, 3],
      'bs' => {'w'=>2, 's'=>'B'},
      'f' => '0100_0000'.to_i(2),
      'ff' => '0111_1111_1111_1111_0000_0000_0011'.gsub('_', '').to_i(2),
      'h' => 'N',
      'i' => [1, 3],
      'maxlen' => 20,
      'mk' => {
        'bg' => [255, 255, 255],
        'bc' => [128, 128, 128],
        'if' => {
          'a' => [0.7, 0.7],
          'fb' => true,
          's' => 'P',
          'sw' => 'S'
        },
        'r' => 90,
        'tp' => 2,
      },
      'opt' => [['North', 0], ['East', 0], ['South', 3], ['West', 4]],
      'q' => 1,
      'rv' => [],
      't' => 'name',
      'tm' => 'submitName',
      'tu' => 'userName',
    }
    result = pdf.send(:getAnnotOptFromJSProp, prop)
    assert_equal expected, result
  end

  def addfield_result(type, name, x, y, w, h, pdf)
    @h = pdf.get_page_height
    k = pdf.get_scale_factor
    font_size_pt = pdf.get_font_size_pt
    +<<~EOS
      if(getField('tcpdfdocsaved').value != 'saved') {f#{name}=this.addField('#{name}','#{type}',#{pdf.PageNo() - 1},[#{sprintf("%.2f,%.2f,%.2f,%.2f", x * k, (@h - y) * k + 1, (x + w) * k, (@h - y - h) * k + 1)}]);
      f#{name}.textSize=#{font_size_pt};
    EOS
  end

  test "addfield test" do
    pdf = RBPDF.new
    pdf.add_page
    type = 'text'
    name = 'field1'
    x = 10
    y = 10
    w = 50
    h = 10

    expected = addfield_result(type, name, x, y, w, h, pdf)
    expected << "f#{name}.fillColor=['RGB',1.000,1.000,1.000];\n"
    expected << "f#{name}.textColor=['RGB',0.000,0.000,0.000];\n}"
    result = pdf.send(:addfield, type, name, x, y, w, h, {'fillColor' => '#ffffff', 'textColor' => '#000000'})
    assert_equal expected, result

    expected << addfield_result(type, name, x, y, w, h, pdf)
    expected << "f#{name}.required='true';\n"
    expected << "f#{name}.maxlength='10';\n}"
    result = pdf.send(:addfield, type, name, x, y, w, h, {'required' => true, 'maxlength' => 10})
    assert_equal expected, result
  end

  test "TextField test" do
    # Check javascript
    pdf = RBPDF.new
    pdf.add_page
    name = 'test_field'
    x = 50
    y = 50
    w = 100
    h = 50
    prop = {'required' => 'true', 'maxlength' => 10}

    expected = addfield_result('text', name, x, y, w, h, pdf)
    expected << "f#{name}.required='true';\n"
    expected << "f#{name}.maxlength='10';\n}"

    pdf.TextField(name, w, h, prop, {}, x, y, true)
    javascript = pdf.instance_variable_get('@javascript')
    assert_equal expected, javascript

    # Check Annotation
    opt = {'maxlen' => 10}
    eopt = {
      'Subtype' => 'Widget',
      'ap' => { 'n' => 'q BT /F1 12.00 Tf 0 g ET Q' },
      'border' => [0, 0, 1],
      'bs' => { 's' => 'S', 'w' => 1 },
      'maxlen' => 10,
      'da' => '/F1 12.00 Tf 0 g',
      'f' => '0000_0100'.to_i(2),
      'ft' => 'Tx',
      'ff' => '0000_0000_0000_0000_0000_0000_0010'.gsub('_', '').to_i(2), # required
      'mk'=>{
        'bc' => [128, 128, 128],
        'bg' => [255, 255, 255],
        'if' => { 'a' => [0.5, 0.5] },
      },
      't' => name,
    }

    pdf = RBPDF.new
    pdf.TextField(name, w, h, prop, opt, 50, 50) # js = false
    javascript = pdf.instance_variable_get('@javascript')
    assert_equal '', javascript
    page_annots = pdf.instance_variable_get('@page_annots')
    assert_equal 2,    page_annots.length
    assert_equal nil,  page_annots[0]
    assert_equal 1,    page_annots[1].length
    assert_equal 0,    page_annots[1][0]['numspaces']
    assert_equal x,    page_annots[1][0]['x']
    assert_equal y,    page_annots[1][0]['y']
    assert_equal w,    page_annots[1][0]['w']
    assert_equal h,    page_annots[1][0]['h']
    assert_equal eopt, page_annots[1][0]['opt']
    assert_equal name, page_annots[1][0]['txt']
  end

  test "RadioButton test" do
    # Check javascript
    pdf = RBPDF.new
    pdf.add_page
    name = 'radio'
    x = 50
    y = 50
    w = 100
    h = 50
    prop = {'required' => 'true', 'maxlength' => 10}

    expected = addfield_result('radiobutton', name, x, y, w, w, pdf)
    expected << "f#{name}.required='true';\n"
    expected << "f#{name}.maxlength='10';\n}"

    pdf.RadioButton(name, w, prop, {}, 'On', false, x, y, true)
    javascript = pdf.instance_variable_get('@javascript')
    assert_equal expected, javascript

    # Check Annotation : checked = false
    opt = {'default_value' => 'default_value'}
    eopt = {
      'Subtype' => 'Widget',
      'ap' => {
        'n' => {
         'Off' => 'q 0 g BT /F3 12.00 Tf 0 0 Td (o) Tj ET Q',
         'On' => 'q 0 g BT /F3 12.00 Tf 0 0 Td (n) Tj ET Q'
        }
      },
      'as' => 'Off',
      'border' => [0, 0, 1],
      'bs' => { 's' => 'I', 'w' => 1 },
      'default_value' => 'default_value',
      'da' => '/F3 12.00 Tf 0 g',
      'f' => '0000_0100'.to_i(2),
      'ft' => 'Btn',
      'ff' => '0000_0000_0000_1100_0000_0000_0010'.gsub('_', '').to_i(2), # Radio, NoToggleToOff, required
      'mk'=>{
        'bc' => [128, 128, 128],
        'bg' => [255, 255, 255],
        'ca' =>  '(l)',
        'if' => { 'a' => [0.5, 0.5] },
      },
    }

    pdf = RBPDF.new
    pdf.add_page
    annots_obj_id = pdf.instance_variable_get('@annot_obj_id')
    pdf.RadioButton(name, w, prop, opt, 'On', false, x, y) # js = false
    javascript = pdf.instance_variable_get('@javascript')
    assert_equal '', javascript

    page_annots = pdf.instance_variable_get('@page_annots')
    assert_equal 2,    page_annots.length
    assert_equal nil,  page_annots[0]
    assert_equal 1,    page_annots[1].length
    assert_equal 0,    page_annots[1][0]['numspaces']
    assert_equal x,    page_annots[1][0]['x']
    assert_equal y,    page_annots[1][0]['y']
    assert_equal w,    page_annots[1][0]['w']
    assert_equal w,    page_annots[1][0]['h']
    assert_equal eopt, page_annots[1][0]['opt']
    assert_equal name, page_annots[1][0]['txt']

    radio_groups = pdf.instance_variable_get('@radio_groups')
    assert_equal annots_obj_id + 1, radio_groups[0]

    radiobutton_groups = pdf.instance_variable_get('@radiobutton_groups')
    assert_equal 2,                 radiobutton_groups.length
    assert_equal annots_obj_id + 2, radiobutton_groups[1][name][0]['kid']
    assert_equal 'Off',             radiobutton_groups[1][name][0]['def']

    # Check Annotation : checked = true
    eopt['as'] = 'On'
    eopt['v'] = ['/On']

    pdf = RBPDF.new
    pdf.add_page
    annots_obj_id = pdf.instance_variable_get('@annot_obj_id')
    pdf.RadioButton(name, w, prop, opt, 'On', true, x, y) # js = false
    javascript = pdf.instance_variable_get('@javascript')
    assert_equal '', javascript

    page_annots = pdf.instance_variable_get('@page_annots')
    assert_equal 2,    page_annots.length
    assert_equal nil,  page_annots[0]
    assert_equal 1,    page_annots[1].length
    assert_equal 0,    page_annots[1][0]['numspaces']
    assert_equal x,    page_annots[1][0]['x']
    assert_equal y,    page_annots[1][0]['y']
    assert_equal w,    page_annots[1][0]['w']
    assert_equal w,    page_annots[1][0]['h']
    assert_equal eopt, page_annots[1][0]['opt']
    assert_equal name, page_annots[1][0]['txt']

    radiobutton_groups = pdf.instance_variable_get('@radiobutton_groups')
    assert_equal 2,                 radiobutton_groups.length
    assert_equal annots_obj_id + 2, radiobutton_groups[1][name][0]['kid']
    assert_equal 'On',              radiobutton_groups[1][name][0]['def']
  end

  def eopt_result_Ch(name, values, ff)
    {
      'Subtype' => 'Widget',
      'ap' => {
        'n' => <<~EOS.chomp
          /Tx BMC q /F1 12.00 Tf 0 g 0.57 w 0 J 0 j [] 0 d 0 G 0 g

          0.57 w 0 J 0 j [] 0 d 0 G 0 g
          BT 1.13 16.08 Td 0 Tr 0.00 w [(-)] TJ ET
          0.57 w 0 J 0 j [] 0 d 0 G 0 g
          BT 1.13 1.08 Td 0 Tr 0.00 w [(Male)] TJ ET
          0.57 w 0 J 0 j [] 0 d 0 G 0 g
          BT 1.13 -13.92 Td 0 Tr 0.00 w [(Fema'le)] TJ ET
          Q EMC
        EOS
      },
      'border' => [0, 0, 1],
      'bs' => { 's' => 'S', 'w' => 1 },
      'default_value' => 'default_value',
      'da' => '/F1 12.00 Tf 0 g',
      'f' => '0000_0100'.to_i(2),
      'ft' => 'Ch',
      'ff' => ff,
      'mk'=>{
        'bc' => [128, 128, 128],
        'bg' => [255, 255, 255],
        'if' => { 'a' => [0.5, 0.5] },
      },
      "opt" => values,
      't' => name,
    }
  end

  test "ListBox test" do
    # Check javascript : Each element of an array that can be converted to a string.
    pdf = RBPDF.new
    pdf.add_page
    name = 'list'
    x = 50
    y = 60
    w = 40
    h = 10
    values = ['option1', "opti'on2", 'option3']
    prop = {'required' => 'true', 'maxlength' => 10}

    expected = addfield_result('listbox', name, x, y, w, h, pdf)
    expected << "f#{name}.required='true';\n"
    expected << "f#{name}.maxlength='10';\n}"
    expected << "f#{name}.setItems(['option1','opti\'on2','option3']);\n"

    result = pdf.ListBox(name, w, h, values, prop, {}, x, y, true )
    javascript = pdf.instance_variable_get('@javascript')
    assert_equal expected, javascript

    # Check javascript : Each element of an array that is an array.
    pdf = RBPDF.new
    pdf.add_page
    values = [['', '-'], ['M', 'Male'],['F', "Fema'le"]]

    expected = addfield_result('listbox', name, x, y, w, h, pdf)
    expected << "f#{name}.required='true';\n"
    expected << "f#{name}.maxlength='10';\n}"
    expected << "f#{name}.setItems([['','-'],['M','Male'],['F','Fema\'le']]);\n"

    result = pdf.ListBox(name, w, h, values, prop, {}, x, y, true )
    javascript = pdf.instance_variable_get('@javascript')
    assert_equal expected, javascript

    # Check Annotation
    pdf = RBPDF.new
    opt = {'default_value' => 'default_value'}
    ff =  '0000_0000_0000_0000_0000_0000_0010'.gsub('_', '').to_i(2) # required
    eopt = eopt_result_Ch(name, values, ff)

    result = pdf.ListBox(name, w, h, values, prop, opt, x, y) # js = false
    javascript = pdf.instance_variable_get('@javascript')
    assert_equal '', javascript
    page_annots = pdf.instance_variable_get('@page_annots')
    assert_equal 2,    page_annots.length
    assert_equal nil,  page_annots[0]
    assert_equal 1,    page_annots[1].length
    assert_equal 0,    page_annots[1][0]['numspaces']
    assert_equal x,    page_annots[1][0]['x']
    assert_equal y,    page_annots[1][0]['y']
    assert_equal w,    page_annots[1][0]['w']
    assert_equal h,    page_annots[1][0]['h']
    assert_equal eopt, page_annots[1][0]['opt']
    assert_equal name, page_annots[1][0]['txt']
  end

  test "ComboBox test" do
    # Check javascript : Each element of an array that can be converted to a string.
    pdf = RBPDF.new
    pdf.add_page
    name = 'combo'
    x = 50
    y = 60
    w = 40
    h = 10
    values = ['option1', "opti'on2", 'option3']
    prop = {'required' => 'true', 'maxlength' => 10}

    expected = addfield_result('combobox', name, x, y, w, h, pdf)
    expected << "f#{name}.required='true';\n"
    expected << "f#{name}.maxlength='10';\n}"
    expected << "f#{name}.setItems(['option1','opti\'on2','option3']);\n"

    result = pdf.ComboBox(name, w, h, values, prop, {}, x, y, true )
    javascript = pdf.instance_variable_get('@javascript')
    assert_equal expected, javascript

    # Check javascript : Each element of an array that is an array.
    pdf = RBPDF.new
    values = [['', '-'], ['M', 'Male'],['F', "Fema'le"]]

    expected = addfield_result('combobox', name, x, y, w, h, pdf)
    expected << "f#{name}.required='true';\n"
    expected << "f#{name}.maxlength='10';\n}"
    expected << "f#{name}.setItems([['','-'],['M','Male'],['F','Fema\'le']]);\n"

    result = pdf.ComboBox(name, w, h, values, prop, {}, x, y, true )
    javascript = pdf.instance_variable_get('@javascript')
    assert_equal expected, javascript

    # Check Annotation
    pdf = RBPDF.new
    opt = {'default_value' => 'default_value'}
    ff = '0000_0000_0010_0000_0000_0000_0010'.gsub('_', '').to_i(2) # Combo, required
    eopt = eopt_result_Ch(name, values, ff)

    result = pdf.ComboBox(name, w, h, values, prop, opt, x, y) # js = false
    javascript = pdf.instance_variable_get('@javascript')
    assert_equal '', javascript
    page_annots = pdf.instance_variable_get('@page_annots')
    assert_equal 2,    page_annots.length
    assert_equal nil,  page_annots[0]
    assert_equal 1,    page_annots[1].length
    assert_equal 0,    page_annots[1][0]['numspaces']
    assert_equal x,    page_annots[1][0]['x']
    assert_equal y,    page_annots[1][0]['y']
    assert_equal w,    page_annots[1][0]['w']
    assert_equal h,    page_annots[1][0]['h']
    assert_equal eopt, page_annots[1][0]['opt']
    assert_equal name, page_annots[1][0]['txt']
  end

  test "CheckBox test" do
    # Check javascript
    pdf = RBPDF.new
    pdf.add_page
    name = 'check'
    x = 50
    y = 50
    w = 100
    h = 50
    onvalue = 'Yes'
    prop = {'required' => 'true', 'maxlength' => 10}

    expected = addfield_result('checkbox', name, x, y, w, w, pdf)
    expected << "f#{name}.required='true';\n"
    expected << "f#{name}.maxlength='10';\n}"

    pdf.CheckBox(name, w, false, prop, {}, onvalue, x, y, true)
    javascript = pdf.instance_variable_get('@javascript')
    assert_equal expected, javascript

    # Check Annotation : checked = false
    opt = {'default_value' => 'default_value'}
    eopt = {
      'Subtype' => 'Widget',
      'ap' => {
        'n' => {
         'Off' => 'q 0 g BT /F3 12.00 Tf 0 0 Td (o) Tj ET Q',
         'Yes' => 'q 0 g BT /F3 12.00 Tf 0 0 Td (n) Tj ET Q'
        }
      },
      'as' => 'Off',
      'border' => [0, 0, 1],
      'bs' => { 's' => 'I', 'w' => 1 },
      'default_value' => 'default_value',
      'da' => '/F3 12.00 Tf 0 g',
      'f' => '0000_0100'.to_i(2),
      'ft' => 'Btn',
      'ff' => '0000_0000_0000_0000_0000_0000_0010'.gsub('_', '').to_i(2), # required
      'mk'=>{
        'bc' => [128, 128, 128],
        'bg' => [255, 255, 255],
        'if' => { 'a' => [0.5, 0.5] },
      },
      'opt' => [onvalue],
      't' => name,
      'v' => ['/Off'],
    }

    pdf = RBPDF.new
    pdf.add_page
    pdf.CheckBox(name, w, false, prop, opt, onvalue, x, y) # js = false
    javascript = pdf.instance_variable_get('@javascript')
    assert_equal '', javascript
    page_annots = pdf.instance_variable_get('@page_annots')
    assert_equal 2,    page_annots.length
    assert_equal nil,  page_annots[0]
    assert_equal 1,    page_annots[1].length
    assert_equal 0,    page_annots[1][0]['numspaces']
    assert_equal x,    page_annots[1][0]['x']
    assert_equal y,    page_annots[1][0]['y']
    assert_equal w,    page_annots[1][0]['w']
    assert_equal w,    page_annots[1][0]['h']
    assert_equal eopt, page_annots[1][0]['opt']
    assert_equal name, page_annots[1][0]['txt']

    # Check Annotation : checked = true
    onvalue = 'OK'
    eopt['opt'] = [onvalue]
    eopt['as'] = 'Yes'
    eopt['v'] = ['/Yes']

    pdf = RBPDF.new
    pdf.add_page
    pdf.CheckBox(name, w, true, prop, opt, onvalue, x, y)  # js = false
    javascript = pdf.instance_variable_get('@javascript')
    assert_equal '', javascript
    page_annots = pdf.instance_variable_get('@page_annots')
    assert_equal 2,    page_annots.length
    assert_equal nil,  page_annots[0]
    assert_equal 1,    page_annots[1].length
    assert_equal 0,    page_annots[1][0]['numspaces']
    assert_equal x,    page_annots[1][0]['x']
    assert_equal y,    page_annots[1][0]['y']
    assert_equal w,    page_annots[1][0]['w']
    assert_equal w,    page_annots[1][0]['h']
    assert_equal eopt, page_annots[1][0]['opt']
    assert_equal name, page_annots[1][0]['txt']
  end

  def eopt_result_Btn(pdf, caption, name, w, aa)
    s = pdf.send(:textstring, caption)
    k = pdf.get_scale_factor
    width = pdf.GetStringWidth(caption)
    xdk = sprintf('%.2f', ((w - width) / 2.0 ) * k)

    {
      'Subtype' => 'Widget',
      'aa' => aa,
      'ap' => {
        'n' => <<~EOS.chomp
        /Tx BMC q /F1 12.00 Tf 0 g 0.800 g
        2.83 w 0 J 0 j [] 0.00 d 0.906 G 0.800 g
        0.00 141.73 283.46 -141.73 re B 
        2.83 w
        0 J
        0 j
        [] 0.00 d
        0.906 G 
        0.800 g
        2.83 w 0 J 0 j [] 0.00 d 0.906 G 0.800 g
        q 0 g BT #{xdk} 125.50 Td 0 Tr 0.00 w [(#{caption})] TJ ET Q
        Q EMC
        EOS
      },
      'border' => [0, 0, 1],
      'bs' => { 's' => 'S', 'w' => 1 },
      'default_value' => 'default_value',
      'da' => '/F1 12.00 Tf 0 g',
      'f' => '0000_0000'.to_i(2),
      'ft' => 'Btn',
      'ff' => '0000_0000_0001_0000_0000_0000_0010'.gsub('_', '').to_i(2), # Pushbutton, required
      'h' => 'P',
      'mk'=>{
        'ac' => s,
        'bc' => [128, 128, 128],
        'bg' => [255, 255, 255],
        'ca' => s,
        'if' => { 'a' => [0.5, 0.5] },
        'rc' => s,
      },
      't' => caption,
      'v' => name,
    }
  end

  test "Button test" do
    # Check javascript
    pdf = RBPDF.new
    pdf.add_page
    name = 'button'
    caption = "Pr'int"
    action = "Print('')"
    x = 50
    y = 50
    w = 100
    h = 50
    prop = {'required' => 'true', 'maxlength' => 10}

    expected = addfield_result('button', name, x, y, w, h, pdf)
    expected << "f#{name}.required='true';\n"
    expected << "f#{name}.maxlength='10';\n}"
    expected << "f#{name}.buttonSetCaption('#{caption}');\n"
    expected << "f#{name}.setAction('MouseUp','#{action}');\n"
    expected << "f#{name}.highlight='push';\n"
    expected << "f#{name}.print=false;\n"

    pdf.Button(name, w, h, caption, action, prop, {}, x, y, true)
    javascript = pdf.instance_variable_get('@javascript')
    assert_equal expected, javascript

    # Check Annotation : Print
    opt = {'default_value' => 'default_value'}
    eopt = eopt_result_Btn(pdf, caption, name, w, '/D 300001 0 R')

    pdf = RBPDF.new
    pdf.add_page
    pdf.Button(name, w, h, caption, action, prop, opt, x, y) # js = false
    javascript = pdf.instance_variable_get('@javascript')
    assert_equal '', javascript

    page_annots = pdf.instance_variable_get('@page_annots')
    assert_equal 2,    page_annots.length
    assert_equal nil,  page_annots[0]
    assert_equal 1,    page_annots[1].length
    assert_equal 0,    page_annots[1][0]['numspaces']
    assert_equal x,    page_annots[1][0]['x']
    assert_equal y,    page_annots[1][0]['y']
    assert_equal w,    page_annots[1][0]['w']
    assert_equal h,    page_annots[1][0]['h']
    assert_equal eopt, page_annots[1][0]['opt']
    assert_equal name, page_annots[1][0]['txt']

    js_objects = pdf.instance_variable_get('@js_objects')
    assert_equal true, js_objects.value?({"js"=>"Print('')", "onload"=>false})

    # Check Annotation : action : S
    caption = 'Reset'
    action = {'S'=>'ResetForm'}
    eopt = eopt_result_Btn(pdf, caption, name, w, "/D << /S /ResetForm >>")

    pdf = RBPDF.new
    pdf.add_page
    pdf.Button(name, w, h, caption, action, prop, opt, x, y) # js = false
    javascript = pdf.instance_variable_get('@javascript')
    assert_equal '', javascript

    page_annots = pdf.instance_variable_get('@page_annots')
    assert_equal 2,    page_annots.length
    assert_equal nil,  page_annots[0]
    assert_equal 1,    page_annots[1].length
    assert_equal 0,    page_annots[1][0]['numspaces']
    assert_equal x,    page_annots[1][0]['x']
    assert_equal y,    page_annots[1][0]['y']
    assert_equal w,    page_annots[1][0]['w']
    assert_equal h,    page_annots[1][0]['h']
    assert_equal eopt, page_annots[1][0]['opt']
    assert_equal name, page_annots[1][0]['txt']

    # Check Annotation : action : Flags
    caption = 'Flags'
    action = {'Flags'=>
      ['Include/Exclude', 'IncludeNoValueFields', 'ExportFormat', 'GetMethod', 'SubmitCoordinates',
       'XFDF', 'IncludeAppendSaves', 'IncludeAnnotations', 'SubmitPDF', 'CanonicalFormat',
       'ExclNonUserAnnots', 'ExclFKey', 'EmbedForm']}
    eopt = eopt_result_Btn(pdf, caption, name, w, "/D << /Flags #{'0010_1111_1111_1111'.gsub('_', '').to_i(2)} >>")

    pdf = RBPDF.new
    pdf.add_page
    pdf.Button(name, w, h, caption, action, prop, opt, x, y) # js = false
    javascript = pdf.instance_variable_get('@javascript')
    assert_equal '', javascript

    page_annots = pdf.instance_variable_get('@page_annots')
    assert_equal 2,    page_annots.length
    assert_equal nil,  page_annots[0]
    assert_equal 1,    page_annots[1].length
    assert_equal 0,    page_annots[1][0]['numspaces']
    assert_equal x,    page_annots[1][0]['x']
    assert_equal y,    page_annots[1][0]['y']
    assert_equal w,    page_annots[1][0]['w']
    assert_equal h,    page_annots[1][0]['h']
    assert_equal eopt, page_annots[1][0]['opt']
    assert_equal name, page_annots[1][0]['txt']
  end
end
