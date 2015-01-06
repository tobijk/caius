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

    method test_markdown_converter_mdtest {} {
        docstr "Test the markdown converter on a variety of source files."

        run_suite mdtest
    }

    method test_markdown_converter_extra {} {
        docstr "Test the markdown converter on a variety of source files."

        run_suite caius
    }

    method run_suite {suite_name} {
        foreach {doc} [glob $::DATA_DIR/markdown/$suite_name/*.md] {
            puts "checking $doc"

            set markdown_file [file rootname $doc].md
            set html_file     [file rootname $doc].html

            set fp [open $markdown_file]
            set markdown [read $fp]
            close $fp

            set fp [open $html_file]
            set html [read $fp]
            close $fp

            set result [::Markdown::convert $markdown]

            if {$result ne $html} {
                error "conversion of '$markdown_file' didn't \
                    produce expected result"
            }
        }

        return
    }
}

exit [[TestMarkdown #auto] run $::argv]

