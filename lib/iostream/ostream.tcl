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

        method finalize {channel} {
            set _state :start
        }

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

        method finalize {channel} {
            flush $_target
        }

        method write {channel data} {
            puts -nonewline $_target $data
            return {}
        }
    }

    ::itcl::class AnsiEscapeFilter {

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

    ::itcl::class Capture {
        private variable _buffer

        constructor {} {}

        method initialize {channel mode} {
            if {[llength $mode] != 1 || [lindex $mode 0] ne "write"} {
                error "OutputStream::Capture can only be opened for writing."
            }
            return {initialize finalize write}
        }

        method finalize {channel} {}

        method write {channel data} {
            append _buffer $data
            return {}
        }

        method get {} {
            return $_buffer
        }

        method clear {} {
            set _buffer {}
        }
    }

    ::itcl::class XMLEscape {
        constructor {} {}

        method initialize {channel mode} {
            if {[llength $mode] != 1 || [lindex $mode 0] ne "write"} {
                error "OutputStream::XMLEscape can only be opened for writing."
            }
            return {initialize finalize write}
        }

        method finalize {channel} {}

        method write {channel data} {
            return [string map {& &amp; < &lt; > &gt; \" &quot;} $data]
        }
    }
}

