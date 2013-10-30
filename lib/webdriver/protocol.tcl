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
package require OOSupport
package require Error

namespace eval WebDriver {

    namespace eval Protocol {

        proc _check_http_response {token} {
            set status_code [::http::ncode $token]
            set data        [::http::data  $token]
            set headers     [::http::meta  $token]

            # invalid requests, no response object
            if {[regexp {4\d\d} $status_code]} {
                raise ::WebDriver::InvalidRequestError "$status_code: $data"
            }

            # create response object
            set response_object [::itcl::code [::WebDriver::Response #auto]]
            $response_object set_headers $headers

            # redirects (new session)
            if {[regexp {3\d\d} $status_code]} {
                return $response_object
            }

            except {

                # all other requests (2xx, 5xx) must return a response object
                if {$data ne ""} {
                    if { [ catch \
                            {
                                $response_object from_json $data
                            } msg ]  
                    } { 
                        raise ::WebDriver::UnknownError "request failed: unknown error"
                    }
                }

                # failed requests carry more information in the response object
                if {[regexp {5\d\d} $status_code]} {
                    set status [$response_object status]

                    if { $status == 0 } {
                        raise ::WebDriver::UnknownError "request failed: unknown error"
                    }

                    set info_object [::WebDriver::FailedCommandInfo #auto]
                    $info_object from_tcl [$response_object value]

                    # save first line of error message
                    set msg [$info_object message]
                    set msg [lindex [split $msg "\r\n"] 0]

                    if { [info exists ::WebDriver::Response::Code($status)] } {
                        set error_class $::WebDriver::Response::Code($status)
                        if 1 "raise ::WebDriver::${error_class} {$msg}"
                    } else {
                        raise ::WebDriver::FailedCommandError "$msg"
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
            ::http::config -accept "application/json" -useragent "Caius FT Framework"

            # just copy parms, no checks
            set parms [lrange $args 0 end-1]
            set url [lindex $args end]

            except {
                # send request
                if { [ catch \
                        {
                            set token [eval "::http::geturl $url \
                                -type application/json $parms"]
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

    ::itcl::class StackTraceFrame {

        common attributes {
            {string file_name   ""   ro}
            {string class_name  ""   ro}
            {string method_name ""   ro}
            {number line_number null ro}
        }

        constructor {} {
            OOSupport::init_attributes
        }

        destructor {}

        OOSupport::bless_attributes -json_support -collapse_underscore \
            -skip_undefined
    }

    ::itcl::class FailedCommandInfo {

        common attributes {
            {string message "" ro}
            {string screen  "" ro}
            {string class   "" ro}
            {[::WebDriver::StackTraceFrame] stack_trace {} ro}
        }

        constructor {} {
            OOSupport::init_attributes
        }

        destructor {}

        OOSupport::bless_attributes -json_support -collapse_underscore \
            -skip_undefined
    }

    ::itcl::class Response {

        public common Code
        
        set Code(0) Success
        set Code(6) NoSuchDriverError
        set Code(7) NoSuchElementError
        set Code(8) NoSuchFrameError
        set Code(9) UnknownCommandError
        set Code(10) StaleElementReferenceError
        set Code(11) ElementNotVisibleError
        set Code(12) InvalidElementStateError
        set Code(13) UnknownError
        set Code(15) ElementIsNotSelectableError
        set Code(17) JavaScriptError
        set Code(19) XPathLookupError
        set Code(21) TimeoutError
        set Code(23) NoSuchWindowError
        set Code(24) InvalidCookieDomainError
        set Code(25) UnableToSetCookieError
        set Code(26) UnexpectedAlertOpenError
        set Code(27) NoAlertOpenError
        set Code(28) ScriptTimeoutError
        set Code(29) InvalidElementCoordinatesError
        set Code(30) IMENotAvailableError
        set Code(31) IMEEngineActivationError
        set Code(32) InvalidSelectorError
        set Code(33) SessionNotCreatedException
        set Code(34) MoveTargetOutOfBoundsError

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

