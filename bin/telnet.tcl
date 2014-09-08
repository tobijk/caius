#!/usr/bin/tclsh
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
package require Expect

::itcl::class Telnet {

    private variable _sock
    private common _stop
    private variable _desired_options_sent 0
    array set _stop {}

    common IAC        "\xff"
    common DO         "\xfd"
    common DONT       "\xfe"
    common WILL       "\xfb"
    common WONT       "\xfc"
    common ECHO       "\x01"
    common LINEMODE   "\x22"
    common SUPGOAHEAD "\x03"

    constructor {host {port 23}} {
        set _sock [socket -async $host $port]

        fconfigure $_sock -buffering none -translation binary -blocking 0
        fconfigure stdin  -buffering none -translation binary -blocking 0
        fconfigure stdout -buffering line -translation binary -blocking 1

        fileevent stdin  readable [list {*}[::itcl::code $this] _do_send]
        fileevent $_sock readable [list {*}[::itcl::code $this] _do_receive]
    }

    method _do_send {} {
        if {[eof stdin]} {
            set _stop($this) true
            return
        }

        set data [read stdin]
        set data [string map [list "\r\n" "\r\n" "\r" "\r\0" "\n" "\r\n"] $data]
        puts -nonewline $_sock $data
    }

    method _do_receive {} {
        if {[eof $_sock]} {
            set _stop($this) true
            return
        }

        set data    [read $_sock]
        set nbytes  [string length $data]
        set usrdata ""
        set nvtdata ""
 
        for {set i 0} {$i < $nbytes} {incr i} {
            set chr [string index $data $i]

            if {$chr != "\xff"} {
                append usrdata $chr
                continue
            }

            set cmd [string index $data [incr i]]
            set opt [string index $data [incr i]]

            append nvtdata [$this _process_option $cmd $opt]
        }

        # fix CRs
        set usrdata [string map [list "\r\0" "\r"] $usrdata]

        # print transmitted data
        if {[string index $usrdata 0] != ""} {
            puts -nonewline stdout $usrdata
            flush stdout
        }

        # answer telnet options
        if {[string index $nvtdata 0] != ""} {
            puts -nonewline $_sock $nvtdata
            flush $_sock
        }
    }

    method _process_option {cmd opt} {
        set nvtdata ""

        if {!$_desired_options_sent} {
            append nvtdata "${IAC}${DO}${SUPGOAHEAD}"
            append nvtdata "${IAC}${DO}${ECHO}"
            set _desired_options_sent 1
        }

        if {$cmd eq "${WILL}"} {
            switch ${opt} \
                ${SUPGOAHEAD} {} \
                ${ECHO}       {
                    # put tty in raw mode
                    stty raw -echo
                } \
                default {
                    append nvtdata "${IAC}${DONT}${opt}"
                }
        } elseif {$cmd eq "${DO}"} {
            append nvtdata "${IAC}${WONT}${opt}"
        }

        return $nvtdata
    }

    method do {} {
        # enter event loop
        vwait ::Telnet::_stop($this)
    }
}

#### MAIN ####
if {$::argc < 1 || $::argc > 2} {
    puts stderr "Usage: telnet.tcl <host> \[<port>\]"
    exit 1
}

set host [lindex $::argv 0]
set port [lindex $::argv 1]

if {$port eq ""} {
    set port 23
}

set telnet [Telnet #auto $host $port]
$telnet do

