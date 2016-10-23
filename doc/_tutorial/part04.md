---
title:  "Part IV: Extension Modules"
previous: part03
previous_title: "Driving the Web Browser"
next:
next_title:
layout: tutorial
---

# Convenience Classes and Functions

Caius provides a number of convenience classes and functions, that are meant
to make object-oriented programming in [incr Tcl] more fun and more efficient.

## Exception Handling

Import the `Error` package to gain access to Caius' advanced error handling
facilities. Code blocks that may raise an error are wrapped in an `except`
clause, as shown below.

~~~~{tcl}
package require Error

except {
    raise RuntimeError "something bad happened."
} e {
    RuntimeError {
        puts "Caught a runtime error: [$e msg]"
    }
    TimeoutError {
        puts "Caught a timeout exception!"

        # reraise the exception
        reraise $e
    }
}
~~~~

The example demonstrates how you can anticipate and respond to different types
of exceptions. If you want to re-raise an exception from a handler, make sure
to use the `reraise` keyword and *not* `raise`.

Using an `except` clause, you can also catch standard Tcl errors raised with
the `error` command:

~~~~{tcl}
package require Error

except {
    error "this is a Tcl error."
} e {
    TclError {
        puts "Caught a Tcl error: [$e msg]"
    }
}
~~~~

**A word of caution:** the third argument to `except` is actually interpreted as a
list. That's why you cannot put comments there:

~~~~{tcl}
except {
    # Comments as usual...
} e {
    # You cannot put a comment here!
    TclError {
        # But you can put a comment here.
    }
}
~~~~

Caius' sub-modules define and may raise their own exception types. To create a
new exception Type, simply inhert from base type `Exception`. For example,
`RuntimeError` is declared as follows:

~~~~{tcl}
::itcl::class RuntimeError {
    inherit ::Exception

    constructor {msg} { ::Exception::constructor $msg } {}
    destructor {}
}
~~~~

## Serialization to JSON

Caius allows you to create objects, which can by serizalized to and later
restored from JSON. Let's say we have a `Vertex` class to represent a point
in 3D space. This could look roughly like this:

~~~~{tcl}
package require Itcl
package require OOSupport

::itcl::class Vertex {

    common attributes {
        {number x null rw}
        {number y null rw}
        {number z null rw}
    }

    method constructor {x y z} {
        OOSupport::init_attributes

        set _x $x
        set _y $y
        set _z $z
    }

    OOSupport::bless_attributes -json_support
}
~~~~

At the top of the class definition, we created a class variable `attributes`,
which is a list of 4-tuples `{type name default access}`. This way, we declared
the attributes `x`, `y` and `z`, as the `Vertex` coordinates in space.
Available attribute types are

* number
* string
* bool
* or a class name (must be recognized by `itcl::is class`)

Additionally you can declare arrays of either type by wrapping the type
specifier in square brackets. You cannot have mixed-type arrays.

In the constructor the call to `init_attributes` implicitely creates the
corresponding member variables `_x`, `_y`, `_z`. This seems to be a bit awkward
at first sight. But then at the bottom of the class definition, the call to
`bless_attributes` creates accessor functions for each attribute according to
the attribute's permissions.

Attributes can be marked as

* `rw` (read-write),
* `ro` (read-only),
* `wo` (write-only) or
* `-` (no access).

Since all our attributes are marked as `rw`, both an accessor and a mutator are
created. You can now modify the properties of a `Vertex` as follows:

~~~~{tcl}
set vertex [Vertex #auto 1.2 3.3 9.7]

# prints "1.2"
puts [$vertex x]

$vertex set_x 11.1

# prints "11.1"
puts [$vertex x]
~~~~

The additional argument `-json_support` causes your Vertex objects to be
blessed with methods `to_json` and `from_json`. Calling the first will dump all
attributes declared in `common attributes` as JSON, calling the latter will
restore the object state from JSON input.

~~~~{tcl}
puts [$vertex to_json]
~~~~

The above prints the object's state in JSON notation to standard output:

~~~~{json}
{
        "x": 11.1,
        "y": 3.3,
        "z": 9.7
}
~~~~

Concerning restoration of an object from JSON consider the following example:

~~~~{tcl}
set new_vertex [Vertex #auto 1.0 1.0 1.0]
puts [$new_vertex to_json]

$new_vertex from_json [$vertex to_json]
puts [$new_vertex to_json]
~~~~

