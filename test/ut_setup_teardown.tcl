#!/usr/bin/tclsh

package require Itcl
package require Error
package require Testing

::itcl::class TestSetupAndTeardown {
    inherit ::Testing::TestObject

    variable _setup_before_run_count 0
    variable _teardown_after_run_count 0

    variable _setup_run_count 0
    variable _teardown_run_count 0

    method setup_before {} {
        incr _setup_before_run_count
    }

    method teardown_after {} {
        incr _teardown_after_run_count
    }

    method setup {} {
        incr _setup_run_count
    }

    method teardown {} {
        incr _teardown_run_count
    }

    method test_01 {} {
        # noop
    }

    method test_02 {} {
        # noop
    }

    method this_is_not_a_test {} {
        # noop
    }

    method test_03_setup_teardown {} {
        docstr "Test that setup and teardown functions are called correctly."

        if {$_setup_before_run_count ne 1} {
            error "setup before should have run once but ran \
                ${_setup_before_run_count} times."
        }

        if {$_setup_run_count ne 3} {
            error "setup should have run 3 times but ran only \
                ${_setup_run_count} times."
        }

        if {$_teardown_run_count ne 2} {
            error "teardown should have run 2 times but ran only \
                ${_teardown_run_count} times."
        }

        if {$_teardown_after_run_count ne 0} {
            error "teardown after should not have but ran \
                ${_teardown_after_run_count} times."
        }
    }
}

exit [[TestSetupAndTeardown #auto] run $::argv]

