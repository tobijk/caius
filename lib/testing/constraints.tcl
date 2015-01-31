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

package require Error
package require OS

namespace eval Testing {

    namespace export \
        set_constraint \
        test_constraints \
        constraints

    proc set_constraint {constraint value} {
        if {![string is boolean -strict $value]} {
            raise ::ValueError "$value is not a boolean value."
        }

        set ::Testing::_constraints($constraint) $value
    }

    proc test_constraints {args} {
        foreach {constraint} $args {
            if {!([info exists ::Testing::_constraints($constraint)] && \
                $::Testing::_constraints($constraint))} \
            {
                return 0
            }
        }

        return 1
    }

    proc constraints {{constraints {}} block} {
        foreach {constraint} $constraints {
            if {[string index $constraint 0] eq {!}} {
                set wanted 0
                set constraint [string replace $constraint 0 0]
            } else {
                set wanted 1
            }

            if {[info exists ::Testing::_constraints($constraint)] && \
                $::Testing::_constraints($constraint)} \
            {
                if {!$wanted} {
                    return
                }
            } else {
                if {$wanted} {
                    return
                }
            }
        }

        uplevel $block
    }

    proc init_default_constraints {} {
        set ::Testing::_constraints(unix) false
        set ::Testing::_constraints(win)  false
        set ::Testing::_constraints(mac)  false

        set ::Testing::_constraints(unixOrWin) false
        set ::Testing::_constraints(macOrWin)  false
        set ::Testing::_constraints(macOrUnix) false

        set ::Testing::_constraints(tempNotUnix) true
        set ::Testing::_constraints(tempNotWin)  true
        set ::Testing::_constraints(tempNotMac)  true

        set ::Testing::_constraints(unixCrash) true
        set ::Testing::_constraints(winCrash)  true
        set ::Testing::_constraints(macCrash)  true

        set ::Testing::_constraints(emptyTest) false
        set ::Testing::_constraints(knownBug)  false
        set ::Testing::_constraints(nonPortable) false
        set ::Testing::_constraints(userInteraction) false

        set ::Testing::_constraints(pointer64) false
        set ::Testing::_constraints(unixExecs) true
        set ::Testing::_constraints(root) false
        set ::Testing::_constraints(nonRoot) true

        if {$::tcl_platform(platform) eq {unix}} {
            set ::Testing::_constraints(unix) true
            set ::Testing::_constraints(tempNotUnix) false
            set ::Testing::_constraints(unixCrash) false
        }

        if {$::tcl_platform(platform) eq {windows}} {
            set ::Testing::_constraints(win) true
            set ::Testing::_constraints(tempNotWin) false
            set ::Testing::_constraints(winCrash) false
        }

        if {$::tcl_platform(platform) eq {macintosh}} {
            set ::Testing::_constraints(mac) true
            set ::Testing::_constraints(tempNotMac) false
            set ::Testing::_constraints(macCrash) false
        }

        if {$::Testing::_constraints(unix) || $::Testing::_constraints(win)} {
            set ::Testing::_constraints(unixOrWin) true
        }
        if {$::Testing::_constraints(mac) || $::Testing::_constraints(win)} {
            set ::Testing::_constraints(macOrWin) true
        }
        if {$::Testing::_constraints(mac) || $::Testing::_constraints(unix)} {
            set ::Testing::_constraints(macOrUnix) true
        }

        if {$::tcl_platform(pointerSize) == 4} {
            set ::Testing::_constraints(pointer64) true
        }

        foreach {cmd} {cat echo sh wc rm sleep fgrep ps chmod mkdir} {
            if {[::OS::find_executable $cmd] eq {}} {
                set ::Testing::_constraints(unixExecs) false
                break
            }
        }

        if {$::Testing::_constraints(unix)} {
            set whoami [::OS::find_executable whoami]

            if {($whoami ne {}) && ([exec $whoami] eq {root})} {
                set ::Testing::_constraints(root) true
                set ::Testing::_constraints(nonRoot) false
            }
        }
    }

    if {![array exists _constraints]} {
        init_default_constraints
    }
}

