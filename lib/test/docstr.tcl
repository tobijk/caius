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

package require Itcl
package require textutil

namespace eval Testing {

    ::itcl::class Docstrings {

        method docstr {args} {}

        method get_docstr {function_name} {
            if {[catch {
                    set body [$this info function $function_name -body] 
                }] != 0} \
            {
                return ""
            }

            if {[lindex $body 0] ne "docstr"} {
                return ""
            }

            set docstr [string map {\r\n \n \r \n} [lindex $body 1]]

            set lbreak [string first \n $docstr]
            if {$lbreak != -1} {
                set first_line [string range $docstr 0 $lbreak]

                set rest [::textutil::undent [
                        string range $docstr [expr $lbreak + 1] end
                    ]
                ]

                set rest [string trimright $rest]
            }

            return [join [list $first_line $rest] ""]
        }
    }
}

