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

package ifneeded WebDriver 1.0 "
    source \[file join [list $dir] error.tcl\]
    source \[file join [list $dir] capabilities.tcl\]
    source \[file join [list $dir] protocol.tcl\]
    source \[file join [list $dir] cookie.tcl\]
    source \[file join [list $dir] element.tcl\]
    source \[file join [list $dir] window.tcl\]
    source \[file join [list $dir] session.tcl\]
    source \[file join [list $dir] version.tcl\]
    source \[file join [list $dir] keyboard.tcl\]
"

