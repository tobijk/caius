#!/usr/bin/tclsh

package require Itcl
package require Thread
package require WebDriver
package require OOSupport
package require Testing
package require Subprocess

#
# TEST CASES
#

::itcl::class TestWebDriverSession {
    inherit Testing::TestObject

    method test_create_session_with_unfulfillable_capabilities {} {
        docstr "Create a session with an impossible configuration and expect an error."

        set cap [namespace which [::WebDriver::Capabilities #auto]]
        $cap set_browser_name "earthhog"

        except {
            set session [::WebDriver::Session #auto http://127.0.0.1:4444/wd/hub $cap]
        } e {
            ::WebDriver::ServerError {
                puts [$e msg]
                return
            }
        }

        error "an error should have been raised earlier."
    }
}

exit [[TestWebDriverSession #auto] run $::argv]
