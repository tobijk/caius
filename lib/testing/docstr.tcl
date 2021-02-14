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
package require textutil

namespace eval Testing {

    ::itcl::class Docstrings {

        method docstr {args} {}

        method get_docstr {function_name} {
            if {[catch {
                    set body [string trim [$this info function $function_name -body]]
                }] != 0} \
            {
                return ""
            }

            if {[string range $body 0 5] ne "docstr"} {
                return ""
            }

            regexp {docstr\s+(?:\{((?:[^\}]|\\\})*)\}|\"((?:[^\"]|\\\")*)\")} \
                $body match group1 group2

            if {$group1 ne {}} {
                set docstr $group1
            } else {
                set docstr $group2
            }

            set docstr [string map {\r\n \n \r \n \\\" \"} \
                [subst -novariables -nocommands $docstr]]

            set lbreak [string first \n $docstr]
            if {$lbreak != -1} {
                set first_line [string range $docstr 0 $lbreak]

                set rest [::textutil::undent [
                        string range $docstr [expr $lbreak + 1] end
                    ]
                ]

                set rest [string trimright $rest]
                set docstr [join [list $first_line $rest] ""]
            }

            return $docstr
        }
    }
}

