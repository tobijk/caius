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

::itcl::class TestTesting {
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

    method test_assertions_simple {} {
        docstr "Test raising assertions as `::Testing::assert {<expression>}`
        works"

        set a 1
        set b 0

        set assertion_raised 0

        except {
            ::Testing::assert {$a == $b}
        } e {
            ::TclError {
                puts [$e msg]
            }
            ::Testing::AssertionFailed {
                set assertion_raised 1
            }
        }

        if {!$assertion_raised} {
            error "an assertion should have been raised."
        }
    }

    method test_assertions_with_command {} {
        docstr "Test raising assertions as `::Testing::assert {\[cmd]}`
        works"

        set x -1

        set assertion_raised 0

        except {
            ::Testing::assert {[expr $x + 1]}
        } e {
            ::TclError {
                puts [$e msg]
            }
            ::Testing::AssertionFailed {
                set assertion_raised 1
            }
        }

        if {!$assertion_raised} {
            error "an assertion should have been raised."
        }
    }

}

exit [[TestTesting #auto] run $::argv]

