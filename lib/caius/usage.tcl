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

package require Error
package require textutil

namespace eval Caius {

    proc version_info {} {
        puts "Caius Test Execution and Reporting Tool                              "
        puts "Copyright (c) 2014, Tobias Koch <tobias.koch@gmail.com>              "
    }

    proc usage {} {
        version_info
        puts "                                                                     "
        puts "Usage: caius <command> \[OPTIONS] \[PARAMS]                          "
        puts "                                                                     "
        puts "Available commands:                                                  "
        puts "                                                                     "
        puts "  report                                                             "
        puts "  run                                                                "
        puts "  testplan                                                           "
        puts "                                                                     "
        puts "Type 'caius <command> --help' for command-specific usage information."
        puts "                                                                     "
    }

    proc usage_report {} {
        version_info
        puts "                                                                      "
        puts "Usage: caius report <directory>                                       "
        puts "                                                                      "
        puts "Summary:                                                              "
        puts "                                                                      "
        puts " Scans the <directory> for test results. The directory should contain "
        puts " subdirectories created by a previous call to `caius testplan`. Each  "
        puts " of these in turn should contain exactly one results XML file plus any"
        puts " number of artifcats, which will be linked into the test report.      "
        puts "                                                                      "
        puts " The test report will be created inside <directory> as one or more    "
        puts " HTML files.                                                          "
        puts "                                                                      "
    }

    proc usage_run {} {
        version_info
    }

    proc usage_testplan {} {
        version_info
        puts "                                                                      "
        puts "Usage: caius testplan \[OPTIONS] <testplan>                           "
        puts "                                                                      "
        puts "Summary:                                                              "
        puts "                                                                      "
        puts " Executes all tests listed in the testplan. The testplan is written in"
        puts " an XML-based format. An example testplan can be found in the source  "
        puts " distribution.                                                        "
        puts "                                                                      "
        puts "Options:                                                              "
        puts "                                                                      "
        puts " -d, --work-dir <dir> Change working directory before running tests.  "
        puts "                                                                      "
    }
}

