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
        docstr "Test that capabilities are correctly initialized."

        set cap [WebDriver::Capabilities #auto]
        $cap set_browser_name "firefox"
        $cap set_platform_name "windows"
        $cap set_page_load_strategy "eager"
        $cap set_accept_insecure_certs true

        puts [$cap to_json]

        if {[$cap to_json] == $::CAPABILITIES_JSON} {
            return
        }

        error "error in JSON"
    }

    method test_webdriver_capabilities_per_param_initialization {} {
        docstr "Test that capabilities are correctly initialized."

        set cap [ \
            WebDriver::Capabilities #auto \
                -accept_insecure_certs \
                -browser_name firefox \
                -platform_name windows \
                -page_load_strategy eager \
        ]

        puts [$cap to_json]

        if {[$cap to_json] == $::CAPABILITIES_JSON} {
            return
        }

        error "error in JSON"
    }
}

exit [[TestWebDriverCapabilities #auto] run $::argv]

