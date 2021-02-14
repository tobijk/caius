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

## \file spawn.tcl
# \brief A wrapper for controlling subprocesses with Expect.

package require Itcl
package require Error

namespace eval CliDriver {

    ##
    # \brief A convenience class for controlling subprocesses with Expect.
    #
    ::itcl::class Spawn {
        inherit CliDriver::Core

        ##
        # Connects an Expect session object to a subprocess.
        #
        # @param args  the command to execute
        #
        # The parameter list passed to the constructor is interpreted as the
        # command line to be executed to launch the subprocess.
        #
        constructor {args} {
            except {
                spawn {*}$args
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

