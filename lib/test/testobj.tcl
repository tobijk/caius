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

namespace eval Testing {

    ::itcl::class TestObject {

        private variable _outformat "text"

        public method run {{argc 0} {argv {}}} {
            set tests_to_run {}

            foreach {v} $argv {
                switch $v {
                    "-h" -
                    "--help" {
                        puts "Caius Functional Testing Framework - Test Module [$this info class]  "
                        puts "                                                                     "
                        puts "Usage: [file tail $::argv0] \[OPTIONS] \[<test1> <test2> ...]        "
                        puts "                                                                     "
                        puts "Options:                                                             "
                        puts " -h, --help        Print this help message end exit.                 "
                        puts " -x, --xml         Output test results in XML format.                "
                        puts " -l, --list        Print list of available tests in this class.      "
                        return
                    }
                    "-x" -
                    "--xml" {
                        set _outformat "xml"
                    }
                    "-l" -
                    "--list" {
                        puts [join [$this ::Testing::TestObject::list_tests] "\n"]
                        return
                    }
                    default {
                        if {[string index $v 0] eq "-"} {
                            raise RuntimeError "unknown command line parameter '$v'."
                        } else {
                            if {[catch {$this info function $v} err] != 0} {
                                raise RuntimeError "no such test '$v'."
                            }

                            lappend tests_to_run $v
                        }
                    }
                }
            }

            $this ::Testing::TestObject::execute $tests_to_run
        }

        public method execute {{tests_to_run {}}} {
            if {[llength $tests_to_run] > 0} {
                set num_tests [llength [set all_tests $tests_to_run]]
            } else {
                set num_tests [llength [set all_tests \
                    [$this ::Testing::TestObject::list_tests]]]
            }

            set indenter_out  [::itcl::code [OutputStream::Indenter #auto "    "]]
            set escape_filter [::itcl::code [OutputStream::AnsiEscapeFilter #auto]]
            set newlines_flip [::itcl::code [OutputStream::FlipNewlines #auto unix]]
            set redirect_err  [::itcl::code [OutputStream::Redirect #auto stdout]]

            set count 1

            foreach {test} $all_tests {
                set verdict "PASS"

                $this ::Testing::TestObject::record test_info $test $count $num_tests
                except {
                    puts "- Log:"
                    chan push stdout $indenter_out
                    chan push stdout $newlines_flip
                    chan push stdout $escape_filter
                    chan push stderr $redirect_err

                    set start_time [clock milliseconds]

                    $this ::Testing::TestObject::setup
                    $this $test
                } e {
                    ::Exception {
                        set verdict "FAIL"
                    }
                } final {
                    except {
                        $this ::Testing::TestObject::teardown
                    } et {
                        ::Exception {
                            $this ::Testing::TestObject::record warning [$et stack_trace]
                        }
                    } final {
                        set stop_time [clock milliseconds]

                        chan pop stderr
                        chan pop stdout
                        chan pop stdout
                        chan pop stdout
                    }
                }
                set total_time [expr $stop_time - $start_time]

                if {$verdict eq "FAIL"} {
                    $this record trace [$e stack_trace]
                }

                $this ::Testing::TestObject::record result $verdict $total_time
                incr count
            }

            ::itcl::delete object $indenter_out
            ::itcl::delete object $newlines_flip
            ::itcl::delete object $escape_filter
            ::itcl::delete object $redirect_err
        }

        public method list_tests {} {
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

        private method setup {} {
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

        private method teardown {} {
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

        private method record {type args} {
            switch $type {
                test_info {
                    lassign $args test_name count num_tests
                    set heading "* Test $count/$num_tests: [string trimleft $test_name ::] "
                    append heading [string repeat - [expr 70 - [string length $heading]]]
                    puts "$heading START"
                }
                warning -
                trace {
                    lassign $args msg
                    puts "\n- [string totitle $type]:"
                    puts [regsub -all -lineanchor {^} $msg "    "]
                }
                result {
                    lassign $args verdict milliseconds

                    set m  [expr $milliseconds / (60000)]
                    set s  [expr ($milliseconds - $m * 60000) / 1000]
                    set ms [expr $milliseconds % 1000]

                    set total_time [format "%02d min %02d sec %03d ms" $m $s $ms]

                    puts ""
                    set footer "- Verdict: $verdict"
                    append footer [string repeat " " [expr 70 - 15 - [string length $total_time] + 5]]
                    append footer " " $total_time "\n"
                    puts $footer
                }
            }
        }
    }
}

