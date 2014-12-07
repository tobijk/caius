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

