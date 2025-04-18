#!/usr/bin/tclsh

package require Itcl
package require WebDriver
package require Error
package require OOSupport
package require Testing

set DATA_DIR "[file dirname [file normalize $::argv0]]/data"
set PAGE1_URL "file://$DATA_DIR/html/page_click_alert.html"
set PAGE2_URL "file://$DATA_DIR/html/page_fill_prompt.html"

#
# TEST CASES
#

set CLICK_ME_TEXT "You clicked me!"

::itcl::class TestWebDriverAlerts {
    inherit Testing::TestObject

    method test_summon_alert {} {
        docstr "Test clicking on an element to summon a JavaScript alert and dismiss it."

        set cap [namespace which [WebDriver::Capabilities #auto]]
        $cap set_browser_name "firefox"

        set session [WebDriver::Session #auto http://127.0.0.1:4444/wd/hub $cap]

        $session set_logging_enabled 1
        set window [$session active_window]

        $window set_url $::PAGE1_URL
        set link [$window element by_id a:clickme]

        $link click
        set alert_text [$window alert_text]
        if {$alert_text != $::CLICK_ME_TEXT} {
            error "alert text should have been $::CLICK_ME_TEXT but is $alert_text."
        }

        $window dismiss_alert

        ::itcl::delete object $session
    }

    method test_fill_prompt {} {
        docstr "Test clicking on an element to summon a JavaScript prompt and fill it."

        set cap [namespace which [WebDriver::Capabilities #auto]]
        $cap set_browser_name "firefox"

        set session [WebDriver::Session #auto http://127.0.0.1:4444/wd/hub $cap]

        $session set_logging_enabled 1
        set window [$session active_window]

        $window set_url $::PAGE2_URL
        set link [$window element by_id a:clickme]

        $link click

        $window alert_send_text "John"
        $window accept_alert

        set input [$window element by_id input]
        if {[$input property value] ne "John"} {
            error "input field text is wrong."
        }

        ::itcl::delete object $session
    }

    method test_invoke_alert_methods_when_there_is_no_alert {} {
        docstr "Test alert methods when there is no alert."

        set cap [namespace which [WebDriver::Capabilities #auto]]
        $cap set_browser_name "firefox"

        set session [WebDriver::Session #auto http://127.0.0.1:4444/wd/hub $cap]

        $session set_logging_enabled 1
        set window [$session active_window]

        $window set_url $::PAGE2_URL

        set exception_raise 0

        except {
            $window alert_send_text "John"
        } e {
            ::WebDriver::NotFoundError {
                puts [$e msg]
                set exception_raised 1
            }
        }

        if {$exception_raised == 0} {
            error "alert_send_text should have raised an exception."
        }

        set exception_raised 0

        except {
            $window accept_alert
        } e {
            ::WebDriver::NotFoundError {
                puts [$e msg]
                set exception_raised 1
            }
        }

        if {$exception_raised == 0} {
            error "accept_alert should have raised an exception."
        }

        set exception_raised 0

        except {
            $window alert_text
        } e {
            ::WebDriver::NotFoundError {
                puts [$e msg]
                set exception_raised 1
            }
        }

        if {$exception_raised == 0} {
            error "alert_text should have raised an exception."
        }

        set exception_raised 0

        except {
            $window dismiss_alert
        } e {
            ::WebDriver::NotFoundError {
                puts [$e msg]
                set exception_raised 1
            }
        }

        if {$exception_raised == 0} {
            error "dismiss_alert should have raised an exception."
        }

        ::itcl::delete object $session
    }
}

exit [[TestWebDriverAlerts #auto] run $::argv]

