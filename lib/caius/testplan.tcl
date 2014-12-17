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

package require Itcl
package require Error
package require tdom

namespace eval Caius {

    ::itcl::class Testplan {

        private variable _config
        private variable _counter
        private variable _runner

        constructor {} {
            set _counter 0
            set _runner [::Caius::Runner #auto]
        }

        destructor {
            ::itcl::delete object $_runner
        }

        method usage {} {
            puts "                                                                        "
            puts "Usage: caius runplan \[OPTIONS] <testplan>                              "
            puts "                                                                        "
            puts "Summary:                                                                "
            puts "                                                                        "
            puts " Executes all tests listed in the testplan. The testplan is written in  "
            puts " an XML-based format. An example testplan can be found in the source    "
            puts " distribution.                                                          "
            puts "                                                                        "
            puts "Options:                                                                "
            puts "                                                                        "
            puts " -d, --work-dir <dir>    Change working directory before running tests. "
            puts " -f, --format <fmt>      Output test results either in Caius' native    "
            puts "                         'xml' result format or as 'junit' XML.         "
            puts "Windows only:                                                           "
            puts "                                                                        "
            puts " --script-encoding <enc> Encoding of Tcl scripts in the test suite.     "
            puts "                                                                        "
            puts "                         If a file with extension .tcl is encountered   "
            puts "                         in the testplan, it is executed as             "
            puts "                                                                        "
            puts "                         tclsh.exe -encoding <enc> <script>             "
            puts "                                                                        "
        }

        method parse_command_line {{argv {}}} {
            set _config(work_dir) .
            set _config(outformat) xml
            set _config(encoding) [encoding system]

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
                                raise ::Caius::Error "unknown output format '$v'."
                            }
                        }
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

            # read the testplan XML into DOM tree
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

            set root [$testplan documentElement]

            cd $_config(work_dir)
            set _config(work_dir) [pwd]

            set _counter 0
            set exit_code 0

            # execute testplan test by test
            foreach {child} [$root childNodes] {
                switch [$child nodeName] {
                    run {
                        set command [string trim [$child text]]
                        set timeout [$child getAttribute timeout 0]

                        if {[execute_command $command $timeout] != 0} {
                            set exit_code 1
                        }
                    }
                    default {}
                }
            }

            $testplan delete
            return $exit_code
        }

        method execute_command {command {timeout 0}} {
            set exit_code 0
            set cmd [lindex $command 0]

            # interpret commands relative to testplan
            if {[file pathtype $cmd] ne {absolute}} {
                set command [lreplace $command 0 0 \
                    [file join $_config(testplan_dir) $cmd] \
                ]
            }

            # create directory for artifacts
            set subdir [format "%04d_%s" [incr _counter] \
                [regsub {[-.]} [file tail [lindex [split $cmd] 0]] {_}]\
            ]
            file mkdir [set workdir [file join $_config(work_dir) $subdir]]

            except {
                puts -nonewline "[format "%04d" $_counter]: $cmd ... "
                flush stdout

                set rval [$_runner execute "-f ${_config(outformat)} \
                    -d $workdir -t $timeout \
                    --script-encoding ${_config(encoding)} \
                    $command"]

                if {$rval != 0} {
                    puts "fail"
                    set exit_code 1
                } else {
                    puts "pass"
                }
            } e {
                ::Exception {
                    puts stderr "Warning: [$e msg]"
                    set exit_code 1
                }
            }

            return $exit_code
        }
    }
}

