#!/usr/bin/tclsh
#
# The MIT License (MIT)
#
# Copyright (c) 2014-2021 Tobias Koch <tobias.koch@gmail.com>
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

