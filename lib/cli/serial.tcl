#
#   Caius Functional Testing Framework
#
#   Copyright 2013 Tobias Koch <tobias.koch@gmail.com>
#
#   This program is free software; you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation; either version 2 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#
#   See the LICENSE file in the source distribution for more information.
#

package require Itcl
package require Error

namespace eval Cli {

    ::itcl::class Stty {
        inherit Cli::Core

        constructor {port {baud 56000} {parity n} {data_bits 8} {stop_bits 1}} {
            except {
                set fp [open $port r+]
                fconfigure $fp -buffering none -translation binary \
                    -mode $baud,$parity,$data_bits,$stop_bits -eofchar {}
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

