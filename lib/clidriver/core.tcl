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
                    set pid [exp_pid -i $_spawn_id]
                    ::close -i $_spawn_id

                    # hack to reap dead background processes
                    exec true

                    # if spawn_id was pointing to a process
                    if {$pid} {

                        if {[OS process_exists $pid]} {
                            OS terminate $pid
                            after 500

                            if {[OS process_exists $pid]} {
                                OS kill $pid
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
    }
}

