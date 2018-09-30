# coding: UTF-8
#============================================================+
# Begin       : 2008-03-04
# Last Update : 2010-05-20
#
# Description : Example 012 for RBPDF class
#               Graphic Functions
#
# Author: Jun NAITOH
# License: LGPL 2.1 or later
#============================================================+

require("example_common.rb")

class Example012Controller < ApplicationController
  def index
    # create new PDF document
    pdf = RBPDF.new(PDF_PAGE_ORIENTATION, PDF_UNIT, PDF_PAGE_FORMAT, true, 'UTF-8', false)
    
    # set document information
    pdf.set_creator(PDF_CREATOR)
    pdf.set_author(PDF_AUTHOR)
    pdf.set_title('RBPDF Example 012')
    pdf.set_subject('RBPDF Tutorial')
    pdf.set_keywords('RBPDF, PDF, example, test, guide')
    
    # disable header and footer
    pdf.set_print_header(false)
    pdf.set_print_footer(false)
    
    # set default monospaced font
    pdf.set_default_monospaced_font(PDF_FONT_MONOSPACED)
    
    # set margins
    pdf.set_margins(PDF_MARGIN_LEFT, PDF_MARGIN_TOP, PDF_MARGIN_RIGHT)
    
    # set auto page breaks
    pdf.set_auto_page_break(true, PDF_MARGIN_BOTTOM)
    
    # set image scale factor
    pdf.set_image_scale(PDF_IMAGE_SCALE_RATIO)
    
    # set some language-dependent strings
    pdf.set_language_array($l)
    
    # ---------------------------------------------------------
    
    # set font
    pdf.set_font('helvetica', '', 10)
    
    # add a page
    pdf.add_page()
    
    style = {'width' => 0.5, 'cap' => 'butt', 'join' => 'miter', 'dash' => '10,20,5,10', 'phase' => 10, 'color' => [255, 0, 0]}
    style2 = {'width' => 0.5, 'cap' => 'butt', 'join' => 'miter', 'dash' => 0, 'color' => [255, 0, 0]}
    style3 = {'width' => 1, 'cap' => 'round', 'join' => 'round', 'dash' => '2,10', 'color' => [255, 0, 0]}
    style4 = {'L' => 0,
                    'T' => {'width' => 0.25, 'cap' => 'butt', 'join' => 'miter', 'dash' => '20,10', 'phase' => 10, 'color' => [100, 100, 255]},
                    'R' => {'width' => 0.50, 'cap' => 'round', 'join' => 'miter', 'dash' => 0, 'color' => [50, 50, 127]},
                    'B' => {'width' => 0.75, 'cap' => 'square', 'join' => 'miter', 'dash' => '30,10,5,10'}}
    style5 = {'width' => 0.25, 'cap' => 'butt', 'join' => 'miter', 'dash' => 0, 'color' => [0, 64, 128]}
    style6 = {'width' => 0.5, 'cap' => 'butt', 'join' => 'miter', 'dash' => '10,10', 'color' => [0, 128, 0]}
    style7 = {'width' => 0.5, 'cap' => 'butt', 'join' => 'miter', 'dash' => 0, 'color' => [255, 128, 0]}
    
    # Line
    pdf.text(5, 4, 'Line examples')
    pdf.line(5, 10, 80, 30, style)
    pdf.line(5, 10, 5, 30, style2)
    pdf.line(5, 10, 80, 10, style3)
    
    # Rect
    pdf.text(100, 4, 'Rectangle examples')
    pdf.rect(100, 10, 40, 20, 'DF', style4, [220, 220, 200])
    pdf.rect(145, 10, 40, 20, 'D', {'all' => style3})
    
    # Curve
    pdf.text(5, 34, 'Curve examples')
    pdf.curve(5, 40, 30, 55, 70, 45, 60, 75, nil, style6)
    pdf.curve(80, 40, 70, 75, 150, 45, 100, 75, 'F', style6)
    pdf.curve(140, 40, 150, 55, 180, 45, 200, 75, 'DF', style6, [200, 220, 200])
    
    # Circle and ellipse
    pdf.text(5, 79, 'Circle and ellipse examples')
    pdf.set_line_style(style5)
    pdf.circle(25,105,20)
    pdf.circle(25,105,10, 90, 180, nil, style6)
    pdf.circle(25,105,10, 270, 360, 'F')
    pdf.circle(25,105,10, 270, 360, 'C', style6)
    
    pdf.set_line_style(style5)
    pdf.ellipse(100,103,40,20)
    pdf.ellipse(100,105,20,10, 0, 90, 180, nil, style6)
    pdf.ellipse(100,105,20,10, 0, 270, 360, 'DF', style6)
    
    pdf.set_line_style(style5)
    pdf.ellipse(175,103,30,15,45)
    pdf.ellipse(175,105,15,7.50, 45, 90, 180, nil, style6)
    pdf.ellipse(175,105,15,7.50, 45, 270, 360, 'F', style6, [220, 200, 200])
    
    # Polygon
    pdf.text(5, 129, 'Polygon examples')
    pdf.set_line_style({'width' => 0.5, 'cap' => 'butt', 'join' => 'miter', 'dash' => 0, 'color' => [0, 0, 0]})
    pdf.polygon([5,135,45,135,15,165])
    pdf.polygon([60,135,80,135,80,155,70,165,50,155], 'DF', [style6, style7, style7, 0, style6], [220, 200, 200])
    pdf.polygon([120,135,140,135,150,155,110,155], 'D', [style6, 0, style7, style6])
    pdf.polygon([160,135,190,155,170,155,200,160,160,165], 'DF', {'all' => style6}, [220, 220, 220])
    
    # Polygonal Line
    pdf.set_line_style({'width' => 0.5, 'cap' => 'butt', 'join' => 'miter', 'dash' => 0, 'color' => [0, 0, 164]})
    pdf.poly_line([80,165,90,160,100,165,110,160,120,165,130,160,140,165], 'D', nil, nil)
    
    # Regular polygon
    pdf.text(5, 169, 'Regular polygon examples')
    pdf.set_line_style(style5)
    pdf.regular_polygon(20, 190, 15, 6, 0, 1, 'F')
    pdf.regular_polygon(55, 190, 15, 6)
    pdf.regular_polygon(55, 190, 10, 6, 45, 0, 'DF', [style6, 0, style7, 0, style7, style7])
    pdf.regular_polygon(90, 190, 15, 3, 0, 1, 'DF', {'all' => style5}, [200, 220, 200], 'F', [255, 200, 200])
    pdf.regular_polygon(125, 190, 15, 4, 30, 1, nil, {'all' => style5}, nil, nil, style6)
    pdf.regular_polygon(160, 190, 15, 10)
    
    # Star polygon
    pdf.text(5, 209, 'Star polygon examples')
    pdf.set_line_style(style5)
    pdf.star_polygon(20, 230, 15, 20, 3, 0, 1, 'F')
    pdf.star_polygon(55, 230, 15, 12, 5)
    pdf.star_polygon(55, 230, 7, 12, 5, 45, 0, 'DF', {'all' => style7}, [220, 220, 200], 'F', [255, 200, 200])
    pdf.star_polygon(90, 230, 15, 20, 6, 0, 1, 'DF', {'all' => style5}, [220, 220, 200], 'F', [255, 200, 200])
    pdf.star_polygon(125, 230, 15, 5, 2, 30, 1, nil, {'all' => style5}, nil, nil, style6)
    pdf.star_polygon(160, 230, 15, 10, 3)
    pdf.star_polygon(160, 230, 7, 50, 26)
    
    # Rounded rectangle
    pdf.text(5, 249, 'Rounded rectangle examples')
    pdf.set_line_style({'width' => 0.5, 'cap' => 'butt', 'join' => 'miter', 'dash' => 0, 'color' => [0, 0, 0]})
    pdf.rounded_rect(5, 255, 40, 30, 3.50, '1111', 'DF')
    pdf.rounded_rect(50, 255, 40, 30, 6.50, '1000')
    pdf.rounded_rect(95, 255, 40, 30, 10.0, '1111', nil, style6)
    pdf.rounded_rect(140, 255, 40, 30, 8.0, '0101', 'DF', style6, [200, 200, 200])
    
    # Arrows
    pdf.text(185, 249, 'Arrows')
    pdf.set_line_style(style5)
    pdf.set_fill_color(255, 0, 0)
    pdf.Arrow(x0=200, y0=280, x1=185, y1=266, head_style=0, arm_size=5, arm_angle=15)
    pdf.Arrow(x0=200, y0=280, x1=190, y1=263, head_style=1, arm_size=5, arm_angle=15)
    pdf.Arrow(x0=200, y0=280, x1=195, y1=261, head_style=2, arm_size=5, arm_angle=15)
    pdf.Arrow(x0=200, y0=280, x1=200, y1=260, head_style=3, arm_size=5, arm_angle=15)
    
    # - . - . - . - . - . - . - . - . - . - . - . - . - . - . -
    
    # ellipse
    
    # add a page
    pdf.add_page()
    
    pdf.cell(0, 0, 'Arc of Ellipse')
    
    # center of ellipse
    xc=100
    yc=100
    
    # X Y axis
    pdf.set_draw_color(200, 200, 200)
    pdf.line(xc-50, yc, xc+50, yc)
    pdf.line(xc, yc-50, xc, yc+50)
    
    # ellipse axis
    pdf.set_draw_color(200, 220, 255)
    pdf.line(xc-50, yc-50, xc+50, yc+50)
    pdf.line(xc-50, yc+50, xc+50, yc-50)
    
    # ellipse
    pdf.set_draw_color(200, 255, 200)
    pdf.ellipse(xc, yc, rx=30, ry=15, angle=45, astart=0, afinish=360, style='D', line_style=nil, fill_color=nil, nc=2)
    
    # ellipse arc
    pdf.set_draw_color(255, 0, 0)
    pdf.ellipse(xc, yc, rx=30, ry=15, angle=45, astart=45, afinish=90, style='D', line_style=nil, fill_color=nil, nc=2)
    
    
    # ---------------------------------------------------------
    
    # Close and output PDF document
    send_data pdf.output(), :type => "application/pdf", :disposition => "inline"
  end
end

#============================================================+
# END OF FILE
#============================================================+
