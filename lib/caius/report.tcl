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

namespace eval Caius {

    ::itcl::class Reporter {

        private variable _config

        method usage {} {
            puts "                                                                      "
            puts "Usage: caius report <directory>                                       "
            puts "                                                                      "
            puts "Summary:                                                              "
            puts "                                                                      "
            puts " Scans the <directory> for test results. The directory should contain "
            puts " subdirectories created by a previous call to `caius testplan`. Each  "
            puts " of these in turn should contain exactly one results XML file plus any"
            puts " number of artifcats, which will be linked into the test report.      "
            puts "                                                                      "
            puts " The test report will be created inside <directory> as one or more    "
            puts " HTML files.                                                          "
            puts "                                                                      "
        }

        method parse_command_line {{argv {}}} {
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
                    default {
                        if {[string index $o 0] eq "-"} {
                            raise ::Caius::Error "unknown command line parameter '$o'"
                        }

                        if {[expr $i + 1] != [llength $argv]} {
                            $this usage
                            exit 1
                        }

                        if {![file isdirectory $o]} {
                            raise ::Caius::Error \
                                "directory '$o' is not a directory or does not exist."
                        }

                        set _config(work_dir) $o
                    }
                }
            }
        }

        method find_stylesheet {} {
            if {[file type $::argv0] eq {link}} {
                set my_argv0 [file readlinke $::argv0]
            } else {
                set my_argv0 $::argv0
            }

            set install_dir [file normalize "[file dirname $my_argv0]/.." ]

            if {![file isfile "$install_dir/xsl/report.xsl"]} {
                raise ::Caius::Error "could not locate XSL stylesheet."
            }

            return "$install_dir/xsl/report.xsl"
        }

        method execute {argv} {
            parse_command_line $argv

            # set working directory
            cd $_config(work_dir)

            # try to load XSL stylesheet
            set style_file_name [$this find_stylesheet]
            set fp [open $style_file_name r]
            set xsl_doc [dom parse -channel $fp]
            close $fp
            $xsl_doc toXSLTcmd stylesheet

            # get all subdirs
            set subdirs [glob -nocomplain -type d *]

            # create testsuite master XML doc
            set xml_testsuite [dom createDocument testsuite]
            set xml_testsuite_root [$xml_testsuite documentElement]

            # scan for result XMLs and merge them to master doc
            foreach {dir} $subdirs {
                if {[file isfile "$dir/result.xml"]} {
                    set fp {}

                    except {
                        set fp [open "$dir/result.xml"]
                        set xml_testset [dom parse -channel $fp]
                        set xml_testset_root [$xml_testset documentElement]
                        $xml_testset removeChild $xml_testset_root
                        $xml_testsuite_root appendChild $xml_testset_root
                        $xml_testset delete
                    } e {
                        ::TclError {
                            # pass
                        }
                    } final {
                        if {$fp ne {}} {
                            close $fp
                            set fp {}
                        }
                    }
                }
            }

            $stylesheet transform $xml_testsuite result_doc
            set fp [open result.html w+]
            $result_doc asXML -channel $fp
            close $fp

            $xml_testsuite delete
            $stylesheet delete
            $result_doc delete

            return 0
        }
    }
}

