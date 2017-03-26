# Copyright (c) 2011-2017 NAITOH Jun
# Released under the MIT license
# http://www.opensource.org/licenses/MIT

require 'test_helper'

class RbpdfTest < Test::Unit::TestCase
  class MYPDF < RBPDF
    def getPageBuffer(page)
      super
    end
  end

  test "Transaction write test without diskcache" do
    pdf = MYPDF.new
    pdf.add_page()
    page = pdf.get_page

    pdf.write(0, "LINE 0\n")
    contents01 = pdf.getPageBuffer(page).dup

    pdf.start_transaction()

    pdf.write(0, "LINE 1\n")
    pdf.write(0, "LINE 2\n")
    contents02 = pdf.getPageBuffer(page).dup
    assert_not_equal contents01, contents02

    # rolls back to the last (re)start 1
    pdf = pdf.rollback_transaction()
    contents03 = pdf.getPageBuffer(page).dup
    assert_equal contents01, contents03

    pdf.start_transaction()

    pdf.write(0, "LINE 3\n")
    pdf.write(0, "LINE 4\n")
    contents04 = pdf.getPageBuffer(page).dup
    assert_not_equal contents03, contents04

    # rolls back to the last (re)start 2
    pdf = pdf.rollback_transaction()
    contents05 = pdf.getPageBuffer(page).dup
    assert_equal contents03, contents05

    pdf.commit_transaction()
  end

  test "Transaction test with diskcache" do
    pdf = MYPDF.new('P', 'mm', 'A4', true, "UTF-8", true)
    pdf.add_page()
    page = pdf.get_page

    pdf.write(0, "LINE 0\n")
    contents01 = pdf.getPageBuffer(page).dup
    cache_file1 = pdf.cache_file_length.dup

    pdf.start_transaction()

    pdf.write(0, "LINE 1\n")
    pdf.write(0, "LINE 2\n")
    cache_file2 = pdf.cache_file_length.dup
    contents02 = pdf.getPageBuffer(page).dup
    assert_not_equal cache_file1, cache_file2
    assert_not_equal contents01, contents02

    # rolls back to the last (re)start 1
    pdf = pdf.rollback_transaction()

    cache_file3 = pdf.cache_file_length.dup
    contents03 = pdf.getPageBuffer(page).dup
    assert_equal cache_file1, cache_file3
    assert_equal contents01, contents03

    pdf.start_transaction()

    pdf.write(0, "LINE 3\n")
    pdf.write(0, "LINE 4\n")
    contents04 = pdf.getPageBuffer(page).dup
    assert_not_equal contents03, contents04

    # rolls back to the last (re)start 2
    pdf = pdf.rollback_transaction()

    contents05 = pdf.getPageBuffer(page).dup
    assert_equal contents03, contents05
  end

  test "Transaction multi_cell test without diskcache" do
    pdf = MYPDF.new
    pdf.add_page()
    page = pdf.get_page

    pdf.multi_cell(50, 5, 'mult_cell 1', 0)
    contents01 = pdf.getPageBuffer(page).dup

    pdf.start_transaction()

    pdf.multi_cell(50, 5, 'mult_cell 1', 1)
    pdf.multi_cell(50, 5, 'mult_cell 2', 1)
    contents02 = pdf.getPageBuffer(page).dup
    assert_not_equal contents01, contents02

    # rolls back to the last (re)start 1
    pdf = pdf.rollback_transaction()
    contents03 = pdf.getPageBuffer(page).dup
    assert_equal contents01, contents03

    pdf.start_transaction()

    pdf.multi_cell(50, 5, 'mult_cell 3', 1)
    pdf.multi_cell(50, 5, 'mult_cell 4', 1)
    contents04 = pdf.getPageBuffer(page).dup
    assert_not_equal contents03, contents04

    # rolls back to the last (re)start 2
    pdf = pdf.rollback_transaction()
    contents05 = pdf.getPageBuffer(page).dup
    assert_equal contents03, contents05

    pdf.commit_transaction()
  end

  test "Transaction mult_cell test with diskcache" do
    pdf = MYPDF.new('P', 'mm', 'A4', true, "UTF-8", true)
    pdf.add_page()
    page = pdf.get_page

    pdf.multi_cell(50, 5, 'mult_cell 0', 1)
    cache_file1 = pdf.cache_file_length.dup
    contents01 = pdf.getPageBuffer(page).dup

    pdf.start_transaction()

    pdf.multi_cell(50, 5, 'mult_cell 1', 1)
    pdf.multi_cell(50, 5, 'mult_cell 2', 1)
    cache_file2 = pdf.cache_file_length.dup
    contents02 = pdf.getPageBuffer(page).dup
    assert_not_equal cache_file1, cache_file2
    assert_not_equal contents01, contents02

    # rolls back to the last (re)start 1
    pdf = pdf.rollback_transaction()

    contents03 = pdf.getPageBuffer(page).dup
    cache_file3 = pdf.cache_file_length.dup
    assert_equal cache_file1, cache_file3
    assert_equal contents01, contents03

    pdf.start_transaction()

    pdf.multi_cell(50, 5, 'mult_cell 3', 1)
    pdf.multi_cell(50, 5, 'mult_cell 4', 1)
    contents04 = pdf.getPageBuffer(page).dup
    assert_not_equal contents03, contents04

    # rolls back to the last (re)start 2
    pdf = pdf.rollback_transaction()

    contents05 = pdf.getPageBuffer(page).dup
    assert_equal contents03, contents05
  end

  test "Transaction mult_cell self test with diskcache" do
    pdf = MYPDF.new('P', 'mm', 'A4', true, "UTF-8", true)
    pdf.add_page()
    page = pdf.get_page

    pdf.multi_cell(50, 5, 'mult_cell 0', 1)
    cache_file1 = pdf.cache_file_length.dup
    contents01 = pdf.getPageBuffer(page).dup

    pdf.start_transaction()

    pdf.multi_cell(50, 5, 'mult_cell 1', 1)
    pdf.multi_cell(50, 5, 'mult_cell 2', 1)
    cache_file2 = pdf.cache_file_length.dup
    contents02 = pdf.getPageBuffer(page).dup
    assert_not_equal cache_file1, cache_file2
    assert_not_equal contents01, contents02

    # rolls back to the last (re)start 1
    pdf.rollback_transaction(true)

    contents03 = pdf.getPageBuffer(page).dup
    cache_file3 = pdf.cache_file_length.dup
    assert_equal cache_file1, cache_file3
    assert_equal contents01, contents03

    pdf.start_transaction()

    pdf.multi_cell(50, 5, 'mult_cell 3', 1)
    pdf.multi_cell(50, 5, 'mult_cell 4', 1)
    contents04 = pdf.getPageBuffer(page).dup
    assert_not_equal contents03, contents04

    # rolls back to the last (re)start 2
    pdf.rollback_transaction(true)

    contents05 = pdf.getPageBuffer(page).dup
    assert_equal contents03, contents05
  end
end
