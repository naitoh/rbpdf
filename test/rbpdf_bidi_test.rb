# coding: ASCII-8BIT
#
# Copyright (c) 2011-2017 NAITOH Jun
# Released under the MIT license
# http://www.opensource.org/licenses/MIT

require 'test_helper'

class RbpdfTest < Test::Unit::TestCase
  class MYPDF < RBPDF
    def UTF8StringToArray(str)
      super
    end
    def utf8Bidi(ta, str='', forcertl=false)
      super
    end
    def cache_utf8_string_to_array(str)
      @cache_utf8_string_to_array[str]
    end
    def rtl_text_dir
      super
    end
    def get_current_font
      return @current_font
    end
  end

  test "RTL test" do
    pdf = MYPDF.new

    # LTR
    rtl = pdf.get_rtl
    assert_equal false, rtl
    rtl = pdf.is_rtl_text_dir
    assert_equal false, rtl
    rtl = pdf.rtl_text_dir
    assert_equal 'L', rtl

    pdf.set_temp_rtl('rtl')
    rtl = pdf.is_rtl_text_dir
    assert_equal true, rtl
    rtl = pdf.rtl_text_dir
    assert_equal 'R', rtl

    # RTL
    pdf.set_rtl(true)
    rtl = pdf.get_rtl
    assert_equal true, rtl
    rtl = pdf.is_rtl_text_dir
    assert_equal true, rtl
    rtl = pdf.rtl_text_dir
    assert_equal 'R', rtl

    pdf.set_temp_rtl('ltr')
    rtl = pdf.is_rtl_text_dir
    assert_equal false, rtl
    rtl = pdf.rtl_text_dir
    assert_equal 'L', rtl
  end

  test "Bidi subset font test" do
    pdf = MYPDF.new
    ary_ucs4 = pdf.UTF8StringToArray("abc")
    assert_equal [0x61, 0x62, 0x63], ary_ucs4
    current_font = pdf.get_current_font
    assert_equal 256, current_font['subsetchars'].length

    ary_ucs4 = pdf.UTF8StringToArray("\xd7\xa2\xd7\x91\xd7\xa8\xd7\x99\xd7\xaa")
    assert_equal [0x5e2, 0x5d1, 0x5e8, 0x5d9, 0x5ea], ary_ucs4
    current_font = pdf.get_current_font
    assert_equal 261, current_font['subsetchars'].compact.length
  end

  test "Bidi" do
    pdf = MYPDF.new

    # UCS4 charactor -> UTF-8 charactor
    utf8_chr = pdf.unichr(0x61)
    assert_equal "a", utf8_chr
    utf8_chr = pdf.unichr(0x5e2)
    assert_equal "\xd7\xa2", utf8_chr

    # UTF-8 string -> array of UCS4 charactor
    ary_ucs4 = pdf.UTF8StringToArray("abc")
    assert_equal [0x61, 0x62, 0x63], ary_ucs4
    current_font = pdf.get_current_font
    assert_equal 256, current_font['subsetchars'].compact.length

    ary_ucs4 = pdf.UTF8StringToArray("\xd7\xa2\xd7\x91\xd7\xa8\xd7\x99\xd7\xaa")
    assert_equal [0x5e2, 0x5d1, 0x5e8, 0x5d9, 0x5ea], ary_ucs4
    current_font = pdf.get_current_font
    assert_equal 256 + 5, current_font['subsetchars'].compact.length

    # Bidirectional Algorithm
    ascii_str   = "abc"
    utf8_str_1  = "\xd7\xa2"
    utf8_str_2  = "\xd7\xa2\xd7\x91\xd7\xa8\xd7\x99\xd7\xaa"

    ary_ucs4 = pdf.utf8Bidi(pdf.UTF8StringToArray(ascii_str))
    assert_equal [0x61, 0x62, 0x63], ary_ucs4
    ary_ucs4 = pdf.utf8Bidi(pdf.UTF8StringToArray(ascii_str), ascii_str, 'R')
    assert_equal [0x61, 0x62, 0x63], ary_ucs4

    ary_ucs4 = pdf.utf8Bidi(pdf.UTF8StringToArray(utf8_str_1))
    assert_equal [0x5e2], ary_ucs4
    current_font = pdf.get_current_font
    assert_equal 256 + 5, current_font['subsetchars'].compact.length

    ary_ucs4 = pdf.utf8Bidi(pdf.UTF8StringToArray(utf8_str_1), utf8_str_1, 'R')
    assert_equal [0x5e2], ary_ucs4
    current_font = pdf.get_current_font
    assert_equal 256 + 5, current_font['subsetchars'].compact.length

    ary_ucs4 = pdf.utf8Bidi(pdf.UTF8StringToArray(utf8_str_2))
    assert_equal [0x5ea, 0x5d9, 0x5e8, 0x5d1, 0x5e2], ary_ucs4
    current_font = pdf.get_current_font
    assert_equal 256 + 5, current_font['subsetchars'].compact.length

    ary_ucs4 = pdf.utf8Bidi(pdf.UTF8StringToArray(utf8_str_2), utf8_str_2, 'R')
    assert_equal [0x5ea, 0x5d9, 0x5e8, 0x5d1, 0x5e2], ary_ucs4 ##
    current_font = pdf.get_current_font
    assert_equal 256 + 5, current_font['subsetchars'].compact.length

    ary_str = pdf.utf8Bidi(pdf.UTF8StringToArray(ascii_str + utf8_str_2), ascii_str + utf8_str_2, 'L')
    assert_equal [0x61, 0x62, 0x63, 0x5ea, 0x5d9, 0x5e8, 0x5d1, 0x5e2], ary_str
    current_font = pdf.get_current_font
    assert_equal 256 + 5, current_font['subsetchars'].compact.length

    ary_str = pdf.utf8Bidi(pdf.UTF8StringToArray(ascii_str + utf8_str_2))        # LTR
    assert_equal [0x61, 0x62, 0x63, 0x5ea, 0x5d9, 0x5e8, 0x5d1, 0x5e2], ary_str
    current_font = pdf.get_current_font
    assert_equal 256 + 5, current_font['subsetchars'].compact.length

    ary_str = pdf.utf8Bidi(pdf.UTF8StringToArray(ascii_str + utf8_str_2), ascii_str + utf8_str_2, 'R')
    assert_equal [0x5ea, 0x5d9, 0x5e8, 0x5d1, 0x5e2, 0x61, 0x62, 0x63], ary_str
    current_font = pdf.get_current_font
    assert_equal 256 + 5, current_font['subsetchars'].compact.length

    ary_str = pdf.utf8Bidi(pdf.UTF8StringToArray(utf8_str_2 + ascii_str), utf8_str_2 + ascii_str, 'L')
    assert_equal [0x5ea, 0x5d9, 0x5e8, 0x5d1, 0x5e2, 0x61, 0x62, 0x63], ary_str
    ary_str = pdf.utf8Bidi(pdf.UTF8StringToArray(utf8_str_2 + ascii_str))        # RTL
    assert_equal [0x61, 0x62, 0x63, 0x5ea, 0x5d9, 0x5e8, 0x5d1, 0x5e2], ary_str
    ary_str = pdf.utf8Bidi(pdf.UTF8StringToArray(utf8_str_2 + ascii_str), utf8_str_2 + ascii_str, 'R')
    assert_equal [0x61, 0x62, 0x63, 0x5ea, 0x5d9, 0x5e8, 0x5d1, 0x5e2], ary_str
  end

  test "Bidi ascii space test" do
    pdf = MYPDF.new

    ascii_str   = "abc def"
    ary_ucs4_1 = pdf.utf8Bidi(pdf.UTF8StringToArray(ascii_str))
    assert_equal [0x61, 0x62, 0x63, 0x20, 0x64, 0x65, 0x66], ary_ucs4_1
    ary_ucs4_2 = pdf.utf8Bidi(pdf.UTF8StringToArray(ascii_str), '', 'R')
    assert_equal ary_ucs4_1, ary_ucs4_2
    ary_ucs4_2 = pdf.utf8Bidi(pdf.UTF8StringToArray(ascii_str), '', 'L')
    assert_equal ary_ucs4_1, ary_ucs4_2

    ascii_str   = "abc  def"
    ary_ucs4_1 = pdf.utf8Bidi(pdf.UTF8StringToArray(ascii_str))
    assert_equal [0x61, 0x62, 0x63, 0x20, 0x20, 0x64, 0x65, 0x66], ary_ucs4_1
    ary_ucs4_2 = pdf.utf8Bidi(pdf.UTF8StringToArray(ascii_str), '', 'R')
    assert_equal ary_ucs4_1, ary_ucs4_2
    ary_ucs4_2 = pdf.utf8Bidi(pdf.UTF8StringToArray(ascii_str), '', 'L')
    assert_equal ary_ucs4_1, ary_ucs4_2

    ascii_str   = "abc  "
    ary_ucs4_1 = pdf.utf8Bidi(pdf.UTF8StringToArray(ascii_str))
    assert_equal [0x61, 0x62, 0x63, 0x20, 0x20], ary_ucs4_1
    ary_ucs4_2 = pdf.utf8Bidi(pdf.UTF8StringToArray(ascii_str), '', 'L')
    assert_equal ary_ucs4_1, ary_ucs4_2
    ary_ucs4_2 = pdf.utf8Bidi(pdf.UTF8StringToArray(ascii_str), '', 'R')
    assert_equal [0x20, 0x20, 0x61, 0x62, 0x63], ary_ucs4_2

    ascii_str   = "abc_def"
    ary_ucs4_1 = pdf.utf8Bidi(pdf.UTF8StringToArray(ascii_str))
    assert_equal [0x61, 0x62, 0x63, 0x5f, 0x64, 0x65, 0x66], ary_ucs4_1
    ary_ucs4_2 = pdf.utf8Bidi(pdf.UTF8StringToArray(ascii_str), '', 'R')
    assert_equal ary_ucs4_1, ary_ucs4_2
    ary_ucs4_2 = pdf.utf8Bidi(pdf.UTF8StringToArray(ascii_str), '', 'L')
    assert_equal ary_ucs4_1, ary_ucs4_2
  end

  test "Bidi ascii numeric space test" do
    pdf = MYPDF.new

    ascii_str   = "abc 123 def"
    ary_ucs4_1 = pdf.utf8Bidi(pdf.UTF8StringToArray(ascii_str))
    assert_equal [0x61, 0x62, 0x63, 0x20, 0x31, 0x32, 0x33, 0x20, 0x64, 0x65, 0x66], ary_ucs4_1
    ary_ucs4_2 = pdf.utf8Bidi(pdf.UTF8StringToArray(ascii_str), '', 'R')
    assert_equal ary_ucs4_1, ary_ucs4_2
    ary_ucs4_2 = pdf.utf8Bidi(pdf.UTF8StringToArray(ascii_str), '', 'L')
    assert_equal ary_ucs4_1, ary_ucs4_2

    ascii_str   = "abc_123_def"
    ary_ucs4_1 = pdf.utf8Bidi(pdf.UTF8StringToArray(ascii_str))
    assert_equal [0x61, 0x62, 0x63, 0x5f, 0x31, 0x32, 0x33, 0x5f, 0x64, 0x65, 0x66], ary_ucs4_1
    ary_ucs4_2 = pdf.utf8Bidi(pdf.UTF8StringToArray(ascii_str), '', 'R')
    assert_equal ary_ucs4_1, ary_ucs4_2
    ary_ucs4_2 = pdf.utf8Bidi(pdf.UTF8StringToArray(ascii_str), '', 'L')
    assert_equal ary_ucs4_1, ary_ucs4_2
  end

  test "Bidi ascii colon test" do
    pdf = MYPDF.new

    ascii_str   = "abc:def"
    ary_ucs4_1 = pdf.utf8Bidi(pdf.UTF8StringToArray(ascii_str))
    assert_equal [0x61, 0x62, 0x63, 0x3a, 0x64, 0x65, 0x66], ary_ucs4_1
    ary_ucs4_2 = pdf.utf8Bidi(pdf.UTF8StringToArray(ascii_str), '', 'R')
    assert_equal ary_ucs4_1, ary_ucs4_2
    ary_ucs4_2 = pdf.utf8Bidi(pdf.UTF8StringToArray(ascii_str), '', 'L')
    assert_equal ary_ucs4_1, ary_ucs4_2

    ascii_str   = "abc: def"
    ary_ucs4_1 = pdf.utf8Bidi(pdf.UTF8StringToArray(ascii_str))
    assert_equal [0x61, 0x62, 0x63, 0x3a, 0x20, 0x64, 0x65, 0x66], ary_ucs4_1
    ary_ucs4_2 = pdf.utf8Bidi(pdf.UTF8StringToArray(ascii_str), '', 'R')
    assert_equal ary_ucs4_1, ary_ucs4_2
    ary_ucs4_2 = pdf.utf8Bidi(pdf.UTF8StringToArray(ascii_str), '', 'L')
    assert_equal ary_ucs4_1, ary_ucs4_2

    ascii_str   = "abc : def"
    ary_ucs4_1 = pdf.utf8Bidi(pdf.UTF8StringToArray(ascii_str))
    assert_equal [0x61, 0x62, 0x63, 0x20, 0x3a, 0x20, 0x64, 0x65, 0x66], ary_ucs4_1
    ary_ucs4_2 = pdf.utf8Bidi(pdf.UTF8StringToArray(ascii_str), '', 'R')
    assert_equal ary_ucs4_1, ary_ucs4_2
    ary_ucs4_2 = pdf.utf8Bidi(pdf.UTF8StringToArray(ascii_str), '', 'L')
    assert_equal ary_ucs4_1, ary_ucs4_2

    ascii_str   = "abc  ::  def"
    ary_ucs4_1 = pdf.utf8Bidi(pdf.UTF8StringToArray(ascii_str))
    assert_equal [0x61, 0x62, 0x63, 0x20, 0x20, 0x3a, 0x3a, 0x20, 0x20, 0x64, 0x65, 0x66], ary_ucs4_1
    ary_ucs4_2 = pdf.utf8Bidi(pdf.UTF8StringToArray(ascii_str), '', 'R')
    assert_equal ary_ucs4_1, ary_ucs4_2
    ary_ucs4_2 = pdf.utf8Bidi(pdf.UTF8StringToArray(ascii_str), '', 'L')
    assert_equal ary_ucs4_1, ary_ucs4_2
  end


  test "Bidi arabic test" do
    pdf = MYPDF.new

    # Bidirectional Algorithm
    ascii_str   = "role"
    utf8_arabic_str_1  = "\xd8\xaf\xd9\x88\xd8\xb1"
    utf8_arabic_char_1  = "\xd8\xaf"

    # UCS4 charactor -> UTF-8 charactor
    utf8_chr = pdf.unichr(0x62f)
    assert_equal "\xd8\xaf", utf8_chr

    # UTF-8 string -> array of UCS4 charactor
    ary_ucs4 = pdf.UTF8StringToArray(ascii_str)
    assert_equal [0x72, 0x6f, 0x6c, 0x65], ary_ucs4
    ary_ucs4 = pdf.UTF8StringToArray(utf8_arabic_str_1)
    assert_equal [0x62f, 0x648, 0x631], ary_ucs4
    ary_ucs4 = pdf.UTF8StringToArray(utf8_arabic_char_1)
    assert_equal [0x62f], ary_ucs4


    ary_ucs4 = pdf.utf8Bidi(pdf.UTF8StringToArray(ascii_str))
    assert_equal [0x72, 0x6f, 0x6c, 0x65], ary_ucs4

    ary_ucs4 = pdf.utf8Bidi(pdf.UTF8StringToArray(ascii_str), ascii_str, 'R')
    assert_equal [0x72, 0x6f, 0x6c, 0x65], ary_ucs4

    ary_ucs4 = pdf.utf8Bidi(pdf.UTF8StringToArray(utf8_arabic_char_1))
    assert_equal [0xfea9], ary_ucs4
    ary_ucs4 = pdf.utf8Bidi(pdf.UTF8StringToArray(utf8_arabic_char_1), utf8_arabic_char_1, 'R')
    assert_equal [0xfea9], ary_ucs4

    ary_ucs4 = pdf.utf8Bidi(pdf.UTF8StringToArray(utf8_arabic_str_1))
    assert_equal [0xfead, 0xfeed, 0xfea9], ary_ucs4
  end

  test "Bidi Persian Sunday test" do
    pdf = MYPDF.new

    utf8_persian_str_1  = "\xdb\x8c" # 0x06cc
    utf8_persian_str_2  = "\xdb\x8c\xda\xa9" # 0x06cc, 0x06a9
    utf8_persian_str_3  = "\xdb\x8c\xda\xa9\xe2\x80\x8c"  # 0x06cc, 0x06a9, 0x200c
    utf8_persian_str_4  = "\xdb\x8c\xda\xa9\xe2\x80\x8c\xd8\xb4"  # 0x06cc, 0x06a9, 0x200c, 0x0634
    utf8_persian_str_5  = "\xdb\x8c\xda\xa9\xe2\x80\x8c\xd8\xb4\xd9\x86" # 0x06cc, 0x06a9, 0x200c, 0x0634, 0x0646
    utf8_persian_str_6  = "\xdb\x8c\xda\xa9\xe2\x80\x8c\xd8\xb4\xd9\x86\xd8\xa8" # 0x06cc, 0x06a9, 0x200c, 0x0634, 0x0646, 0x0628
    utf8_persian_str_7  = "\xdb\x8c\xda\xa9\xe2\x80\x8c\xd8\xb4\xd9\x86\xd8\xa8\xd9\x87" # Sunday # 0x06cc, 0x06a9, 0x200c, 0x0634, 0x0646, 0x0628, 0x0647

    ary_ucs4 = pdf.utf8Bidi(pdf.UTF8StringToArray(utf8_persian_str_1))
    assert_equal [0xfbfc], ary_ucs4
    current_font = pdf.get_current_font
    assert_equal 256 + 2, current_font['subsetchars'].compact.length  # 0x06cc, 0xfbfc

    ary_ucs4 = pdf.utf8Bidi(pdf.UTF8StringToArray(utf8_persian_str_2))
    assert_equal [0xfb8f, 0xfbfe], ary_ucs4
    current_font = pdf.get_current_font
    assert_equal 256 + 5, current_font['subsetchars'].compact.length # 0xfbfc + 0x06cc, 0x06a9, 0xfb8f, 0xfbfe

    ary_ucs4 = pdf.utf8Bidi(pdf.UTF8StringToArray(utf8_persian_str_3))
    assert_equal [0x200c, 0xfb8f, 0xfbfe], ary_ucs4
    current_font = pdf.get_current_font
    assert_equal 256 + 6, current_font['subsetchars'].compact.length # 0xfbfc + 0x06cc, 0x06a9, 0x200c, 0xfb8f, 0xfbfe

    ary_ucs4 = pdf.utf8Bidi(pdf.UTF8StringToArray(utf8_persian_str_4))
    assert_equal [0xfeb5, 0x200c, 0xfb8f, 0xfbfe], ary_ucs4
    current_font = pdf.get_current_font
    assert_equal 256 + 8, current_font['subsetchars'].compact.length # 0xfbfc + 0x06cc, 0x06a9, 0x200c, 0x0634, 0xfeb5, 0xfb8f, 0xfbfe

    ary_ucs4 = pdf.utf8Bidi(pdf.UTF8StringToArray(utf8_persian_str_5))
    assert_equal [0xfee6, 0xfeb7, 0x200c, 0xfb8f, 0xfbfe], ary_ucs4
    current_font = pdf.get_current_font
    assert_equal 256 + 11, current_font['subsetchars'].compact.length # 0xfbfc, 0xfeb5 + 0x06cc, 0x06a9, 0x200c, 0x0634, 0x0646, 0xfee6, 0xfeb7, 0xfb8f, 0xfbfe

    ary_ucs4 = pdf.utf8Bidi(pdf.UTF8StringToArray(utf8_persian_str_6))
    assert_equal [0xfe90, 0xfee8, 0xfeb7, 0x200c, 0xfb8f, 0xfbfe], ary_ucs4
    current_font = pdf.get_current_font
    assert_equal 256 + 14, current_font['subsetchars'].compact.length # 0xfbfc, 0xfeb5, 0xfee6 + 0x06cc, 0x06a9, 0x200c, 0x0634, 0x0646, 0x0628, 0xfe90, 0xfee8, 0xfeb7, 0xfb8f, 0xfbfe

    ary_ucs4 = pdf.utf8Bidi(pdf.UTF8StringToArray(utf8_persian_str_7))
    assert_equal [0xfeea, 0xfe92, 0xfee8, 0xfeb7, 0x200c, 0xfb8f, 0xfbfe], ary_ucs4
    current_font = pdf.get_current_font
    assert_equal 256 + 17, current_font['subsetchars'].compact.length # 0xfbfc, 0xfeb5, 0xfee6, 0xfe90 + 0x06cc, 0x06a9, 0x200c, 0x0634, 0x0646, 0x0628, 0x0647, 0xfeea, 0xfe92, 0xfee8, 0xfeb7, 0xfb8f, 0xfbfe
  end

  test "Bidi Persian Sunday forcertl test" do
    pdf = MYPDF.new
    utf8_persian_str_sunday = "\xdb\x8c\xda\xa9\xe2\x80\x8c\xd8\xb4\xd9\x86\xd8\xa8\xd9\x87"

    ary_ucs4_1 = pdf.utf8Bidi(pdf.UTF8StringToArray(utf8_persian_str_sunday), '', 'R')
    assert_equal [0xfeea, 0xfe92, 0xfee8, 0xfeb7, 0x200C, 0xfb8f, 0xfbfe], ary_ucs4_1
    ary_ucs4_2 = pdf.utf8Bidi(pdf.UTF8StringToArray(utf8_persian_str_sunday), '', 'L')
    assert_equal ary_ucs4_1, ary_ucs4_2
  end

  test "Bidi Persian Monday test" do
    pdf = MYPDF.new

    utf8_persian_str_1  = "\xd8\xaf"
    utf8_persian_str_2  = "\xd8\xaf\xd9\x88"
    utf8_persian_str_3  = "\xd8\xaf\xd9\x88\xd8\xb4"
    utf8_persian_str_4  = "\xd8\xaf\xd9\x88\xd8\xb4\xd9\x86"
    utf8_persian_str_5  = "\xd8\xaf\xd9\x88\xd8\xb4\xd9\x86\xd8\xa8"
    utf8_persian_str_6  = "\xd8\xaf\xd9\x88\xd8\xb4\xd9\x86\xd8\xa8\xd9\x87" # Monday

    ary_ucs4 = pdf.utf8Bidi(pdf.UTF8StringToArray(utf8_persian_str_1))
    assert_equal [0xfea9], ary_ucs4
    ary_ucs4 = pdf.utf8Bidi(pdf.UTF8StringToArray(utf8_persian_str_2))
    assert_equal [0xfeed, 0xfea9], ary_ucs4
    ary_ucs4 = pdf.utf8Bidi(pdf.UTF8StringToArray(utf8_persian_str_3))
    assert_equal [0xfeb5, 0xfeed, 0xfea9], ary_ucs4
    ary_ucs4 = pdf.utf8Bidi(pdf.UTF8StringToArray(utf8_persian_str_4))
    assert_equal [0xfee6, 0xfeb7, 0xfeed, 0xfea9], ary_ucs4
    ary_ucs4 = pdf.utf8Bidi(pdf.UTF8StringToArray(utf8_persian_str_5))
    assert_equal [0xfe90, 0xfee8, 0xfeb7, 0xfeed, 0xfea9], ary_ucs4
    ary_ucs4 = pdf.utf8Bidi(pdf.UTF8StringToArray(utf8_persian_str_6))
    assert_equal [0xfeea, 0xfe92, 0xfee8, 0xfeb7, 0xfeed, 0xfea9], ary_ucs4
  end

  test "Bidi Persian Monday forcertl test" do
    pdf = MYPDF.new
    utf8_persian_str_monday = "\xd8\xaf\xd9\x88\xd8\xb4\xd9\x86\xd8\xa8\xd9\x87"

    ary_ucs4_1 = pdf.utf8Bidi(pdf.UTF8StringToArray(utf8_persian_str_monday), '', 'R')
    assert_equal [0xfeea, 0xfe92, 0xfee8, 0xfeb7, 0xfeed, 0xfea9], ary_ucs4_1
    ary_ucs4_2 = pdf.utf8Bidi(pdf.UTF8StringToArray(utf8_persian_str_monday), '', 'L')
    assert_equal ary_ucs4_1, ary_ucs4_2
  end

  test "Bidi Persian and English test" do
    pdf = MYPDF.new

    utf8_persian_str_sunday = "\xdb\x8c\xda\xa9\xe2\x80\x8c\xd8\xb4\xd9\x86\xd8\xa8\xd9\x87"
    ary_ucs4 = pdf.utf8Bidi(pdf.UTF8StringToArray(utf8_persian_str_sunday + ' abc'))
    assert_equal [0x61, 0x62, 0x63, 0x20, # 'abc '
                  0xfeea, 0xfe92, 0xfee8, 0xfeb7, 0x200C, 0xfb8f, 0xfbfe], ary_ucs4 # Sunday
    ary_ucs4 = pdf.utf8Bidi(pdf.UTF8StringToArray(utf8_persian_str_sunday + ' abc'), '', 'R')
    assert_equal [0x61, 0x62, 0x63, 0x20, # 'abc '
                  0xfeea, 0xfe92, 0xfee8, 0xfeb7, 0x200C, 0xfb8f, 0xfbfe], ary_ucs4 # Sunday
    ary_ucs4 = pdf.utf8Bidi(pdf.UTF8StringToArray(utf8_persian_str_sunday + ' abc'), '', 'L')
    assert_equal [0xfeea, 0xfe92, 0xfee8, 0xfeb7, 0x200C, 0xfb8f, 0xfbfe, # Sunday
                  0x20, 0x61, 0x62, 0x63], ary_ucs4 # 'abc '
  end

  test "Bidi English and Persian test" do
    pdf = MYPDF.new

    utf8_persian_str_sunday = "\xdb\x8c\xda\xa9\xe2\x80\x8c\xd8\xb4\xd9\x86\xd8\xa8\xd9\x87"
    ary_ucs4 = pdf.utf8Bidi(pdf.UTF8StringToArray('abc ' + utf8_persian_str_sunday))
    assert_equal [0x61, 0x62, 0x63, 0x20, # 'abc '
                  0xfeea, 0xfe92, 0xfee8, 0xfeb7, 0x200C, 0xfb8f, 0xfbfe], ary_ucs4 # Sunday
    ary_ucs4 = pdf.utf8Bidi(pdf.UTF8StringToArray('abc ' + utf8_persian_str_sunday), '', 'L')
    assert_equal [0x61, 0x62, 0x63, 0x20, # 'abc '
                  0xfeea, 0xfe92, 0xfee8, 0xfeb7, 0x200C, 0xfb8f, 0xfbfe], ary_ucs4 # Sunday
    ary_ucs4 = pdf.utf8Bidi(pdf.UTF8StringToArray('abc ' + utf8_persian_str_sunday), '', 'R')
    assert_equal [0xfeea, 0xfe92, 0xfee8, 0xfeb7, 0x200C, 0xfb8f, 0xfbfe, # Sunday
                  0x20, 0x61, 0x62, 0x63], ary_ucs4 # 'abc '
  end

  test "Bidi date test" do
    pdf = MYPDF.new

    utf8_date_str_1  = '12/01/2014'

    pdf.set_rtl(true)
    pdf.set_temp_rtl('rtl')
    # UTF-8 string -> array of UCS4 charactor
    ary_ucs4 = pdf.UTF8StringToArray(utf8_date_str_1)
    assert_equal [0x31, 0x32, 0x2f, 0x30, 0x31, 0x2f, 0x32, 0x30, 0x31, 0x34], ary_ucs4  # 12/01/2014

    ary_ucs4 = pdf.utf8Bidi(pdf.UTF8StringToArray(utf8_date_str_1))
    assert_equal [0x31, 0x32, 0x2f, 0x30, 0x31, 0x2f, 0x32, 0x30, 0x31, 0x34], ary_ucs4  # 12/01/2014

    ary_ucs4 = pdf.utf8Bidi(pdf.UTF8StringToArray(utf8_date_str_1), utf8_date_str_1, 'R')
    assert_equal [0x31, 0x32, 0x2f, 0x30, 0x31, 0x2f, 0x32, 0x30, 0x31, 0x34], ary_ucs4  # 12/01/2014
  end

  test "Bidi Japanese test" do
    pdf = MYPDF.new

    utf8_japanese_aiueo_str_1  = "\xe3\x81\x82\xe3\x81\x84\xe3\x81\x86\xe3\x81\x88\xe3\x81\x8a"

    # UTF-8 string -> array of UCS4 charactor
    ary_ucs4 = pdf.UTF8StringToArray(utf8_japanese_aiueo_str_1)
    assert_equal [0x3042, 0x3044, 0x3046, 0x3048, 0x304a], ary_ucs4  # Japanese aiueo

    current_font = pdf.get_current_font
    assert_equal 256 + 5, current_font['subsetchars'].compact.length
  end

  test "UTF8StringToArray cache_utf8_string_to_array test" do
    pdf = MYPDF.new

    chars = pdf.UTF8StringToArray('1234')
    chars.reverse!

    rtn = pdf.cache_utf8_string_to_array('1234')
    assert_equal [0x31, 0x32, 0x33, 0x34], rtn
  end

  test "UniArrSubString test" do
    pdf = RBPDF.new
    str = pdf.uni_arr_sub_string(['a', 'b', 'c', ' ', 'd', 'e', 'f'])
    assert_equal 'abc def', str
  end
end
