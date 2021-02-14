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

package require Itcl
package require Subprocess
package require Error
package require Markdown
package require tdom

namespace eval Caius {

    ::itcl::class Runner {

        private variable _config

        method usage {} {
            puts "                                                                        "
            puts "Usage: caius run \[OPTIONS] <executable>                                "
            puts "                                                                        "
            puts "Summary:                                                                "
            puts "                                                                        "
            puts " Runs the <executable> and records its output and exit status. This     "
            puts " command is meant for running tests written with the Caius framework    "
            puts " but is not limited to that.                                            "
            puts "                                                                        "
            puts " If the executable being run produces a conforming result XML on        "
            puts " standard output, Caius will save it as such. If the output is          "
            puts " something different, Caius will coerce it into a result XML readable   "
            puts " by `caius report`.                                                     "
            puts "                                                                        "
            puts "Options:                                                                "
            puts "                                                                        "
            puts " -d, --work-dir=<dir>    Change working directory before running tests. "
            puts " -f, --format <fmt>      Output test results in native 'xml' or 'junit' "
            puts "                         format. Note that the runner only converts the "
            puts "                         input to XML if it is not already XML.         "
            puts " -n, --test-name=<name>  Set test name for non-native tests that don't  "
            puts "                         produce a result XML.                          "
            puts " -t, --timeout=<sec>     Timeout in seconds after which to abort.       "
            puts " -o, --output=<file>     Name of the file to which to print the test    "
            puts "                         report, the default is 'result.xml'.           "
            puts "Windows only:                                                           "
            puts "                                                                        "
            puts " --script-encoding <enc> Assume that Tcl scripts have encoding <enc>.   "
            puts "                                                                        "
            puts "                         If a file with extension .tcl is passed to the "
            puts "                         test runner it is executed as                  "
            puts "                                                                        "
            puts "                         tclsh.exe -encoding <enc> <script>             "
            puts "                                                                        "

        }

        method parse_command_line {{argv {}}} {
            set test_cmd {}

            array unset _config
            set _config(timeout) 0
            set _config(out_file) result.xml
            set _config(work_dir) .
            set _config(outformat) xml
            set _config(encoding) [encoding system]

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
                        $this usage
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
                    --script-encoding {
                        if {$v eq {}} {
                            set v [lindex $argv [incr i]]
                        }
                        set v [string tolower $v]

                        if {[lsearch -exact [encoding names] $v] == -1} {
                            raise ::Caius::Error "unsupported encoding '$v'."
                        }
                        set _config(encoding) $v
                    }
                    default {
                        if {[string index $o 0] eq "-"} {
                            raise ::Caius::Error "unknown command line parameter '$o'"
                        } else {
                            set test_cmd $o

                            if {!([file isfile $test_cmd] && \
                                    ( \
                                     [file executable  $test_cmd] || \
                                     [regexp {\.tcl\Z} $test_cmd] \
                                    )
                                ) && \
                                [set test_cmd [OS::find_executable $o]] eq {}} \
                            {
                                raise ::Caius::Error "could not find executable '$o'"
                            }

                            set _config(test_binary) $test_cmd
                            set test_cmd [file normalize $test_cmd]

                            append test_cmd " " [lrange $argv [incr i] end]
                            set _config(test_cmd) $test_cmd
                            break
                        }
                    }
                }
            }

            if {[llength $argv] == 0 || ![info exists _config(test_binary)]} {
                $this usage
                exit 1
            }

            if {![info exists _config(test_name)]} {
                set _config(test_name) [file tail $_config(test_binary)]
            }

