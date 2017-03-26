# Copyright (c) 2011-2017 NAITOH Jun
# Released under the MIT license
# http://www.opensource.org/licenses/MIT

require 'test_helper'

class RbpdfFormatTest < Test::Unit::TestCase
  test "set_page_orientation" do
    pdf = RBPDF.new

    pagedim = pdf.set_page_orientation('')
    assert_equal 'P',   pagedim['or']
    assert_equal true,  pagedim['pb']
    assert_equal nil,   pagedim['olm']
    assert_equal nil,   pagedim['orm']
    assert_in_delta 20, pagedim['bm'], 0.1

    pagedim = pdf.set_page_orientation('P')
    assert_equal 'P',   pagedim['or']

    pagedim = pdf.set_page_orientation('L', false)
    assert_equal 'L',   pagedim['or']
    assert_equal false, pagedim['pb']

    pagedim = pdf.set_page_orientation('P', true, 5)
    assert_equal 'P',   pagedim['or']
    assert_equal true,  pagedim['pb']
    assert_equal 5,     pagedim['bm']
  end
end
