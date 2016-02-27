---
title:  "Part I: Getting Started"
next: part02
next_title: "Driving the Command Line"
layout: tutorial
---

# Introduction

Caius is a functional testing framework written in object-oriented Tcl using
the \[incr Tcl] extension. It provides intuitive, object-oriented programming 
interfaces to Expect and Selenium WebDriver.

The `caius` command line tool provides a generic test runner which allows you
to execute tests written in any programming language and test framework. The
integrated report generator collects test results and turns them into legible,
clean test reports.

# Installation

In order to install and try out Caius on your system, follow the instructions
in this section.

## Pre-requisites

Caius is developed and tested on Debian/GNU Linux but should run on other
Linux distributions without problems. Using Caius on BSD or other Unix-like
systems may require minor modifications.

Caius requires Tcl 8.6 or later with thread support, a recent version of
tcllib and Expect. In addition, the tdom package is required for results
parsing and report generation.

## Installation from Source

Caius comes with a simple installer script that will copy modules and scripts
into your Tcl package path. After unpacking the sources, execute the installer
script via

    sudo ./install.tcl

After that you should be able to call `caius` from the command line.

# Writing Tests

This section explains how to write test modules and how to execute them.

## Outline of a Test Class

In Caius, test modules are classes which derive from `Testing::TestObject`. A
minimal test module looks like this:

~~~{tcl}
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

    method test_fail_with_assertion {} {
        Testing::assert {1 == 2}
    }
}

