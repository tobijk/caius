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

    ::itcl::class Proxy {

        common attributes {
            { string  proxy_type            "direct"  rw }
            { string  proxy_autoconfig_url  ""        rw }
            { string  ftp_proxy             ""        rw }
            { string  http_proxy            ""        rw }
            { string  ssl_proxy             ""        rw }
        }

        constructor {} {
            OOSupport::init_attributes
        }

        destructor {}

        OOSupport::bless_attributes -json_support -collapse_underscore \
            -skip_undefined
    }
}

