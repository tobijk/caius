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
package require OOSupport
package require Error

namespace eval WebDriver {

    namespace eval Protocol {

        proc _check_http_response {token} {
            set status_code [::http::ncode $token]
            set body        [::http::data  $token]
            set headers     [::http::meta  $token]

            # create response object
            set response_object [namespace which [::WebDriver::Response #auto]]
            $response_object set_headers $headers

            # redirects (new session)
            if {[regexp {3\d\d} $status_code]} {
                return $response_object
            }

            except {
                if {$body ne ""} {
                    if { [ catch \
                            {
                                $response_object from_json $body
                            } msg ]  
                    } { 
                        raise ::WebDriver::UnknownError \
                            "request failed: unknown error"
                    }
                }

                if {![regexp {2\d\d} $status_code]} {
                    set info_object [::WebDriver::FailedCallInfo #auto]
                    $info_object from_tcl [$response_object value]

                    set msg \
                        "$status_code: [$info_object error] - [$info_object message]"

                    if {[regexp {4\d\d} $status_code]} {
                        raise ::WebDriver::InvalidRequestError "$msg"
                    }

                    if {[regexp {5\d\d} $status_code]} {
                        raise ::WebDriver::ServerError "$msg"
                    }
                }
            } e {
                ::Exception {
                    ::itcl::delete object $response_object
                    reraise $e
                }
            } final {
                if {[info exists info_object]} {
                    ::itcl::delete object $info_object
                }
            }

            return $response_object
        }

        proc dispatch {args} {
            # store current settings
            set http_config [::http::config]

            # content and accept headers must be set to "application/json"
            ::http::config -accept "application/json;charset=utf-8" -useragent "Caius FT Framework"

            # just copy parms, no checks
            set parms [lrange $args 0 end-1]
            set url [lindex $args end]

            except {
                # send request
                if { [ catch \
                        {
                            set token [eval "::http::geturl $url \
                                -type \"application/json;charset=utf-8\" $parms"]
                        } msg ]
                } {
                    raise ::WebDriver::Error "error while dispatching request: $msg"
                }

                set response [::WebDriver::Protocol::_check_http_response $token]
            } e {

            } final {
                # delete http session token
                if {[info exists token]} {
                    ::http::cleanup $token
                }
                #restore previous configuration
                if 1 "::http::config $http_config"
            }

            return $response
        }
    }

    ::itcl::class FailedCallInfo {

        common attributes {
            {string error      "" ro}
            {string message    "" ro}
            {string stacktrace "" ro}
        }

        constructor {} {
            OOSupport::init_attributes
        }

        destructor {}

        OOSupport::bless_attributes -json_support -collapse_underscore \
            -skip_undefined
    }

    ::itcl::class Response {

        common attributes {
            {string session_id "" ro}
            {number status     0  ro}
            {string value      "" ro}
            {string headers    "" rw}
        }

        constructor {} {
            OOSupport::init_attributes
        }

        destructor {}

        OOSupport::bless_attributes -json_support -collapse_underscore \
            -skip_undefined
    }
}

