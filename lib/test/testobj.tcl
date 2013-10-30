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

package require Error
package require OS
package require OutputStream
package require Expect
package require fileutil

namespace eval Testing {

    ::itcl::class TestObject {

        method run {} {
            set num_tests [llength [set all_tests [$this test_list]]]

            set indenter_out  [::itcl::code [OutputStream::Indenter #auto "    "]]
            set escape_filter [::itcl::code [OutputStream::AnsiEscapeFilter #auto]]
            set newlines_flip [::itcl::code [OutputStream::FlipNewlines #auto unix]]
            set redirect_err  [::itcl::code [OutputStream::Redirect #auto stdout]]

            puts "Exercising tests in [$this info class]:"
            set test_count 1

            foreach {test} $all_tests {
                set verdict "PASS"

                # print a heading
                set heading "* Test $test_count/$num_tests: [namespace tail $test] "
                append heading [string repeat "-" [expr 70 - [string length $heading]]] " "
                puts "$heading START"

                # setup log channel transformations
                puts "- Log:"
                chan push stdout $indenter_out
                chan push stdout $newlines_flip
                chan push stdout $escape_filter
                chan push stderr $redirect_err

                # run setup, test, teardown
                except {
                    $this ::Testing::TestObject::setup
                    $this $test
                    $this ::Testing::TestObject::teardown
                } e {
                    ::Exception {
                        set verdict "FAIL"
                    }
                } final {
                    # remove log channel transformations
                    chan pop stderr
                    chan pop stdout
                    chan pop stdout
                    chan pop stdout
                }
                puts ""

                # print stack trace
                if {$verdict eq "FAIL"} {
                    puts "- Trace:"
                    puts [regsub -all -lineanchor {^} [$e stack_trace] "    "]
                    puts ""
                }

                puts "- Verdict: $verdict\n"
                incr test_count
            }

            ::itcl::delete object $indenter_out
            ::itcl::delete object $newlines_flip
            ::itcl::delete object $escape_filter
            ::itcl::delete object $redirect_err
        }

        # PROTECTED

        protected method test_list {} {
            set all_methods [lsort [$this info function]]
            set all_tests {}

            foreach {m} $all_methods {
                lassign [$this info function $m -protection -type] protection type

                if {$type eq "method" && $protection eq "public"} {
                    set tail [namespace tail $m]

                    if {[regexp -nocase {^test[^[:space:]]*} $tail]} {
                        lappend all_tests $m
                    }
                }
            }

            return $all_tests
        }

        protected method setup {} {
            foreach {class} [lreverse [$this info heritage]] {
                if {![catch { lassign [$this info function ${class}::setup \
                        -protection -type] protection type }]} \
                {
                    if {$type eq "method" && $protection eq "public"} {
                        $this ${class}::setup
                    }
                }
            }
        }

        protected method teardown {} {
            foreach {class} [$this info heritage] {
                if {![catch { lassign [$this info function ${class}::teardown \
                        -protection -type] protection type }]} \
                {
                    if {$type eq "method" && $protection eq "public"} {
                        $this ${class}::teardown
                    }
                }
            }
        }
    }
}

