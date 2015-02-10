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

        method test_with_assertion {} {
            set a 0
            set b 1

            # will raise ::Testing::AssertionFailed
            ::Testing::assert {$a == $b}
        }

        ::Testing::constraints {umts} {
            method test_umts_connectivity {} {
                # test code ...
            }
        }
    }

    exit [[MyTests #auto] run $::argv]

## DESCRIPTION

`Testing::TestObject` is the base class for all *native* tests written using
the Caius framework. While it is *not* mandatory to derive tests from the
`TestObject` class, it is highly recommended, as it provides built-in test
execution and reporting functionality via its `run` method.

## API

### namespace Testing

* `assert` `{` *expression* `}`:
  Assert that *expression* is true. If not, raise a `::Testing::AssertionFailed`
  exception. The given *expression* is evaluated as by `if`.

* `constraints` *constraints* *body*:
  Executes the *body* of code at the *current* stack level if all constraints
  are satisfied. For example

      ::Testing::constraints {unix nonRoot} {
          # code executed if platform is Unix and user not root
      }

  Constraints can be set or unset with the `set_constraint` command. There are a
  number of pre-defined constraints:

  * `unix`:
    Test or code block only runs on a Unix platform (includes Mac OS X).

  * `win`:
    Test or code block only works on MS Windows.

  * `tempNotUnix`:
    Constraint to temporarily disable tests or code on Unix.

  * `tempNotWin`:
    Constraint to temporarily disable tests or code on Windows.

  * `unixCrash`:
    Indicate that a test or block of code crashes on Unix.

  * `winCrash`:
    Indicate that a test or block of code crashes on Windows.

  * `emptyTest`:
    Indicate that a test is empty, maybe to serve as a template or to be
    filled in later.

  * `knownBug`:
    Indicate that a test is known to fail.

  * `nonPortable`:
    Indicate that a test is not portable.

  * `userInteraction`:
    Indicate that a test requires user interaction.

  * `pointer64`:
    The host platform uses 64 bit pointers (typically this indicates that the
    OS itself is 64 bit, as well).

  * `unixExecs`:
    Test requires common Unix tools. This tests for cat, echo, sh, wc, rm,
    sleep, fgrep, ps, chmod, mkdir.

  * `root`:
    Test requires superuser privileges on Unix.

  * `nonRoot` :
     Test must be run in an unprivileged account.

* `set_constraint` *constraint* *boolean*:
   Enable or disable *constraint*.

* `test_constraints` *constraints*:
   Test given list of constraints and return 1 if all constraints are satisfied
   or 0 otherwise.

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