            # make sure reports go to work dir
            if {[file pathtype $_config(out_file)] ne "absolute"} {
                set _config(out_file) [file normalize \
                    $_config(work_dir)/$_config(out_file)]
            }
        }

        method process_test_output {out_name err_name verdict milliseconds} {
            set d10mb [expr 1024 * 1024 * 10]

            set out [open $out_name r]
            set err [open $err_name r]

            chan configure $out -encoding utf-8
            chan configure $err -encoding utf-8

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

            proc xml_escape {text} {
                return [string map {& &amp; < &lt; > &gt; \" &quot;} $text]
            }

            if {$xml_dom eq {}} {
                set out_data  [xml_escape $out_data]
                set err_data  [xml_escape $err_data]
                set test_cmd  [xml_escape [concat {*}$_config(test_cmd)]]
                set test_name [xml_escape [concat {*}$_config(test_name)]]

                if {$_config(outformat) eq "junit"} {
                    set timestamp [clock format \
                        [expr ([clock milliseconds] - $milliseconds) / 1000] \
                            -format "%Y-%m-%dT%H:%M:%S"]

                    if {$verdict eq "FAIL"} {
                        set failures 1
                    } else {
                        set failures 0
                    }

                    append xml "<?xml version=\"1.0\" encoding=\"utf-8\"?>\n" \
                               "<testsuite name=\"$test_cmd\" " \
                               "  timestamp=\"$timestamp\" " \
                               "  hostname=\"[info hostname]\" " \
                               "  tests=\"1\" " \
                               "  failures=\"$failures\" " \
                               "  errors=\"0\" " \
                               "  time=\"[expr $milliseconds / 1000.0]\">\n" \
                               "  <testcase classname=\"$test_name\" " \
                               "    name=\"$test_cmd\" "\
                               "    time=\"[expr $milliseconds / 1000.0]\">\n"

                    if {$verdict eq "FAIL"} {
                        append xml "<failure type=\"failure\"></failure>"

                    }

                    if {$out_data ne {}} {
                        append xml "    <system-out>$out_data</system-out>\n"
                    }
                    if {$err_data ne {}} {
                        append xml "    <system-err>$err_data</system-err>\n"
                    }

                    append xml "  </testcase>\n" \
                               "</testsuite>\n"
                } else {
                    append xml "<?xml version=\"1.0\" encoding=\"utf-8\"?>\n" \
                               "<testset name=\"$test_name\">\n" \
                               "  <test name=\"$test_name\" time=\"$total_time\" verdict=\"${verdict}\">\n" \
                               "    <description>[::Markdown::convert ```$test_cmd```]</description>\n" \
                               "    <log>" \
                               ${out_data} \
                               "</log>\n"

                    if {$err_data ne {}} {
                        append xml "    <error>${err_data}</error>\n"
                    }

                    append xml "  </test>\n" \
                               "</testset>\n"
                }

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
            puts -nonewline $fp [$xml_dom asXML -indent none]

            close $fp
            $xml_dom delete
        }

        method execute {argv} {
            parse_command_line $argv

            set command $_config(test_cmd)
            set cmd [lindex $command 0]

            # special acrobatics on Windows
            if {[regexp {\.tcl\Z} $cmd] && \
                    $::tcl_platform(platform) eq {windows}} \
            {
                set tcl_shell [info nameofexecutable]

                if {$tcl_shell eq {}} {
                    set tcl_shell [auto_execok tclsh.exe]
                }

                # shut your eyes and hope for the best
                if {$tcl_shell eq {}} {
                    set tcl_shell tclsh.exe
                }

                set command "$tcl_shell -encoding ${_config(encoding)} \
                    $command"
            }
            
            cd $_config(work_dir)

            set out [file tempfile out_name]
            chan configure $out -encoding binary
            set err [file tempfile err_name]
            chan configure $err -encoding binary

            set timeout_occurred 0
            set start_time [clock milliseconds]
            except {
                set p [Subprocess::Popen #auto -timeout $_config(timeout) \
                        -stdout $out \
                        -stderr $err {*}$command \
                    ]

                set exit_code [$p wait]
                set timeout_occurred [$p timeout_occurred]

                itcl::delete object $p
            } e {
                ::Subprocess::Error {
                    set err [open $err_name a]
                    puts -nonewline $err "[$e info class]: [$e msg]"
                    close $err
                    set exit_code -3
                }
            }
            set stop_time  [clock milliseconds]
            set total_time [expr $stop_time - $start_time]

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

