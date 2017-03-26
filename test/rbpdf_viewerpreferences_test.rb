# Copyright (c) 2011-2017 NAITOH Jun
# Released under the MIT license
# http://www.opensource.org/licenses/MIT

require 'test_helper'

class RbpdfPageTest < Test::Unit::TestCase
  class MYPDF < RBPDF
    def putviewerpreferences
      super
    end
  end

  test "viewerpreferences test" do
    # set array for viewer preferences
    preferences = {
        'HideToolbar' => true,
        'HideMenubar' => true,
        'HideWindowUI' => true,
        'FitWindow' => true,
        'CenterWindow' => true,
        'DisplayDocTitle' => true,
        'NonFullScreenPageMode' => 'UseNone', # UseNone, UseOutlines, UseThumbs, UseOC
        'ViewArea' => 'CropBox', # CropBox, BleedBox, TrimBox, ArtBox
        'ViewClip' => 'CropBox', # CropBox, BleedBox, TrimBox, ArtBox
        'PrintArea' => 'CropBox', # CropBox, BleedBox, TrimBox, ArtBox
        'PrintClip' => 'CropBox', # CropBox, BleedBox, TrimBox, ArtBox
        'PrintScaling' => 'AppDefault', # None, AppDefault
        'Duplex' => 'DuplexFlipLongEdge', # Simplex, DuplexFlipShortEdge, DuplexFlipLongEdge
        'PickTrayByPDFSize' => true,
        'PrintPageRange' => [1,1,2,3],
        'NumCopies' => 2
    }

    pdf = MYPDF.new
    pdf.set_viewer_preferences(preferences)
    out = pdf.putviewerpreferences()

    assert_equal '/ViewerPreferences << /Direction /L2R /HideToolbar true /HideMenubar true /HideWindowUI true /FitWindow true /CenterWindow true /DisplayDocTitle true /NonFullScreenPageMode /UseNone /ViewArea /CropBox /ViewClip /CropBox /PrintArea /CropBox /PrintClip /CropBox /PrintScaling /AppDefault /Duplex /DuplexFlipLongEdge /PickTrayByPDFSize true /PrintPageRange [0 0 1 2] /NumCopies 2 >>', out
  end
end
