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

            if {[llength $args] != 2} {
                raise ::WebDriver::Error "WebDriver::Cookie: insufficient arguments."
            }

            set _name  [lindex $args 0]
            set _value [lindex $args 1]
        }

        destructor {}

        # accessor functions and JSON support
        OOSupport::bless_attributes -json_support -collapse_underscore \
            -skip_undefined
    }
}

