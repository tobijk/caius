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
# \brief A wrapper for controlling a serial line with Expect.

package require Itcl
package require Error
package require cmdline

namespace eval CliDriver {

    ##
    # \brief A convenience class for controlling a serial line with Expect.
    #
    ::itcl::class Stty {
        inherit CliDriver::Core

        constructor {args} {
            set params(baud)      56000
            set params(parity)    n
            set params(data_bits) 8
            set params(stop_bits) 1

            while {[string index [lindex $args 0] 0] == "-"} {
                set opt [lindex $args 0]

                switch $opt {
                    "-baud" {
                        set params(baud) [lindex $args 1]
                        set args [lreplace $args 0 1]

                        if {![string is integer -strict $params(baud)]} {
                            raise ::CliDriver::Error \
                                "CliDriver::Stty: expected an integer for -baud."
                        }
                    }
                    "-parity" {
                        set params(parity) [lindex $args 1]
                        set args [lreplace $args 0 1]

                        if {![string is boolean -strict $params(parity)]} {
                            raise ::CliDriver::Error \
                                "CliDriver::Stty: expected boolean for -parity."
                        }

                        if {$params(parity)} {
                            set params(parity) y
                        } else {
                            set params(parity) n
                        }
                    }
                    "-data_bits" {
                        set params(data_bits) [lindex $args 1]
                        set args [lreplace $args 0 1]

                        if {![string is digit -strict $params(data_bits)]} {
                            raise ::CliDriver::Error \
                                "CliDriver:Stty: expected a single digit for -data_bits."
                        }
                    }
                    "-stop_bits" {
                        set params(stop_bits) [lindex $args 1]
                        set args [lreplace $args 0 1]

                        if {![string is digit -strict $params(stop_bits)]} {
                            raise ::CliDriver::Error \
                                "CliDriver:Stty: expected a single digit for -stop_bits."
                        }
                    }
                    default {
                        raise ::CliDriver::Error \
                            "CliDriver::Stty: unknown option '$opt'."
                    }
                }
            }

            set port [lindex $args 0]

            if {"$port" eq ""} {
                raise ::CliDriver::Error \
                    "CliDriver::Stty: missing the *port* argument."
            }

            except {
                set tty_mode [join [list $params(baud) $params(parity) \
                    $params(data_bits) $params(stop_bits)] ","]

                set fp [open $port rb+]
                fconfigure $fp -buffering none -eofchar {}

                except {
                    fconfigure $fp -mode $tty_mode
                } e {
                    ::TclError {
                        raise ::CliDriver::Error \
                            "CliDriver::Stty: unable to set -mode $tty_mode on $port."
                    }
                }

                spawn -open $fp
                set _spawn_id $spawn_id
            } e {
                ::TclError {
                    reraise $e
                }
            }
        }

        destructor {}
    }
}

