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

package require Itcl
package require Error
package require tdom

namespace eval Caius {

    ::itcl::class Testplan {

        private variable _config
        private variable _count

        constructor {} {
            set _count 0
        }

        method usage {} {
            puts "                                                                       "
            puts "Usage: caius runplan \[OPTIONS] <testplan>                             "
            puts "                                                                       "
            puts "Summary:                                                               "
            puts "                                                                       "
            puts " Executes all tests listed in the testplan. The testplan is written in "
            puts " an XML-based format. An example testplan can be found in the source   "
            puts " distribution.                                                         "
            puts "                                                                       "
            puts "Options:                                                               "
            puts "                                                                       "
            puts " -d, --work-dir <dir>  Change working directory before running tests.  "
            puts " -f, --format <fmt>    Output test results either in Caius' native     "
            puts "                       'xml' result format or as 'junit' XML.          "
            puts " -j, --jobs <num>      Run this many tests in parallel, if the testplan"
            puts "                       contains parallelizable sections.               "
            puts "                                                                       "
        }

        method parse_command_line {{argv {}}} {
            set _config(work_dir) .
            set _config(outformat) xml
            set _config(jobs) 1

            if {[llength $argv] == 0} {
                lappend argv --help-me-please-i-have-no-clue
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
                    --help-me-please-i-have-no-clue -
                    --help {
                        $this usage

                        if {$o eq {--help-me-please-i-have-no-clue}} {
                            exit 1
                        }

                        exit 0
                    }
                    -d -
                    --work-dir {
                        if {$v eq {}} { set v [lindex $argv [incr i]] }
                        if {![file isdirectory $v]} {
                            raise ::Caius::Error "'$v' does not exist or isn't a directory."
                        }
                        set _config(work_dir) $v
                    }
                    -f -
                    --format {
                        if {$v eq {}} {
                            set v [lindex $argv [incr i]]
                        }
                        switch $v {
                            "xml"   -
                            "junit" {
                                set _config(outformat) $v

                                # make sure this propagates to children
                                set ::env(CAIUS_OUTPUT_FORMAT) $v
                            }
                            default {
                                raise RuntimeError "unknown output format '$v'."
                            }
                        }
                    }
                    -j -
                    --jobs {
                        if {$v eq {}} { set v [lindex $argv [incr i]] }
                        if {![string is integer $v] || ($v < 0)} {
                            raise ::Caius::Error "'$v' is not an unsigned integer."
                        }
                        set _config(jobs) $v
                    }
                    default {
                        if {$i < [expr [llength $argv] - 1]} {
                            $this usage
                            exit 1
                        }

                        if {![file isfile $o]} {
                            raise ::Caius::Error "testplan file '$o' not found"
                        }

                        set _config(testplan) [file normalize $o]
                        set _config(testplan_dir) [file dirname \
                            $_config(testplan)]
                    }
                }
            }

            if {![info exists _config(testplan)]} {
                $this usage
                exit 1
            }
        }

        method execute {argv} {
            parse_command_line $argv

            # load testplan XML from disk
            set fp {}
            except {
                set fp [open $_config(testplan) r]
                set testplan [dom parse -channel $fp]
            } e {
                ::Exception {
                    raise ::Caius::Error "failed to read testplan: '[$e msg]'"
                }
            } final {
                if {$fp ne {}} { close $fp }
            }

            # reset internal counter
            set _count 0

            # iterate over XML and execute tests
            set old_work_dir [pwd]
            cd $_config(work_dir)
            set exit_code [process_testplan [$testplan documentElement]]
            cd $old_work_dir

            $testplan delete
            return $exit_code
        }

        method process_testplan {root {wait 1} {work_dir {}}} {
            set exit_code 0
            set threads {}

            if {$work_dir eq {}} {
                set work_dir [pwd]
            }

            foreach {child} [$root childNodes] {

                # determine what action to take
                switch [$child nodeName] {
                    parallel {
                        incr exit_code [process_testplan $child 0 $work_dir]
                        continue
                    }
                    run {
                        # go on
                    }
                    default {
                        continue
                    }
                }

                # fix parameters for runner
                set command [string trim [$child text]]
                set timeout [$child getAttribute timeout 0]
                set outformat $_config(outformat)

                if {[file pathtype $command] ne {absolute}} {
                    set command "$_config(testplan_dir)/$command"
                }

                set subdir [format "%03d_%s" [incr _count] \
                    [regsub {[-.]} [file tail [lindex [split $command] 0]] {_}]\
                ]
                file mkdir $work_dir/$subdir

                # initiate test exeuction in thread
                lappend threads [if "1" "::thread::create -joinable {
                    package require Caius

                    set command   {$command}
                    set work_dir  {$work_dir/$subdir}
                    set timeout   {$timeout}
                    set outformat {$outformat}

                    return \[::Caius::Testplan::run_test \$command \$work_dir \\
                        \$timeout \$outformat\]
                }"]

                # wait if queue is full, i.e. max jobs running
                if {$wait || [llength $threads] >= $_config(jobs)} {
                    if {[::thread::join [lindex $threads 0]] != 0} {
                        incr exit_code
                    }
                    set threads [lreplace $threads 0 0]
                }
            }

            # wait on last threads to finish up
            while {[llength $threads] > 0} {
                if {[::thread::join [lindex $threads 0]] != 0} {
                    incr exit_code
                }
                set threads [lreplace $threads 0 0]
            }

            return $exit_code
        }

        proc run_test {command work_dir timeout outformat} {
            set exit_code 0
            set runner [::Caius::Runner #auto]

            except {
                puts "Running '$command'"

                set rval [$runner execute "-f $outformat -d $work_dir \
                    -t $timeout $command"]

                if {$rval != 0} {
                    set exit_code 1
                }
            } e {
                ::Exception {
                    puts stderr "Error: [$e msg]"
                    set exit_code 1
                }
            }

            ::itcl::delete object $runner
            return $exit_code
        }
    }
}

