#
#   Caius Functional Testing Framework
#
#   Copyright 2013 Tobias Koch <tobias.koch@gmail.com>
#
#   This program is free software; you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation; either version 2 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#
#   See the LICENSE file in the source distribution for more information.
#

package require Itcl
package require OOSupport

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
            { bool   native_events               true        rw }
            { ::WebDriver::Proxy  proxy          new         rw }
        }

        constructor {} {
            OOSupport::init_attributes
        }

        destructor {}

        OOSupport::bless_attributes -json_support -collapse_underscore \
            -skip_undefined
    }

    ::itcl::class RequiredCapabilities {

        common attributes $WebDriver::Capabilities::attributes

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

