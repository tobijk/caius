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
package require Error

namespace eval Caius {

    ::itcl::class Reporter {

        private variable _config

        method usage {} {
            puts "                                                                       "
            puts "Usage: caius report \[OPTIONS\] <directory>                            "
            puts "                                                                       "
            puts "Summary:                                                               "
            puts "                                                                       "
            puts " Scans the <directory> for test results. The directory should contain  "
            puts " subdirectories created by a previous call to `caius testplan`. Each of"
            puts " these in turn should contain exactly one results XML file plus any    "
            puts " number of artifcats, which will be linked into the test report.       "
            puts "                                                                       "
            puts " The test report will be created inside <directory> as one or more     "
            puts " HTML files.                                                           "
            puts "                                                                       "
            puts "Options:                                                               "
            puts "                                                                       "
            puts " --with-xml   Spit out the test report in aggregated XML in addition   "
            puts "              to the HTML report. This is for users who wish to run    "
            puts "              their on XSL transforms on it to generate custom reports."
            puts "              The XML file will be saved under the name \"result.xml\"."
            puts "                                                                       "
        }

        method parse_command_line {{argv {}}} {
            set _config(work_dir) .
            set _config(with_xml) 0

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
                    --with-xml {
                        set _config(with_xml) 1
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
                                "'$o' is not a directory or does not exist."
                        }

                        set _config(work_dir) $o
                    }
                }
            }
        }

        method find_stylesheet {} {
            if {[file type $::argv0] eq {link}} {
                set my_argv0 [file readlink $::argv0]
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
            chan configure $fp -encoding utf-8
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
                        chan configure $fp -encoding utf-8
                        set xml_testset [dom parse -channel $fp]
                        set xml_testset_root [$xml_testset documentElement]
                        $xml_testset_root setAttribute artifacts_path $dir
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

            if {$_config(with_xml)} {
                set fp [open result.xml w+]
                chan configure $fp -encoding utf-8
                $xml_testsuite asXML -channel $fp -indent 4 -doctypeDeclaration 1
                close $fp
            }

            set fp [open result.html w+]
            chan configure $fp -encoding utf-8
            $result_doc asXML -channel $fp -indent none -doctypeDeclaration 1
            close $fp

            $xml_testsuite delete
            $stylesheet delete
            $result_doc delete

            return 0
        }
    }
}

