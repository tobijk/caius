#
# The MIT License (MIT)
#
# Copyright (c) 2014 Caius Project
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#

package require Itcl
package require OOSupport
package require cmdline

namespace eval WebDriver {

    ::itcl::class Capabilities {

        common attributes {
            { string browser_name                "htmlunit"  rw }
            { string version                     ""          rw }
            { bool   platform                    ""          rw }
            { bool   javascript_enabled          true        rw }
            { bool   takes_screenshot            true        rw }
            { bool   handles_alerts              true        rw }
            { bool   database_enabled            true        rw }
            { bool   location_context_enabled    true        rw }
            { bool   application_cache_enabled   true        rw }
            { bool   browser_connection_enabled  true        rw }
            { bool   css_selectors_enabled       true        rw }
            { bool   web_storage_enabled         true        rw }
            { bool   rotatable                   true        rw }
            { bool   accept_ssl_certs            true        rw }
            { bool   native_events               false       rw }
            { ::WebDriver::Proxy  proxy          new         rw }
        }

        constructor {args} {
            OOSupport::init_attributes

            set options {
                {browser_name.arg               htmlunit "the browser to use (htmlunit|chrome|firefox|ie|...)"}
                {javascript_enabled.arg         true     "enable JavaScript (true|false)"}
                {takes_screenshot.arg           true     "enable taking screenshots (true|false)"}
                {handles_alerts.arg             true     "enable alert handling (true|false)"}
                {database_enabled.arg           true     "enable using browser database storage (true|false)"}
                {location_context_enabled.arg   true     "allow accessing the browser's location context (true|false)"}
                {application_cache_enabled.arg  true     "allow session to interact with application cache (true|false)"}
                {browser_connection_enabled.arg true     "allow querying and modifying browser connectivity (true|false)"}
                {css_selectors_enabled.arg      true     "enable use of CSS selectors (true|false)"}
                {web_storage_enabled.arg        true     "enable interaction with storage objects (true|false"}
                {rotatable.arg                  true     "enable rotation on mobile platforms (true|false)"}
                {accept_ssl_certs.arg           true     "accept all SSL certificates by default (true|false)"}
                {native_events.arg              false    "whether session can generate native input events (true|false)"}
                {proxy.arg                      new      "a WebDriver::Proxy object"}
            }

            array set params [::cmdline::getoptions args $options]

            foreach {key val} [array get params] {
                if {$key ne {proxy}} {
                    set _${key} $val
                } else {
                    if {$val ne {new}} {
                        set _${key} $val
                    }
                }
            }
        }

        destructor {}

        OOSupport::bless_attributes -json_support -collapse_underscore \
            -skip_undefined
    }

    ::itcl::class RequiredCapabilities {

        common attributes {
            { string browser_name                "htmlunit"  rw }
            { string version                     ""          rw }
            { bool   platform                    ""          rw }
            { bool   javascript_enabled          true        rw }
            { bool   takes_screenshot            true        rw }
            { bool   handles_alerts              true        rw }
            { bool   database_enabled            true        rw }
            { bool   location_context_enabled    true        rw }
            { bool   application_cache_enabled   true        rw }
            { bool   browser_connection_enabled  true        rw }
            { bool   css_selectors_enabled       true        rw }
            { bool   web_storage_enabled         true        rw }
            { bool   rotatable                   true        rw }
            { bool   accept_ssl_certs            true        rw }
            { bool   native_events               false       rw }
            { ::WebDriver::Proxy  proxy          new         rw }
        }

        constructor {} {}

        destructor {}

        OOSupport::bless_attributes -json_support -collapse_underscore \
            -skip_undefined
    }

    ::itcl::class DesiredAndRequiredCapabilities {

        common attributes {
            {::WebDriver::Capabilities          desired_capabilities   null  rw}
            {::WebDriver::RequiredCapabilities  required_capabilities  null  rw}
        }

        constructor {{desired_capabilities ""} \
            {required_capabilities ""}} \
        {
            OOSupport::init_attributes

            # set defaults
            if {$desired_capabilities == ""} {
                set _desired_capabilities [::WebDriver::Capabilities #auto]
            } else {
                set _desired_capabilities $desired_capabilities
            }

            if {$required_capabilities == ""} {
                set _required_capabilities [::WebDriver::RequiredCapabilities #auto]
            } else {
                set _required_capabilities $required_capabilities
            }
        }

        destructor {
            ::itcl::delete object $_desired_capabilities
            ::itcl::delete object $_desired_capabilities
        }

        OOSupport::bless_attributes -json_support -collapse_underscore \
            -skip_undefined
    }
}

