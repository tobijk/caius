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
package require Subprocess
package require Error
package require markdown
package require tdom

namespace eval Caius {

    ::itcl::class Runner {

        private variable _config

        method usage {} {
            puts "                                                                      "
            puts "Usage: caius run \[OPTIONS] <executable>                              "
            puts "                                                                      "
            puts "Summary:                                                              "
            puts "                                                                      "
            puts " Runs the <executable> and records its output and exit status. This   "
            puts " command is meant for running tests written with the Caius framework  "
            puts " but is not limited to that.                                          "
            puts "                                                                      "
            puts " If the executable being run produces a conforming result XML on      "
            puts " standard output, Caius will save it as such. If the output is        "
            puts " something different, Caius will coerce it into a result XML readable "
            puts " by `caius report`.                                                   "
            puts "                                                                      "
            puts "Options:                                                              "
            puts "                                                                      "
            puts " -d, --work-dir=<dir>   Change working directory before running tests."
            puts " -n, --test-name=<name> Set test name for non-native tests that don't "
            puts "                        produce a result XML.                         "
            puts " -t, --timeout=<sec>    Timeout in seconds after which to abort.      "
            puts " -o, --output=<file>    Name of the file to which to print the test   "
            puts "                        report, the default is 'result.xml'.          "
        }

        method parse_command_line {{argv {}}} {
            set test_cmd {}
            set _config(timeout) 0
            set _config(out_file) result.xml
            set _config(work_dir) .

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
                        set _config(work_dir) $v
                        if {![file isdirectory $v]} {
                            raise ::Caius::Error "'$v' does not exist or isn't a directory"
                        }
                    }
                    -t -
                    --timeout {
                        if {$v eq {}} { set v [lindex $argv [incr i]] }
                        if {![string is integer $v]} {
                            raise ::Caius::Error "invalid timeout, expected integer but got '$v'"
                        }
                        set _config(timeout) [expr $v * 1000]
                    }
                    -n -
                    --test-name {
                        if {$v eq {}} { set v [lindex $argv [incr i]] }
                        set _config(test_name) $v
                    }
                    -o -
                    --output {
                        if {$v eq {}} { set v [lindex $argv [incr i]] }
                        set _config(out_file) $v
                    }
                    default {
                        if {[string index $o 0] eq "-"} {
                            raise ::Caius::Error "unknown command line parameter '$o'"
                        } else {
                            set test_cmd $o

                            if {![file executable $test_cmd] && \
                                    [set test_cmd [OS::find_executable $o]] eq {}} {
                                raise ::Caius::Error "could not find executable '$o'"
                            }

                            set _config(test_binary) $test_cmd

                            append test_cmd { } [lrange $argv [incr i] end]
                            set _config(test_cmd) $test_cmd
                            break
                        }
                    }
                }
            }

            if {![info exist _config(test_name)]} {
                set _config(test_name) [file tail $_config(test_binary)]
            }
        }

        method process_test_output {out_name err_name verdict milliseconds} {
            set d10mb [expr 1024 * 1024 * 10]

            set out [open $out_name r]
            set err [open $err_name r]

            set xml_dom {}

            if {[file size $out_name] <= $d10mb} {
                except {
                    set xml_dom [dom parse -channel $out]
                } e {
                    ::TclError {
                        seek $out 0 start
                        set out_data [read $out]
                    }
                }
            } else {
                set out_data [read $out $d10mb]
            }

            # read max 10 MB per channel
            set err_data [read $err $d10mb]

            close $out
            close $err
            file delete $out_name
            file delete $err_name

            # format time
            set m  [expr $milliseconds / (60000)]
            set s  [expr ($milliseconds - $m * 60000) / 1000]
            set ms [expr $milliseconds % 1000]
            set total_time [format "%02d:%02d.%03d" $m $s $ms]

            if {$xml_dom eq {}} {
                set out_data [string map {& &amp; < &lt; > &gt; \" &quot;} $out_data]
                set err_data [string map {& &amp; < &lt; > &gt; \" &quot;} $err_data]

                append xml "<?xml version=\"1.0\" encoding=\"utf-8\"?>\n" \
                           "<testset name=\"${_config(test_name)}\">\n" \
                           "  <test name=\"${_config(test_name)}\" time=\"$total_time\" verdict=\"${verdict}\">\n" \
                           "    <description>[::markdown::convert ```${_config(test_cmd)}```]</description>\n" \
                           "    <log>" \
                           ${out_data} \
                           "</log>\n"

                if {$err_data ne {}} {
                    append xml "    <error>${err_data}</error>\n"
                }

                append xml "  </test>\n" \
                           "</testset>\n"

                except {
                    set xml_dom [dom parse $xml]
                } e {
                    ::TclError {
                        raise ::Caius::Error "unable to construct and parse test result XML"
                    }
                }
            }

            set fp [open $_config(out_file) w+]
            chan configure $fp -encoding "utf-8"

            puts $fp "<?xml version=\"1.0\" encoding=\"utf-8\"?>"
            puts -nonewline $fp [$xml_dom asXML]

            close $fp
            $xml_dom delete
        }

        method execute {argv} {
            parse_command_line $argv

            # set working directory
            cd $_config(work_dir)

            set out [file tempfile out_name]
            set err [file tempfile err_name]

            set start_time [clock milliseconds]  
            set p [Subprocess #auto -timeout $_config(timeout) -stdout $out \
                -stderr $err {*}$_config(test_cmd)]
            set exit_code [$p wait]
            set stop_time [clock milliseconds]

            set total_time [expr $stop_time - $start_time]
            set timeout_occurred [$p timeout_occurred]
            itcl::delete object $p

            if {$timeout_occurred} {
                set verdict "TIMEOUT"
            } elseif {$exit_code != 0} {
                set verdict "FAIL"
            } else {
                set verdict "PASS"
            }

            process_test_output $out_name $err_name $verdict $total_time
            return $exit_code
        }
    }
}

