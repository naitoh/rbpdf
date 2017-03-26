# Copyright (c) 2011-2017 NAITOH Jun
# Released under the MIT license
# http://www.opensource.org/licenses/MIT

require 'test_helper'

class RbpdfTest < Test::Unit::TestCase
  test "bookmark test" do
    pdf = RBPDF.new
    pdf.add_page()

    # Adds a bookmark.
    # [@param string :txt] bookmark description.
    # [@param int :level] bookmark level.
    # [@param float :y] Ordinate of the boorkmark position (default = -1 = current position).
    # [@param int :page] target page number (leave empty for current page).

    book = pdf.bookmark('Chapter 1', 0, 0)
    assert_equal [{:l=>0, :y=>0, :t=>"Chapter 1", :p=>1}], book

    book = pdf.bookmark('Paragraph 1.1', 1, 0)
    assert_equal [{:y=>0, :l=>0, :t=>"Chapter 1", :p=>1},
                  {:y=>0, :l=>1, :t=>"Paragraph 1.1", :p=>1}], book

    pdf.add_page()

    book = pdf.bookmark('Paragraph 1.2', 1, 0)
    assert_equal [{:y=>0, :l=>0, :t=>"Chapter 1", :p=>1},
                  {:y=>0, :l=>1, :t=>"Paragraph 1.1", :p=>1},
                  {:y=>0, :l=>1, :t=>"Paragraph 1.2", :p=>2}], book

    book = pdf.bookmark('Sub-Paragraph 1.2.1', 2, 10)
    assert_equal [{:y=>0, :l=>0, :t=>"Chapter 1", :p=>1},
                  {:y=>0, :l=>1, :t=>"Paragraph 1.1", :p=>1},
                  {:y=>0, :l=>1, :t=>"Paragraph 1.2", :p=>2},
                  {:y=>10, :l=>2, :t=>"Sub-Paragraph 1.2.1", :p=>2}], book

    pdf.add_page()

    book = pdf.bookmark('Paragraph 1.3', 1, 0)
    assert_equal [{:y=>0, :l=>0, :t=>"Chapter 1", :p=>1},
                  {:y=>0, :l=>1, :t=>"Paragraph 1.1", :p=>1},
                  {:y=>0, :l=>1, :t=>"Paragraph 1.2", :p=>2},
                  {:y=>10, :l=>2, :t=>"Sub-Paragraph 1.2.1", :p=>2},
                  {:y=>0, :l=>1, :t=>"Paragraph 1.3", :p=>3}], book

    book = pdf.bookmark('Sub-Paragraph 1.1.1', 2, 0, 2)
    assert_equal [{:y=>0, :l=>0, :t=>"Chapter 1", :p=>1},
                  {:y=>0, :l=>1, :t=>"Paragraph 1.1", :p=>1},
                  {:y=>0, :l=>1, :t=>"Paragraph 1.2", :p=>2},
                  {:y=>10, :l=>2, :t=>"Sub-Paragraph 1.2.1", :p=>2},
                  {:y=>0, :l=>1, :t=>"Paragraph 1.3", :p=>3},
                  {:y=>0, :l=>2, :t=>"Sub-Paragraph 1.1.1", :p=>2}], book

    pdf.add_page()

    book = pdf.bookmark('Paragraph 1.4', 1, 20)
    assert_equal [{:y=>0, :l=>0, :t=>"Chapter 1", :p=>1},
                  {:y=>0, :l=>1, :t=>"Paragraph 1.1", :p=>1},
                  {:y=>0, :l=>1, :t=>"Paragraph 1.2", :p=>2},
                  {:y=>10, :l=>2, :t=>"Sub-Paragraph 1.2.1", :p=>2},
                  {:y=>0, :l=>1, :t=>"Paragraph 1.3", :p=>3},
                  {:y=>0, :l=>2, :t=>"Sub-Paragraph 1.1.1", :p=>2},
                  {:y=>20, :l=>1, :t=>"Paragraph 1.4", :p=>4}], book
  end
end
