Testing(3caius) -- base class for all native test classes
==============================================================================

## EXAMPLE

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

    exit [[MyTests #auto] run $::argv]

## DESCRIPTION

`Testing::TestObject` is the base class for all *native* tests written using
the Caius framework. While it is *not* mandatory to derive tests from the
`TestObject` class, it is highly recommended, as it provides built-in test
execution and reporting functionality via its `run` method.

## API

### itcl::class Testing::TestObject

* `method run` ?`-f` *report_format*? ?*test* *test* ...?:
  Execute the listed *test* methods and output test results in the given
  *report_format*, which must be one of *junit*, *text*, *xml* or *zero*. If no tests
  are explicitely listed, execute all methods in the class starting with the
  prefix *test*.

* `method list_tests`:
  Return a list of all available test methods on the given `TestObject`.

* `method setup_before` [interface]:
  If implemented, this method is called once on entry to the test module.

* `method teardown_after` [interface]:
  If implemented, this method is called once after the last test in the module
  has finished.

* `method setup` [interface]:
  If implemented, this method is invoked before each test.

* `method teardown` [interface]:
  If implemented, this method is invoked after each test.

## ADDITIONAL NOTES

All methods starting with the prefix *test* are considered test cases and
automatically invoked by the `run` method.

## SEE ALSO

`itcl`(3)
