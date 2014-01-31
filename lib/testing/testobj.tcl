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

package require Error
package require OS
package require OutputStream

namespace eval Testing {

    ::itcl::class TestObject {
        inherit Docstrings

        private variable _outformat "text"

        public method run {{argc 0} {argv {}}} {
            set tests_to_run {}
            set special_action none

            for {set i 0} {$i < [llength $argv]} {incr i} {
                set o [lindex $argv $i]
                set v {}

                if {[set pos [string first = $o]] != -1} {
                    set v [string range $o [expr $pos + 1] end]
                    set o [string range $o 0 [expr $pos - 1]]
                }

                switch $o {
                    -h -
                    --help {
                        puts "Caius Functional Testing Framework - Test Module [$this info class]  "
                        puts "                                                                     "
                        puts "Usage: [file tail $::argv0] \[OPTIONS] \[<test1> <test2> ...]        "
                        puts "                                                                     "
                        puts "Options:                                                             "
                        puts " -h, --help          Print this help message end exit                "
                        puts " -f, --format <fmt>  Output test results in one of these formats:    "
                        puts "                     'xml'   - Caius native XML reporting format     "
                        puts "                     'junit' - JUnit-compatible XML output           "
                        puts "                     'zero'  - Don't apply special formatting        "
                        puts "                     'text'  - Pretty-printed text (default)         "
                        puts " -l, --list          Print list of available tests in this class.    "
                        puts " -i, --info          Print doc strings of tests and exit.            "

                        return $this
                    }
                    -f -
                    --format {
                        if {$v eq {}} {
                            set v [lindex $argv [incr i]]
                        }
                        switch $v {
                            "xml"   -
                            "junit" -
                            "text"  -
                            "zero" {
                                set _outformat $v
                            }
                            default {
                                raise RuntimeError "unknown output format '$v'."
                            }
                        }
                    }
                    -l -
                    --list {
                        set special_action "list"
                    }
                    -i -
                    --info {
                        set special_action "info"
                    }
                    default {
                        if {[string index $o 0] eq "-"} {
                            raise RuntimeError "unknown command line parameter '$o'."
                        } else {
                            if {[catch {$this info function $o} err] != 0} {
                                raise RuntimeError "no such test '$o'."
                            }

                            lappend tests_to_run $o
                        }
                    }
                }
            }

            switch $special_action {
                "info" {

                    if {[llength $tests_to_run] > 0} {
                        set all_tests $tests_to_run
                    } else {
                        set all_tests [$this ::Testing::TestObject::list_tests]
                    }

                    foreach {test} $all_tests {
                        set docstr [$this get_docstr $test]

                        puts "$test:"
                        if {$docstr ne ""} {
                            puts "[regsub -all -lineanchor {^} $docstr "  "]\n"
                        } else {
                            puts "  \[No description available]\n"
                        }
                    }
                }

                "list" {
                    puts [join [$this ::Testing::TestObject::list_tests] "\n"]
                }

                default {
                    $this ::Testing::TestObject::execute $tests_to_run
                }
            }

            return $this
        }

        public method execute {{tests_to_run {}}} {
            if {[llength $tests_to_run] > 0} {
                set num_tests [llength [set all_tests $tests_to_run]]
            } else {
                set num_tests [llength [set all_tests \
                    [$this ::Testing::TestObject::list_tests]]]
            }

            set count 1
            switch $_outformat {
                xml {
                    set result [::Testing::XMLFormatter #auto]
                }
                zero {
                    set result [::Testing::ZeroFormatter #auto]
                }
                junit {
                    set result [::Testing::JUnitFormatter #auto]
                }
                default {
                    set result [::Testing::TextFormatter #auto]
                }
            }

            $result module_start [$this info class]
            $this ::Testing::TestObject::setup setup_before

            foreach {test} $all_tests {
                set verdict "PASS"

                $result test_start $test $count $num_tests
                $result test_desc  [$this get_docstr $test]

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

            $this ::Testing::TestObject::teardown teardown_after
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

        private method setup {{method setup}} {
            foreach {class} [lreverse [$this info heritage]] {
                if {![catch { lassign [$this info function ${class}::${method} \
                        -protection -type] protection type }]} \
                {
                    if {$type eq "method" && $protection eq "public"} {
                        $this ${class}::${method}
                    }
                }
            }
        }

        private method teardown {{method teardown}} {
            foreach {class} [$this info heritage] {
                if {![catch { lassign [$this info function ${class}::${method} \
                        -protection -type] protection type }]} \
                {
                    if {$type eq "method" && $protection eq "public"} {
                        $this ${class}::${method}
                    }
                }
            }
        }
    }
}

