#
# The MIT License (MIT)
#
# Copyright (c) 2014 Caius Project
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

package require Thread
package require OOSupport
package require OS
package require Error
package require OutputStream
package require cmdline

namespace eval Subprocess {

    ::itcl::class Error {
        inherit ::Exception

        constructor {msg} { ::Exception::constructor $msg } {}
        destructor {}
    }

    ::itcl::class Popen {

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

            set parent_thread_id [::thread::id]

            ::tsv::set _subprocess_${parent_thread_id}_${this} started 0
            ::tsv::set _subprocess_${parent_thread_id}_${this} error   ""

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

                ::tsv::set _subprocess_${parent_thread_id}_${this} status -1
                lassign \[chan pipe] pipe_stderr pipe_write_end

                except {
                    set pipe_stdio \[open \"|$args 2>@\$pipe_write_end\" r+]
                } e {
                    Exception {
                        if {\[info exists pipe_stdio]} {
                            close \$pipe_stdio
                        }

                        close \$pipe_stderr

                        [OutputStream::transforms_destroy_code stdout]
                        [OutputStream::transforms_destroy_code stderr]

                        ::thread::mutex lock $mutex
                        ::tsv::set _subprocess_${parent_thread_id}_${this} error \[\$e msg]
                        ::tsv::set _subprocess_${parent_thread_id}_${this} started 1
                        ::thread::cond notify $cond
                        ::thread::mutex unlock $mutex

                        return
                    }
                } final {
                    close \$pipe_write_end
                }

                set pid \[::pid \$pipe_stdio]
                ::tsv::set _subprocess_${parent_thread_id}_${this} pid \$pid

                fconfigure \$pipe_stdio    -buffering none -translation binary -blocking 0
                fconfigure \$pipe_stderr   -buffering none -translation binary -blocking 0
                fconfigure \$params(stdin) -translation binary -blocking 0

                ::thread::mutex lock $mutex
                ::tsv::set _subprocess_${parent_thread_id}_${this} started 1
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

                    ::tsv::set _subprocess_${parent_thread_id}_${this} timeout_occurred 1
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

                ::tsv::set _subprocess_${parent_thread_id}_${this} status \$exitcode
            }"]

            ::thread::mutex lock $mutex
            while {![::tsv::get _subprocess_${parent_thread_id}_${this} started]} {
                ::thread::cond wait $cond $mutex
            }
            ::thread::mutex unlock $mutex

            ::thread::mutex destroy $mutex
            ::thread::cond destroy $cond

            if {[set err [::tsv::get \
                    _subprocess_${parent_thread_id}_${this} error]] ne ""} \
            {
                raise ::Subprocess::Error $err
            }
        }

        destructor {
            set parent_thread_id [::thread::id]

            $this kill
            ::tsv::unset _subprocess_${parent_thread_id}_${this}

            except {
                ::thread::join $_thread_id
            } e {
                ::Exception {
                    # pass
                }
            }
        }

        method pid {} {
            set parent_thread_id [::thread::id]
            return [::tsv::get _subprocess_${parent_thread_id}_${this} pid]
        }

        method terminate {} {
            set parent_thread_id [::thread::id]
            if {[$this process_exists]} {
                ::OS::terminate [::tsv::get \
                    _subprocess_${parent_thread_id}_${this} pid]
            }
        }

        method kill {} {
            set parent_thread_id [::thread::id]
            if {[$this process_exists]} {
                ::OS::kill [::tsv::get \
                    _subprocess_${parent_thread_id}_${this} pid]
            }
        }

        method process_exists {} {
            set parent_thread_id [::thread::id]

            if {[::tsv::exists _subprocess_${parent_thread_id}_${this} pid] && \
                    [::OS::process_exists [::tsv::get \
                        _subprocess_${parent_thread_id}_${this} pid]]}\
            {
                return 1
            }

            return 0
        }

        method wait {} {
            set parent_thread_id [::thread::id]
            ::thread::join $_thread_id
            return [::tsv::get _subprocess_${parent_thread_id}_${this} status]
        }

        method timeout_occurred {} {
            set parent_thread_id [::thread::id]

            if {[::tsv::exists _subprocess_${parent_thread_id}_${this} \
                timeout_occurred]} \
            {
                return 1
            }

            return 0
        }
    }
}

