# coding: ASCII-8BIT
# frozen_string_literal: true
# The MIT License
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#
# This implements native php methods used by tcpdf, which have had to be
# reimplemented within Ruby.

module Rbpdf

  def getimagesize(filename)
    return nil unless File.exist?(filename)

    out = Hash.new
    type = File::extname(filename)
    if type == '.png'
      open(filename,'rb') do |f|
        # Check signature
        return false if (f.read(8)!=137.chr + 'PNG' + 13.chr + 10.chr + 26.chr + 10.chr)
        # Read header chunk
        f.read(4)
        return false if (f.read(4)!='IHDR')
        out[0] = freadint(f)
        out[1] = freadint(f)
        out[2] = 'PNG'
        out[3] = "height=\"#{out[1]}\" width=\"#{out[0]}\""
        out['mime'] = 'image/png'
      end

      return out
    end

    unless Object.const_defined?(:MiniMagick)
      Error('No Mini Magick: Non-PNG file is not supported.: ' + filename);
      return false
    end

    unless Object.const_defined?(:Marcel)
      Error('No Marcel: Non-PNG file is not supported.: ' + filename);
      return false
    end

    image = MiniMagick::Image.open(filename)
    
    width = image.width
    height = image.height

    mime_type = File.open filename do |file|
      ::Marcel::MimeType.for file
    end

    out['mime'] = mime_type
    out[0] = width
    out[1] = height
    
    # These are actually meant to return integer values But I couldn't seem to find anything saying what those values are.
    # So for now they return strings. The only place that uses this at the moment is the parsejpeg method, so I've changed that too.
    case mime_type
    when "image/gif"
      out[2] = "GIF"
    when "image/jpeg"
      out[2] = "JPEG"
    when "image/png"
      out[2] = "PNG"
    when "image/webp", "image/x-webp"
      out[2] = "WEBP"
      out['mime'] = "image/webp"
    when "image/vnd.wap.wbmp"
      out[2] = "WBMP"
    when "image/x-xpixmap"
      out[2] = "XPM"
    end
    out[3] = "height=\"#{height}\" width=\"#{width}\""
    
    # This needs work to cover more situations
    # I can't see how to just list the number of channels with ImageMagick / mini_magick
    case image["%[channels]"].downcase.split.first
    when 'cmyk'
      out['channels'] = 4
    when 'rgb', 'rgba', 'srgb', 'srgba'  # Mac OS X : sRGB
      out['channels'] = 3
      if image.colorspace.downcase == 'pseudoclassgray'  # PseudoClassGray
        out['channels'] = 0
      else
        out['channels'] = 3
      end
    when 'gray', 'graya'
        out['channels'] = 0
    else
        out['channels'] = 0
    end

    out['bits'] = image["%[depth]"].to_i
    
    out
  end
  
end
