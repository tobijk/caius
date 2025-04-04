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
package require cmdline

namespace eval WebDriver {

    ::itcl::class Capabilities {

        common attributes {
            {string  browser_name            "chrome"    rw}
            {string  browser_version         ""          rw}
            {string  platform_name           "linux"     rw}
            {string  page_load_strategy      "normal"    rw}
            {bool    accept_insecure_certs   false       rw}
        }

        constructor {args} {
            OOSupport::init_attributes

            set options {
                {browser_name.arg            chrome   "the browser to use (chrome|firefox|ie|...)"}
                {browser_version.arg         ""       "the browser version (any)"}
                {platform_name.arg           linux    "platform to use (default: linux)"}
                {page_load_strategy.arg      normal   "page load strategy (normal|eager|none)"}
                {accept_insecure_certs.arg   false    "accept insecure SSL certificates (true|false)"}
            }

            array set params [::cmdline::getoptions args $options]

            foreach {key val} [array get params] {
                set _${key} $val
            }
        }

        destructor {}

        OOSupport::bless_attributes -json_support -collapse_underscore \
            -skip_undefined
    }
}
