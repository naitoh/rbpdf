# Copyright (c) 2011-2017 NAITOH Jun
# Released under the MIT license
# http://www.opensource.org/licenses/MIT

require 'test_helper'

class RbpdfFontTest < Test::Unit::TestCase
  class MYPDF < RBPDF
    def putfonts()
      super
    end

    def getFontBuffer(font)
      super
    end

    def getFontsList()
      super
    end
    
    def fontlist()
      @fontlist
    end
  end

  test "Font subsetting enable/disable test" do
    pdf = MYPDF.new
    subsetting = pdf.get_font_subsetting
    assert_equal true, subsetting

    pdf.set_font_subsetting(false)
    subsetting = pdf.get_font_subsetting
    assert_equal false, subsetting

    pdf.set_font_subsetting(true)
    subsetting = pdf.get_font_subsetting
    assert_equal true, subsetting
  end
  
  test "Font getFontsList" do
    pdf = MYPDF.new
    pdf.getFontsList()
    fonts = pdf.fontlist()
    assert fonts.include?('kozminproregular') 
  end

  test "core Font test" do
    pdf = MYPDF.new

    pdf.set_font('helvetica', '', 18)
    pdf.set_font('helvetica', 'B', 18)
    pdf.set_font('helvetica', 'I', 18)
    pdf.set_font('helvetica', 'BI', 18)

    font = pdf.getFontBuffer('helvetica')
    assert_equal 'Helvetica',             font['name']
    assert_equal 556,                     font['dw']
    font = pdf.getFontBuffer('helveticaB')
    assert_equal 'Helvetica-Bold',        font['name']
    assert_equal 556,                     font['dw']
    font = pdf.getFontBuffer('helveticaI')
    assert_equal 'Helvetica-Oblique',     font['name']
    assert_equal 556,                     font['dw']
    font = pdf.getFontBuffer('helveticaBI')
    assert_equal 'Helvetica-BoldOblique', font['name']
    assert_equal 556,                     font['dw']

    pdf.set_font('times', '', 18)
    pdf.set_font('times', 'B', 18)
    pdf.set_font('times', 'I', 18)
    pdf.set_font('times', 'BI', 18)

    font = pdf.getFontBuffer('times')
    assert_equal 'Times-Roman',      font['name']
    font = pdf.getFontBuffer('timesB')
    assert_equal 'Times-Bold',       font['name']
    font = pdf.getFontBuffer('timesI')
    assert_equal 'Times-Italic',     font['name']
    font = pdf.getFontBuffer('timesBI')
    assert_equal 'Times-BoldItalic', font['name']

    pdf.set_font('courier', '', 18)
    pdf.set_font('courier', 'B', 18)
    pdf.set_font('courier', 'I', 18)
    pdf.set_font('courier', 'BI', 18)

    font = pdf.getFontBuffer('courier')
    assert_equal 'Courier',             font['name']
    font = pdf.getFontBuffer('courierB')
    assert_equal 'Courier-Bold',        font['name']
    font = pdf.getFontBuffer('courierI')
    assert_equal 'Courier-Oblique',     font['name']
    font = pdf.getFontBuffer('courierBI')
    assert_equal 'Courier-BoldOblique', font['name']

    pdf.set_font('symbol', '', 18)
    font = pdf.getFontBuffer('symbol')
    assert_equal 'Symbol',       font['name']

    pdf.set_font('zapfdingbats', '', 18)
    font = pdf.getFontBuffer('zapfdingbats')
    assert_equal 'ZapfDingbats', font['name']

    pdf.putfonts()
  end

  test "TrueTypeUnicode Subset Font test" do
    pdf = MYPDF.new
    pdf.set_font_subsetting(true)

    pdf.set_font('freesans', '', 18)
    pdf.set_font('freesans', 'B', 18)
    pdf.set_font('freesans', 'I', 18)
    pdf.set_font('freesans', 'BI', 18)

    pdf.set_font('freeserif', '', 18)
    pdf.set_font('freeserif', 'B', 18)
    pdf.set_font('freeserif', 'I', 18)
    pdf.set_font('freeserif', 'BI', 18)

    pdf.set_font('freemono', '', 18)
    pdf.set_font('freemono', 'B', 18)
    pdf.set_font('freemono', 'I', 18)
    pdf.set_font('freemono', 'BI', 18)

    pdf.set_font('dejavusans', '', 18)
    pdf.set_font('dejavusans', 'B', 18)
    pdf.set_font('dejavusans', 'I', 18)
    pdf.set_font('dejavusans', 'BI', 18)

    pdf.set_font('dejavusanscondensed', '', 18)
    pdf.set_font('dejavusanscondensed', 'B', 18)
    pdf.set_font('dejavusanscondensed', 'I', 18)
    pdf.set_font('dejavusanscondensed', 'BI', 18)

    pdf.set_font('dejavusansmono', '', 18)
    pdf.set_font('dejavusansmono', 'B', 18)
    pdf.set_font('dejavusansmono', 'I', 18)
    pdf.set_font('dejavusansmono', 'BI', 18)

    pdf.set_font('dejavuserif', '', 18)
    pdf.set_font('dejavuserif', 'B', 18)
    pdf.set_font('dejavuserif', 'I', 18)
    pdf.set_font('dejavuserif', 'BI', 18)

    pdf.set_font('dejavuserifcondensed', '', 18)
    pdf.set_font('dejavuserifcondensed', 'B', 18)
    pdf.set_font('dejavuserifcondensed', 'I', 18)
    pdf.set_font('dejavuserifcondensed', 'BI', 18)

    pdf.set_font('dejavusansextralight', '', 18)

    pdf.putfonts()
  end

  test "TrueTypeUnicode Font test" do
    pdf = MYPDF.new
    pdf.set_font_subsetting(false)

    pdf.set_font('freesans', '', 18)
    pdf.set_font('freesans', 'B', 18)
    pdf.set_font('freesans', 'I', 18)
    pdf.set_font('freesans', 'BI', 18)

    pdf.set_font('freeserif', '', 18)
    pdf.set_font('freeserif', 'B', 18)
    pdf.set_font('freeserif', 'I', 18)
    pdf.set_font('freeserif', 'BI', 18)

    pdf.set_font('freemono', '', 18)
    pdf.set_font('freemono', 'B', 18)
    pdf.set_font('freemono', 'I', 18)
    pdf.set_font('freemono', 'BI', 18)

    pdf.set_font('dejavusans', '', 18)
    pdf.set_font('dejavusans', 'B', 18)
    pdf.set_font('dejavusans', 'I', 18)
    pdf.set_font('dejavusans', 'BI', 18)

    pdf.set_font('dejavusanscondensed', '', 18)
    pdf.set_font('dejavusanscondensed', 'B', 18)
    pdf.set_font('dejavusanscondensed', 'I', 18)
    pdf.set_font('dejavusanscondensed', 'BI', 18)

    pdf.set_font('dejavusansmono', '', 18)
    pdf.set_font('dejavusansmono', 'B', 18)
    pdf.set_font('dejavusansmono', 'I', 18)
    pdf.set_font('dejavusansmono', 'BI', 18)

    pdf.set_font('dejavuserif', '', 18)
    pdf.set_font('dejavuserif', 'B', 18)
    pdf.set_font('dejavuserif', 'I', 18)
    pdf.set_font('dejavuserif', 'BI', 18)

    pdf.set_font('dejavuserifcondensed', '', 18)
    pdf.set_font('dejavuserifcondensed', 'B', 18)
    pdf.set_font('dejavuserifcondensed', 'I', 18)
    pdf.set_font('dejavuserifcondensed', 'BI', 18)

    pdf.set_font('dejavusansextralight', '', 18)

    pdf.putfonts()
  end

  test "cidfont0 Font test" do
    pdf = MYPDF.new

    pdf.set_font('cid0cs', '', 18)
    pdf.set_font('cid0cs', 'B', 18)
    pdf.set_font('cid0cs', 'I', 18)
    pdf.set_font('cid0cs', 'BI', 18)

    pdf.set_font('cid0ct', '', 18)
    pdf.set_font('cid0ct', 'B', 18)
    pdf.set_font('cid0ct', 'I', 18)
    pdf.set_font('cid0ct', 'BI', 18)

    pdf.set_font('cid0jp', '', 18)
    pdf.set_font('cid0jp', 'B', 18)
    pdf.set_font('cid0jp', 'I', 18)
    pdf.set_font('cid0jp', 'BI', 18)

    pdf.set_font('cid0kr', '', 18)
    pdf.set_font('cid0kr', 'B', 18)
    pdf.set_font('cid0kr', 'I', 18)
    pdf.set_font('cid0kr', 'BI', 18)

    pdf.set_font('kozgopromedium', '', 18)
    pdf.set_font('kozgopromedium', 'B', 18)
    pdf.set_font('kozgopromedium', 'I', 18)
    pdf.set_font('kozgopromedium', 'BI', 18)

    font = pdf.getFontBuffer('kozgopromedium')
    assert_equal 99,     font['desc']['StemV']
    assert_equal 0,      font['desc']['ItalicAngle']
    assert_equal 'KozGoPro-Medium-Acro', font['name']

    font = pdf.getFontBuffer('kozgopromediumB')
    assert_equal 99 * 2, font['desc']['StemV']
    assert_equal 0,      font['desc']['ItalicAngle']
    assert_equal 'KozGoPro-Medium-Acro,Bold', font['name']

    font = pdf.getFontBuffer('kozgopromediumI')
    assert_equal 99,     font['desc']['StemV']
    assert_equal(-11,    font['desc']['ItalicAngle'])
    assert_equal 'KozGoPro-Medium-Acro,Italic', font['name']

    font = pdf.getFontBuffer('kozgopromediumBI')
    assert_equal 99 * 2, font['desc']['StemV']
    assert_equal(-11,    font['desc']['ItalicAngle'])
    assert_equal 'KozGoPro-Medium-Acro,BoldItalic', font['name']

    pdf.set_font('kozminproregular', '', 18)
    pdf.set_font('kozminproregular', 'B', 18)
    pdf.set_font('kozminproregular', 'I', 18)
    pdf.set_font('kozminproregular', 'BI', 18)

    pdf.set_font('msungstdlight', '', 18)
    pdf.set_font('msungstdlight', 'B', 18)
    pdf.set_font('msungstdlight', 'I', 18)
    pdf.set_font('msungstdlight', 'BI', 18)

    pdf.set_font('stsongstdlight', '', 18)
    pdf.set_font('stsongstdlight', 'B', 18)
    pdf.set_font('stsongstdlight', 'I', 18)
    pdf.set_font('stsongstdlight', 'BI', 18)

    pdf.set_font('hysmyeongjostdmedium', '', 18)
    pdf.set_font('hysmyeongjostdmedium', 'B', 18)
    pdf.set_font('hysmyeongjostdmedium', 'I', 18)
    pdf.set_font('hysmyeongjostdmedium', 'BI', 18)

    pdf.putfonts()
  end

  test "Set Font fontname test" do
    pdf = MYPDF.new
    pdf.set_font('helvetica', '', 18, pdf.send(:getfontpath, 'helvetica.rb'))
    pdf.set_font('helvetica', 'B', 18, pdf.send(:getfontpath, 'helveticab.rb'))
    pdf.set_font('helvetica', 'I', 18, pdf.send(:getfontpath, 'helveticai.rb'))
    pdf.set_font('helvetica', 'BI', 18, pdf.send(:getfontpath, 'helveticabi.rb'))
    pdf.putfonts()
  end

  test "Font Error test" do
    pdf = RBPDF.new
    RBPDF.k_path_fonts = File.join File.dirname(__FILE__)

    err = assert_raises(RBPDFError) { 
      pdf.set_font('err_font', '', 18)
    }
    assert_equal 'RBPDF error: Could not include font definition file: err_font', err.message

    err = assert_raises(RBPDFError) { 
      pdf.set_font('err_font1', '', 18)
    }
    assert_match(/RBPDF error: The font definition file has a bad format: .*err_font1.rb/, err.message)

    err = assert_raises(RBPDFError) { 
      pdf.set_font('err_font2', '', 18)
    }
    assert_equal 'RBPDF error: Unknow font type: Type0', err.message

    # Font path reset test
    pdf = RBPDF.new
    pdf.set_font('helvetica', '', 18)
  end
end
