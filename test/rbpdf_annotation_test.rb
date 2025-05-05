# frozen_string_literal: true
# Copyright (c) 2011-2023 NAITOH Jun
# Released under the MIT license
# http://www.opensource.org/licenses/MIT

require 'test_helper'

class RbpdfTest < Test::Unit::TestCase
  test "Annotation Basic Test" do
    pdf = RBPDF.new

    x = pdf.get_x
    y = pdf.get_y
    w = 30, h = 40
    txt = "Text annotation \ntest"
    opt = {'Subtype'=>'Text', 'Name' => 'Comment', 'T' => 'title example', 'Subj' => 'example', 'C' => [255, 255, 0]}
    annot_obj_id_org = pdf.instance_variable_get('@annot_obj_id')
    pdf.annotation('', '', w, h, txt, opt)
    page_annots = pdf.instance_variable_get('@page_annots')

    assert_equal 2,   page_annots.length
    assert_equal nil, page_annots[0]
    assert_equal 1,   page_annots[1].length
    assert_equal 0,   page_annots[1][0]['numspaces']
    assert_equal x,   page_annots[1][0]['x']
    assert_equal y,   page_annots[1][0]['y']
    assert_equal w,   page_annots[1][0]['w']
    assert_equal h,   page_annots[1][0]['h']
    assert_equal opt, page_annots[1][0]['opt']
    assert_equal txt, page_annots[1][0]['txt']

    annot_obj_id = pdf.instance_variable_get('@annot_obj_id')
    assert_equal annot_obj_id_org + 1, annot_obj_id
  end

  test "Annotation FileAttachment Test" do
    pdf = RBPDF.new

    TEST_FILE_NAME = 'utf8test.txt'
    TEST_FILE_NAME_PATH = 'example/rails/public/' + TEST_FILE_NAME

    x = 80, y = 25, w = 20, h = 30
    txt = 'text file'
    opt = {'Subtype'=>'FileAttachment', 'Name' => 'PushPin', 'FS' => TEST_FILE_NAME_PATH}
    annot_obj_id_org = pdf.instance_variable_get('@annot_obj_id')
    embedded_start_obj_id = pdf.instance_variable_get('@embedded_start_obj_id')

    pdf.annotation(x, y, w, h, txt, opt)
    page_annots = pdf.instance_variable_get('@page_annots')

    assert_equal 2,   page_annots.length
    assert_equal nil, page_annots[0]
    assert_equal 1,   page_annots[1].length
    assert_equal 0,   page_annots[1][0]['numspaces']
    assert_equal x,   page_annots[1][0]['x']
    assert_equal y,   page_annots[1][0]['y']
    assert_equal w,   page_annots[1][0]['w']
    assert_equal h,   page_annots[1][0]['h']
    assert_equal opt, page_annots[1][0]['opt']
    assert_equal txt, page_annots[1][0]['txt']

    annot_obj_id = pdf.instance_variable_get('@annot_obj_id')
    assert_equal annot_obj_id_org + 1, annot_obj_id
    embeddedfiles = pdf.instance_variable_get('@embeddedfiles')
    assert_equal({TEST_FILE_NAME=>{"file"=>TEST_FILE_NAME_PATH, "n"=>embedded_start_obj_id}}, embeddedfiles)
  end
end
