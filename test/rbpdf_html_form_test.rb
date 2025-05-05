# coding: ASCII-8BIT
# frozen_string_literal: true
#
# Copyright (c) 2011-2023 NAITOH Jun
# Released under the MIT license
# http://www.opensource.org/licenses/MIT

require 'test_helper'

class RbpdfHtmlFormTest < Test::Unit::TestCase
  test "write_html <form>,<input> tag test" do
    pdf = RBPDF.new
    pdf.set_print_header(false)
    pdf.add_page()

    htmlcontent = '<form method="post" action="http://localhost/printvars" enctype="multipart/form-data">
    <label for="name">name:</label> <input type="text" name="name" value="test@example.net" size="20" maxlength="30" />
    <label for="password">password:</label> <input type="password" name="password" value="" size="20" maxlength="30" />
    <label for="infile">file:</label> <input type="file" name="userfile" size="20" />
    <input type="submit" name="submit" value="Submit" />
    <input type="reset" name="reset" value="Reset" />
    <input type="button" name="print" value="Print" onclick="print()" />
    <input type="hidden" name="hiddenfield" value="OK" />
    </form>'

    pdf.write_html(htmlcontent, true, 0, true, 0)
    page_annots = pdf.instance_variable_get('@page_annots')
    assert_equal 2,    page_annots.length
    assert_equal nil,  page_annots[0]
    assert_equal 8,    page_annots[1].length

    assert_not_equal nil, page_annots[1][0]['opt']
    assert_equal 0, page_annots[1][0]['opt']['ff']
    assert_equal 'Tx', page_annots[1][0]['opt']['ft']
    assert_equal 4, page_annots[1][0]['opt']['f']
    assert_equal 30, page_annots[1][0]['opt']['maxlen']
    assert_equal 'name', page_annots[1][0]['opt']['t']
    assert_equal 'test@example.net', page_annots[1][0]['opt']['v']
    assert_equal "name", page_annots[1][0]['txt']

    assert_not_equal nil, page_annots[1][1]['opt']
    assert_equal '0000_0000_0000_0010_0000_0000_0000'.gsub('_', '').to_i(2), page_annots[1][1]['opt']['ff'] # password
    assert_equal 'Tx', page_annots[1][1]['opt']['ft']
    assert_equal 4, page_annots[1][1]['opt']['f']
    assert_equal 'password', page_annots[1][1]['opt']['t']
    assert_equal "password", page_annots[1][1]['txt']

    assert_not_equal nil, page_annots[1][2]['opt']
    assert_equal '0000_0001_0000_0000_0000_0000_0000'.gsub('_', '').to_i(2), page_annots[1][2]['opt']['ff'] # fileSelect
    assert_equal 'Tx', page_annots[1][2]['opt']['ft']
    assert_equal 4, page_annots[1][2]['opt']['f']
    assert_equal 'userfile', page_annots[1][2]['opt']['t']
    assert_equal "userfile", page_annots[1][2]['txt']

    assert_not_equal nil, page_annots[1][3]['opt']
    assert_equal '0000_0000_0001_0000_0000_0000_0000'.gsub('_', '').to_i(2), page_annots[1][3]['opt']['ff'] # Pushbutton
    assert_equal 'Btn', page_annots[1][3]['opt']['ft']
    assert_equal 0, page_annots[1][3]['opt']['f']
    assert_equal '*', page_annots[1][3]['opt']['t']
    assert_equal "FB_userfile", page_annots[1][3]['txt']

    assert_not_equal nil, page_annots[1][4]['opt']
    assert_equal '0000_0000_0001_0000_0000_0000_0000'.gsub('_', '').to_i(2), page_annots[1][4]['opt']['ff'] # Pushbutton
    assert_equal 'Btn', page_annots[1][4]['opt']['ft']
    assert_equal 0, page_annots[1][4]['opt']['f']
    assert_equal 'Submit', page_annots[1][4]['opt']['t']
    assert_equal "submit", page_annots[1][4]['txt']
    assert_equal '/D << /S /SubmitForm /F (http://localhost/printvars) /Flags 4 >>', page_annots[1][4]['opt']['aa']

    assert_not_equal nil, page_annots[1][5]['opt']
    assert_equal '0000_0000_0001_0000_0000_0000_0000'.gsub('_', '').to_i(2), page_annots[1][5]['opt']['ff'] # Pushbutton
    assert_equal 'Btn', page_annots[1][5]['opt']['ft']
    assert_equal 0, page_annots[1][5]['opt']['f']
    assert_equal 'Reset', page_annots[1][5]['opt']['t']
    assert_equal 'B', page_annots[1][5]['opt']['bs']['s']
    assert_equal "reset", page_annots[1][5]['txt']
    assert_equal '/D << /S /ResetForm >>', page_annots[1][5]['opt']['aa']

    assert_not_equal nil, page_annots[1][6]['opt']
    assert_equal '0000_0000_0001_0000_0000_0000_0000'.gsub('_', '').to_i(2), page_annots[1][6]['opt']['ff'] # Pushbutton
    assert_equal 'Btn', page_annots[1][6]['opt']['ft']
    assert_equal 0, page_annots[1][6]['opt']['f']
    assert_equal 'Print', page_annots[1][6]['opt']['t']
    assert_equal "print", page_annots[1][6]['txt']
    js_objects = pdf.instance_variable_get('@js_objects')
    assert_equal true, js_objects.value?({"js"=>"print()", "onload"=>false})

    assert_not_equal nil, page_annots[1][7]['opt']
    assert_equal 0, page_annots[1][7]['opt']['ff']
    assert_equal 'Tx', page_annots[1][7]['opt']['ft']
    assert_equal ['invisible', 'hidden'], page_annots[1][7]['opt']['f']
    assert_equal 'hiddenfield', page_annots[1][7]['opt']['t']
    assert_equal "hiddenfield", page_annots[1][7]['txt']
  end

  test "write_html <select> tag ComboBox test" do
    pdf = RBPDF.new
    pdf.set_print_header(false)
    pdf.add_page()

    htmlcontent = '<select name="selection" size="0">
    <option value="0">zero</option>
    <option value="1">one</option>
    </select>'

    pdf.write_html(htmlcontent, true, 0, true, 0)
    page_annots = pdf.instance_variable_get('@page_annots')
    assert_equal 2,    page_annots.length
    assert_equal nil,  page_annots[0]
    assert_equal 1,    page_annots[1].length
    assert_not_equal nil, page_annots[1][0]['opt']
    assert_equal '0000_0000_0010_0000_0000_0000_0000'.gsub('_', '').to_i(2), page_annots[1][0]['opt']['ff'] # Combo
    assert_equal 'Ch', page_annots[1][0]['opt']['ft']
    assert_equal 'selection', page_annots[1][0]['opt']['t']
    assert_equal "selection", page_annots[1][0]['txt']
  end

  test "write_html <select multiple='multiple'> tag ListBox test" do
    pdf = RBPDF.new
    pdf.set_print_header(false)
    pdf.add_page()

    htmlcontent = '<select name="multiselection" size="2" multiple="multiple">
    <option value="0">zero</option>
    <option value="1">one</option>
    </select>'

    pdf.write_html(htmlcontent, true, 0, true, 0)
    page_annots = pdf.instance_variable_get('@page_annots')
    assert_equal 2,    page_annots.length
    assert_equal nil,  page_annots[0]
    assert_equal 1,    page_annots[1].length
    assert_not_equal nil, page_annots[1][0]['opt']
    assert_equal '0000_0010_0000_0000_0000_0000_0000'.gsub('_', '').to_i(2), page_annots[1][0]['opt']['ff'] # multipleSelection
    assert_equal 'Ch', page_annots[1][0]['opt']['ft']
    assert_equal 'multiselection', page_annots[1][0]['opt']['t']
    assert_equal "multiselection", page_annots[1][0]['txt']
  end

  test "write_html <input type='checkbox'> tag test" do
    pdf = RBPDF.new
    pdf.set_print_header(false)
    pdf.add_page()

    htmlcontent = '<input type="checkbox" name="agree" value="1" checked="checked" />
                   <input type="checkbox" name="no agree" value="1" disabled/>'
    pdf.write_html(htmlcontent, true, 0, true, 0)
    page_annots = pdf.instance_variable_get('@page_annots')
    assert_equal 2,    page_annots.length
    assert_equal nil,  page_annots[0]
    assert_equal 2,    page_annots[1].length
    assert_not_equal nil, page_annots[1][0]['opt']
    assert_equal 0, page_annots[1][0]['opt']['ff']
    assert_equal 'Btn', page_annots[1][0]['opt']['ft']
    assert_equal 'Yes', page_annots[1][0]['opt']['as']
    assert_equal ['/Yes'], page_annots[1][0]['opt']['v']
    assert_equal 'agree', page_annots[1][0]['opt']['t']
    assert_equal 'agree', page_annots[1][0]['txt']

    assert_not_equal nil, page_annots[1][1]['opt']
    assert_equal '0000_0000_0000_0000_0000_0000_0001'.gsub('_', '').to_i(2), page_annots[1][1]['opt']['ff']
    assert_equal 'Btn', page_annots[1][1]['opt']['ft']
    assert_equal 'Off', page_annots[1][1]['opt']['as']
    assert_equal ['/Off'], page_annots[1][1]['opt']['v']
    assert_equal 'no agree', page_annots[1][1]['opt']['t']
    assert_equal 'no agree', page_annots[1][1]['txt']
  end

  test "write_html <input type='radio'> tag test" do
    pdf = RBPDF.new
    pdf.set_print_header(false)
    pdf.add_page()

    htmlcontent = '<input type="radio" name="radioquestion" id="rqa" value="1" /> <label for="rqa">one</label>
    <input type="radio" name="radioquestion" id="rqb" value="2" checked="checked"/> <label for="rqb">two</label>'

    pdf.write_html(htmlcontent, true, 0, true, 0)
    page_annots = pdf.instance_variable_get('@page_annots')
    assert_equal 2,    page_annots.length
    assert_equal nil,  page_annots[0]
    assert_equal 2,    page_annots[1].length
    assert_not_equal nil, page_annots[1][0]['opt']
    assert_equal '0000_0000_0000_1100_0000_0000_0000'.gsub('_', '').to_i(2), page_annots[1][0]['opt']['ff'] # Radio, NoToggleToOff
    assert_equal 'Btn', page_annots[1][0]['opt']['ft']
    assert_equal 'Off', page_annots[1][0]['opt']['as']
    assert_equal 'radioquestion', page_annots[1][0]['txt']
    assert_not_equal nil, page_annots[1][1]['opt']
    assert_equal '0000_0000_0000_1100_0000_0000_0000'.gsub('_', '').to_i(2), page_annots[1][1]['opt']['ff'] # Radio, NoToggleToOff
    assert_equal 'Btn', page_annots[1][1]['opt']['ft']
    assert_equal '2', page_annots[1][1]['opt']['as']
    assert_equal 'radioquestion', page_annots[1][1]['txt']
  end
end
