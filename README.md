[![Build Status](https://github.com/naitoh/rbpdf/workflows/test/badge.svg)](https://github.com/naitoh/rbpdf/actions)

# RBPDF Template Plugin

A template plugin allowing the inclusion of ERB-enabled RBPDF template files.

##
##
## RBPDF Version (The New or UTF8 Version)
##
##

* Use UTF-8 encoding. 
* RTL (Right-To-Left) languages support.
* HTML tag support.
* CSS minimum support.
* Image
 - 8bit PNG image support without MiniMagick/RMagick library.
 - PNG(with alpha channel)/JPEG/GIF/WebP image support. (use MiniMagick or RMagick library)


##
## Installing RBPDF
##

RBPDF is distributed via RubyGems, and can be installed the usual way that you install gems: by simply typing `gem install rbpdf` on the command line. 

==

If you are using image file, it is recommended you install:
```
gem install mini_magick
```
or
```
gem install rmagick
```

RBPDF Example of simple use in .html.erb:

```
<%
  @pdf = RBPDF.new()
  @pdf.set_margins(15, 27, 15)
  @pdf.set_font('FreeSans','', 8)
  @pdf.add_page()
  @pdf.write(5, "text\n", '')
%><%==@pdf.output()%>
```

RBPDF Japanese Example of simple use in .html.erb:
```
<%
  @pdf = RBPDF.new()
  @pdf.set_margins(15, 27, 15)
  @pdf.set_font('kozminproregular','', 8)
  @pdf.add_page()
  @pdf.write(5, "UTF-8 Japanese text.\n", '')
%><%==@pdf.output()%>
```

PDF example output
```
$ OUTPUT=true bundle exec rake test TEST=test/rbpdf_examples_test.rb
$ ls -1 *.pdf
example001.pdf
example002.pdf
example003.pdf
:
```

See the following files for sample of useage:

test_unicode.rbpdf
utf8test.txt
logo_example.png

ENJOY!

License

  The project RBPDF doesn't use same license for all code. There are
  code with:

   * LGPLv2.1+ (GNU Lesser General Public License v2.1 or any later version)

   * MIT (MIT-LICENSE)

  Please, check source code for more details. A license is usually at the start
  of each source file.

  The MIT-LICENSE file (MIT) is the default license for code without an explicitly
  defined license.

