#
#   Caius Functional Testing Framework
#
#   Copyright 2013 Tobias Koch <tobias.koch@gmail.com>
#
#   This program is free software; you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation; either version 2 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#
#   See the LICENSE file in the source distribution for more information.
#

package require OutputStream
package require OOSupport

namespace eval Testing {

    ::itcl::class TestResultFormatter {

        private variable _outformat

        # stream filters
        private variable _capture
        private variable _xmlescape
        private variable _indent
        private variable _escape
        private variable _dos2unix
        private variable _tostdout

        # warnings, errors, log
        private variable _warnings
        private variable _errors
        private variable _log

        # test attributes
        private variable _name

        constructor {{outformat plain}} {
            set _outformat $outformat

            set _capture   [::itcl::code [OutputStream::Capture #auto]]
            set _xmlescape [::itcl::code [OutputStream::XMLEscape #auto]]
            set _indent    [::itcl::code [OutputStream::Indenter #auto "    "]]
            set _escape    [::itcl::code [OutputStream::AnsiEscapeFilter #auto]]
            set _dos2unix  [::itcl::code [OutputStream::FlipNewlines #auto unix]]
            set _tostdout  [::itcl::code [OutputStream::Redirect #auto stdout]]

            set _warnings {}
            set _errors   {}
        }

        destructor {
            ::itcl::delete object $_capture
            ::itcl::delete object $_xmlescape
            ::itcl::delete object $_indent
            ::itcl::delete object $_escape
            ::itcl::delete object $_dos2unix
            ::itcl::delete object $_tostdout
        }

        method test_start {name count num_tests} {
            set name [string trimleft $name ::]

            if {$_outformat eq "xml"} {
                set _name $name
                $_capture clear
            } else {
                append title [format "* Test %d/%d: %s" $count $num_tests $name ]
                append title [string repeat - [expr 70 - [string length $title]]]
                puts "$title START"
            }
        }

        method test_end {verdict milliseconds} {
            set m  [expr $milliseconds / (60000)]
            set s  [expr ($milliseconds - $m * 60000) / 1000]
            set ms [expr $milliseconds % 1000]

            if {$_outformat eq "xml"} {
                set total_time [format "%02d:%02d.%03d" $m $s $ms]

                puts "<test name=\"$_name\" runtime=\"$total_time\" verdict=\"$verdict\">"
                puts "  <log>"
                puts    -nonewline $_log
                puts "  </log>"
                foreach {warning} $_warnings {
                    puts "  <warning>"
                    puts $warning
                    puts "  </warning>"
                }
                foreach {err} $_errors {
                    puts "  <error>"
                    puts    $err
                    puts "  </error>"
                }
                puts "</test>"
            } else {
                set total_time [format "%02d min %02d sec %03d ms" $m $s $ms]

                append footer "\n- Verdict: $verdict"
                append footer [string repeat " " [expr 60 - [string length $total_time]]]
                append footer " $total_time \n"

                puts $footer
            }
        }

        method log_start {} {
            if {$_outformat eq "xml"} {
                chan push stdout $_capture
                chan push stdout $_xmlescape
            } else {
                puts "- Log:"
                chan push stdout $_indent
            }

            chan push stdout $_dos2unix
            chan push stdout $_escape
            chan push stderr $_tostdout
        }

        method log_end {} {
            chan pop stderr
            chan pop stdout
            chan pop stdout
            chan pop stdout
            if {$_outformat eq "xml"} {
                chan pop stdout
                set _log [$_capture get]
            }
        }

        method log_warning {msg} {
            if {$_outformat eq "xml"} {
                lappend _warnings [string map \
                    {& &amp; < &lt; > &gt; \" &quot;} $msg]
            } else {
                puts "\n- Warning:\n[regsub -all -lineanchor {^} $msg "    "]"
            }
        }

        method log_error {msg} {
            if {$_outformat eq "xml"} {
                lappend _errors [string map \
                    {& &amp; < &lt; > &gt; \" &quot;} $msg]
            } else {
                puts "\n- Error:\n[regsub -all -lineanchor {^} $msg "    "]"
            }
        }

        method reset {} {
            $_capture clear
        }
    }
}

