#!/usr/bin/tclsh

package require Itcl
package require WebDriver
package require Error
package require OOSupport
package require Testing

set DATA_DIR "[file dirname [file normalize $::argv0]]/data"

#
# TEST CASES
#

::itcl::class TestWebDriverFailedCommand {
    inherit Testing::TestObject

    method test_webdriver_exception_on_invalid_javascript {} {
        docstr "Inject invalid JavaScript and expect a WebDriver exception to be thrown."

        set cap [namespace which [WebDriver::Capabilities #auto]]
        $cap set_browser_name "firefox"

        except {
            set session [WebDriver::Session #auto http://127.0.0.1:4444/wd/hub $cap]
            $session set_logging_enabled 1
            set window  [$session active_window]

            $window set_url "file://$::DATA_DIR/html/page1.html"

            # inject javascript
            set script {
                return no_var;
            }
            $window execute $script

            ::itcl::delete object $session
        } e {
            ::WebDriver::Error {
                ::itcl::delete object $session
                return 0
            }
        }

        error "injected script should have caused an exception to occur"
    }
}

exit [[TestWebDriverFailedCommand #auto] run $::argv]

