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

        constructor {{url ""} {required_capabilities ""}} {
            OOSupport::init_attributes

            # these are not serializable
            set _windows {}

            if {$url != ""} {
                # serialize capabilities
                set post_data [format {
                    {
                        "capabilities": {
                            "alwaysMatch": %s
                        }
                    }
                } [$required_capabilities to_json]]

                # open a new session
                set response [::WebDriver::Protocol::dispatch -query $post_data \
                    $url/session]

                # save session URL and ID
                array set meta [$response headers]
                array set data [$response value  ]

                # different versions use different methods to report session id
                if {[info exists meta(Location)]} {
                    set _session_url $meta(Location)
                } elseif {[info exists data(sessionId)]} {
                    set _session_url "$url/session/$data(sessionId)"
                } else {
                    raise ::WebDriver::Error \
                        "session URL not found in response: [$response to_json]"
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
                except {
                    set response [::WebDriver::Protocol::dispatch \
                        -method DELETE $_session_url]
                } e {
                    ::WebDriver::Error {
                        # ignore, maybe window was closed already.
                    }
                } final {
                    if {[info exists response]} {
                        ::itcl::delete object $response
                    }
                }
            }
        }

        # accessor functions and JSON support
        OOSupport::bless_attributes -json_support -collapse_underscore \
            -skip_undefined

        method set_page_load_timeout {ms} {
            if {![regexp {^\d+$} $ms]} {
                raise ::ValueError \
                    "invalid timeout value '$ms' for page load timeout"
            }

            if {$_logging_enabled} {
                ::WebDriver::log $_session_id "set page load timeout to ${ms}ms"
            }

            set json "{ \"pageLoad\": $ms }"
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

            set json "{ \"script\": $ms }"
            set response [::WebDriver::Protocol::dispatch -query $json \
                $_session_url/timeouts]
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

            set json "{ \"implicit\": $ms }"
            set response [::WebDriver::Protocol::dispatch -query $json \
                $_session_url/timeouts]
            ::itcl::delete object $response
        }

        method active_window {} {
            set response [::WebDriver::Protocol::dispatch \
                $_session_url/window]

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
                $_session_url/window/handles]

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
                $_session_url/execute/async]

            # return TCL'ized JSON object or single value
            set result [$response value]

            ::itcl::delete object $response
            return $result
        }

        private method __elements {by locator {root null} {single true}} {
            array set by2text "
                by_css_selector      {css selector}
                by_link_text         {link text}
                by_partial_link_text {partial link text}
                by_xpath             {xpath}
                by_class_name        {class name}
                by_id                {id}
                by_name              {name}
                by_tag_name          {tag name}
            "

            set strategy $by2text($by)

            ##
            # WORKAROUND:
            #
            # Selenium 3 seems to have dropped these from the protocol, probably
            # because they can be expressed through the other strategies?
            ##
            set internal_strategy ""
            set internal_locator ""

            switch $strategy {
                {class name} {
                    set internal_strategy {css selector}
                    set internal_locator  .$locator
                }
                {id} {
                    set internal_strategy {xpath}
                    set internal_locator  //*\[@id='$locator'\]
                }
                {name} {
                    set internal_strategy {xpath}
                    set internal_locator  //*\[@name='$locator'\]
                }
                {tag name} {
                    set internal_strategy {css selector}
                    set internal_locator  $locator
                }
                default {
                    set internal_strategy $strategy
                    set internal_locator  $locator
                }
            }

            set internal_locator \
                [::OOSupport::json_escape_chars $internal_locator]
            set json "{
                \"using\": \"$internal_strategy\",
                \"value\": \"$internal_locator\"
            }"

            if {$_logging_enabled} {
                if {$single == true} {
                    set what "element"
                } else {
                    set what "elements"
                }
                set log_str "get $what by $strategy "
                if {$root ne {null}} {
                    append log_str "'<element [$root web_element_id]>/$locator'"
                } else {
                    append log_str "'$locator'"
                }
                ::WebDriver::log $_session_id $log_str
            }

            set result ""

            if {$root eq "null"} {
                set url [$this session_url]/element
            } else {
                set url [$this session_url]/element/[$root web_element_id]/element
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

                if {$_logging_enabled} {
                    set log_str "got element [$result web_element_id]"
                    ::WebDriver::log $_session_id $log_str
                }
            } else {
                set element_list [$response value]
                set id_list {}

                foreach {elm} $element_list {
                    set fq_element [namespace which \
                        [[::WebDriver::WebElement #auto $this] from_tcl $elm]]

                    lappend result $fq_element
                    lappend id_list [$fq_element web_element_id]
                }

                if {$_logging_enabled} {
                    set log_str "got elements [join $id_list ", "]"
                    ::WebDriver::log $_session_id $log_str
                }
            }

            ::itcl::delete object $response
            return $result
        }
    }
}

