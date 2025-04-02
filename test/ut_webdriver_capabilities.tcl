#!/usr/bin/tclsh

package require WebDriver
package require OOSupport
package require Testing

#
# PREAMBLE
#

set CAPABILITIES_JSON \
{{
	"browserName": "firefox",
	"platformName": "windows",
	"pageLoadStrategy": "eager",
	"acceptInsecureCerts": true
}}

#
# TEST CASES
#

::itcl::class TestWebDriverCapabilities {
    inherit Testing::TestObject

    method test_webdriver_capabilities {} {
        docstr "Test that capabilities can be created and modified."

        WebDriver::Capabilities cap
        cap set_browser_name "firefox"
        cap set_platform_name "windows"
        cap set_page_load_strategy "eager"
        cap set_accept_insecure_certs true

        if {[cap to_json] == $::CAPABILITIES_JSON} {
            return 0
        }

        puts [cap to_json]

        error "error in JSON"
    }
}

exit [[TestWebDriverCapabilities #auto] run $::argv]

