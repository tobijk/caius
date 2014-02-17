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
package require OOSupport

namespace eval OutputStream {

    variable filter_stack
    array set filter_stack {}

    proc push {channel filter} {
        variable filter_stack

        if {![info exists filter_stack($channel)]} {
            set filter_stack($channel) {}
        }

        set transform [chan push $channel $filter]
        lappend filter_stack($channel) $filter
    }

    proc pop {channel} {
        variable filter_stack

        if {[info exists filter_stack($channel)]} {
            set filter_stack($channel) \
                [lreplace $filter_stack($channel) end end]
        }

        chan pop $channel
    }

    proc transforms {channel} {
        variable filter_stack

        if {[info exists filter_stack($channel)]} {
            return $filter_stack($channel)
        }

        return {}
    }

    proc transforms_create_code {channel} {
        variable filter_stack

        set code {}

        if {[info exists filter_stack($channel)]} {
            set i 0

            foreach {filter} $filter_stack($channel) {
                set class [$filter info class]

                append code "
                if {{$class} eq {::OutputStream::Capture}} {
                    set _filter_${channel}_$i \[$class #auto true]
                } else {
                    set _filter_${channel}_$i \[$class #auto]
                }
                \$_filter_${channel}_$i from_json {[$filter to_json]}
                chan push $channel \$_filter_${channel}_$i
                "

                incr i
            }
        }

        return $code
    }

    proc transforms_destroy_code {channel} {
        variable filter_stack

        set code {}

        if {[info exists filter_stack($channel)]} {
            set i 0

            foreach {filter} $filter_stack($channel) {
                append code "chan pop $channel
                ::itcl::delete object \$_filter_${channel}_$i
                "

                incr i
            }
        }

        return $code
    }

    ##
    # \brief A channel filter that prefixes each line with a given string.
    #
    ::itcl::class Indent {

        ## \private
        common attributes {
            {string indent "    " ro}
        }

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

        OOSupport::bless_attributes -json_support

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
        common attributes {
            {string target {} ro}
        }

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

        OOSupport::bless_attributes -json_support

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

        common attributes {}

        OOSupport::bless_attributes -json_support

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
        common attributes {
            {string newline "\n" ro}
        }

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

        OOSupport::bless_attributes -json_support

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
        common attributes {
            {string buffer_file {}    ro}
        }

        private variable _handle {}
        private variable _shared false

        constructor {{shared false}} {
            OOSupport::init_attributes
            set _shared $shared
        }

        destructor {
            if {!$_shared && [file exists $_buffer_file]} {
                file delete $_buffer_file
            }
        }

        OOSupport::bless_attributes -json_support

        ## \private
        method initialize {channel mode} {
            if {[llength $mode] != 1 || [lindex $mode 0] ne "write"} {
                error "OutputStream::Capture can only be opened for writing."
            }

            if {$_buffer_file eq {}} {
                close [file tempfile _buffer_file]
            }

            if {$_handle eq {}} {
                set _handle [open $_buffer_file a]
            }

            return {initialize finalize write}
        }

        ## \private
        method finalize {channel} {
            close $_handle
            set _handle {}
        }

        ## \private
        method write {channel data} {
            puts -nonewline $_handle $data
            return {}
        }

        ##
        # Returns the captured content.
        #
        method get {} {
            set handle [open $_buffer_file r]
            set buf [read $handle]
            close $handle
            return $buf
        }

        ##
        # Clears the buffer.
        #
        method clear {} {
            if {$_handle ne {}} {
                chan truncate $_handle 0
            }
        }
    }

    ##
    # \brief A channel filter to escape XML special characters.
    #
    ::itcl::class XMLEscape {
        ## \private
        common attributes {}

        constructor {} {}

        OOSupport::bless_attributes -json_support

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

