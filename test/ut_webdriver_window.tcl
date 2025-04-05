#!/usr/bin/tclsh

package require Itcl
package require Thread
package require WebDriver
package require OOSupport
package require Testing
package require Subprocess

set DATA_DIR "[file dirname [file normalize $::argv0]]/data"
set PAGE1_URL "file://$DATA_DIR/html/page_text.html"
set PAGE2_URL "file://$DATA_DIR/html/page_fill_prompt.html"

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

        $window set_url $::PAGE1_URL
        $window execute "window.close()"

        except {
            $session active_window
        } e {
            ::WebDriver::HTTPError {
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

        $window set_url https://www.google.de
        $window execute {open("https://www.yahoo.de")}

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

    method test_go_back_and_forth_in_history {} {
        docstr "Go back and forth in history."

        set cap [namespace which [WebDriver::Capabilities #auto]]
        $cap set_browser_name "firefox"

        set session [WebDriver::Session #auto http://127.0.0.1:4444/wd/hub $cap]

        $session set_logging_enabled 1
        set window [$session active_window]

        $window set_url $::PAGE1_URL
        after 1000
        $window set_url $::PAGE2_URL
        after 1000
        $window back

        set current_url [$window url]
        if {$current_url ne $::PAGE1_URL} {
            error "current url should be $::PAGE1_URL but is $current_url."
        }

        $window forward
        set current_url [$window url]
        if {$current_url ne $::PAGE2_URL} {
            error "current url should be $::PAGE2_URL but is $current_url."
        }

        ::itcl::delete object $session
    }

    method test_get_and_set_size {} {
        docstr "Get and set window dimensions."

        set cap [namespace which [WebDriver::Capabilities #auto]]
        $cap set_browser_name "firefox"

        set session [WebDriver::Session #auto http://127.0.0.1:4444/wd/hub $cap]

        $session set_logging_enabled 1
        set window [$session active_window]

        $window set_url $::PAGE1_URL
        $window maximize

        after 500

        $window set_size 1024 768
        lassign [$window size] w h

        if {$w != 1024} {
            error "width should be 1024 but is $w."
        }
        if {$h != 768} {
            error "height should be 768 but is $h."
        }

        after 500

        $window set_size 1080 900
        lassign [$window size] w h

        if {$w != 1080} {
            error "width should be 1024 but is $w."
        }
        if {$h != 900} {
            error "height should be 768 but is $h."
        }

        ::itcl::delete object $session
    }

    method test_get_set_and_remove_cookies {} {
        docstr "Retrieve cookies, get, set, delete and purge."

        set cap [namespace which [WebDriver::Capabilities #auto]]
        $cap set_browser_name "firefox"

        set session [WebDriver::Session #auto http://127.0.0.1:4444/wd/hub $cap]

        $session set_logging_enabled 1
        set window [$session active_window]

        $window set_url "https://www.google.de"

        set num_cookies_before [llength [$window cookies]]
        $window set_cookie -path "/" test_cookie test_value
        set cookies [$window cookies]

        if {[llength $cookies] != [expr {$num_cookies_before + 1}]} {
            error "failed to add cookie."
        }

        foreach {cookie} $cookies {
            puts [$cookie to_json]
        }

        $window delete_cookie test_cookie
        set cookies [$window cookies]

        if {[llength $cookies] != $num_cookies_before} {
            error "failed to delete cookie."
        }

        $window purge_cookies
        set cookies [$window cookies]

        if {[llength $cookies] != 0} {
            error "failed to purge cookies."
        }

        ::itcl::delete object $session
    }
}

exit [[TestWebDriverWindow #auto] run $::argv]
