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

