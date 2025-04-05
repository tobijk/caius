#!/usr/bin/tclsh

package require WebDriver
package require OOSupport
package require Testing

#
# PREAMBLE
#

set COOKIE_JSON \
{{
	"name": "the_name",
	"value": "the_value",
	"path": "/foo",
	"domain": "bar.com",
	"secure": true,
	"httpOnly": true,
	"expiry": 1234567890
}}

#
# TEST CASES
#

::itcl::class TestWebDriverCookie {
    inherit Testing::TestObject

    method test_webdriver_cookie {} {
        docstr "Test that cookies are initialized correctly."

        set cookie [WebDriver::Cookie #auto the_name the_value]
        $cookie set_path /foo
        $cookie set_domain bar.com
        $cookie set_secure true
        $cookie set_http_only true
        $cookie set_expiry 1234567890

        puts [$cookie to_json]

        if {[$cookie to_json] == $::COOKIE_JSON} {
            return
        }

        error "error in JSON"
    }

    method test_webdriver_cookie_per_param_initialization {} {
        docstr "Test that cookies are initialized correctly."

        set cookie [ \
            WebDriver::Cookie #auto \
                -path /foo \
                -domain bar.com \
                -secure \
                -http_only \
                -expiry 1234567890 \
                    the_name the_value \
        ]

        puts [$cookie to_json]

        if {[$cookie to_json] == $::COOKIE_JSON} {
            return
        }

        error "error in JSON"
    }
}

exit [[TestWebDriverCookie #auto] run $::argv]

