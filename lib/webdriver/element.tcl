#
# Caius Functional Testing Framework
#
# Copyright (c) 2013, Tobias Koch <tobias.koch@gmail.com>
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without modifi-
# cation, are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice,
#    this list of conditions and the following disclaimer.
#
# 2. Redistributions in binary form must reproduce the above copyright notice,
#    this list of conditions and the following disclaimer in the documentation
#    and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDER ``AS IS'' AND ANY EXPRESS
# OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
# OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN
# NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
# INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUD-
# ING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF
# USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
# THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUD-
# ING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFT-
# WARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
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
            return [list $value(x) $value(y)]
        }

        method size {} {
            set response [::WebDriver::Protocol::dispatch \
                [$_session session_url]/element/$_ELEMENT/size]
            array set value [$response value]
            ::itcl::delete $response
            return [list $value(width) $value(height)]
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

