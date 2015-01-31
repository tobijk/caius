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

    private variable _constrained_test_run 0

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

    ::Testing::constraints {win mac unix} {
        method test_constraints_01_should_never_run {} {
            set _constrained_test_run 1
        }
    }

    method test_constraints_02_check_test_not_run {} {
        docstr "Test that `test_constraints_01_should_never_run` was not run."

        if {$_constrained_test_run} {
            error "the constrained test case was executed."
        }
    }

    method test_constraints_03_constrain_code_blocks {} {
        docstr "Test that using constraints inline works."

        set block_1_run 0

        ::Testing::constraints {win mac unix} {
            set block_1_run 1
        }

        if {$block_1_run} {
            error "block 1 should not have been executed."
        }

        set block_2_run 0

        ::Testing::constraints {} {
            set block_2_run 1
        }

        if {!$block_2_run} {
            error "block 2 should have been executed."
        }
    }

    method test_custom_set_test_constraints {} {
        docstr "Test that setting constraints manually works."

        set block_1_run 0

        ::Testing::constraints {testConstraint} {
            set block_1_run 1
        }

        if {$block_1_run} {
            error "block 1 should not have been executed."
        }

        if {[::Testing::test_constraints testConstraint1]} {
            error "testConstraint1 has not been set."
        }

        if {[::Testing::test_constraints testConstraint1 testConstraint2]} {
            error "testConstraint1 and testConstraint2 have not been set."
        }

        ::Testing::set_constraint testConstraint1 1
        ::Testing::set_constraint testConstraint2 1

        set block_2_run 0

        ::Testing::constraints {testConstraint1 testConstraint2} {
            set block_2_run 1
        }

        if {!$block_2_run} {
            error "block 2 should have been executed."
        }

        if {![::Testing::test_constraints testConstraint1]} {
            error "testConstraint1 has been set."
        }

        if {![::Testing::test_constraints testConstraint1 testConstraint2]} {
            error "testConstraint1 and testConstraint2 have been set"
        }
    }
}

exit [[TestTesting #auto] run $::argv]

