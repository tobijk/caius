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
# \brief Functions for exception handling.

package require Itcl

##
# Raises an exception.
#
# @param exception_type  the class name of the exception to be thrown
# @param msg             the error message associated with the exception
#
proc raise {exception_type msg} {
    set exception_obj [namespace which [$exception_type #auto $msg]]
    error "$exception_obj" "[$exception_obj info class]: $msg"
}

##
# Re-raises an exception.
#
# @param exception_obj  an exception object instance.
#
# `reraise` may only be used inside an exception handler block like this:
#
# ~~~~~~~~~~{.tcl}
# except {
#     raise RuntimeError "something went wrong..."
# } e {
#     RuntimeError {
#        puts [$e msg]
#        reraise $e
#     }
# }
# ~~~~~~~~~~
#
proc reraise {exception_obj} {
    uplevel "error \"$exception_obj\""
}

##
# Catch all errors and exceptions in a block of code.
#
# ~~~~~~~~~~{.tcl}
# except {
#     # your code here
# } e {
#     TclError {
#         puts "Caught a Tcl error: [$e msg]"
#     }
#     ValueError {
#         puts "Caught a ValueError: [$e msg]"
#     }
#     Exception {
#         puts "Caught a generic Exception"
#         reraise $e
#     }
# } final {
#     puts "I'm executed no matter what."
# }
# ~~~~~~~~~~
#
# The exception types listed in the handler block are evaluated in the order
# in which they are listed. For each entry a check is made, whether the
# exception object `e` has the given type in its inheritance chain. If yes,
# the handler is invoked. If no, the next entry is evaluated.
#
# An optional `final` clause will always be executed, whether an exception
# occurred or not.
#
proc except {block exception_var clauses {final_kw ""} {final_block ""}} {

    # handle case where no catch clauses exist
    set __buf "{ false } {}"

    if {($final_kw ne "") && ($final_kw ne "final")} {
        error "syntax error: expected keyword 'final' followed by code block"
    }

    foreach {exception_class handler} $clauses {
        lappend __buf "{\[\$$exception_var isa $exception_class]} {$handler}"
    }
    set __buf [join $__buf " elseif "]

    uplevel "\
    set __rcode 0
    set __rval 0

    if { \[ catch {
        $block
    } $exception_var __except_opts_$exception_var] == 1 } {

        # convert Tcl error to TclError object
        if { !\[::itcl::is object \$$exception_var] } {
            set $exception_var \[namespace which \[::TclError #auto \"\$$exception_var\"]]
        }

        # populate the exception object with info about the error
        \$$exception_var set_stack_trace \[dict get \$__except_opts_$exception_var -errorinfo]
        \$$exception_var set_code        \[dict get \$__except_opts_$exception_var -errorcode]
        \$$exception_var set_line        \[dict get \$__except_opts_$exception_var -errorline]

        # evaluate handler clauses
        set __rcode \[ catch { if $__buf else {error \$$exception_var} } __rval ]

        # if exception is caught, the object needs to be deleted!
        if {\$__rcode == 0} {
            ::itcl::delete object \$$exception_var
        }
    }

    $final_block

    if {\$__rcode != 0} {
        return -code \$__rcode \$__rval
    }"
}

