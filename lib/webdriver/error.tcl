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

package require Itcl
package require Error

namespace eval WebDriver {

    ::itcl::class Error {
        inherit ::Exception

        constructor {msg} {
            ::Exception::constructor "$msg"
        } {}

        destructor {}
    }

    ::itcl::class FailedCommandError {
        inherit ::WebDriver::Error

        constructor {msg} {
            ::WebDriver::Error::constructor "$msg"
        } {}

        destructor {}
    }

    ::itcl::class NoSuchDriverError {
        inherit ::WebDriver::FailedCommandError

        constructor {msg} {
            ::WebDriver::FailedCommandError::constructor "$msg"
        } {}

        destructor {}
    }

    ::itcl::class NoSuchElementError {
        inherit ::WebDriver::FailedCommandError

        constructor {msg} {
            ::WebDriver::FailedCommandError::constructor "$msg"
        } {}

        destructor {}
    }

    ::itcl::class NoSuchFrameError {
        inherit ::WebDriver::FailedCommandError

        constructor {msg} {
            ::WebDriver::FailedCommandError::constructor "$msg"
        } {}

        destructor {}
    }

    ::itcl::class UnknownCommandError {
        inherit ::WebDriver::FailedCommandError

        constructor {msg} {
            ::WebDriver::FailedCommandError::constructor "$msg"
        } {}

        destructor {}
    }

    ::itcl::class StaleElementReferenceError {
        inherit ::WebDriver::FailedCommandError

        constructor {msg} {
            ::WebDriver::FailedCommandError::constructor "$msg"
        } {}

        destructor {}
    }

    ::itcl::class ElementNotVisibleError {
        inherit ::WebDriver::FailedCommandError

        constructor {msg} {
            ::WebDriver::FailedCommandError::constructor "$msg"
        } {}

        destructor {}
    }

    ::itcl::class InvalidElementStateError {
        inherit ::WebDriver::FailedCommandError

        constructor {msg} {
            ::WebDriver::FailedCommandError::constructor "$msg"
        } {}

        destructor {}
    }

    ::itcl::class UnknownError {
        inherit ::WebDriver::FailedCommandError

        constructor {msg} {
            ::WebDriver::FailedCommandError::constructor "$msg"
        } {}

        destructor {}
    }

    ::itcl::class ElementIsNotSelectableError {
        inherit ::WebDriver::FailedCommandError

        constructor {msg} {
            ::WebDriver::FailedCommandError::constructor "$msg"
        } {}

        destructor {}
    }

    ::itcl::class JavaScriptError {
        inherit ::WebDriver::FailedCommandError

        constructor {msg} {
            ::WebDriver::FailedCommandError::constructor "$msg"
        } {}

        destructor {}
    }

    ::itcl::class XPathLookupError {
        inherit ::WebDriver::FailedCommandError

        constructor {msg} {
            ::WebDriver::FailedCommandError::constructor "$msg"
        } {}

        destructor {}
    }

    ::itcl::class TimeoutError {
        inherit ::WebDriver::FailedCommandError

        constructor {msg} {
            ::WebDriver::FailedCommandError::constructor "$msg"
        } {}

        destructor {}
    }

    ::itcl::class NoSuchWindowError {
        inherit ::WebDriver::FailedCommandError

        constructor {msg} {
            ::WebDriver::FailedCommandError::constructor "$msg"
        } {}

        destructor {}
    }

    ::itcl::class InvalidCookieDomainError {
        inherit ::WebDriver::FailedCommandError

        constructor {msg} {
            ::WebDriver::FailedCommandError::constructor "$msg"
        } {}

        destructor {}
    }

    ::itcl::class UnableToSetCookieError {
        inherit ::WebDriver::FailedCommandError

        constructor {msg} {
            ::WebDriver::FailedCommandError::constructor "$msg"
        } {}

        destructor {}
    }

    ::itcl::class UnexpectedAlertOpenError {
        inherit ::WebDriver::FailedCommandError

        constructor {msg} {
            ::WebDriver::FailedCommandError::constructor "$msg"
        } {}

        destructor {}
    }

    ::itcl::class NoAlertOpenError {
        inherit ::WebDriver::FailedCommandError

        constructor {msg} {
            ::WebDriver::FailedCommandError::constructor "$msg"
        } {}

        destructor {}
    }

    ::itcl::class ScriptTimeoutError {
        inherit ::WebDriver::FailedCommandError

        constructor {msg} {
            ::WebDriver::FailedCommandError::constructor "$msg"
        } {}

        destructor {}
    }

    ::itcl::class InvalidElementCoordinatesError {
        inherit ::WebDriver::FailedCommandError

        constructor {msg} {
            ::WebDriver::FailedCommandError::constructor "$msg"
        } {}

        destructor {}
    }

    ::itcl::class IMENotAvailableError {
        inherit ::WebDriver::FailedCommandError

        constructor {msg} {
            ::WebDriver::FailedCommandError::constructor "$msg"
        } {}

        destructor {}
    }

    ::itcl::class IMEEngineActivationError {
        inherit ::WebDriver::FailedCommandError

        constructor {msg} {
            ::WebDriver::FailedCommandError::constructor "$msg"
        } {}

        destructor {}
    }

    ::itcl::class InvalidSelectorError {
        inherit ::WebDriver::FailedCommandError

        constructor {msg} {
            ::WebDriver::FailedCommandError::constructor "$msg"
        } {}

        destructor {}
    }

    ::itcl::class SessionNotCreatedException {
        inherit ::WebDriver::FailedCommandError

        constructor {msg} {
            ::WebDriver::FailedCommandError::constructor "$msg"
        } {}

        destructor {}
    }

    ::itcl::class MoveTargetOutOfBoundsError {
        inherit ::WebDriver::FailedCommandError

        constructor {msg} {
            ::WebDriver::FailedCommandError::constructor "$msg"
        } {}

        destructor {}
    }

    # ADDITIONAL

    ::itcl::class CloseSessionWindowError {
        inherit ::WebDriver::FailedCommandError

        constructor {msg} {
            ::WebDriver::FailedCommandError::constructor "$msg"
        } {}

        destructor {}
    }

    ::itcl::class InvalidRequestError {
        inherit ::WebDriver::Error

        constructor {msg} {
            ::WebDriver::Error::constructor "$msg"
        } {}

        destructor {}
    }
}

