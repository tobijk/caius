#!/usr/bin/tclsh

package require Itcl
package require Testing
package require Markdown

set DATA_DIR "[file dirname [file normalize $::argv0]]/data"

#
# TEST CASES
#

::itcl::class TestMarkdown {
    inherit Testing::TestObject

    method test_markdown_converter {} {
        docstr "Test the markdown converter on a variety of source files"

        foreach {doc} {bq code inline lists p_br_h_hr} {
            set markdown_file $::DATA_DIR/markdown/$doc.text
            set html_file     $::DATA_DIR/markdown/$doc.html

            set fp [open $markdown_file]
            set markdown [read $fp]
            close $fp

            set fp [open $html_file]
            set html [read $fp]
            close $fp

            set result [::markdown::convert $markdown]

            if {$result ne $html} {
                error "conversion of '$markdown_file' didn't \
                    produce expected result"
            }
        }

        return
    }
}

exit [[TestMarkdown #auto] run $::argv]

