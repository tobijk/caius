#
# Caius Functional Testing Framework
#
# Copyright (c) 2014, Ashok P. Nadkarni <tobias.koch@gmail.com>
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

