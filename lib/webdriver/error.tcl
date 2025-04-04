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
package require Error

namespace eval WebDriver {

    ::itcl::class Error {
        inherit ::Exception

        constructor {msg} {
            ::Exception::constructor "$msg"
        } {}

        destructor {}
    }

    # FAILED COMMAND

    ::itcl::class FailedCommandError {
        inherit ::WebDriver::Error

        constructor {msg} {
            ::WebDriver::Error::constructor "$msg"
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

    ::itcl::class CloseSessionWindowError {
        inherit ::WebDriver::FailedCommandError

        constructor {msg} {
            ::WebDriver::FailedCommandError::constructor "$msg"
        } {}

        destructor {}
    }

    # PROTOCOL ERROR

    ::itcl::class HTTPError {
        inherit ::WebDriver::Error

        constructor {msg} {
            ::WebDriver::Error::constructor "$msg"
        } {}

        destructor {}
    }

    # CLIENT ERROR

    ::itcl::class InvalidRequestError {
        inherit ::WebDriver::HTTPError

        constructor {msg} {
            ::WebDriver::HTTPError::constructor "$msg"
        } {}

        destructor {}
    }

    ::itcl::class NotFoundError {
        inherit ::WebDriver::InvalidRequestError

        constructor {msg} {
            ::WebDriver::InvalidRequestError::constructor "$msg"
        } {}

        destructor {}
    }

    # SERVER ERROR

    ::itcl::class ServerError {
        inherit ::WebDriver::Error

        constructor {msg} {
            ::WebDriver::Error::constructor "$msg"
        } {}

        destructor {}
    }
}
