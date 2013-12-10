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

    method set_stack_trace {stack_trace} {
        $this ::Exception::set_stack_trace "::TclError: $stack_trace"
    }
}

