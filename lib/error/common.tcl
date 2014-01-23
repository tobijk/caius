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

package require Itcl

##
# Raises an exception.
#
# @param exception_type  the class name of the exception to be thrown
# @param msg             the error message associated with the exception
#
proc raise {exception_type msg} {
    set exception_obj [::itcl::code [$exception_type #auto $msg]]
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

        $final_block

        if { !\[::itcl::is object \$$exception_var] } {
            set $exception_var \[::itcl::code \[::TclError #auto \"\$$exception_var\"]]
        }

        \$$exception_var set_stack_trace \[dict get \$__except_opts_$exception_var -errorinfo]
        \$$exception_var set_code        \[dict get \$__except_opts_$exception_var -errorcode]
        \$$exception_var set_line        \[dict get \$__except_opts_$exception_var -errorline]

        set __rcode \[ catch { if $__buf else {error \$$exception_var} } __rval ]
    } else {

        $final_block

    }

    if {\$__rcode != 0} {
        return -code \$__rcode \$__rval
    }"
}

