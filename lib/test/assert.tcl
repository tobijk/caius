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
package require Error

namespace eval Testing {

    ::itcl::class AssertionFailed {
        inherit Exception

        constructor {msg} {
            ::Exception::constructor "$msg"
        } {}

        destructor {}
    }

    proc assert {args} {
        if 1 "if {$args} {
            return 0 
        }"
        raise Testing::AssertionFailed "asserting '$args' failed"
    }
}

