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

::itcl::class Exception {

    common attributes {
        { string stack_trace ""   rw }
        { string code        ""   rw }
        { number line        null rw }
    }

    private variable _msg

    constructor {msg} {
        OOSupport::init_attributes
        set _msg $msg
    }

    destructor {}

    OOSupport::bless_attributes

    method msg {} {
        return $_msg
    }
}

::itcl::class RuntimeError {
    inherit ::Exception

    constructor {msg} { ::Exception::constructor $msg } {}
    destructor {}
}

::itcl::class ValueError {
    inherit ::RuntimeError

    constructor {msg} { ::RuntimeError::constructor $msg } {}
    destructor {}
}

::itcl::class TclError {
    inherit ::RuntimeError


    constructor {msg} { ::RuntimeError::constructor $msg } {}

    destructor {}
}

