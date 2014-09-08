OOSupport(3caius) -- simplify object-oriented programming in [incr Tcl]
==============================================================================

## EXAMPLE

    package require Itcl
    package require OOSupport

    itcl::class Item {
        common attributes {
            {string   name     ""    rw}
            {bool     active   false rw}
            {number   value    0.0   rw}
            {[::Item] subitems {}    rw}
        }

        constructor {} {
            OOSupport::init_attributes
        }

        OOSupport::bless_attributes -json_support
    }

    set sub_item1 [Item #auto]
    $sub_item1 set_name   "sub item1"
    $sub_item1 set_active true
    $sub_item1 set_value  23.7

    set sub_item2 [Item #auto]
    $sub_item2 set_name   "sub item2"
    $sub_item2 set_active true
    $sub_item2 set_value  14.8

    set main_item [Item #auto]
    $main_item set_name   "main item"
    $main_item set_value  1
    $main_item set_subitems [list [namespace which $sub_item1] \
        [namespace which $sub_item2]]

    # save main item as JSON
    set json_dump [$main_item to_json]

    # initialize different item from JSON
    set new_item [Item #auto]
    $new_item from_json $json_dump

    puts [$new_item to_json]

## DESCRIPTION

This module provides convenience functions that allow you to define attributes
on your Itcl classes and automatically generate getters, setters and support
for serialization to JSON.

When defining a new type, you can declare its accessible properties in a class
variable called `attributes`:

    itcl::class Type {
        common attributes {
            {type name default access}
            ...
        }
        ...

The *type* specifier should be one of *bool*, *number*, *string* or a class
name that is recognized by `itcl::is class`. Additionally you can declare arrays
of either type by putting the *type* specifier in square brackets. It is *not*
possible to keep mixed-type arrays.

The type specifier is evaluated during serialization to or de-serialization
from JSON. Since Tcl doesn't have explicit types, it would otherwise not be
possible to map to and from JSON without loss of information.

After having declared the `common attributes`, you have to bring them to life,
by calling `OOSupport::init_attributes` in the constructor:

        ...
        constructor {} {
            OOSupport::init_attributes
        }
        ...

This way, when an object is instantiated, member variables will be created
automatically according to the attributes declaration. For an attribute `name`
the corresponding member variable will be `_name`. The member variable will be
initiated to the *default* value supplied in the attribute declaration.

Last but not least, you can *bless* your attributes with accessor functions
according to the *access* specification, which can be one of

* ro (read-only)
* wo (write-only)
* rw (read-write)
* -- (no access)

The getters or setters are created by calling `OOSupport::bless_attributes`
in the body of your class definition. If read support is enabled for an
attribute *name*, the attribute value can be retrieved by calling a method
`name`. If write support is enabled on the attribute, then the attribute
can be set via a method `set_name`.

If you pass the additional parameter `-json_support` to `bless_attributes`,
your objects will also have methods `to_json` and `from_json` which can be
used to serialize the object state to JSON or restore an object from its
JSON representation.

## API

* `init_attributes`:
  In a constructor, bring to life member variables according to the
  `common attributes` declaration and initialize them with specified default
  values.

* `bless_attributes` ?*-opts*?:
  In the body of a class definition, auto-generate getter and setter methods
  for members according to the *access* specification of each attribute.

  If the `-json_support` parameter is supplied, then objects will be blessed
  with additional methods `to_json` and `from_json` that allow serializing an
  object to and restoring it from JSON.
  
  If `-skip_undefined` is specified, then empty strings and variables of
  other types that are initialized to `null` will not be included in JSON output.
  
  If `-collapse_underscore` is given, then attributes of the form `attr_name`
  will be dumped and read in camel-case as `attrName` instead.

## SEE ALSO

`itcl`(3itcl), `json`(3tcl)

