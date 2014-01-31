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
# \brief Classes for modifying the behavior of output streams (Tcl channels).

package require Tcl 8.6
package require Itcl

namespace eval OutputStream {

    ##
    # \brief A channel filter that prefixes each line with a given string.
    #
    ::itcl::class Indent {
        ## \private
        private variable _indent
        ## \private
        private variable _state

        ##
        # Creates an Indent object.
        #
        # @param indent  the string to prefix to each line (default 4 spaces)
        #
        # To indent each line written to stdout by the specified amount,
        # create and apply the Indent as follows:
        #
        # ~~~~~~~~~~{.tcl}
        # set indent [OutputStream::Indent #auto "  "]
        #
        # chan push stdout $indent
        # puts "This will be indented by two spaces."
        #
        # chan pop stdout
        # puts "Back to normal."
        # ~~~~~~~~~~
        #
        # Please note that the Indent expects to operate on line-buffered
        # data. There is no logic to deal with incomplete lines for the time
        # being.
        #
        constructor {{indent "    "}} {
            set _indent $indent
            set _state  :start
        }

        ## \private
        method initialize {channel mode} {
            if {[llength $mode] != 1 || [lindex $mode 0] ne "write"} {
                error "OutputStream::Indent can only be opened for writing."
            }
            return {initialize finalize write}
        }

        ## \private
        method finalize {channel} {
            set _state :start
        }

        ## \private
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

    ##
    # \brief A channel modifier that redirects all input to another channel.
    #
    ::itcl::class Redirect {
        ## \private
        private variable _target

        ##
        # Creates a Redirect object.
        #
        # @param target  the name of the channel to redirect to
        #
        # For example, if you wanted to redirect everything written to stderr
        # to stdout instead, you could do it like this:
        #
        # ~~~~~~~~~~{.tcl}
        # set redirect [OutputStream::Redirect #auto stdout]
        #
        # chan push stderr $redirect
        # puts stderr "This will go to stdout."
        #
        # chan pop stderr
        # ~~~~~~~~~~
        #
        constructor {{target stdout}} {
            set _target $target
        }

        ## \private
        method initialize {channel mode} {
            if {[llength $mode] != 1 || [lindex $mode 0] ne "write"} {
                error "OutputStream::Redirect can only be opened for writing."
            }
            return {initialize finalize write}
        }

        ## \private
        method finalize {channel} {
            flush $_target
        }

        ## \private
        method write {channel data} {
            puts -nonewline $_target $data
            return {}
        }
    }

    ##
    # \brief A channel filter that removes common ANSI escape sequences.
    #
    ::itcl::class AnsiEscapeFilter {

        ## \private
        method initialize {channel mode} {
            if {[llength $mode] != 1 || [lindex $mode 0] ne "write"} {
                error "OutputStream::AnsiEscapeFilter can only be opened for writing."
            }
            return {initialize finalize write}
        }

        ## \private
        method finalize {channel} {}

        ## \private
        method write {channel data} {
            set regex1 {\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[m|K]}
            set regex2 {\x1B\]0;[^\x07]+\x07}
            set regex  "$regex1|$regex2"
            return [regsub -all $regex $data ""]
        }
    }

    ##
    # \brief A channel filter that converts line endings.
    #
    ::itcl::class NormalizeNewlines {
        ## \private
        private variable _newline

        ##
        # Creates a NormalizeNewlines object.
        #
        # @param style  one of 'unix' or 'windows'
        #
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

        ## \private
        method initialize {channel mode} {
            if {[llength $mode] != 1 || [lindex $mode 0] ne "write"} {
                error "OutputStream::NormalizeNewlines can only be opened for writing."
            }
            return {initialize finalize write}
        }

        ## \private
        method finalize {channel} {}

        ## \private
        method write {channel data} {
            return [regsub -all {\r*\n} $data $_newline]
        }
    }

    ##
    # \brief Capture things written to a channel in memory.
    #
    ::itcl::class Capture {
        ## \private
        private variable _buffer

        constructor {} {
            set _buffer {}
        }

        ## \private
        method initialize {channel mode} {
            if {[llength $mode] != 1 || [lindex $mode 0] ne "write"} {
                error "OutputStream::Capture can only be opened for writing."
            }
            return {initialize finalize write}
        }

        ## \private
        method finalize {channel} {}

        ## \private
        method write {channel data} {
            append _buffer $data
            return {}
        }

        ##
        # Returns the captured content.
        #
        method get {} {
            return $_buffer
        }

        ##
        # Clears the buffer.
        #
        method clear {} {
            set _buffer {}
        }
    }

    ##
    # \brief A channel filter to escape XML special characters.
    #
    ::itcl::class XMLEscape {
        constructor {} {}

        ## \private
        method initialize {channel mode} {
            if {[llength $mode] != 1 || [lindex $mode 0] ne "write"} {
                error "OutputStream::XMLEscape can only be opened for writing."
            }
            return {initialize finalize write}
        }

        ## \private
        method finalize {channel} {}

        ## \private
        method write {channel data} {
            return [string map {& &amp; < &lt; > &gt; \" &quot;} $data]
        }
    }
}

