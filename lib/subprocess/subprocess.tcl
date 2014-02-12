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

package require Thread
package require OOSupport
package require OS
package require Error
package require cmdline

::itcl::class Subprocess {

    private variable _thread_id {}

    constructor {args} {
        set options {
            {stdout.arg  stdout "set the channel to which to redirect stdout"}
            {stderr.arg  stderr "set the channel to which to redirect stderr"}
            {stdin.arg   stdin  "set the channel to which to redirect stdin" }
            {timeout.arg 0      "timeout in seconds"                         }
        }

        array set params [::cmdline::getoptions args $options]
  
        set mutex [::thread::mutex create]
        set cond  [::thread::cond  create]

        foreach {fd} {stdout stderr stdin} {
            if {$params($fd) ne $fd} {
                ::thread::detach $params($fd)
            }
        }

        set _thread_id [if 1 "::thread::create -joinable {
            package require OS
            package require Error

            proc read_incoming {input output {check read_end}} {
                global stop

                if {\$check eq {read_end}} {
                    if {\[eof \$input]} {
                        set stop($this) true
                        return
                    }
                } else {
                    if {\[eof \$output]} {
                        set stop($this) true
                        return
                    }
                }

                puts -nonewline \$output \[::read \$input]
            }

            array set params {[array get params]}
            set stop($this) false

            ::tsv::set _subprocess_status $this -1
            lassign \[chan pipe] pipe_stderr pipe_write_end

            except {
                set pipe_stdio \[open \"|$args 2>@\$pipe_write_end\" r+]
            } e {
                Exception {
                    if {\[info exists pipe_stdio]} {
                        close \$pipe_stdio
                    }

                    close \$pipe_stderr
                    error \[\$e msg]
                }
            } final {
                close \$pipe_write_end
                ::thread::cond notify $cond
            }

            set pid \[::pid \$pipe_stdio]
            ::tsv::set _subprocess_pid $this \$pid

            fconfigure \$pipe_stdio    -buffering none -translation binary -blocking 0
            fconfigure \$pipe_stderr   -buffering none -translation binary -blocking 0
            fconfigure \$params(stdin) -translation binary -blocking 0

            fileevent \$pipe_stdio    readable \[list read_incoming \$pipe_stdio  \$params(stdout)]
            fileevent \$pipe_stderr   readable \[list read_incoming \$pipe_stderr \$params(stderr)]
            fileevent \$params(stdin) readable \[list read_incoming stdin \$pipe_stdio write_end]

            set timeout_occurred($this) 0
            set deadline 0

            # set timeout action and deadline
            if {\$params(timeout) > 0} {
                set script {
                    set stop($this) 1
                    set timeout_occurred($this) 1
                }
                set deadline \[expr \[clock milliseconds] + \$params(timeout)]
                after \$params(timeout) \$script
            }

            # attach alternative channels
            foreach {fd} {stdout stderr stdin} {
                if {\$params(\$fd) ne \$fd} {
                    ::thread::attach \$params(\$fd)
                }
            }

            # sits in event loop until pipe closed
            vwait stop($this)

            # maybe process just shut down a channel for fun
            while {\[::OS::process_exists \$pid] && !\$timeout_occurred($this)} {
                after 100

                read_incoming \$pipe_stdio \$params(stdout)
                read_incoming \$pipe_stderr \$params(stderr)
                read_incoming \$params(stdin) \$pipe_stdio

                if {(\$params(timeout) > 0) && \[clock milliseconds] > \$deadline} {
                    set timeout_occurred($this) 1
                }
            }

            # close alternative channels
            foreach {fd} {stdout stderr stdin} {
                if {\$params(\$fd) ne \$fd} {
                    close \$params(\$fd)
                }
            }

            # process timed out, kill it
            if {\$timeout_occurred($this)} {
                if {\[::OS::process_exists \$pid]} {
                    ::OS::terminate \$pid
                    after 250

                    if {\[::OS::process_exists \$pid]} {
                        ::OS::kill \$pid
                    }
                }
            }

            # else close will not get the exit status
            fconfigure \$pipe_stdio -blocking 1

            set exitcode 0

            except {
                ::close \$pipe_stdio
            } e {
                ::TclError {
                    set details \[\$e code]
                    switch \[lindex \$details 0] {
                        \"CHILDSTATUS\" {
                            set exitcode \[lindex \$details 2]
                        }
                        \"CHILDKILLED\" {
                            set exitcode -1
                        }
                        default {
                            reraise \$e
                        }
                    }
                }
            } final {
                ::close \$pipe_stderr
            }

            # raise timeout after cleaning up
            if {\$timeout_occurred($this)} {
                raise ::TimeoutError \
                    \"subprocess did not finish within \${params(timeout)}ms.\"
            }

            ::tsv::set _subprocess_status $this \$exitcode
        }"]

        ::thread::mutex lock $mutex
        ::thread::cond wait $cond $mutex
        ::thread::mutex unlock $mutex

        ::thread::mutex destroy $mutex
        ::thread::cond destroy $cond
    }

    destructor {
        $this kill

        if {[::tsv::exists _subprocess_pid $this]} {
            ::tsv::unset _subprocess_pid $this
        }
        if {[::tsv::exists subprocess_status $this]} {
            ::tsv::unset _subprocess_status $this
        }

        except {
            ::thread::join $_thread_id
        } e {
            ::Exception {
                # pass
            }
        }
    }

    method terminate {} {
        if {[$this process_exists]} {
            ::OS::terminate [::tsv::get _subprocess_pid $this]
        }
    }

    method kill {} {
        if {[$this process_exists]} {
            ::OS::kill [::tsv::get _subprocess_pid $this]
        }
    }

    method process_exists {} {
        if {[::tsv::exists _subprocess_pid $this] && \
                [::OS::process_exists [::tsv::get _subprocess_pid $this]]}\
        {
            return 1
        }

        return 0
    }

    method wait {} {
        ::thread::join $_thread_id
        return [::tsv::get _subprocess_status $this]
    }
}

