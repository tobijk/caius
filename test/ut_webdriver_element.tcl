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
        $cap set_browser_name "chrome"

        set session [WebDriver::Session #auto http://127.0.0.1:4444/wd/hub $cap]
        $session set_logging_enabled 1
        set window [$session active_window]

        $window set_url $::PAGE_URL

        set label [$window element by_id label]
        if {[$label text] ne $::LABEL_TEXT} {
            error "label text is not correct or encoding problem."
        }

        set input [$window element by_id input]
        if {[$input attribute value] ne $::INPUT_TEXT} {
            error "input field text is wrong."
        }

        $input click
        $input clear

        set ::INPUT_TEXT [encoding convertfrom "utf-8" "Hello World! ÄÖÜß"]
        $input send_keys $::INPUT_TEXT

        if {[$input attribute value] ne $::INPUT_TEXT} {
            error "input field text wrong or encoding problem."
        }

        if {[$input tag_name] ne "input"} {
            error "input element has wrong tag name."
        }

        if {![$input enabled]} {
            error "input element should be enabled."
        }

        set input_ [$window element by_id input]

        if {![$input equals $input_]} {
            error "references should point to same element."
        }

        ::itcl::delete object $label
        ::itcl::delete object $input
        ::itcl::delete object $input_
        ::itcl::delete object $session

        return
    }
}

exit [[TestWebDriverElementAccess #auto] run $::argv]

