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

package require OOSupport
package require OS
package require Error
package require cmdline

::itcl::class Subprocess {

    common attributes {
        { number  pid      "" ro }
        { number  exitcode 0  ro }
        { string  stdio    {} ro }
        { string  stderr   {} ro }
    }

    common _stop
    array set _stop {}
    common _timeout_occurred
    array set _timeout_occurred {}

    private variable _output_stdout stdout
    private variable _output_stderr stderr

    constructor {args} {
        ::OOSupport::init_attributes

        lassign [chan pipe] _stderr _write_end
        set _stdio [open "|$args 2>@$_write_end" r+]
        close $_write_end

        set _pid [::pid $_stdio]
    }

    ::OOSupport::bless_attributes

    method terminate {} {
        if {$_pid ne {}} {
            ::OS::terminate $_pid
        }
    }

    method kill {} {
        if {$_pid ne {}} {
            ::OS::kill $_pid
        }
    }

    method process_exists {} {
        if {$_pid ne {} && [::OS::process_exists $_pid]} {
            return 1
        }

        return 0
    }

    method wait {args} {
        set options {
            {stdout.arg  stdout "set the channel to which to redirect stdout"}
            {stderr.arg  stderr "set the channel to which to redirect stderr"}
            {timeout.arg 0      "timeout in seconds"                         }
        }

        array set params [::cmdline::getoptions args $options]

        set _output_stdout $params(stdout)
        set _output_stderr $params(stderr)

        fconfigure $_stdio  -buffering none -translation binary -blocking 0
        fconfigure $_stderr -buffering none -translation binary -blocking 0

        fileevent $_stdio  readable [list [::itcl::code $this] \
            read_incoming_stdio ]
        fileevent $_stderr readable [list [::itcl::code $this] \
            read_incoming_stderr]

        # write input data then start "recording"
        foreach {data} $args {
            puts -nonewline $_stdio $data
        }

        set _timeout_occurred($this) 0
        set deadline 0

        # set timeout action and deadline
        if {$params(timeout) > 0} {
            set script "\
                set ::Subprocess::_stop($this) 1
                set ::Subprocess::_timeout_occurred($this) 1"
            set deadline [expr [clock milliseconds] + $params(timeout) * 1000]
            after [expr $params(timeout) * 1000] $script
        }

        # sits in event loop until pipe closed
        vwait ::Subprocess::_stop($this)

        # maybe process just shut down a channel for fun
        while {[$this process_exists] && !$_timeout_occurred($this)} {
            after 250

            read_incoming_stdio
            read_incoming_stderr

            if {($params(timeout) > 0) && [clock milliseconds] > $deadline} {
                set _timeout_occurred($this) 1
            }
        }

        # process timed out, kill it
        if {$_timeout_occurred($this)} {
            if {[$this process_exists]} {
                $this terminate
                after 250

                if {[$this process_exists]} {
                    $this kill
                }
            }
        }

        # else close will not get the exit status
        fconfigure $_stdio -blocking 1

        except {
            ::close $_stdio
        } e {
            ::TclError {
                set details [$e code]
                switch [lindex $details 0] {
                    "CHILDSTATUS" {
                        set _exitcode [lindex $details 2]
                    }
                    "CHILDKILLED" {
                        set _exitcode -1
                    }
                    default {
                        reraise $e
                    }
                }
            }
        } final {
            ::close $_stderr
        }

        # raise timeout after cleaning up
        if {$_timeout_occurred($this)} {
            raise ::TimeoutError \
                "subprocess did not finish within ${params(timeout)} seconds."
        }

        return $_exitcode
    }

    method read_incoming_stdio {} {
        if {[eof $_stdio]} {
            set _stop($this) true
            return
        }

        puts -nonewline $_output_stdout [::read $_stdio]
    }

    method read_incoming_stderr {} {
        if {[eof $_stderr]} {
            set _stop($this) true
            return
        }

        puts -nonewline $_output_stderr [::read $_stderr]
    }
}

