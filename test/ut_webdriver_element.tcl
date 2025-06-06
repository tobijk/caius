#!/usr/bin/tclsh

package require Itcl
package require WebDriver
package require Error
package require OOSupport
package require Testing

set DATA_DIR "[file dirname [file normalize $::argv0]]/data"
set PAGE_URL "file://$DATA_DIR/html/page_text.html"

#
# TEST CASES
#

set LABEL_TEXT "Label Text"
set INPUT_TEXT "Input Field"

::itcl::class TestWebDriverElementAccess {
    inherit Testing::TestObject

    method test_reading_and_setting_elements {} {
        docstr "Test locating elements, getting content, clicking and sending
        text."

        set cap [namespace which [WebDriver::Capabilities #auto]]
        $cap set_browser_name "firefox"

        set session [WebDriver::Session #auto http://127.0.0.1:4444/wd/hub $cap]
        $session set_logging_enabled 1
        set window [$session active_window]

        $window set_url $::PAGE_URL

        set label [$window element by_id label]
        if {[$label text] ne $::LABEL_TEXT} {
            error "label text is not correct or encoding problem."
        }

        set input [$window element by_id input]
        if {[$input property value] ne $::INPUT_TEXT} {
            error "input field text is wrong."
        }

        lassign [$input location] x y
        if {$x == 0 || $y == 0} {
            error "failed to fetch element location."
        }

        $input click
        $input clear

        if {[$input displayed] ne true} {
            error "input field should be visisble."
        }

        set ::INPUT_TEXT [encoding convertfrom "utf-8" "Hello World! ÄÖÜß"]
        $input send_keys $::INPUT_TEXT

        if {[$input displayed] ne true} {
            error "input field should be visisble."
        }

        if {[$input property value] ne $::INPUT_TEXT} {
            error "input field text wrong or encoding problem."
        }

        if {[$input tag_name] ne "input"} {
            error "input element has wrong tag name."
        }

        if {![$input enabled]} {
            error "input element should be enabled."
        }

        ::itcl::delete object $label
        ::itcl::delete object $input
        ::itcl::delete object $session

        return
    }

    method test_retrieving_multiple_elements {} {
        docstr "Test retrieving multiple elements matching same locator."

        set cap [namespace which [WebDriver::Capabilities #auto]]
        $cap set_browser_name "firefox"

        set session [WebDriver::Session #auto http://127.0.0.1:4444/wd/hub $cap]
        $session set_logging_enabled 1
        set window [$session active_window]

        $window set_url $::PAGE_URL

        set list_items [$window elements by_tag_name "li"]

        ::Testing::assert {[llength $list_items] == 3}

        foreach {ref} $list_items {
            ::itcl::delete object $ref
        }

        ::itcl::delete object $session
    }

    method test_retrieving_non_existent_element {} {
        docstr "Test that retrieving an unavailable element returns nothing."

        set cap [namespace which [WebDriver::Capabilities #auto]]
        $cap set_browser_name "firefox"

        set session [WebDriver::Session #auto http://127.0.0.1:4444/wd/hub $cap]
        $session set_logging_enabled 1
        set window [$session active_window]

        $window set_url $::PAGE_URL

        except {
            set element [$window element by_id "no-such-element"]
        } e {
            ::WebDriver::NotFoundError {
                puts [$e msg]
                return
            }
        } final {
            ::itcl::delete object $session
        }

        error "an error sould have been thrown earlier"
    }

    method test_retrieving_by_invalid_xpath {} {
        docstr "Test that supplying an invalid xpath throws an error."

        set cap [namespace which [WebDriver::Capabilities #auto]]
        $cap set_browser_name "firefox"

        set session [WebDriver::Session #auto http://127.0.0.1:4444/wd/hub $cap]
        $session set_logging_enabled 1
        set window [$session active_window]

        $window set_url $::PAGE_URL

        except {
            $window elements by_xpath "("
        } e {
            ::WebDriver::InvalidRequestError {
                puts [$e msg]
                return
            }
        } final {
            ::itcl::delete object $session
        }

        error "invalid xpath should have thrown an error."
    }
}

exit [[TestWebDriverElementAccess #auto] run $::argv]

