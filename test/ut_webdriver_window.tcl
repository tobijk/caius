#!/usr/bin/tclsh

package require Itcl
package require Thread
package require WebDriver
package require OOSupport
package require Testing
package require Subprocess

set DATA_DIR "[file dirname [file normalize $::argv0]]/data"
set PAGE_URL "file://$DATA_DIR/html/page_text.html"

#
# TEST CASES
#

::itcl::class TestWebDriverWindow {
    inherit Testing::TestObject

    method test_calling_active_window_fails_if_window_closed {} {
        docstr "Close a window and then try to access its handle, expect an error."

        set cap [namespace which [::WebDriver::Capabilities #auto -browser_name firefox]]
        set session [::WebDriver::Session #auto http://127.0.0.1:4444/wd/hub $cap]

        $session set_logging_enabled true
        set window [$session active_window]

        $window set_url $::PAGE_URL
        $window execute "window.close()"

        except {
            $session active_window
        } e {
            ::WebDriver::NotFoundError {
                puts [$e msg]
                return
            }
        } final {
            ::itcl::delete object $session
        }

        error "an error should have been raised earlier."
    }

    method test_multiple_windows {} {
        docstr "Open two windows an switch in between them."

        set cap [namespace which [WebDriver::Capabilities #auto -browser_name firefox]]
        set session [WebDriver::Session #auto http://127.0.0.1:4444/wd/hub $cap]

        $session set_logging_enabled true
        set window [$session active_window]

        $window set_url http://www.google.de
        $window execute {open("http://www.yahoo.de")}

        set session_windows [$session windows]

        if {[llength $session_windows] != 2} {
            error "session_windows should have two entries."
        }

        # Switch focus back and forth between the windows.
        for {set i 0} {$i < 10} {incr i} {
            set j [expr $i % 2]

            [lindex $session_windows $j] focus
            set current_window [$session active_window]

            if {![string equal $current_window [lindex $session_windows $j]]} {
                error "window focus should be on window $j."
            }
        }

        ::itcl::delete object $session
    }
}

exit [[TestWebDriverWindow #auto] run $::argv]
