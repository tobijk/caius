Error(3caius) -- fine-grained error handling facilities
==============================================================================

## EXAMPLE

    package require Itcl
    package require Error

    ::itcl::class MyError {
        inherit ::Exception

        constructor {msg} { ::Exception::constructor $msg } {}
        destructor {}
    }

    except {
        # ...
        raise MyError "something unexpected happened"
    } e {
        TclError {
            puts "caught a native Tcl error"
        }
        RuntimeError {
            puts "handling a runtime error"

            # re-raise the error
            reraise $e
        }
        MyError {
            puts "handling my error type"
        }
    } final {
        puts "always executed"
    }

## DESCRIPTION

The `Error` module provides facilities to raise and handle errors and exceptions.
It also defines a number of base exception types.

## API

* `raise` *class* *string*:
  <p>
  Raise an exception of type *class* with error message *string*.
  </p>

In order to catch exceptions (or Tcl errors) that may occur during the
execution of a code block, the block may be guarded with an `except` statement:

`except` {<br/>
&nbsp;&nbsp;*control_flow*<br/>
} *evar* {<br/>
&nbsp;&nbsp;?*class1* {<br/>
&nbsp;&nbsp;&nbsp;&nbsp;*handler_code*<br/>
&nbsp;&nbsp;&nbsp;&nbsp;?`reraise` *$evar*?<br/>
&nbsp;&nbsp;}?<br/>
&nbsp;&nbsp;...<br/>
&nbsp;&nbsp;*classN* {<br/>
&nbsp;&nbsp;&nbsp;&nbsp;*handler_code*<br/>
&nbsp;&nbsp;&nbsp;&nbsp;?`reraise` *$evar*?<br/>
&nbsp;&nbsp;}<br/>
} ?`final` {<br/>
&nbsp;&nbsp;*control_flow*<br/>
}?

The `except` command takes a minimum of three arguments:

 - the block of code to be executed,
 - the *name* of a variable for storing an exception object reference,
 - a list of exception types to catch and corresponding handler clauses.

If a regular Tcl `error` occurs inside a block guarded by `except` then it
is automatically converted to an exception of type `TclError` (see also the
example at the top). Inside a handler clause, the exception can be re-thrown
with the `reraise` keyword.

Optionally the list of handlers can be followed by the keyword `final` and
another code block which will be executed regardless of whether an exception
occurred or not.

### itcl::class Exception

The mother of all exceptions. All user-defined exceptions should directly or
indirectly inherit from `Exception`.

* `constructor` *msg*:
  <p>
  Exceptions are generally not created directly, but rather by use of the
  `raise` command.
  </p>

* `method msg`:
  <p>
  Return the error message stored with the exception object.
  </p>

### itcl::class RuntimeError

Inherits from `Exception`.

### itcl::class ValueError

Inherits from `RuntimeError`.

### itcl::class TimeoutError

Inherits from `RuntimeError`.

### itcl::class TclError

Inherits from `RuntimeError`. This is a special exception type. It represents 
Tcl errors that occur inside blocks guarded by `except`.

## SEE ALSO

`catch`(3tcl)
