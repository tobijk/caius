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

namespace eval OS {

    namespace export \
        terminate \
        kill \
        process_exists \
        find_executable

    namespace ensemble create

    proc terminate {pid} {
        catch {
            exec {*}[auto_execok taskkill.exe] /PID $pid
        }
    }

    proc kill {pid} {
        catch {
            exec {*}[auto_execok taskkill.exe] /F /PID $pid
        }
    }

    proc process_exists {pid} {
        set tasklist [exec {*}[auto_execok tasklist.exe] /fi "pid eq $pid" /nh]
        return [regexp "^\\s*\\S+\\s+$pid\\s" $tasklist]
    }

    proc find_executable {executable} {
        foreach path [split $::env(PATH) ";"] {
            set exe [file join $path $executable]
            if {[file isfile $exe] && [file executable $exe]} {
                return $exe
            }
        }

        return {}
    }
}

