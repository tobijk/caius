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

        set cap [namespace which [::WebDriver::Capabilities #auto]]
        $cap set_browser_name "firefox"
        set session [::WebDriver::Session #auto http://127.0.0.1:4444/wd/hub $cap]

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
}

exit [[TestWebDriverWindow #auto] run $::argv]
