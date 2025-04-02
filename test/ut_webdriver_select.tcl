#!/usr/bin/tclsh

package require Itcl
package require WebDriver
package require Error
package require Testing

set DATA_DIR "[file dirname [file normalize $::argv0]]/data"
set PAGE_URL "file://$DATA_DIR/html/page_select.html"

#
# TEST CASES
#

::itcl::class TestWebDriverCheckElements {
    inherit Testing::TestObject

    method test_handling_checkboxes {} {
        docstr "Test checking checkboxes and reading their state."

        set cap [namespace which [WebDriver::Capabilities #auto]]
        $cap set_browser_name "firefox"

        set session [WebDriver::Session #auto http://127.0.0.1:4444/wd/hub $cap]
        $session set_logging_enabled 1
        set window [$session active_window]

        $window set_url $::PAGE_URL

        set checkbox [$window element by_id id_enable]
        if {[$checkbox selected]} {
            error "checkbox should not be selected." 
        }

        $checkbox click
        if {![$checkbox selected]} {
            error "checkbox should be selected."
        }

        ::itcl::delete object $checkbox
        ::itcl::delete object $session
    }

    method test_handling_comboboxes {} {
        docstr "Test selecting from a combobox."

        set cap [namespace which [WebDriver::Capabilities #auto]]
        $cap set_browser_name "firefox"

        set session [WebDriver::Session #auto http://127.0.0.1:4444/wd/hub $cap]
        $session set_logging_enabled 1
        set window [$session active_window]

        $window set_url $::PAGE_URL

        set combobox [$window element by_id id_select]
        set option_b [$combobox descendant by_xpath "//option\[2]"]

        $option_b click

        if {![$option_b selected]} {
            error "B should be selected."
        }

        ::itcl::delete object $option_b
        ::itcl::delete object $combobox

        ::itcl::delete object $session
    }
}

exit [[TestWebDriverCheckElements #auto] run $::argv]

