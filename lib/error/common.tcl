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

proc raise {exception_type msg} {
    set exception_obj [::itcl::code [$exception_type #auto $msg]]
    error "$exception_obj" "[$exception_obj info class]: $msg"
}

proc reraise {exception_obj} {
    uplevel "error \"$exception_obj\""
}

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
    } $exception_var except_opts] == 1 } {

        $final_block

        if { !\[::itcl::is object \$$exception_var] } {
            set $exception_var \[::itcl::code \[::TclError #auto \"\$$exception_var\"]]
        }

        \$$exception_var set_stack_trace \[dict get \$except_opts -errorinfo]
        \$$exception_var set_code        \[dict get \$except_opts -errorcode]
        \$$exception_var set_line        \[dict get \$except_opts -errorline]

        set __rcode \[ catch { if $__buf else {error \$$exception_var} } __rval ]
    } else {

        $final_block

    }

    if {\$__rcode != 0} {
        return -code \$__rcode \$__rval
    }"
}

