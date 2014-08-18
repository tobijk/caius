#!/usr/bin/tclsh

package require Itcl
package require Testing

#
# PREAMBLE
#
itcl::class  MyTest {
    inherit Testing::TestObject

    method test_something {} {
        docstr "This tests something."
    }
}


#
# TEST CASES
#

::itcl::class TestDocstrings {
    inherit Testing::TestObject

    method test_extracting_docstring_from_test_method {} {
        docstr "Test extracting a docstring from a test method."

        set the_test [MyTest #auto]
        set the_doc_str [$the_test get_docstr test_something]

        if {$the_doc_str eq "This tests something."} {
            return
        }

        error "failed to extract docstring."
    }
}

exit [[TestDocstrings #auto] run $::argv]

