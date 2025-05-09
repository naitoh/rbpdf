# coding: UTF-8
# frozen_string_literal: true
#============================================================+
# Begin       : 2008-06-09
# Last Update : 2010-05-20
#
# Description : Example 030 for RBPDF class
#               Colour gradients
#
# Author: Jun NAITOH
# License: LGPL 2.1 or later
#============================================================+

require("example_common.rb")

class Example030Controller < ApplicationController
  def index
    # create new PDF document
    pdf = RBPDF.new(PDF_PAGE_ORIENTATION, PDF_UNIT, PDF_PAGE_FORMAT, true, 'UTF-8', false)

    # set document information
    pdf.set_creator(PDF_CREATOR)
    pdf.set_author(PDF_AUTHOR)
    pdf.set_title('RBPDF Example 030')
    pdf.set_subject('RBPDF Tutorial')
    pdf.set_keywords('RBPDF, PDF, example, test, guide')

    # set default header data
    pdf.set_header_data(PDF_HEADER_LOGO, PDF_HEADER_LOGO_WIDTH, PDF_HEADER_TITLE + ' 030', PDF_HEADER_STRING)

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
    pdf.set_font('helvetica', 'B', 20)
    # --- first page ------------------------------------------
    # add a page
    pdf.add_page()

    pdf.cell(0, 0, 'RBPDF Gradients', 0, 1, 'C', 0, '', 0, false, 'T', 'M')

    # set colors for gradients (r,g,b) or (grey 0-255)
    red = [255, 0, 0]
    blue = [0, 0, 200]
    yellow = [255, 255, 0]
    green = [0, 255, 0]
    white = [255]
    black = [0]

    # set the coordinates x1,y1,x2,y2 of the gradient (see linear_gradient_coords.jpg)
    coords = [0, 0, 1, 0]

    # paint a linear gradient
    pdf.linear_gradient(20, 45, 80, 80, red, blue, coords)

    # write label
    pdf.text(20, 130, 'LinearGradient()')

    # set the coordinates fx,fy,cx,cy,r of the gradient (see radial_gradient_coords.jpg)
    coords = [0.5, 0.5, 1, 1, 1.2]

    # paint a radial gradient
    pdf.radial_gradient(110, 45, 80, 80, white, black, coords)

    # write label
    pdf.text(110, 130, 'RadialGradient()')

    # paint a coons patch mesh with default coordinates
    pdf.coons_patch_mesh(20, 155, 80, 80, yellow, blue, green, red)

    # write label
    pdf.text(20, 240, 'CoonsPatchMesh()')

    # set the coordinates for the cubic B�zier points x1,y1 ... x12, y12 of the patch (see coons_patch_mesh_coords.jpg)
    coords = [
      0.00, 0.00, 0.33, 0.20,             # lower left
      0.67, 0.00, 1.00, 0.00, 0.80, 0.33, # lower right
      0.80, 0.67, 1.00, 1.00, 0.67, 0.80, # upper right
      0.33, 1.00, 0.00, 1.00, 0.20, 0.67, # upper left
      0.00, 0.33]                         # lower left
    coords_min = 0 # minimum value of the coordinates
    coords_max = 1 # maximum value of the coordinates

    # paint a coons patch gradient with the above coordinates
    pdf.coons_patch_mesh(110, 155, 80, 80, yellow, blue, green, red, coords, coords_min, coords_max)

    # write label
    pdf.text(110, 240, 'CoonsPatchMesh()')

    # --- second page -----------------------------------------
    pdf.add_page()

    # first patch: f = 0
    patch_array = []
    patch_array[0] = {}
    patch_array[0]['f'] = 0
    patch_array[0]['points'] = [
      0.00,0.00, 0.33,0.00,
      0.67,0.00, 1.00,0.00, 1.00,0.33,
      0.8,0.67, 1.00,1.00, 0.67,0.8,
      0.33,1.80, 0.00,1.00, 0.00,0.67,
      0.00,0.33]
    patch_array[0]['colors'] = []
    patch_array[0]['colors'][0] = {'r' => 255, 'g' => 255, 'b' => 0}
    patch_array[0]['colors'][1] = {'r' => 0, 'g' => 0, 'b' => 255}
    patch_array[0]['colors'][2] = {'r' => 0, 'g' => 255,'b' => 0}
    patch_array[0]['colors'][3] = {'r' => 255, 'g' => 0,'b' => 0}

    # second patch - above the other: f = 2
    patch_array[1] = {}
    patch_array[1]['f'] = 2
    patch_array[1]['points'] = [
      0.00,1.33,
      0.00,1.67, 0.00,2.00, 0.33,2.00,
      0.67,2.00, 1.00,2.00, 1.00,1.67,
      1.5,1.33]
    patch_array[1]['colors'] = []
    patch_array[1]['colors'][0] = {'r' => 0, 'g' => 0, 'b' => 0}
    patch_array[1]['colors'][1] = {'r' => 255, 'g' => 0, 'b' => 255}

    # third patch - right of the above: f = 3
    patch_array[2] = {}
    patch_array[2]['f'] = 3
    patch_array[2]['points'] = [
      1.33,0.80,
      1.67,1.50, 2.00,1.00, 2.00,1.33,
      2.00,1.67, 2.00,2.00, 1.67,2.00,
      1.33,2.00]
    patch_array[2]['colors'] = []
    patch_array[2]['colors'][0] = {'r' => 0, 'g' => 255, 'b' => 255}
    patch_array[2]['colors'][1] = {'r' => 0, 'g' => 0, 'b' => 0}

    # fourth patch - below the above, which means left(?) of the above: f = 1
    patch_array[3] = {}
    patch_array[3]['f'] = 1
    patch_array[3]['points'] = [
      2.00,0.67,
      2.00,0.33, 2.00,0.00, 1.67,0.00,
      1.33,0.00, 1.00,0.00, 1.00,0.33,
      0.8,0.67]
    patch_array[3]['colors'] = []
    patch_array[3]['colors'][0] = {'r' => 0, 'g' => 0, 'b' => 0}
    patch_array[3]['colors'][1] = {'r' => 0, 'g' => 0, 'b' => 255}

    coords_min = 0
    coords_max = 2

    pdf.coons_patch_mesh(10, 45, 190, 200, '', '', '', '', patch_array, coords_min, coords_max)

    # write label
    pdf.text(10, 250, 'CoonsPatchMesh()')

    # ---------------------------------------------------------

    # Close and output PDF document
    send_data pdf.output(), :type => "application/pdf", :disposition => "inline"
  end
end

#============================================================+
# END OF FILE
#============================================================+
