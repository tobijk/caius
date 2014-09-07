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
package require OutputStream
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

        # escape remainging args, because we insert them into a string below
        set args [string map {"\$" "\\\$" "\[" "\\\[" "\]" "\\\]" "\{" "\\\{" \
                    "\}" "\\\}" "\"" "\\\""} $args]

        set mutex [::thread::mutex create]
        set cond  [::thread::cond  create]

        foreach {fd} {stdout stderr stdin} {
            if {$params($fd) ne $fd} {
                ::thread::detach $params($fd)
            }
        }

        ::tsv::set _subprocess_$this started 0

        set _thread_id [if 1 "::thread::create -joinable {
            package require OS
            package require Error
            package require OutputStream
            package require Itcl

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

            [OutputStream::transforms_create_code stdout]
            [OutputStream::transforms_create_code stderr]

            array set params {[array get params]}
            set stop($this) false

            ::tsv::set _subprocess_$this status -1
            lassign \[chan pipe] pipe_stderr pipe_write_end

            except {
                set pipe_stdio \[open \"|$args 2>@\$pipe_write_end\" r+]
            } e {
                Exception {
                    if {\[info exists pipe_stdio]} {
                        close \$pipe_stdio
                    }

                    close \$pipe_stderr

                    ::thread::mutex lock $mutex
                    ::tsv::set _subprocess_$this started 1
                    ::thread::cond notify $cond
                    ::thread::mutex unlock $mutex

                    error \[\$e msg]
                }
            } final {
                close \$pipe_write_end
            }

            set pid \[::pid \$pipe_stdio]
            ::tsv::set _subprocess_$this pid \$pid

            fconfigure \$pipe_stdio    -buffering none -translation binary -blocking 0
            fconfigure \$pipe_stderr   -buffering none -translation binary -blocking 0
            fconfigure \$params(stdin) -translation binary -blocking 0

            ::thread::mutex lock $mutex
            ::tsv::set _subprocess_$this started 1
            ::thread::cond notify $cond
            ::thread::mutex unlock $mutex

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

            # process timed out, kill it
            if {\$timeout_occurred($this)} {
                if {\[::OS::process_exists \$pid]} {
                    ::OS::terminate \$pid
                    after 250

                    if {\[::OS::process_exists \$pid]} {
                        ::OS::kill \$pid
                    }
                }

                ::tsv::set _subprocess_$this timeout_occurred 1
            }

            # close alternative channels
            foreach {fd} {stdout stderr stdin} {
                if {\$params(\$fd) ne \$fd} {
                    close \$params(\$fd)
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

            [OutputStream::transforms_destroy_code stdout]
            [OutputStream::transforms_destroy_code stderr]

            ::tsv::set _subprocess_$this status \$exitcode
        }"]

        ::thread::mutex lock $mutex
        while {![::tsv::get _subprocess_$this started]} {
            ::thread::cond wait $cond $mutex
        }
        ::thread::mutex unlock $mutex

        ::thread::mutex destroy $mutex
        ::thread::cond destroy $cond
    }

    destructor {
        $this kill
        ::tsv::unset _subprocess_$this

        except {
            ::thread::join $_thread_id
        } e {
            ::Exception {
                # pass
            }
        }
    }

    method pid {} {
        return [::tsv::get _subprocess_$this pid]
    }

    method terminate {} {
        if {[$this process_exists]} {
            ::OS::terminate [::tsv::get _subprocess_$this pid]
        }
    }

    method kill {} {
        if {[$this process_exists]} {
            ::OS::kill [::tsv::get _subprocess_$this pid]
        }
    }

    method process_exists {} {
        if {[::tsv::exists _subprocess_$this pid] && \
                [::OS::process_exists [::tsv::get _subprocess_$this pid]]}\
        {
            return 1
        }

        return 0
    }

    method wait {} {
        ::thread::join $_thread_id
        return [::tsv::get _subprocess_$this status]
    }

    method timeout_occurred {} {
        if {[::tsv::exists _subprocess_$this timeout_occurred]} {
            return 1
        }

        return 0
    }
}

