# coding: UTF-8
# frozen_string_literal: true
#============================================================+
# Begin       : 2008-03-04
# Last Update : 2010-06-02
#
# Description : Example 014 for RBPDF class
#               Javascript Form and user rights (only works on Adobe Acrobat)
#
# Author: Jun NAITOH
# License: LGPL 2.1 or later
#============================================================+

require("example_common.rb")

class Example014Controller < ApplicationController
  def index
    # create new PDF document
    pdf = RBPDF.new(PDF_PAGE_ORIENTATION, PDF_UNIT, PDF_PAGE_FORMAT, true, 'UTF-8', false)

    # set document information
    pdf.set_creator(PDF_CREATOR)
    pdf.set_author(PDF_AUTHOR)
    pdf.set_title('RBPDF Example 014')
    pdf.set_subject('RBPDF Tutorial')
    pdf.set_keywords('RBPDF, PDF, example, test, guide')

    # set default header data
    pdf.set_header_data(PDF_HEADER_LOGO, PDF_HEADER_LOGO_WIDTH, PDF_HEADER_TITLE + ' 014', PDF_HEADER_STRING)

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

    # set some language-dependent strings
    pdf.set_language_array($l)

    # ---------------------------------------------------------

    # set font
    # IMPORTANT: disable font subsetting to allow users editing the document
    pdf.set_font('helvetica', '', 10)

    # add a page
    pdf.add_page()

    # It is possible to create text fields, combo boxes, check boxes and buttons.
    # Fields are created at the current position and are given a name.
    # This name allows to manipulate them via JavaScript in order to perform some validation for instance.

    # set default form properties
    pdf.setFormDefaultProp({'lineWidth'=>1, 'borderStyle'=>'solid', 'fillColor'=>[255, 255, 200], 'strokeColor'=>[255, 128, 128]})

    pdf.set_font('helvetica', 'BI', 18)
    pdf.cell(0, 5, 'Example of Form', 0, 1, 'C')
    pdf.ln(10)

    pdf.set_font('helvetica', '', 12)

    # First name
    pdf.cell(35, 5, 'First name:')
    pdf.text_field('firstname', 50, 5)
    pdf.ln(6)

    # Last name
    pdf.cell(35, 5, 'Last name:')
    pdf.text_field('lastname', 50, 5)
    pdf.ln(6)

    # Gender
    pdf.cell(35, 5, 'Gender:')
    pdf.combo_box('gender', 30, 5, [['', '-'], ['M', 'Male'],['F', 'Female']])
    pdf.ln(6)

    # Drink
    pdf.cell(35, 5, 'Drink:')
    pdf.radio_button('drink', 5, {}, {}, 'Water')
    pdf.cell(35, 5, 'Water')
    pdf.ln(6)
    pdf.cell(35, 5, '')
    pdf.radio_button('drink', 5, {}, {}, 'Beer', true)
    pdf.cell(35, 5, 'Beer')
    pdf.ln(6)
    pdf.cell(35, 5, '')
    pdf.radio_button('drink', 5, {}, {}, 'Wine')
    pdf.cell(35, 5, 'Wine')
    pdf.ln(10)

    # Listbox
    pdf.cell(35, 5, 'List:')
    pdf.list_box('listbox', 60, 15, ['', 'item1', 'item2', 'item3', 'item4', 'item5', 'item6', 'item7'], {'multipleSelection'=>'true'})
    pdf.ln(20)

    # Adress
    pdf.cell(35, 5, 'Address:')
    pdf.text_field('address', 60, 18, {'multiline'=>true})
    pdf.ln(19)

    # E-mail
    pdf.cell(35, 5, 'E-mail:')
    pdf.text_field('email', 50, 5)
    pdf.ln(6)

    # Newsletter
    pdf.cell(35, 5, 'Newsletter:')
    pdf.check_box('newsletter', 5, true, {}, {}, 'OK')
    pdf.ln(10)

    # Date of the day
    pdf.cell(35, 5, 'Date:')
    pdf.text_field('date', 30, 5, {}, {'v' => Date.today.to_s, 'dv' => Date.today.to_s})
    pdf.ln(10)

    pdf.SetX(50)

    # button to validate and print
    pdf.button('print', 30, 10, 'Print', 'Print()', {'lineWidth'=>2, 'borderStyle'=>'beveled', 'fillColor'=>[128, 196, 255], 'strokeColor'=>[64, 64, 64]})

    # Reset button
    pdf.button('reset', 30, 10, 'Reset', {'S'=>'ResetForm'}, {'lineWidth'=>2, 'borderStyle'=>'beveled', 'fillColor'=>[128, 196, 255], 'strokeColor'=>[64, 64, 64]})

    # Submit button
    pdf.button('submit', 30, 10, 'Submit', {'S'=>'SubmitForm', 'F'=>'http://localhost/printvars.php', 'Flags'=>['ExportFormat']}, {'lineWidth'=>2, 'borderStyle'=>'beveled', 'fillColor'=>[128, 196, 255], 'strokeColor'=>[64, 64, 64]})

    # Form validation functions
    js = <<~EOD
    function CheckField(name,message) {
      var f = getField(name)
      if(f.value == '') {
          app.alert(message)
          f.setFocus()
          return false
      }
      return true
    }
    function Print() {
      if(!CheckField('firstname','First name is mandatory')) {return;}
      if(!CheckField('lastname','Last name is mandatory')) {return;}
      if(!CheckField('gender','Gender is mandatory')) {return;}
      if(!CheckField('address','Address is mandatory')) {return;}
      print()
    }
    EOD

    # Add Javascript code
    pdf.IncludeJS(js)

    # ---------------------------------------------------------

    # Close and output PDF document
    send_data pdf.output(), :type => "application/pdf", :disposition => "inline"
  end
end

#============================================================+
# END OF FILE
#============================================================+
