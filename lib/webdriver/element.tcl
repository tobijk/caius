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

    ::itcl::class WebElement {

        common attributes {
            {string ELEMENT "" rw}
        }

        # not serializable
        private variable _session

        constructor {session} {
            OOSupport::init_attributes
            set _session $session
        }

        destructor {}

        OOSupport::bless_attributes -json_support -skip_undefined \
            -collapse_underscore

        method descendant {by locator} {
            return [namespace inscope ::WebDriver::Session \
                $_session __elements $by "$locator" "$this" true]
        }

        method descendants {by locator} {
            return [namespace inscope ::WebDriver::Session \
                $_session __elements $by "$locator" "$this" false]
        }

        method move_to {{xoffset null} {yoffset null}} {
            set json "{ \"element\": \"[$this ELEMENT]\""
            if {($xoffset ne "null") && ($yoffset ne "null")} {
                set json "$json, \"xoffset\": $xoffset, \"yoffset\": $yoffset"
            }
            set json "$json }"

            set response [::WebDriver::Protocol::dispatch \
                -query $json \
                [$_session session_url]/moveto]
            ::itcl::delete $response
        }

        method click {} {
            set response [::WebDriver::Protocol::dispatch \
                -method POST \
                [$_session session_url]/element/$_ELEMENT/click]
            ::itcl::delete object $response
        }

        method submit {} {
            set response [::WebDriver::Protocol::dispatch \
                -method POST \
                [$_session session_url]/element/$_ELEMENT/submit]
            ::itcl::delete object $response
        }

        method text {} {
            set response [::WebDriver::Protocol::dispatch \
                [$_session session_url]/element/$_ELEMENT/text]
            set element_text [encoding convertfrom "utf-8" [$response value]]
            ::itcl::delete object $response
            return $element_text
        }

        method send_keys {text} {
            set json "{\"value\": \[\"[OOSupport::json_escape_chars $text]\"]}"
            set response [::WebDriver::Protocol::dispatch \
                -query $json \
                [$_session session_url]/element/$_ELEMENT/value]
            ::itcl::delete object $response
        }

        method tag_name {} {
            set response [::WebDriver::Protocol::dispatch \
                [$_session session_url]/element/$_ELEMENT/name]
            set tag_name [encoding convertfrom "utf-8" [$response value]]
            ::itcl::delete object $response
            return $tag_name
        }

        method clear {} {
            set response [::WebDriver::Protocol::dispatch \
                -method POST \
                [$_session session_url]/element/$_ELEMENT/clear]
            ::itcl::delete object $response
        }

        method selected {} {
            set response [::WebDriver::Protocol::dispatch \
                [$_session session_url]/element/$_ELEMENT/selected]
            set value [$response value]
            ::itcl::delete object $response
            return $value
        }

        method enabled {} {
            set response [::WebDriver::Protocol::dispatch \
                [$_session session_url]/element/$_ELEMENT/enabled]
            set value [$response value]
            ::itcl::delete object $response
            return $value
        }

        method attribute {attr_name} {
            set response [::WebDriver::Protocol::dispatch \
                [$_session session_url]/element/$_ELEMENT/attribute/$attr_name]
            set value [$response value]
            ::itcl::delete object $response
            return [encoding convertfrom "utf-8" $value]
        }

        method equals {other} {
            set other_id [$other ELEMENT]
            set response [::WebDriver::Protocol::dispatch \
                [$_session session_url]/element/$_ELEMENT/equals/$other_id]
            set value [$response value]
            ::itcl::delete object $response
            return $value
        }

        method displayed {} {
            set response [::WebDriver::Protocol::dispatch \
                [$_session session_url]/element/$_ELEMENT/displayed]
            set value [$response value]
            ::itcl::delete object $response
            return $value
        }

        method location {} {
            set response [::WebDriver::Protocol::dispatch \
                [$_session session_url]/element/$_ELEMENT/location]
            array set value [$response value]
            ::itcl::delete $response
            return [list $array(x) $array(y)]
        }

        method size {} {
            set response [::WebDriver::Protocol::dispatch \
                [$_session session_url]/element/$_ELEMENT/size]
            array set value [$response value]
            ::itcl::delete $response
            return [list $array(width) $array(height)]
        }

        method css_property {css_property} {
            set response [::WebDriver::Protocol::dispatch \
                [$_session session_url]/element/$_ELEMENT/css/$css_property]
            set value [encoding convertfrom "utf-8" [$response value]]
            ::itcl::delete $response
            return $value
        }
    }
}

