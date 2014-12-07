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
            exec kill -15 $pid
        }
    }

    proc kill {pid} {
        catch {
            exec kill -9 $pid
        }
    }

    proc process_exists {pid} {
        if {[catch { set fp [open "/proc/$pid/stat"]}] != 0} {
            return 0
        }

        set stats [read $fp]
        close $fp

        if {[regexp {\d+ \([^)]+\) (\S+)} $stats match state]} {
            if {$state eq {Z}} {
                return 0
            }
        }

        return 1
    }

    proc find_executable {executable} {
        foreach {path} [split $::env(PATH) ':'] {
            if {[file isfile $path/$executable] && \
                    [file executable $path/$executable]} {
                return $path/$executable
            }
        }

        return {}
    }
}

