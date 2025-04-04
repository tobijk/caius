#
# The MIT License (MIT)
#
# Copyright (c) 2014-2021 Tobias Koch <tobias.koch@gmail.com>
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

    ::itcl::class Cookie {

        common attributes {
            { string name      ""   "rw" }
            { string value     ""   "rw" }
            { string path      "/"  "rw" }
            { string domain    ""   "rw" }
            { bool   secure    null "rw" }
            { bool   http_only null "rw" }
            { number expiry    null "rw" }
        }

        constructor {args} {
            OOSupport::init_attributes

            set options {
                {path.arg      "/"  "the cookie path"}
                {domain.arg    ""   "the domain"}
                {secure.arg    null "whether the cookie is secure"}
                {http_only.arg null "whether the cookie is for http only"}
                {expiry.arg    null "timestamp marking the expiration date"}
            }

            array set params [::cmdline::getoptions args $options]

            foreach {key val} [array get params] {
                set _${key} $val
            }

            if {[llength $args] != 0} {
                if {[llength $args] != 2} {
                    raise ::WebDriver::Error "WebDriver::Cookie: invalid number of arguments."
                }

                set _name  [lindex $args 0]
                set _value [lindex $args 1]
            }
        }

        destructor {}

        # accessor functions and JSON support
        OOSupport::bless_attributes -json_support -collapse_underscore \
            -skip_undefined
    }
}
