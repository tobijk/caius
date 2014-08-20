Testing(3caius) -- base class for all native test classes
==============================================================================

## SYNOPSIS

    package require Itcl
    package require Testing

    itcl::class MyTests {
        inherit Testing::TestObject

        method test_passing {} {
            puts "Hello, I pass!"
        }

        method test_failing {} {
            error "Hello, I'm about to fail!"
        }
    }

    exit [[MyTestModule #auto] run $::argv]

## DESCRIPTION

`Testing::TestObject` is the base class for all *native* test written using
the Caius framework. While it is *not* mandatory to derive tests from the
`TestObject` class, it is highly recommended, as it provides built-in test
execution and reporting functionality via its `run` method.

## API

### itcl::class Testing::TestObject

* `method run ?-f report_format? ?test test ...?`:
  Execute the listed test methods and output test results in the given
  `report_format`, which must be one of junit, text, xml, zero. If no tests
  are explicitely listed, execute all methods in the class starting with the
  prefix *test*.

* `method list_tests`:
  Return a list of all available test methods on the given instance.

## SEE ALSO

`itcl`(3)
