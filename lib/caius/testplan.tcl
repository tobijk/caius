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

        method usage {} {
            puts "                                                                      "
            puts "Usage: caius runplan \[OPTIONS] <testplan>                            "
            puts "                                                                      "
            puts "Summary:                                                              "
            puts "                                                                      "
            puts " Executes all tests listed in the testplan. The testplan is written in"
            puts " an XML-based format. An example testplan can be found in the source  "
            puts " distribution.                                                        "
            puts "                                                                      "
            puts "Options:                                                              "
            puts "                                                                      "
            puts " -d, --work-dir <dir>  Change working directory before running tests. "
            puts " -f, --format <fmt>    Output test results either in Caius' native    "
            puts "                       'xml' result format or as 'junit' XML.         "
            puts "                                                                      "
        }

        method parse_command_line {{argv {}}} {
            set _config(work_dir) .
            set _config(outformat) xml

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
                                raise RuntimeError "unknown output format '$v'."
                            }
                        }
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

            set runner [::Caius::Runner #auto]
            set root [$testplan documentElement]

            # change work dir
            cd $_config(work_dir)

            set count 0
            set cwd [pwd]
            set exit_code 0

            foreach {child} [$root childNodes] {
                if {[$child nodeName] ne {run}} { continue }

                set cmd [string trim [$child text]]
                set timeout [$child getAttribute timeout 0]

                if {[file pathtype $cmd] ne {absolute}} {
                    set cmd "$_config(testplan_dir)/$cmd"
                }

                set subdir [format "%03d_%s" [incr count] \
                    [regsub {[-.]} [file tail [lindex [split $cmd] 0]] {_}]\
                ]
                file mkdir $cwd/$subdir

                except {
                    puts "Running '$cmd'"
                    set rval [$runner execute "-f ${_config(outformat)} \
                        -d $cwd/$subdir -t $timeout $cmd"]

                    if {$rval != 0} {
                        set exit_code 1
                    }
                } e {
                    ::Exception {
                        puts stderr "Warning: [$e msg]"
                        set exit_code 1
                    }
                }
            }

            ::itcl::delete object $runner
            $testplan delete

            return $exit_code
        }
    }
}

