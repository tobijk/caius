#!/usr/bin/tclsh

package require WebDriver
package require OOSupport
package require Testing

#
# PREAMBLE
#

set REQUIRED_CAPABILITIES_JSON \
{{
	"browserName": "chrome"
}}

set CAPABILITIES_JSON \
{{
	"browserName": "firefox",
	"javascriptEnabled": true,
	"takesScreenshot": true,
	"handlesAlerts": true,
	"databaseEnabled": true,
	"locationContextEnabled": true,
	"applicationCacheEnabled": true,
	"browserConnectionEnabled": true,
	"cssSelectorsEnabled": true,
	"webStorageEnabled": true,
	"rotatable": true,
	"acceptSslCerts": true,
	"nativeEvents": false,
	"proxy":
	{
		"proxyType": "direct"
	}
}}

#
# TEST CASES
#

::itcl::class TestWebDriverCapabilities {
    inherit Testing::TestObject

    method test_webdriver_capabilities {} {
        docstr "Test that capabilities can be created and modified."

        WebDriver::Capabilities cap
        cap set_browser_name firefox

        if {[cap to_json] == $::CAPABILITIES_JSON} {
            return 0
        }

        puts [cap to_json]

        error "error in JSON"
    }

    method test_webdriver_required_capabilities {} {
        docstr "Test that required capabilities can be created an modified."

        set req_cap [WebDriver::RequiredCapabilities #auto]
        $req_cap set_browser_name chrome

        if {[$req_cap to_json] == $::REQUIRED_CAPABILITIES_JSON} {
            return 0
        }

        error "error in JSON"
    }
}

exit [[TestWebDriverCapabilities #auto] run $::argv]

