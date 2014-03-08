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

namespace eval Cli {

    ##
    # \brief A convenience class for controlling a serial line with Expect.
    #
    ::itcl::class Stty {
        inherit Cli::Core

        ##
        # Connects an Expect session object to a serial line.
        #
        # @param port              the serial port to open
        # @param -baud rate        the baud rate (default 56000)
        # @param -parity <parity>  parity (y or n, default n)
        # @param -bits <bits>      data bits (default 8)
        # @param -stop_bits <bits> stop bits (default 1)
        constructor {port args} {
            set options {
                {baud.arg  56000 "set the channel to which to redirect stdout"}
                {parity.arg    n "set the channel to which to redirect stderr"}
                {data_bits.arg 8 "set the channel to which to redirect stdin" }
                {stop_bits.arg 1 "timeout in seconds"                         }
            }

            array set params [::cmdline::getoptions args $options]

            except {
                set tty_mode [join [list $params(baud) $params(parity) \
                    $params(data_bits) $params(stop_bits)] ","]
                set fp [open $port r+]
                fconfigure $fp -buffering none -translation binary \
                    -mode $tty_mode -eofchar {}
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

