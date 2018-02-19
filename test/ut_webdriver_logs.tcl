#!/usr/bin/tclsh

package require Itcl
package require WebDriver
package require Error
package require OOSupport
package require Testing

set CAPTURE ""

proc new_puts {args} {
    puts $args
}

#
# TEST CASES
#

::itcl::class TestWebDriverLogging {
    inherit Testing::TestObject

    method test_retrieve_driver_log {} {
        docstr "Fetch the driver log types and server log."

        set cap [namespace which [WebDriver::Capabilities #auto]]
        $cap set_browser_name "chrome"
        $cap set_native_events 1

        set session [WebDriver::Session #auto http://127.0.0.1:4444/wd/hub $cap]
        $session set_logging_enabled 1

        set log_types [$session log_types]
        if {[list length $log_types] < 4} {
            error "expected at least four standard log types."
        }

        set log [$session get_log server]
        if {[string length $log] == 0} {
            error "expected server log not to be empty."
        }

        ::itcl::delete object $session

        return
    }
}

exit [[TestWebDriverLogging #auto] run $::argv]

