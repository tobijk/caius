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

package require Tcl 8.6
package require Itcl

namespace eval OutputStream {

    ::itcl::class Indenter {
        private variable _indent
        private variable _state

        constructor {{indent "    "}} {
            set _indent $indent
            set _state  :start
        }

        method initialize {channel mode} {
            if {[llength $mode] != 1 || [lindex $mode 0] ne "write"} {
                error "OutputStream::Indenter can only be opened for writing."
            }
            return {initialize finalize write}
        }

        method finalize {channel} {}

        method write {channel data} {
            set lines [regexp -inline -all -line -- {^.*(?:\r?\n)?} $data]

            foreach {line} $lines {
                if {$_state eq {:start}} {
                    append out $_indent
                }
                append out $line

                if {[regexp {\r?\n$} $line]} {
                    set _state :start
                } else {
                    set _state :inline
                }
            }
            return $out
        }
    }

    ::itcl::class Redirect {
        private variable _target

        constructor {{target stdout}} {
            set _target $target
        }

        method initialize {channel mode} {
            if {[llength $mode] != 1 || [lindex $mode 0] ne "write"} {
                error "OutputStream::Redirect can only be opened for writing."
            }
            return {initialize finalize write}
        }

        method finalize {channel} {}

        method write {channel data} {
            puts -nonewline $_target $data
            return {}
        }
    }

    ::itcl::class AnsiEscapeFilter {

        constructor {{target stdout}} {
            set _target $target
        }

        method initialize {channel mode} {
            if {[llength $mode] != 1 || [lindex $mode 0] ne "write"} {
                error "OutputStream::AnsiEscapeFilter can only be opened for writing."
            }
            return {initialize finalize write}
        }

        method finalize {channel} {}

        method write {channel data} {
            set regex1 {\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[m|K]}
            set regex2 {\x1B\]0;[^\x07]+\x07}
            set regex  "$regex1|$regex2"
            return [regsub -all $regex $data ""]
        }
    }

    ::itcl::class FlipNewlines {
        private variable _newline

        constructor {{style unix}} {
            switch $style {
                unix {
                    set _newline "\n"
                }
                windows {
                    set _newline "\r\n"
                }
                default {
                    error "newline style must be one of 'unix', 'windows'."
                }
            }
        }

        method initialize {channel mode} {
            if {[llength $mode] != 1 || [lindex $mode 0] ne "write"} {
                error "OutputStream::FlipNewlines can only be opened for writing."
            }
            return {initialize finalize write}
        }

        method finalize {channel} {}

        method write {channel data} {
            return [regsub -all {\r*\n} $data $_newline]
        }
    }
}

