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

package require OutputStream
package require OOSupport
package require Markdown

namespace eval Testing {

    ::itcl::class TextFormatter {

        # stream filters
        private variable _indent
        private variable _escape
        private variable _dos2unix
        private variable _tostdout
        private variable _errors

        constructor {} {
            set _indent   [::itcl::code [OutputStream::Indent #auto "    "]]
            set _escape   [::itcl::code [OutputStream::AnsiEscapeFilter #auto]]
            set _dos2unix [::itcl::code [OutputStream::NormalizeNewlines #auto unix]]
            set _tostdout [::itcl::code [OutputStream::Redirect #auto stdout]]
            set _errors {}
        }

        destructor {
            ::itcl::delete object $_indent
            ::itcl::delete object $_escape
            ::itcl::delete object $_dos2unix
            ::itcl::delete object $_tostdout
        }

        method module_start {name} {
            set _class_name [string trimleft $name ::]
            puts "* EXERCISING TESTS IN \"$_class_name\"\n"
        }

        method module_end {} {
            # do nothing
        }

        method test_start {name count num_tests} {
            set name [string trimleft $name ::]

            append title [format "* Test %d/%d: %s" $count $num_tests $name ]
            append title [string repeat - [expr 70 - [string length $title]]]

            puts "$title START"
        }

        method test_desc {text} {
            if {$text ne ""} {
                puts "\n- Description:\n[regsub -all \
                    -lineanchor {^} $text "    "]"
            }
        }

        method test_end {verdict milliseconds} {
            if {$_errors ne {}} {
                puts "\n- Errors:"
                puts [string trimright [join $_errors "\n\n"]]
            }

            set m  [expr $milliseconds / (60000)]
            set s  [expr ($milliseconds - $m * 60000) / 1000]
            set ms [expr $milliseconds % 1000]

            set total_time [format "%02d min %02d sec %03d ms" $m $s $ms]

            append footer "\n- Verdict: $verdict"
            append footer [string repeat " " [expr 60 - [string length $total_time]]]
            append footer " $total_time \n"

            puts $footer
        }

        method log_start {} {
            puts "\n- Log:"
            OutputStream::push stdout $_indent
            OutputStream::push stdout $_dos2unix
            OutputStream::push stdout $_escape
            OutputStream::push stderr $_tostdout
        }

        method log_end {} {
            OutputStream::pop stderr
            OutputStream::pop stdout
            OutputStream::pop stdout
            OutputStream::pop stdout
        }

        method log_error {msg} {
            lappend _errors [regsub -all -lineanchor {^} $msg "    "]
        }

        method reset {} {
            set _errors {}
        }
    }

    ::itcl::class ZeroFormatter {

        # stream filters
        private variable _escape
        private variable _dos2unix
        private variable _tostdout
        private variable _errors

        constructor {} {
            set _escape   [::itcl::code [OutputStream::AnsiEscapeFilter #auto]]
            set _dos2unix [::itcl::code [OutputStream::NormalizeNewlines #auto unix]]
            set _tostdout [::itcl::code [OutputStream::Redirect #auto stdout]]
            set _errors {}
        }

        destructor {
            ::itcl::delete object $_escape
            ::itcl::delete object $_dos2unix
            ::itcl::delete object $_tostdout
        }

        method module_start {name} {
            # do nothing
        }

        method module_end {} {
            # do nothing
        }

        method test_start {name count num_tests} {
            # do nothing
        }

        method test_desc {text} {
            # do nothing
        }

        method test_end {verdict milliseconds} {
            if {$_errors ne {}} {
                puts stderr [join $_errors "\n\n"]
            }
        }

        method log_start {} {
            OutputStream::push stdout $_dos2unix
            OutputStream::push stdout $_escape
            OutputStream::push stderr $_tostdout
        }

        method log_end {} {
            OutputStream::pop stderr
            OutputStream::pop stdout
            OutputStream::pop stdout
        }

        method log_error {msg} {
            lappend _errors [string trim $msg]
        }

        method reset {} {
            set _errors {}
        }
    }

    ::itcl::class XMLFormatter {

        # stream filters
        private variable _capture
        private variable _xmlescape
        private variable _escape
        private variable _dos2unix
        private variable _tostdout

        # warnings, errors, log
        private variable _errors
        private variable _log
        private variable _desc

        # test attributes
        private variable _class_name
        private variable _test_name

        constructor {} {
            set _capture   [::itcl::code [OutputStream::Capture #auto]]
            set _xmlescape [::itcl::code [OutputStream::XMLEscape #auto]]
            set _escape    [::itcl::code [OutputStream::AnsiEscapeFilter #auto]]
            set _dos2unix  [::itcl::code [OutputStream::NormalizeNewlines #auto unix]]
            set _tostdout  [::itcl::code [OutputStream::Redirect #auto stdout]]

            set _errors   {}
            set _log      {}
            set _desc     {}
        }

        destructor {
            ::itcl::delete object $_capture
            ::itcl::delete object $_xmlescape
            ::itcl::delete object $_escape
            ::itcl::delete object $_dos2unix
            ::itcl::delete object $_tostdout
        }

        method module_start {name} {
            set _class_name [string trimleft $name ::]

            puts "<?xml version=\"1.0\" encoding=\"utf-8\"?>"
            puts "<testset name=\"$_class_name\">"
        }

        method module_end {} {
            puts "</testset>"
        }

        method test_start {name count num_tests} {
            set name [string trimleft $name ::]
            set _test_name $name
            $_capture clear
        }

        method test_desc {text} {
            set _desc [::markdown::convert $text]
        }

        method test_end {verdict milliseconds} {
            set m  [expr $milliseconds / (60000)]
            set s  [expr ($milliseconds - $m * 60000) / 1000]
            set ms [expr $milliseconds % 1000]

            set total_time [format "%02d:%02d.%03d" $m $s $ms]

            puts "  <test name=\"$_test_name\" time=\"$total_time\" verdict=\"$verdict\">"
            if {$_desc ne {}} {
                puts "    <description>$_desc</description>"
            }
            if {$_log ne {}} {
                puts "    <log>$_log</log>"
            }
            if {$_errors ne {}} {
                puts -nonewline "    <error>"
                puts -nonewline [join $_errors "\n\n"]
                puts "</error>"
            }
            puts "  </test>"
        }

        method log_start {} {
            OutputStream::push stdout $_capture
            OutputStream::push stdout $_xmlescape
            OutputStream::push stdout $_dos2unix
            OutputStream::push stdout $_escape
            OutputStream::push stderr $_tostdout
        }

        method log_end {} {
            OutputStream::pop stderr
            OutputStream::pop stdout
            OutputStream::pop stdout
            OutputStream::pop stdout
            OutputStream::pop stdout

            # Why does encoding happen before the transformations kick in!?
            set _log [encoding convertfrom [chan configure stdout -encoding] \
                [$_capture get]]
        }

        method log_error {msg} {
            lappend _errors [string map \
                {& &amp; < &lt; > &gt; \" &quot;} [string trim $msg]]
        }

        method reset {} {
            $_capture clear

            set _errors   {}
            set _log      {}
            set _desc     {}
        }
    }

    ::itcl::class JUnitFormatter {

        # stream filters
        private variable _capture
        private variable _xmlescape
        private variable _escape
        private variable _dos2unix
        private variable _tostdout

        # warnings, errors, log
        private variable _errors
        private variable _log

        # test attributes
        private variable _class_name
        private variable _test_name

        # result sets
        private variable _result_sets
        private variable _num_failed_tests
        private variable _num_total_tests
        private variable _start_time
        private variable _stop_time

        constructor {} {
            set _capture   [::itcl::code [OutputStream::Capture #auto]]
            set _xmlescape [::itcl::code [OutputStream::XMLEscape #auto]]
            set _escape    [::itcl::code [OutputStream::AnsiEscapeFilter #auto]]
            set _dos2unix  [::itcl::code [OutputStream::NormalizeNewlines #auto unix]]
            set _tostdout  [::itcl::code [OutputStream::Redirect #auto stdout]]

            set _errors   {}
            set _log      {}

            set _num_failed_tests 0
            set _num_total_tests 0
        }

        destructor {
            ::itcl::delete object $_capture
            ::itcl::delete object $_xmlescape
            ::itcl::delete object $_escape
            ::itcl::delete object $_dos2unix
            ::itcl::delete object $_tostdout
        }

        method module_start {name} {
            set _class_name [string trimleft $name ::]
            puts "<?xml version=\"1.0\" encoding=\"utf-8\"?>"
            set _start_time [clock milliseconds] 
        }

        method module_end {} {
            set total_time [expr ([clock milliseconds] - $_start_time) / 1000.0]
            set timestamp [clock format \
                [expr $_start_time / 1000] -format "%Y-%m-%dT%H:%M:%S"]

            puts "<testsuite name=\"\"\
                timestamp=\"$timestamp\"\
                hostname=\"[info hostname]\"\
                tests=\"$_num_total_tests\"\
                failures=\"$_num_failed_tests\"\
                errors=\"0\" time=\"$total_time\">"

            foreach {result_set} $_result_sets {
                lassign $result_set \
                    test_name \
                    test_verdict \
                    test_time \
                    test_log \
                    test_errors

                set test_class [namespace qualifiers $test_name]
                set test_name  [namespace tail       $test_name] 

                if {$test_verdict eq {PASS}} {
                    if {$test_log ne {}} {
                        puts "  <testcase classname=\"$test_class\"\
                            name=\"$test_name\" time=\"$test_time\">"
                        puts "    <system-out>$test_log</system-out>"
                        puts "  </testcase>"
                    } else {
                        puts "  <testcase classname=\"$test_class\"\
                            name=\"$test_name\" time=\"$test_time\"/>"
                    }
                } else {
                    puts "  <testcase classname=\"$test_class\"\
                        name=\"$test_name\" time=\"$test_time\">"

                    set msg [string trim [lindex [split $test_errors "\n"] 0]]

                    puts "    <failure type=\"failure\"\
                        message=\"$msg\">$test_errors</failure>"

                    if {$test_log ne {}} {
                        puts "    <system-out>$test_log</system-out>"
                    }

                    puts "  </testcase>"
                }
            }

            puts "</testsuite>"
        }

        method test_start {name count num_tests} {
            set name [string trimleft $name ::]
            set _test_name $name
            $_capture clear
        }

        method test_desc {text} {
            # do nothing
        }

        method test_end {verdict milliseconds} {
            set seconds  [expr $milliseconds / 1000.0]

            set _errors   [join $_errors "\n\n"]

            lappend _result_sets \
                [list $_test_name $verdict $seconds $_log $_errors]

            if {$verdict eq {FAIL}} {
                incr _num_failed_tests
            }

            incr _num_total_tests
        }

        method log_start {} {
            OutputStream::push stdout $_capture
            OutputStream::push stdout $_xmlescape
            OutputStream::push stdout $_dos2unix
            OutputStream::push stdout $_escape
            OutputStream::push stderr $_tostdout
        }

        method log_end {} {
            OutputStream::pop stderr
            OutputStream::pop stdout
            OutputStream::pop stdout
            OutputStream::pop stdout
            OutputStream::pop stdout
            set _log [$_capture get]
        }

        method log_error {msg} {
            lappend _errors [string map \
                {& &amp; < &lt; > &gt; \" &quot;} $msg]
        }

        method reset {} {
            $_capture clear

            set _errors   {}
            set _log      {}
            set _desc     {}
        }
    }
}

