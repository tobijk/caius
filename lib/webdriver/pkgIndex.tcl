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

package ifneeded WebDriver 1.0 "
    source \[file join [list $dir] error.tcl\]
    source \[file join [list $dir] proxy.tcl\]
    source \[file join [list $dir] capabilities.tcl\]
    source \[file join [list $dir] protocol.tcl\]
    source \[file join [list $dir] cookie.tcl\]
    source \[file join [list $dir] element.tcl\]
    source \[file join [list $dir] window.tcl\]
    source \[file join [list $dir] session.tcl\]
    source \[file join [list $dir] version.tcl\]
    source \[file join [list $dir] keyboard.tcl\]
"