exit [[MyTests #auto] run $::argv]
~~~

The test class `MyTests` inherits a lot of functionality from
`Testing::TestObject`, most importantly the `run` method. The `run` method is
responsible for parsing any command line arguments and initiating the test
execution.

A test is any method that starts with the prefix `test`. Tests are executed
in lexicographical order. If you absolutely need your tests to run in a certain
order, you can use prefixes like `test_01`, `test_02`, etc.

Test methods don't take any parameters and their return value is ignored. To
make a test fail, you have to raise an error. This can be a normal Tcl error or
an Exception thrown using the `raise` command from Caius' `Error` package.

## Repeated Setup and Teardown

If you need to do repeated setup and cleanup work before and after each test
case, you can define methods `setup` and `teardown`. They will be invoked
automatically for you.

## One-time Preparation and Cleanup

If you need work to be done once on entry to your test module and once again
after the last test case has been run, *don't* use the constructor and
destructor of your test class for this purpose. Instead define methods
`setup_before` and `teardown_after`.

## Documenting Your Tests

In order to document your tests, you may define *docstrings* for your test
methods as shown in the following example:

~~~~{tcl}
itcl::class MyTest {
    inherit Testing::TestObject

    method test_something {} {
        docstr "This is an example docstring.

        Test steps:

        * step 1
        * step 2

        Docstrings are written in
        \[markdown syntax](http://daringfireball.net/projects/markdown/syntax).
        "

        # implementation here
    }
}
~~~~

Docstrings are a concept stolen from Python. They are a special feature
of Caius and not generally available in Tcl. They only work in test methods.
The `docstr` command must be the *very first* statement in the method body.

Docstrings are written in [markdown syntax](http://daringfireball.net/projects/markdown/syntax).
They are included in the test results output and converted to HTML for 
display in test reports. Note that since docstrings are Tcl strings, braces,
brackets and quotation marks need to be escaped.

## Making the Test Script Executable

In order to make a test script executable, simply add a shebang line at the top
of the script:

    #!/usr/bin/tclsh

Then mark the script as executable:

    chmod +x test.tcl

If your distribution ships with multiple versions of Tcl, or if Tcl 8.6 is not
the default version, you may have to be explicit about which `tclsh` you would
like to be invoked.

# Running Tests

This section explains how to execute your tests individually or as part of
a test plan.

## Direct Execution of Test Scripts

Test scripts that invoke the `run` method on a test object are fully
self-contained and can be called directly. In order to see which parameters
you can pass to your script, call it with the `--help` command line switch:

    ./test.tcl --help

In order to run all the tests, invoke the script without any arguments. Or if
you would like to run only selected tests, specify them separately on the
command line:

    ./test.tcl test1 test2 ...

In order to see which tests are available in your module, use the `--list`
command line switch:

    ./test.tcl -l

Per default, test scripts print the test results in an XML-based reporting
format. These XML reports have a simple structure, but if you need something
more readable, you can instruct the script to output logs and results in a
nicely indented text format using the `--format` parameter:

    ./test.tcl -f text

## Using the Caius Testrunner Application

When executing your tests in an automated fashion, for example from a CI
system, it is recommended that you invoke them indirectly using the
`caius run` command. Among other things, `caius run` can let your test scripts
timeout, which is essential if you want to avoid getting stuck on badly
written or misbehaving test cases.

In order to execute a test script with a 60 seconds timeout invoke it like
this:

    caius run -t 60 path/to/test

The `caius run` command will also do the right thing and recover in case your
script dies prematurely and/or for some reason produces an incomplete or
invalid results XML. Whenever the output of a script is valid XML, the test
runner will save it as it is. If a script produces broken XML or *any other*
format, the test runner will automatically convert it into a valid XML report.

An important implication of this is that `caius run` can run tests written in
any language and any framework. The only requirement is that tests terminate
with a non-zero exit status on failure.

## Creating and Executing a Test Plan

Test plans are written in a simple XML format and define a sequence of test
scripts to be executed. The following listing shows a basic example:

~~~~{xml}
<testplan>
    <run timeout="60">/home/tobias/Demo/test1.tcl</run>
    <run timeout="60">/home/tobias/Demo/test2.tcl</run>
    ...
</testplan>
~~~~

Test plans are loaded and executed with the `caius runplan` command. For each
test, a subdirectory will be created inside the current working directory. This
subdirectory will be made the working directory of the respective test script
itself.

You can explicitly set the initial working directory of the `runplan` command
using the `--work-dir` command line switch.

## Working with Constraints

Let's say you are testing a range of network devices offering connectivity
through an arbitrary combination of Ethernet, Wifi, DSL and UMTS. You have
tests for each feature and want to enable them selectively according to the
capabilities of the device under test.

To this end, you may attach constraints to arbitrary blocks of code or entire
test methods:

~~~{tcl}
# test works only for devices that have a wifi chip and a DSL modem
::Testing::constraints {wifi dsl} {
    method test_share_dsl_connection_over_wifi {} {
        # test code here ...
    }
}
~~~

When executing your test module, you can use the `--constraint` command line
parameter (also multiple times) to declare constraints to be true for the
duration of the test run:

    ./mytest.tcl -c wifi -c dsl

Alternatively, you can export a list of constraints to the environment
variable `CAIUS_TEST_CONSTRAINTS`.

## Executing Tests Matching a Pattern

You may choose to execute only certain tests from a test module by matching
test names against a wildcard pattern with the `--match` command line parameter.
For example, in order to run all tests that have the string *connectivity* in
their name you could say:

    ./mytest.tcl -m "*connectivity*"

Be careful to quote patterns to prevent your shell from interpreting them. The
`--match` option or its `-m` short-hand may be used multiple times.

# Generating Reports

In order to generate a report from the results of a testrun, use the
`caius report` command. It takes as a single argument the directory which to
scan for results.

The directory should contain subdirectories created by a previous call to
`caius runplan`. Each of these in turn should contain exactly one results XML
file named *result.xml* plus any number of artifacts.

The test report will be created inside the given directory as one or more HTML
files.

## Integration with Jenkins

In Jenkins, create a new project and configure your build as you normally would.
Then open the project settings, go to the *Build* section and add an extra build
step for running the tests. The following snippet might serve as an example:

    cd test
    rm -fr spool/*
    caius runplan -d spool -f junit testplan.xml

Note that we pass `-f junit`  to `caius runplan` indicating that test results
should be emitted in JUnit XML result format. Next, go to section *Post-build
Actions* and choose *Publish JUnit test result report*. As the fileset specify

    test/spool/*/result.xml

Finally double check that Jenkins has all the necessary permissions and access
to relevant infrastructure required for executing your tests successfully.
Trigger a build and enjoy your test results being reported natively in Jenkins.

