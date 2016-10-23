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

namespace eval WebDriver {

    ::itcl::class WebElement {

        common attributes {
            {string ELEMENT "" rw}
            {string "element-6066-11e4-a52e-4f735466cecf" "" rw}
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

        method web_element_id {} {
            if {$_ELEMENT ne {}} {
                return $_ELEMENT
            } else {
                return ${_element-6066-11e4-a52e-4f735466cecf}
            }
        }

        method descendant {by locator} {
            return [namespace inscope ::WebDriver::Session \
                $_session __elements $by "$locator" "$this" true]
        }

        method descendants {by locator} {
            return [namespace inscope ::WebDriver::Session \
                $_session __elements $by "$locator" "$this" false]
        }

        method move_to {{xoffset null} {yoffset null}} {
            set json "{ \"element\": \"[$this web_element_id]\""
            if {($xoffset ne "null") && ($yoffset ne "null")} {
                set json "$json, \"xoffset\": $xoffset, \"yoffset\": $yoffset"
            }
            set json "$json }"

            if {[$_session logging_enabled]} {
                ::WebDriver::log [$_session session_id] \
                    "move to $json"
            }

            set response [::WebDriver::Protocol::dispatch \
                -query $json \
                [$_session session_url]/moveto]
            ::itcl::delete object $response
        }

        method click {} {
            if {[$_session logging_enabled]} {
                ::WebDriver::log [$_session session_id] \
                    "click element [$this web_element_id]"
            }

            set response [::WebDriver::Protocol::dispatch \
                -query "{}" \
                [$_session session_url]/element/[$this web_element_id]/click]
            ::itcl::delete object $response
        }

        method submit {} {
            if {[$_session logging_enabled]} {
                ::WebDriver::log [$_session session_id] \
                    "submit form"
            }

            set response [::WebDriver::Protocol::dispatch \
                -query "{}" \
                [$_session session_url]/element/[$this web_element_id]/submit]
            ::itcl::delete object $response
        }

        method text {} {
            set response [::WebDriver::Protocol::dispatch \
                [$_session session_url]/element/[$this web_element_id]/text]
            set element_text [encoding convertfrom "utf-8" [$response value]]
            ::itcl::delete object $response

            if {[$_session logging_enabled]} {
                ::WebDriver::log [$_session session_id] \
                    "element [$this web_element_id] text: $element_text"
            }

            return $element_text
        }

        method send_keys {text} {
            set text [OOSupport::json_escape_chars $text]

            if {[$_session logging_enabled]} {
                ::WebDriver::log [$_session session_id] \
                    "send keys to element [$this web_element_id]: $text"
            }

            set json [encoding convertto "utf-8" "{\"value\": \[\"$text\"]}"]
            set response [::WebDriver::Protocol::dispatch \
                -query $json \
                [$_session session_url]/element/[$this web_element_id]/value]
            ::itcl::delete object $response
        }

        method tag_name {} {
            set response [::WebDriver::Protocol::dispatch \
                [$_session session_url]/element/[$this web_element_id]/name]
            set tag_name [encoding convertfrom "utf-8" [$response value]]

            if {[$_session logging_enabled]} {
                ::WebDriver::log [$_session session_id] \
                    "element [$this web_element_id] tag name: $tag_name"
            }

            ::itcl::delete object $response
            return $tag_name
        }

        method clear {} {
            if {[$_session logging_enabled]} {
                ::WebDriver::log [$_session session_id] \
                    "clear element [$this web_element_id]"
            }

            set response [::WebDriver::Protocol::dispatch \
                -query "{}" \
                [$_session session_url]/element/[$this web_element_id]/clear]
            ::itcl::delete object $response
        }

        method selected {} {
            set response [::WebDriver::Protocol::dispatch \
                [$_session session_url]/element/[$this web_element_id]/selected]
            set value [$response value]
            ::itcl::delete object $response

            if {[$_session logging_enabled]} {
                ::WebDriver::log [$_session session_id] \
                    "element [$this web_element_id] selected: $value"
            }

            return $value
        }

        method enabled {} {
            set response [::WebDriver::Protocol::dispatch \
                [$_session session_url]/element/[$this web_element_id]/enabled]
            set value [$response value]
            ::itcl::delete object $response

            if {[$_session logging_enabled]} {
                ::WebDriver::log [$_session session_id] \
                    "element [$this web_element_id] enabled: $value"
            }

            return $value
        }

        method attribute {attr_name} {
            set response [::WebDriver::Protocol::dispatch \
                [$_session session_url]/element/[$this web_element_id]/attribute/$attr_name]
            set value [encoding convertfrom "utf-8" [$response value]]
            ::itcl::delete object $response

            if {[$_session logging_enabled]} {
                ::WebDriver::log [$_session session_id] \
                    "element [$this web_element_id] attribute $attr_name: $value"
            }

            return $value
        }

        method equals {other} {
            set other_id [$other web_element_id]
            set response [::WebDriver::Protocol::dispatch \
                [$_session session_url]/element/[$this web_element_id]/equals/$other_id]
            set value [$response value]
            ::itcl::delete object $response

            if {[$_session logging_enabled]} {
                ::WebDriver::log [$_session session_id] \
                    "element [$this web_element_id] equals $other_id: $value"
            }

            return $value
        }

        method displayed {} {
            set response [::WebDriver::Protocol::dispatch \
                [$_session session_url]/element/[$this web_element_id]/displayed]
            set value [$response value]
            ::itcl::delete object $response

            if {[$_session logging_enabled]} {
                ::WebDriver::log [$_session session_id] \
                    "element [$this web_element_id] displayed: $value"
            }

            return $value
        }

        method location {} {
            set response [::WebDriver::Protocol::dispatch \
                [$_session session_url]/element/[$this web_element_id]/location]
            array set value [$response value]
            ::itcl::delete $response

            if {[$_session logging_enabled]} {
                ::WebDriver::log [$_session session_id] \
                    "element [$this web_element_id] location: ($value(x), $value(y))"
            }

            return [list $value(x) $value(y)]
        }

        method size {} {
            set response [::WebDriver::Protocol::dispatch \
                [$_session session_url]/element/[$this web_element_id]/size]
            array set value [$response value]
            ::itcl::delete $response

            if {[$_session logging_enabled]} {
                ::WebDriver::log [$_session session_id] \
                    "element [$this web_element_id] size: $value(width)x$value(height)"
            }

            return [list $value(width) $value(height)]
        }

        method css_property {css_property} {
            set response [::WebDriver::Protocol::dispatch \
                [$_session session_url]/element/[$this web_element_id]/css/$css_property]
            set value [encoding convertfrom "utf-8" [$response value]]
            ::itcl::delete $response

            if {[$_session logging_enabled]} {
                ::WebDriver::log [$_session session_id] \
                    "element [$this web_element_id] $css_property: $value"
            }

            return $value
        }
    }
}

