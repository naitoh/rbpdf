# coding: UTF-8
#============================================================+
# Begin       : 2010-05-24
# Last Update : 2010-05-25
#
# Description : Example 061 for RBPDF class
#               XHTML + CSS
#
# Author: Jun NAITOH
# License: LGPL 2.1 or later
#============================================================+

require("example_common.rb")

class Example061Controller < ApplicationController
  def index
    # create new PDF document
    pdf = RBPDF.new(PDF_PAGE_ORIENTATION, PDF_UNIT, PDF_PAGE_FORMAT, true, 'UTF-8', false)
    
    # set document information
    pdf.set_creator(PDF_CREATOR)
    pdf.set_author(PDF_AUTHOR)
    pdf.set_title('RBPDF Example 061')
    pdf.set_subject('RBPDF Tutorial')
    pdf.set_keywords('RBPDF, PDF, example, test, guide')
    
    # set default header data
    pdf.set_header_data(PDF_HEADER_LOGO, PDF_HEADER_LOGO_WIDTH, PDF_HEADER_TITLE + ' 061', PDF_HEADER_STRING)
    
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
    pdf.set_font('helvetica', '', 10)
    
    # add a page
    pdf.add_page()
    
    # NOTE:
    # *********************************************************
    # You can load external XHTML using :
    #
    #   html = ''
    #   file = Rails.root.to_s + 'path/to/your/file.html'
    #   open(file,'rb') do |f|
    #     html << f.read()
    #   end
    #
    # External CSS files will be automatically loaded.
    # Sometimes you need to fix the path of the external CSS.
    # *********************************************************
    
    # define some HTML content with style
    html = <<EOF
    <!-- EXAMPLE OF CSS STYLE -->
    <style>
    	h1 {
    		color: navy;
    		font-family: times;
    		font-size: 24pt;
    		text-decoration: underline;
    	}
    	p.first {
    		color: #003300;
    		font-family: helvetica;
    		font-size: 12pt;
    	}
    	p.first span {
    		color: #006600;
    		font-style: italic;
    	}
    	p#second {
    		color: rgb(00,63,127);
    		font-family: times;
    		font-size: 12pt;
    		text-align: justify;
    	}
    	p#second > span {
    		background-color: #FFFFAA;
    	}
    </style>
    
    <h1 class="title">Example of <i style="color:#990000">XHTML + CSS</i></h1>
    
    <p class="first">Example of paragraph with class selector. <span>Lorem ipsum dolor sit amet, consectetur adipiscing elit. In sed imperdiet lectus. Phasellus quis velit velit, non condimentum quam. Sed neque urna, ultrices ac volutpat vel, laoreet vitae augue. Sed vel velit erat. Class aptent taciti sociosqu ad litora torquent per conubia nostra, per inceptos himenaeos. Cras eget velit nulla, eu sagittis elit. Nunc ac arcu est, in lobortis tellus. Praesent condimentum rhoncus sodales. In hac habitasse platea dictumst. Proin porta eros pharetra enim tincidunt dignissim nec vel dolor. Cras sapien elit, ornare ac dignissim eu, ultricies ac eros. Maecenas augue magna, ultrices a congue in, mollis eu nulla. Nunc venenatis massa at est eleifend faucibus. Vivamus sed risus lectus, nec interdum nunc.</span></p>
    
    <p id="second">Example of paragraph with ID selector. <span>Fusce et felis vitae diam lobortis sollicitudin. Aenean tincidunt accumsan nisi, id vehicula quam laoreet elementum. Phasellus egestas interdum erat, et viverra ipsum ultricies ac. Praesent sagittis augue at augue volutpat eleifend. Cras nec orci neque. Mauris bibendum posuere blandit. Donec feugiat mollis dui sit amet pellentesque. Sed a enim justo. Donec tincidunt, nisl eget elementum aliquam, odio ipsum ultrices quam, eu porttitor ligula urna at lorem. Donec varius, eros et convallis laoreet, ligula tellus consequat felis, ut ornare metus tellus sodales velit. Duis sed diam ante. Ut rutrum malesuada massa, vitae consectetur ipsum rhoncus sed. Suspendisse potenti. Pellentesque a congue massa.</span></p>
EOF
    
    # output the HTML content
    pdf.write_html(html, true, false, true, false, '')
    
    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    
    # reset pointer to the last page
    pdf.last_page()
    
    # ---------------------------------------------------------
    
    # Close and output PDF document
    send_data pdf.output(), :type => "application/pdf", :disposition => "inline"
  end
end

#============================================================+
# END OF FILE                                                
#============================================================+
