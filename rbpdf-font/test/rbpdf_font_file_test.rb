# Copyright (c) 2011-2017 NAITOH Jun
# Released under the MIT license
# http://www.opensource.org/licenses/MIT

require 'test_helper'

class RbpdfFontFileTest < Test::Unit::TestCase
  test "Font path test" do
    font_path = RBPDFFontDescriptor.getfontpath
    exp_path = File.join File.dirname(__FILE__).gsub(/test$/, '') , 'lib', 'fonts'

    assert_equal exp_path, font_path
  end

  test "Core Font File test" do
    fontlist = ['helvetica', 'helveticab', 'helveticai', 'helveticabi',
                'courier', 'courierb', 'courieri', 'courierbi',
                'times', 'timesb', 'timesi', 'timesbi',
                'zapfdingbats', 'symbol']
    fontlist.each {|fontname|
      fontfile = File.join RBPDFFontDescriptor.getfontpath, fontname + '.rb'
      require(fontfile) if File.exist?(fontfile)
      font_desc = RBPDFFontDescriptor.font(fontname)

      assert_equal fontname + 'core', fontname + font_desc[:type].to_s
      assert_not_equal '[' + fontname + ']:', '[' + fontname + ']:' + font_desc[:dw].to_s
      assert_not_equal '[' + fontname + ']:', '[' + fontname + ']:' + font_desc[:cw].to_s
      assert_equal 256, font_desc[:cw].length
    }
  end

  test "cidfont0 Font File test" do
    fontlist = ['cid0cs', 'cid0ct', 'cid0jp', 'cid0kr',
                'hysmyeongjostdmedium', 'kozgopromedium', 'kozminproregular', 'msungstdlight',
                'stsongstdlight']

    font_path = RBPDFFontDescriptor.getfontpath
    fontlist.each {|fontname|
      fontfile = File.join font_path, fontname + '.rb'
      require(fontfile)
      font_desc = RBPDFFontDescriptor.font(fontname)

      assert_equal fontname + 'cidfont0', fontname + font_desc[:type].to_s
      assert_not_equal '[' + fontname + ']:', '[' + fontname + ']:' + font_desc[:name].to_s
      assert_not_equal '[' + fontname + ']:', '[' + fontname + ']:' + font_desc[:displayname].to_s unless fontname =~ /cid0(cs|ct|jp|kr)/
      assert_not_equal '[' + fontname + ']:', '[' + fontname + ']:' + font_desc[:desc].to_s
      assert_not_equal '[' + fontname + ']:', '[' + fontname + ']:' + font_desc[:desc]['Ascent'].to_s
      assert_not_equal '[' + fontname + ']:', '[' + fontname + ']:' + font_desc[:desc]['Descent'].to_s
      assert_not_equal '[' + fontname + ']:', '[' + fontname + ']:' + font_desc[:desc]['CapHeight'].to_s
      assert_not_equal '[' + fontname + ']:', '[' + fontname + ']:' + font_desc[:desc]['Flags'].to_s
      assert_not_equal '[' + fontname + ']:', '[' + fontname + ']:' + font_desc[:desc]['FontBBox'].to_s
      assert_not_equal '[' + fontname + ']:', '[' + fontname + ']:' + font_desc[:desc]['ItalicAngle'].to_s
      assert_not_equal '[' + fontname + ']:', '[' + fontname + ']:' + font_desc[:desc]['StemV'].to_s
      assert_not_equal '[' + fontname + ']:', '[' + fontname + ']:' + font_desc[:desc]['MissingWidth'].to_s if fontname =~ /cid0(cs|ct|jp|kr)/
      assert_not_equal '[' + fontname + ']:', '[' + fontname + ']:' + font_desc[:desc]['XHeight'].to_s if fontname =~ /kozgopromedium|kozminproregular/

      assert_not_equal '[' + fontname + ']:', '[' + fontname + ']:' + font_desc[:cidinfo].to_s
      assert_not_equal '[' + fontname + ']:', '[' + fontname + ']:' + font_desc[:cidinfo]['Registry'].to_s
      assert_not_equal '[' + fontname + ']:', '[' + fontname + ']:' + font_desc[:cidinfo]['Ordering'].to_s
      assert_not_equal '[' + fontname + ']:', '[' + fontname + ']:' + font_desc[:cidinfo]['Supplement'].to_s
      assert_not_equal '[' + fontname + ']:', '[' + fontname + ']:' + font_desc[:cidinfo]['uni2cid'].to_s if fontname =~ /cid0(cs|ct|jp|kr)/
      assert_not_equal '[' + fontname + ']:0', '[' + fontname + ']:' + font_desc[:cidinfo]['uni2cid'].length.to_s if fontname =~ /cid0(cs|ct|jp|kr)/

      assert_not_equal '[' + fontname + ']:', '[' + fontname + ']:' + font_desc[:up].to_s
      assert_not_equal '[' + fontname + ']:', '[' + fontname + ']:' + font_desc[:ut].to_s
      assert_not_equal '[' + fontname + ']:', '[' + fontname + ']:' + font_desc[:dw].to_s
      assert_not_equal '[' + fontname + ']:', '[' + fontname + ']:' + font_desc[:cw].to_s
      assert_not_equal 0, font_desc[:cw].length
      assert_not_equal '[' + fontname + ']:', '[' + fontname + ']:' + font_desc[:enc].to_s
      if font_desc[:diff].nil? and fontname =~ /cid0(cs|ct|jp|kr)/
        assert_not_equal '[' + fontname + ']:', '[' + fontname + ']:' + font_desc[:diff].to_s # font_desc[:diff] => nil
      end
      assert_not_equal '[' + fontname + ']:', '[' + fontname + ']:' + font_desc[:originalsize].to_s if fontname =~ /cid0(cs|ct|jp|kr)/
    }
  end

  test "TrueTypeUnicode Font File test" do
    fontlist = ['freesans', 'freesansb', 'freesansi', 'freesansbi',
                'freemono', 'freemonob', 'freemonoi', 'freemonobi',
                'freeserif', 'freeserifb', 'freeserifi', 'freeserifbi',
                'dejavusans', 'dejavusansb', 'dejavusansi', 'dejavusansbi',
                'dejavusanscondensed', 'dejavusanscondensedb', 'dejavusanscondensedi', 'dejavusanscondensedbi',
                'dejavusansmono', 'dejavusansmonob', 'dejavusansmonoi', 'dejavusansmonobi',
                'dejavuserif', 'dejavuserifb', 'dejavuserifi', 'dejavuserifbi',
                'dejavusansextralight' ]

    font_path = RBPDFFontDescriptor.getfontpath
    fontlist.each {|fontname|
      fontfile = File.join font_path, fontname + '.rb'
      require(fontfile)
      font_desc = RBPDFFontDescriptor.font(fontname)

      assert_equal fontname + 'TrueTypeUnicode', fontname + font_desc[:type].to_s
      assert_not_equal '[' + fontname + ']:', '[' + fontname + ']:' + font_desc[:name].to_s
      assert_not_equal '[' + fontname + ']:', '[' + fontname + ']:' + font_desc[:desc].to_s
      assert_not_equal '[' + fontname + ']:', '[' + fontname + ']:' + font_desc[:desc]['Ascent'].to_s
      assert_not_equal '[' + fontname + ']:', '[' + fontname + ']:' + font_desc[:desc]['Descent'].to_s
      assert_not_equal '[' + fontname + ']:', '[' + fontname + ']:' + font_desc[:desc]['CapHeight'].to_s
      assert_not_equal '[' + fontname + ']:', '[' + fontname + ']:' + font_desc[:desc]['Flags'].to_s
      assert_not_equal '[' + fontname + ']:', '[' + fontname + ']:' + font_desc[:desc]['FontBBox'].to_s
      assert_not_equal '[' + fontname + ']:', '[' + fontname + ']:' + font_desc[:desc]['ItalicAngle'].to_s
      assert_not_equal '[' + fontname + ']:', '[' + fontname + ']:' + font_desc[:desc]['StemV'].to_s
      assert_not_equal '[' + fontname + ']:', '[' + fontname + ']:' + font_desc[:desc]['MissingWidth'].to_s
      assert_not_equal '[' + fontname + ']:', '[' + fontname + ']:' + font_desc[:up].to_s
      assert_not_equal '[' + fontname + ']:', '[' + fontname + ']:' + font_desc[:ut].to_s
      assert_not_equal '[' + fontname + ']:', '[' + fontname + ']:' + font_desc[:dw].to_s
      assert_not_equal '[' + fontname + ']:', '[' + fontname + ']:' + font_desc[:cw].to_s
      assert_not_equal '[' + fontname + ']:0', '[' + fontname + ']:' + font_desc[:cw].length.to_s
      if font_desc[:enc].nil?
        assert_not_equal '[' + fontname + ']:', '[' + fontname + ']:' + font_desc[:enc].to_s
      end
      if font_desc[:diff].nil?
      assert_not_equal '[' + fontname + ']:', '[' + fontname + ']:' + font_desc[:diff].to_s
      end
      assert_not_equal '[' + fontname + ']:', '[' + fontname + ']:' + font_desc[:file].to_s
      assert_true File.exist?( File.join font_path, font_desc[:file])
      assert_not_equal '[' + fontname + ']:', '[' + fontname + ']:' + font_desc[:ctg].to_s
      assert_true File.exist?( File.join font_path, font_desc[:ctg])
      assert_not_equal '[' + fontname + ']:', '[' + fontname + ']:' + font_desc[:originalsize].to_s
    }
  end
end
