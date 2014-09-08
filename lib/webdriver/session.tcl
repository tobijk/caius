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

package require Thread
package require Itcl
package require OOSupport
package require Error
package require http 2.7
package require base64
package require uri

namespace eval WebDriver {

    proc log {session_id log_string} {
        puts "WebDriver\[$session_id]: $log_string"
    }

    ::itcl::class Session {

        common attributes {
            {string  session_url      ""    rw}
            {string  session_id       ""    rw}
            {bool    cloned           false rw}
            {bool    logging_enabled  false rw}
        }

        # these are not serializable
        private variable _windows

        constructor {{url ""} \
            {desired_capabilities  ""} \
            {required_capabilities ""} \
        } {
            OOSupport::init_attributes

            # these are not serializable
            set _windows {}

            if {$url != ""} {
                set desired_and_required_caps [ \
                    ::WebDriver::DesiredAndRequiredCapabilities #auto \
                    $desired_capabilities $required_capabilities]

                # serialize capabilities
                set post_data [$desired_and_required_caps to_json]
                
                # open a new session
                set response [::WebDriver::Protocol::dispatch -query $post_data \
                    $url/session]

                # save session URL and ID
                array set meta [$response headers]

                # different versions use different methods to report session id
                if {[info exists meta(Location)]} {
                    set _session_url $meta(Location)
                } else {
                    set _session_url "$url/session/[$response session_id]"
                }
                set _session_id [lindex [split $_session_url /] end]

                ::itcl::delete object $response
            }
        }

        destructor {
            # delete windows
            foreach {handle window} $_windows {
                ::itcl::delete object $window
            }

            # delete session
            if {!$_cloned} {
                set response [::WebDriver::Protocol::dispatch -method DELETE \
                    $_session_url]
                ::itcl::delete object $response
            }
        }

        # accessor functions and JSON support
        OOSupport::bless_attributes -json_support -collapse_underscore \
            -skip_undefined

        method capabilities {} {
            if {$_logging_enabled} {
                ::WebDriver::log $_session_id "query session capabilities"
            }

            set response [::WebDriver::Protocol::dispatch $_session_url]

            # parse capabilities
            set caps [namespace which [WebDriver::Capabilities #auto]]
            $caps from_tcl [$res value]

            ::itcl::delete object $response
            return $caps
        }

        method log_types {} {
            set response [::WebDriver::Protocol::dispatch \
                $_session_url/log/types]

            set rval [$response value]

            if {$_logging_enabled} {
                ::WebDriver::log $_session_id \
                    "available log types: [join $rval ", "]"
            }

            ::itcl::delete object $response
            return $rval
        }

        method get_log {type} {
            set json "{ \"type\": \"$type\" }"

            if {$_logging_enabled} {
                ::WebDriver::log $_session_id "fetch $type log"
            }

            set response [::WebDriver::Protocol::dispatch -query $json \
                $_session_url/log]

            set log [$response value]
            ::itcl::delete object $response

            return $log
        }

        method set_page_load_timeout {ms} {
            if {![regexp {^\d+$} $ms]} {
                raise ::ValueError \
                    "invalid timeout value '$ms' for page load timeout"
            }

            if {$_logging_enabled} {
                ::WebDriver::log $_session_id "set page load timeout to ${ms}ms"
            }

            set json "{ \"type\": \"page load\", \"ms\": $ms }"
            set response [::WebDriver::Protocol::dispatch -query $json \
                $_session_url/timeouts]
            ::itcl::delete object $response
        }

        method set_async_script_timeout {ms} {
            if {![regexp {^\d+$} $ms]} {
                raise ::ValueError \
                    "invalid timeout value '$ms' for async script timeout"
            }

            if {$_logging_enabled} {
                ::WebDriver::log $_session_id \
                    "set async script timeout to ${ms}ms"
            }

            set json "{ \"ms\": $ms }"
            set response [::WebDriver::Protocol::dispatch -query $json \
                $_session_url/timeouts/async_script]
            ::itcl::delete object $response
        }

        method set_implicit_wait_timeout {ms} {
            if {![regexp {^\d+$} $ms]} {
                raise ::ValueError \
                    "invalid timeout value '$ms' for implicit wait timeout"
            }

            if {$_logging_enabled} {
                ::WebDriver::log $_session_id \
                    "set implicit wait timeout to ${ms}ms"
            }

            set json "{ \"ms\": $ms }"
            set response [::WebDriver::Protocol::dispatch -query $json \
                $_session_url/timeouts/implicit_wait]
            ::itcl::delete object $response
        }

        method active_window {} {
            set response [::WebDriver::Protocol::dispatch \
                $_session_url/window_handle]

            set handle [string trim [$response value] "{}"]
            ::itcl::delete object $response

            array set windows $_windows

            if {[info exists windows($handle)]} {
                set result $windows($handle)
            } else {
                set result [namespace which [::WebDriver::Window #auto $handle \
                    [namespace which $this]]]
                set windows($handle) $result
                set _windows [array get windows]
            }

            return $result
        }

        method windows {} {
            set response [::WebDriver::Protocol::dispatch \
                $_session_url/window_handles]

            set handles [$response value]
            for {set i 0} {$i < [llength $handles]} {incr i} {
                lset handles $i [string trim [lindex $handles $i] "{}"]
            }
            ::itcl::delete object $response

            # 1. create
            # 2. keep
            # 3. delete

            array set h_idx {}

            foreach {h  } $handles { set h_idx($h) 1 }
            foreach {h w} $_windows {
                if {[info exists h_idx($h)]} {
                    set h_idx($h) 2
                } else {
                    set h_idx($h) 3
                }
            }

            array set windows $_windows
            set result {}

            # update handle list
            foreach {h action} [array get h_idx] {
                if {$action == 1} {
                    lappend result [set windows($h) \
                        [ namespace which [ \
                            ::WebDriver::Window #auto $h [namespace which $this] ] \
                        ] \
                    ]
                } elseif {$action == 2} {
                    lappend result $windows($h)
                } elseif {$action == 3} {
                    ::itcl::delete object $windows($h)
                    unset windows($h)
                }
            }
            set _windows [array get windows]

            if {$_logging_enabled} {
                set handles {}
                foreach {w} $result {
                    lappend handles [$w handle]
                }
                ::WebDriver::log $_session_id "session windows:\
                    [join $handles ", "]"
            }

            return $result
        }

        private method __execute_async {script args} {
            set script [::OOSupport::json_escape_chars $script]
            set json "{ \"script\": \"$script\", \"args\": \[[join $args ", "]\] }"

            set response [::WebDriver::Protocol::dispatch \
                -query $json \
                $_session_url/execute_async]

            # return TCL'ized JSON object or single value
            set result [$response value]

            ::itcl::delete object $response
            return $result
        }

        private method __elements {by locator {root null} {single true}} {
            array set by2text "
                by_class_name        {class name}
                by_css_selector      {css selector}
                by_id                {id}
                by_name              {name}
                by_link_text         {link text}
                by_partial_link_text {partial link text}
                by_tag_name          {tag name}
                by_xpath             {xpath}
            "

            set strategy $by2text($by)
            set locator [::OOSupport::json_escape_chars $locator]
            set json "{ \"using\": \"$strategy\", \"value\": \"$locator\" }"

            if {$_logging_enabled} {
                if {$single == true} {
                    set what "element"
                } else {
                    set what "elements"
                }
                set log_str "get $what by $strategy "
                if {$root ne {null}} {
                    append log_str "'$root/$locator'"
                } else {
                    append log_str "'$locator'"
                }
                ::WebDriver::log $_session_id $log_str
            }

            set result ""

            if {$root eq "null"} {
                set url [$this session_url]/element
            } else {
                set url [$this session_url]/element/[$root ELEMENT]/element
            }

            if {!$single} {
                set url "${url}s"
            }

            set response [::WebDriver::Protocol::dispatch \
                -query $json \
                $url]

            if {$single} {
                set result [namespace which \
                    [[::WebDriver::WebElement #auto $this] from_tcl \
                        [$response value]]]
            } else {
                set element_list [$response value]

                foreach {elm} $element_list {
                    lappend result [namespace which \
                        [[::WebDriver::WebElement #auto $this] from_tcl $elm]]
                }
            }

            ::itcl::delete object $response
            return $result
        }
    }
}

