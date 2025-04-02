#!/usr/bin/tclsh

package require Itcl
package require Thread
package require WebDriver
package require OOSupport
package require Testing

set DATA_DIR "[file dirname [file normalize $::argv0]]/data"

#
# TEST CASES
#

::itcl::class TestWebDriverExecute {
    inherit Testing::TestObject

    method test_inject_javascript_and_get_result {} {
        docstr "Inject a piece of JavaScript, execute it synchronously retrieve
        the result."

        set cap [namespace which [::WebDriver::Capabilities #auto]]
        $cap set_browser_name "firefox"
        set result 0

        set session [::WebDriver::Session #auto http://127.0.0.1:4444/wd/hub $cap]
        $session set_logging_enabled 1
        set window  [$session active_window]

        $window set_url "file://$::DATA_DIR/html/page1.html"

        # inject javascript
        set script {
            return Math.sqrt(arguments[0]);
        }
        set result [$window execute $script 144]

        # window is deleted as session property
        ::itcl::delete object $session

        if {$result != 12} {
            error "unexpected script result '$result'"
        }

        return
    }

    method test_run_javascript_asynchronously {} {
        docstr "Inject and run a piece of JavaScript asynchronously, wait on it
        and retrieve the result."

        set cap [namespace which [::WebDriver::Capabilities #auto]]
        $cap set_browser_name "firefox"
        set result 0

        set session [::WebDriver::Session #auto http://127.0.0.1:4444/wd/hub $cap]
        $session set_logging_enabled 1
        set window  [$session active_window]

        $window set_url "file://$::DATA_DIR/html/page1.html"

        set script {
            var callback = arguments[arguments.length - 1]
            var result = Math.sqrt(arguments[0]);
            callback(result);
        }

        set thread_id [$window execute_async -joinable \
            -result thread_shared result $script 169]
        ::thread::join $thread_id

        set result [::tsv::get thread_shared result]
        ::itcl::delete object $session

        if {$result != 13} {
            error "unexpected script result '$result'"
        }

        return
    }
}

exit [[TestWebDriverExecute #auto] run $::argv]

