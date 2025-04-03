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

::itcl::class TestWebDriverScreenshot {
    inherit Testing::TestObject

    method test_take_screenshot_and_check_file_type {} {
        docstr "Open google.com and take a screenshot."

        set cap [namespace which [::WebDriver::Capabilities #auto]]
        $cap set_browser_name "firefox"
        set result 0

        set session [::WebDriver::Session #auto http://127.0.0.1:4444/wd/hub $cap]
        $session set_logging_enabled 1
        set window  [$session active_window]

        $window set_url "https://www.google.com"

        set screenshot [$window screenshot -decode]

        # Save the screenshot to a file
        set filename "google.com.png"
        set filehandle [open $filename "w+b"]
        puts -nonewline $filehandle $screenshot
        close $filehandle

        # window is deleted as session property
        ::itcl::delete object $session

        set cmd [list bash -c {file google.com.png > google.com.png.type}]
        set proc [Subprocess::Popen #auto {*}$cmd]
        $proc wait
        ::itcl::delete object $proc

        set typefile [open "google.com.png.type" "r"]
        set filecontents [read $typefile]
        close $typefile

        if {![string match "*PNG image data*" $filecontents]} {
            error "screenshot does not look like a proper image file."
        }

        return
    }
}

exit [[TestWebDriverScreenshot #auto] run $::argv]
