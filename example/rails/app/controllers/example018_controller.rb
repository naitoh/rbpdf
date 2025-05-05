# coding: UTF-8
# frozen_string_literal: true
#============================================================+
# Begin       : 2008-03-06
# Last Update : 2010-05-20
#
# Description : Example 018 for RBPDF class
#               RTL document with Persian language
#
# Author: Jun NAITOH
# License: LGPL 2.1 or later
#============================================================+

require("example_common.rb")

class Example018Controller < ApplicationController
  def index
    # create new PDF document
    pdf = RBPDF.new(PDF_PAGE_ORIENTATION, PDF_UNIT, PDF_PAGE_FORMAT, true, 'UTF-8', false)
    
    # set document information
    pdf.set_creator(PDF_CREATOR)
    pdf.set_author(PDF_AUTHOR)
    pdf.set_title('RBPDF Example 018')
    pdf.set_subject('RBPDF Tutorial')
    pdf.set_keywords('RBPDF, PDF, example, test, guide')
    
    # set default header data
    pdf.set_header_data(PDF_HEADER_LOGO, PDF_HEADER_LOGO_WIDTH, PDF_HEADER_TITLE + ' 018', PDF_HEADER_STRING)
    
    # set header and footer fonts
    pdf.set_header_font([PDF_FONT_NAME_MAIN, '', PDF_FONT_SIZE_MAIN])
    pdf.set_footer_font([PDF_FONT_NAME_DATA, '', PDF_FONT_SIZE_DATA])
    
    # set default monospaced font
    pdf.set_default_monospaced_font(PDF_FONT_MONOSPACED)
    
    # set margins
    pdf.set_margins(PDF_MARGIN_LEFT, PDF_MARGIN_TOP, PDF_MARGIN_RIGHT)
    pdf.set_header_margin(PDF_MARGIN_HEADER)
    pdf.set_footer_margin(PDF_MARGIN_FOOTER)
    
    # set auto page breaks
    pdf.set_auto_page_break(true, PDF_MARGIN_BOTTOM)
    
    # set image scale factor
    pdf.set_image_scale(PDF_IMAGE_SCALE_RATIO)
    
    # set some language dependent data:
    lg = {}
    lg['a_meta_charset'] = 'UTF-8'
    lg['a_meta_dir'] = 'rtl'
    lg['a_meta_language'] = 'fa'
    lg['w_page'] = 'page'
    
    # set some language-dependent strings
    pdf.set_language_array(lg)
    
    # ---------------------------------------------------------
    
    # set font
    pdf.set_font('dejavusans', '', 12)
    
    # add a page
    pdf.add_page()
    
    # Persian and English content
    htmlpersian = '<span color="#660000">Persian example:</span><br />سلام بالاخره مشکل PDF فارسی به طور کامل حل شد. اینم یک نمونش.<br />مشکل حرف \"ژ\" در بعضی کلمات مانند کلمه ویژه نیز بر طرف شد.<br />نگارش حروف لام و الف پشت سر هم نیز تصحیح شد.<br />با تشکر از  "Asuni Nicola" و محمد علی گل کار برای پشتیبانی زبان فارسی.'
    pdf.write_html(htmlpersian, true, 0, true, 0)
    
    # set LTR direction for english translation
    pdf.set_rtl(false)
    
    pdf.set_font_size(10)
    
    # print newline
    pdf.ln()
    
    # Persian and English content
    htmlpersiantranslation = '<span color="#0000ff">Hi, At last Problem of Persian PDF Solved completely. This is a example for it.<br />Problem of "jeh" letter in some word like "ویژه" (=special) fix too.<br />The joining of laa and alf letter fix now.<br />Special thanks to "Nicola Asuni" and "Mohamad Ali Golkar" for Persian support.</span>'
    pdf.write_html(htmlpersiantranslation, true, 0, true, 0)
    
    # Restore RTL direction
    pdf.set_rtl(true)
    
    # set font size
    #pdf.set_font('almohanad', '', 18)
    
    # print newline
    pdf.ln()
    
    # Arabic and English content
    pdf.cell(0, 12, 'بِسْمِ اللهِ الرَّحْمنِ الرَّحِيمِ',0,1,'C')
    htmlcontent = 'تمَّ بِحمد الله حلّ مشكلة الكتابة باللغة العربية في ملفات الـ<span color="#FF0000">PDF</span> مع دعم الكتابة <span color="#0000FF">من اليمين إلى اليسار</span> و<span color="#009900">الحركَات</span> .<br />تم الحل بواسطة <span color="#993399">صالح المطرفي و Asuni Nicola</span>  . '
    pdf.write_html(htmlcontent, true, 0, true, 0)
    
    # set LTR direction for english translation
    pdf.set_rtl(false)
    
    # set font size
    pdf.set_font_size(18)
    
    # print newline
    pdf.ln()
    
    # Arabic and English content
    htmlcontent2 = '<span color="#0000ff">This is Arabic "العربية" Example With RBPDF.</span>'
    pdf.write_html(htmlcontent2, true, 0, true, 0)
    
    # ---------------------------------------------------------
    
    # Close and output PDF document
    send_data pdf.output(), :type => "application/pdf", :disposition => "inline"
  end
end

#============================================================+
# END OF FILE                                                
#============================================================+
