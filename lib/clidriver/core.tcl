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

## \file
# \brief An object-oriented wrapper around Expect (core functionality).

package require Itcl
package require OS
package require Error
package require Expect

# hack to make Expect use stdout as a channel
catch {
    log_user 0
    log_file -a -leaveopen stdout
}

namespace eval CliDriver {

    ::itcl::class Error {
        inherit ::Exception

        constructor {msg} {
            ::Exception::constructor "$msg"
        } {}

        destructor {}
    }

    ##
    # \brief An object-oriented wrapper around Expect (abstract base class).
    #
    # Don't use this class directly, but rather one of
    #
    # * CliDriver::Stty
    # * CliDriver::Spawn
    # * CliDriver::Ssh
    # * CliDriver::Telnet
    #
    ::itcl::class Core {

        ## \private
        protected variable _spawn_id ""

        constructor {} {}

        destructor {
            $this close
        }

        ##
        # Closes the connection and terminates the process attached to the
        # spawn id associated with this object. Returns the exit code.
        method close {} {
            set exit_code ""

            if {$_spawn_id ne ""} {
                except {
                    set pid [$this pid]
                    ::close -i $_spawn_id

                    # hack to reap dead background processes
                    exec true

                    # if spawn_id was pointing to a process
                    if {$pid} {

                        if {[::OS::process_exists $pid]} {
                            ::OS::terminate $pid
                            after 500

                            if {[OS::process_exists $pid]} {
                                ::OS::kill $pid
                            }
                        }

                        set exit_code [lindex [::wait -i $_spawn_id] 3]
                    }
                } e {} final {
                    set _spawn_id ""
                }
            }

            return $exit_code
        }

        ##
        # Sends a string of characters to the spawned program. This method
        # invokes `exp_send` and implicitely passes it the `spawn_id`
        # associated with this object. All parameters are passed on unmodified.
        method send {args} {
            uplevel "::exp_send -i $_spawn_id $args"
        }

        ##
        # Expects a certain string or pattern to occur in the output of the
        # spawned program. This method invokes `::expect` in the global
        # namespace and implicitely passes it the `spawn_id` associated with
        # this object. All parameters are passed on unmodified.
        method expect {args} {
            uplevel \
                "set spawn_id $_spawn_id
                ::expect $args"
        }

        ##
        # Sets or gets the maximum match buffer size for the `spawn_id`
        # associated with this object.
        #
        # @param size  specifies the buffer size in bytes
        #
        # If `size` is not set, the current buffer size will be returned.
        method match_max {{size ""}} {
            return [match_max -i $_spawn_id $size]
        }

        ##
        # Returns the `spawn_id` associated with this object.
        method spawn_id {} {
            return $_spawn_id
        }

        ##
        # Returns the process ID of the subprocess.
        method pid {} {
            set pid 0

            if {[catch {
                set pid [exp_pid -i $_spawn_id]
            }] != 0} {}

            return $pid
        }

        method terminate {} {
            if {[$this process_exists]} {
                ::OS::terminate [$this pid]
            }
        }

        method kill {} {
            if {[$this process_exists]} {
                ::OS::kill [$this pid]
            }
        }

        method process_exists {} {
            set pid [$this pid]

            if {$pid && [::OS::process_exists $pid]} {
                return 1
            }

            return 0
        }
    }
}

