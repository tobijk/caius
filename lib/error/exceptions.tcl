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

