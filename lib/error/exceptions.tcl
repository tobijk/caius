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

## \file
# \brief Definition of core exception classes.

package require Itcl
package require OOSupport

## 
# \brief The mother of all exceptions.
#
# While it is not mandatory, it is recommended that all custom exception
# classes derive from Exception.
#
::itcl::class Exception {

    common attributes {
        { string stack_trace ""   rw }
        { string code        ""   rw }
        { number line        null rw }
    }

    ## \private
    private variable _msg

    ## 
    # @param msg  a string describing the exception that occurred.
    constructor {msg} {
        OOSupport::init_attributes
        set _msg $msg
    }

    destructor {}

    OOSupport::bless_attributes

    ##
    # Returns the description stored with the exception.
    method msg {} {
        return $_msg
    }
}

##
# \brief Execption that indicates a generic runtime error.
::itcl::class RuntimeError {
    inherit ::Exception

    constructor {msg} { ::Exception::constructor $msg } {}
    destructor {}
}

##
# \brief Exception that indicates a data type or format mismatch.
::itcl::class ValueError {
    inherit ::RuntimeError

    constructor {msg} { ::RuntimeError::constructor $msg } {}
    destructor {}
}

##
# \brief This exception is thrown, when a timeout occurs.
::itcl::class TimeoutError {
    inherit ::RuntimeError

    constructor {msg} { ::RuntimeError::constructor $msg } {}
    destructor {}
}

##
# \brief Exception which indicates that a generic Tcl error occurred.
#
# When code is wrapped inside an `except` block, generic errors can be caught
# as shown in the following example:
#
# ~~~~~~~~~~~~{.tcl}
# except {
#     error "I'm a generic Tcl error."
# } e {
#     TclError {
#         puts [$e msg]
#     }
# }
# ~~~~~~~~~~~~
#
::itcl::class TclError {
    inherit ::RuntimeError

    constructor {msg} { ::RuntimeError::constructor $msg } {}
    destructor {}

    ##
    # Stores the stack trace associated with the exception that occurred. This
    # function is meant for internal use by the exception framework.
    #
    # @param stack_trace  a string containing a stack trace.
    #
    method set_stack_trace {stack_trace} {
        $this ::Exception::set_stack_trace "::TclError: $stack_trace"
    }
}

