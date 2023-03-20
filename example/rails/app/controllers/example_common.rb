# coding: UTF-8
#============================================================+
# Begin       : 2004-06-11
# Last Update : 2010-04-28
#
# Description : Configuration file for TCPDF.
#
# Author: Jun NAITOH
# License: LGPL 2.1 or later
#============================================================+

PDF_PAGE_ORIENTATION='P'
PDF_UNIT='mm'
PDF_PAGE_FORMAT='A4'
PDF_CREATOR='RBPDF'
PDF_AUTHOR='Jun NAITOH'
PDF_HEADER_TITLE='RBPDF Example'
if defined? Rails and defined? Rails.root
  PUBLIC = File.join(Rails.root, 'public')
else
  PUBLIC = File.join(File.dirname(File.expand_path(__FILE__)), '../../public')
end
PDF_HEADER_LOGO="#{PUBLIC}/logo_rbpdf_8bit.png"
PDF_EXAMPLE_LOGO="#{PUBLIC}/logo_example.png"
PDF_IMAGE_DEMO_PNG="#{PUBLIC}/image_demo.png"
PDF_IMAGE_DEMO_JPG="#{PUBLIC}/image_demo.jpg"
PDF_IMAGE_DEMO_WEBP="#{PUBLIC}/image_demo.webp"
PDF_UTF8TEST_TXT="#{PUBLIC}/utf8test.txt"
PDF_TABLE_DATA_DEMO_TXT="#{PUBLIC}/table_data_demo.txt"
PDF_TIGER_AI="#{PUBLIC}/tiger.ai"
PDF_PNG_TEST_ALPHA_PNG="#{PUBLIC}/png_test_alpha.png"
PDF_PNG_TEST_MSK_ALPHA_PNG="#{PUBLIC}/png_test_msk_alpha.png"
PDF_PNG_TEST_NON_ALPHA_PNG="#{PUBLIC}/png_test_non_alpha.png"
PDF_GIF_TEST_MSK_ALPHA_PNG="#{PUBLIC}/gif_test_msk_alpha.png"
PDF_GIF_TEST_NON_ALPHA_PNG="#{PUBLIC}/gif_test_non_alpha.png"
PDF_GIF_TEST_ALPHA_GIF="#{PUBLIC}/gif_test_alpha.gif"
PDF_WEBP_TEST_ALPHA_PNG="#{PUBLIC}/webp_test_alpha.webp"

if !defined? send_data
  def send_data(data, options = {}) 
    data
  end
end

PDF_HEADER_LOGO_WIDTH=30
PDF_HEADER_STRING="by Jun NAITOH - @naitoh"

PDF_FONT_NAME_MAIN='helvetica'
PDF_FONT_SIZE_MAIN=10
PDF_FONT_NAME_DATA='helvetica'
PDF_FONT_SIZE_DATA=8
PDF_FONT_MONOSPACED='courier'

PDF_MARGIN_HEADER=5
PDF_MARGIN_FOOTER=10
PDF_MARGIN_TOP=27
PDF_MARGIN_BOTTOM=25
PDF_MARGIN_LEFT=15
PDF_MARGIN_RIGHT=15
PDF_IMAGE_SCALE_RATIO=1.25

$l = {}
$l['a_meta_charset'] = 'UTF-8'
$l['a_meta_dir'] = 'ltr'
$l['a_meta_language'] = 'en'
