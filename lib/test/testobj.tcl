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

        private variable _outformat "plain"

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

            set count 1
            set result [::Testing::TestResultFormatter #auto $_outformat]

            $result module_start [$this info class]

            foreach {test} $all_tests {
                set verdict "PASS"

                $result test_start $test $count $num_tests
                except {
                    $result log_start

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
                            $result log_warning [$et stack_trace]
                        }
                    } final {
                        set stop_time [clock milliseconds]
                        $result log_end
                    }
                }
                set total_time [expr $stop_time - $start_time]

                if {$verdict eq "FAIL"} {
                    $result log_error [$e stack_trace]
                }

                $result test_end $verdict $total_time

                $result reset
                incr count
            }

            $result module_end

            ::itcl::delete object $result
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
    }
}

