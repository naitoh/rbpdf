# Copyright (c) 2011-2018 NAITOH Jun
# Released under the MIT license
# http://www.opensource.org/licenses/MIT

require 'test_helper'

def logger
  require 'logger'
  return Logger.new(STDOUT)
end

if !defined? ApplicationController
  class ApplicationController
  end
end

class RbpdfTest < Test::Unit::TestCase
  htmls = {
    '001 : Default Header and Footer'                       => '001',
    '002 : Removing Header and Footer'                      => '002',
    '003 : Custom Header and Footer'                        => '003',
    '004 : Cell stretching'                                 => '004',
    '005 : Multicell'                                       => '005',
    '006 : write_html and RTL support'                      => '006',
    '007 : Two independent columns with write_htmlcell()'   => '007',
    '008 : Include external UTF-8 text file'                => '008',
    '009 : Test Image'                                      => '009',
    '011 : Colored Table'                                   => '011',
    '012 : Graphic Functions'                               => '012',
    '014 : Javascript and Forms'                            => '014',
    '015 : Bookmarks (Table of Content)'                    => '015',
    '017 : Two independent columns with MultiCell'          => '017',
    '018 : RTL document with Persian language'              => '018',
    '020 : Two columns composed by MultiCell of different'  => '020',
    '021 : write_html text flow'                            => '021',
    '022 : CMYK colors'                                     => '022',
    '023 : Page Groups'                                     => '023',
    '024 : Object Visibility'                               => '024',
    '025 : Object Transparency'                             => '025',
    '026 : Text Rendering Modes and Text Clipping'          => '026',
    '028 : Changing page formats'                           => '028',
    '029 : Set PDF viewer display preferences.'             => '029',
    '030 : Colour gradients'                                => '030',
    '031 : Pie Chart'                                       => '031',
    '033 : Mixed font types'                                => '033',
    '034 : Clipping'                                        => '034',
    '035 : Line styles with cells and multicells'           => '035',
    '036 : Annotations'                                     => '036',
    '038 : CID-0 CJK unembedded font'                       => '038',
    '039 : HTML justification'                              => '039',
    '040 : Booklet mode (double-sided pages)'               => '040',
    '041 : Annotation - FileAttachment'                     => '041',
    '042 : Test Image with alpha channel'                   => '042',
    '043 : Disk caching'                                    => '043',
    '044 : Move, copy and delete pages'                     => '044',
    '045 : Bookmarks and Table of Content'                  => '045',
    '047 : Transactions'                                    => '047',
    '048 : HTML tables and table headers'                   => '048',
#    '051 : Full page background'                            => '051',
    '054 : XHTML Form'                                      => '054',
    '055 : Display all characters available on core fonts.' => '055',
    '057 : Cell vertical alignments'                        => '057',
    '059 : Table Of Content using HTML templates.'          => '059',
    '060 : Advanced page settings.'                         => '060',
    '061 : XHTML + CSS'                                     => '061',
  }

  data(htmls)
  test "Examples test" do |data|
    $LOAD_PATH << File.join(File.dirname(File.expand_path(__FILE__)), '../example/rails/app/controllers/')

    require "example#{data}_controller"

    content = []
    test = Object.const_get("Example#{data}Controller").new

    contents = test.index
#    contents = assert_nothing_raised do
#      test.index
#    end
    contents.each_line {|line| content.push line.chomp }

    assert_not_equal 0, content.length
    assert_equal '%PDF-1.7', content[0]

    File.open("example#{data}.pdf", mode = "w"){|f| f.write(contents) } if ENV['OUTPUT']
  end
end
