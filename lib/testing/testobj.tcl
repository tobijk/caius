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
package require OutputStream

namespace eval Testing {

    ::itcl::class TestObject {
        inherit Docstrings

        private variable _outformat "xml"
        private variable _verdict PASS
        private variable _pattern_list {}
        private variable _constraints

        public method set_constraint {constraint value} {
            set _constraints($constraint) $value
        }

        public method constraints {args} {
            if {[lindex $args 0] eq {-test}} {
                set args [lreplace $args 0 0]
                set test_only 1
            } else {
                set test_only 0
            }

            foreach {constraint} $args {
                if {[string index $constraint 0] eq {!}} {
                    set wanted 0
                    set constraint [string replace $constraint 0 0]
                } else {
                    set wanted 1
                }

                if {[info exists _constraints($constraint)] && \
                    $_constraints($constraint)} \
                {
                    if {!$wanted} {
                        if {$test_only} {
                            return 0
                        } else {
                            raise ::Testing::TestSkipped \
                                "constraint !${constraint} not satisfied"
                        }
                    }
                } else {
                    if {$wanted} {
                        if {$test_only} {
                            return 0
                        } else {
                            raise ::Testing::TestSkipped \
                                "constraint ${constraint} not satisfied"
                        }
                    }
                }
            }

            return 1
        }

        public method run {{argv {}}} {
            $this init_default_constraints

            set tests_to_run {}
            set special_action none

            # pre-initialize from environment
            if {[info exists ::env(CAIUS_OUTPUT_FORMAT)]} {
                set _outformat $::env(CAIUS_OUTPUT_FORMAT)
            }

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
                        puts "Caius Functional Testing Framework - Test Module [$this info class]   "
                        puts "                                                                      "
                        puts "Usage: [file tail $::argv0] \[OPTIONS] \[<test1> <test2> ...]         "
                        puts "                                                                      "
                        puts "Options:                                                              "
                        puts " -h, --help           Print this help message end exit                "
                        puts "                                                                      "
                        puts " -f, --format <fmt>   Output test results in one of these formats:    "
                        puts "                                                                      "
                        puts "                      junit:                                          "
                        puts "                       XML output compatible with what Ant produces   "
                        puts "                       for JUnit tests. This format is useful for     "
                        puts "                       running Caius in Java-centric CI systems.      "
                        puts "                                                                      "
                        puts "                      text:                                           "
                        puts "                       Verbose test logs in plain text format. This   "
                        puts "                       format is most suitable during development or  "
                        puts "                       to replay and analyze failing tests.           "
                        puts "                                                                      "
                        puts "                      xml:                                            "
                        puts "                       This is Caius' native XML reporting format and "
                        puts "                       the default when executing tests via the test- "
                        puts "                       executor tool.                                 "
                        puts "                                                                      "
                        puts "                      zero:                                           "
                        puts "                       No formatting whatsoever is applied to the     "
                        puts "                       test output. Choose this when using a test     "
                        puts "                       executor which does its own formatting. It is  "
                        puts "                       generally necessary to call tests individually "
                        puts "                       when using this mode.                          "
                        puts "                                                                      "
                        puts " -i, --info           Print test descriptions, don't run the tests.   "
                        puts " -l, --list           Print list of tests in given modules.           "
                        puts "                                                                      "
                        puts " -m, --match <glob>   Run only tests matching glob. This option can be"
                        puts "                      used multiple times.                            "

                        return 0
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
                    -m -
                    --match {
                        if {$v eq {}} {
                            if {[set v [lindex $argv [incr i]]] eq {}} {
                                raise RuntimeError "--match option requires an argument."
                            }
                        }

                        lappend _pattern_list $v
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

            if {$_verdict ne {PASS}} {
                return 1
            }

            return 0
        }

        public method execute {{tests_to_run {}}} {
            if {[llength $tests_to_run] == 0} {
                set tests_to_run [$this ::Testing::TestObject::list_tests]
            }

            if {[llength $_pattern_list] > 0} {
                set all_tests {}

                foreach {test} $tests_to_run {
                    foreach {pattern} $_pattern_list {
                        if {[string match $pattern $test]} {
                            lappend all_tests $test
                            break
                        }
                    }
                }
            } else {
                set all_tests $tests_to_run
            }

            set num_tests [llength [set all_tests]]

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

            foreach {test} $all_tests {
                set verdict "PASS"

                $result test_start $test $count $num_tests
                $result test_desc  [$this get_docstr $test]

                $result log_start
                if {$count == 1} {
                    except {
                        $this ::Testing::TestObject::setup setup_before
                    } e {
                        ::Exception {
                            $result log_error [$e stack_trace]
                        }
                    }
                }

                set start_time [clock milliseconds]
                except {
                    $this ::Testing::TestObject::setup
                    $this $test
                } e {
                    ::Testing::TestSkipped {
                        set e_stack_trace [$e msg]
                        set verdict "SKIP"
                    }
                    ::Exception {
                        set e_stack_trace [$e stack_trace]
                        set verdict "FAIL"
                    }
                } final {
                    except {
                        $this ::Testing::TestObject::teardown
                    } et {
                        ::Exception {
                            $result log_error [$et stack_trace]
                        }
                    } final {
                        set stop_time [clock milliseconds]
                    }
                }
                set total_time [expr $stop_time - $start_time]

                switch $verdict {
                    "FAIL" {
                        set _verdict FAIL
                        $result log_error $e_stack_trace
                    }
                    "SKIP" {
                        $result log_error $e_stack_trace
                    }
                }

                if {$count == $num_tests} {
                    except {
                        $this ::Testing::TestObject::teardown teardown_after
                    } e {
                        ::Exception {
                            $result log_error [$e stack_trace]
                        }
                    }
                }

                $result log_end

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

        private method init_default_constraints {} {
            set _constraints(unix) false
            set _constraints(win)  false
            set _constraints(mac)  false

            set _constraints(unixOrWin) false
            set _constraints(macOrWin)  false
            set _constraints(macOrUnix) false

            set _constraints(tempNotUnix) true
            set _constraints(tempNotWin)  true
            set _constraints(tempNotMax)  true

            set _constraints(unixCrash) true
            set _constraints(winCrash)  true
            set _constraints(macCrash)  true

            set _constraints(emptyTest) false
            set _constraints(knownBug)  false
            set _constraints(nonPortable) false
            set _constraints(userInteraction) false

            set _constraints(pointer64) false
            set _constraints(unixExecs) true
            set _constraints(root) false
            set _constraints(nonRoot) true

            if {$::tcl_platform(platform) eq {unix}} {
                set _constraints(unix) true
                set _constraints(tempNotUnix) false
                set _constraints(unixCrash) false
            }

            if {$::tcl_platform(platform) eq {windows}} {
                set _constraints(win) true
                set _constraints(tempNotWin) false
                set _constraints(winCrash) false
            }

            if {$::tcl_platform(platform) eq {macintosh}} {
                set _constraints(mac) true
                set _constraints(tempNotMac) false
                set _constraints(macCrash) false
            }

            if {$_constraints(unix) || $_constraints(win)} {
                set _constraints(unixOrWin) true
            }
            if {$_constraints(mac) || $_constraints(win)} {
                set _constraints(macOrWin) true
            }
            if {$_constraints(mac) || $_constraints(unix)} {
                set _constraints(macOrUnix) true
            }

            if {$::tcl_platform(pointerSize) == 4} {
                set _constraints(pointer64) true
            }

            foreach {cmd} {cat echo sh wc rm sleep fgrep ps chmod mkdir} {
                if {[::OS::find_executable $cmd] eq {}} {
                    set _constraints(unixExecs) false
                    break
                }
            }

            if {$_constraints(unix)} {
                set whoami [::OS::find_executable whoami]

                if {($whoami ne {}) && ([exec $whoami] eq {root})} {
                    set _constraints(root) true
                    set _constraints(nonRoot) false
                }
            }
        }

        private method setup {{method setup}} {
            foreach {class} [lreverse [uplevel #0 [list $this] info heritage]] {
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
            foreach {class} [uplevel #0 [list $this] info heritage] {
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

