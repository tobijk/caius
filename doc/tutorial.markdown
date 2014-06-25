[TOC]

# Introduction

Caius is a functional testing framework written in object-oriented Tcl using
the [incr Tcl] extension. It provides intuitive, object-oriented programming 
interfaces to Expect and Selenium WebDriver.

The `caius` command line tool provides a generic test runner which allows you
to also execute tests written using other languages and frameworks. The
integrated report generator collects test results and turns them into legible,
clean test reports.

# Installation

In order to install and try out Caius on your system, follow the instructions
in this section.

## Pre-requisites

Caius is developed and tested on Debian/GNU Linux but should run on other
Linux distributions without problems. Using Caius on BSD or other Unix-like
systems may require minor modifications.

Caius requires Tcl 8.6 or later with thread support and a recent version of
tcllib. In addition, the tdom package is required for results parsing and
report generation.

## Installing the Binary Packages

## Installation from Source

# Writing Tests

This section explains how to write test modules.

## Outline of a Test Class

In Caius, test modules are classes which derive from `Testing::TestObject`. A
minimal test module looks like this:

~~~~{.tcl}
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
~~~~

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

~~~~{.tcl}
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
The `docstr` command *must* be the very first statement in the method body.

Docstrings are written in [markdown syntax](http://daringfireball.net/projects/markdown/syntax).
They are included in the test results output and converted to HTML for 
display in test reports. Note that since docstrings are Tcl strings, braces,
brackets and quotation marks need to be escaped.

## Making the Test Script Executable

In order to make a test script executable, simply add a shebang line at the top
of the script:

~~~~{.tcl}
#!/usr/bin/tclsh
~~~~

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

In order to see which tests are available in your module, use the '--list'
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

~~~~{.xml}
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

# Generating Reports

In order to generate a report from the results of a testrun, use the
`caius report` command. It takes as a single argument the directory which to
scan for results.

The directory should contain subdirectories created by a previous call to
`caius runplan`. Each of these in turn should contain exactly one results XML
file named *result.xml* plus any number of artifcats, which will be linked into
the test report.

The test report will be created inside the given directory as one or more HTML
files.

# Driving the Command Line with Expect

Expect has been copied many times, and bindings to libexpect exist for many
other programming language. But none of them achieves the same deep integration
with the language, the ease of use and the versatility of Expect for Tcl.

Caius simplifies working with Expect by wrapping the most commonly used
functionality in an object-oriented programming interface.

## Spawning a Process

In order to spawn a process and interact with it through the standard channels,
create a `CliDriver::Spawn` instance like this:

~~~~{.tcl}
package require CliDriver

set p [CliDriver::Spawn #auto telnet localhost]
~~~~

You can then invoke `send` and `expect` on the object `p` as you would with
classic expect:

~~~~{.tcl}

set count 0
set timeout 5

$p expect {
    "*assword*:*" {
        $p send "password\n"
        exp_continue
    }
    "*ogin*:*" {
        $p send "username\n"
        exp_continue
    }
    "*user@host*" {
        # done
    }
    timeout {
        incr count

        if {$count > 3} {
            error "Timed out during login procedure."
        }

        exp_continue
    }
}

itcl::delete object $p
~~~~

The advantages of working with objects become more apparent when you start
spawning multiple processes. With classic expect you need to keep track of the
spawn ids and set the global `spawn_id` variable each time you switch to another
process. Caius does this for you implicitly.

If you need to, you can still access the spawn id like this

~~~~{.tcl}
set spawn_id [$p spawn_id]
~~~~

and use classic expect calls, for example to wait on multiple channels at the
same time. Note also how we used `timeout` and `exp_continue` just as if we
were working with Expect directly.

When you delete a `Spawn` object while the process it represents is still
active, then the process will be terminated. If the process has ended, it will
be waited on.

## Connecting via SSH and Telnet

Since Expect is often used to log into remote machines using SSH or Telnet,
the convenience classes `CliDriver::Telnet` and `CliDriver:Ssh` are available.
They are used in the same way as `Spawn` but implicitely invoke the `telnet`
or `ssh` command installed in the system.

~~~~{.tcl}
package require CliDriver

set ssh [CliDriver::Ssh #auto user@host]

$ssh expect "*Password:*"
...
~~~~

## Using a Serial Line

Last but not least, there is the `CliDriver::Stty` class. As the name implies, this
one is for running Expect on a serial connection. The constructor takes various
optional parameters, such as the baud rate, that are used to configure the
terminal device, as shown in the following example:

~~~~{.tcl}
package require CliDriver

set serial [CliDriver::Stty #auto /dev/ttyS0 \
    -baud 56000 -parity n -data_bits 8 -stop_bits 1]
~~~~

The settings in the example above are actually the default settings. So in case
they match your requirements, it is sufficient to specify the port.

## Expecting from Multiple Sources

If you need to expect from multiple processes simultaneously, you currently
have to harvest the spawn ids from your CliDriver objects and use a traditional
expect call. A more user-friendly way of doing this may be implemented in future
versions of Caius.

## Important Notes

Caius calls `log_user` and `log_file` to ensure that Expect logs all output
through a Tcl channel. Be aware that modifying either of those settings may
break logging in your test scripts in unexpected ways.

# Selenium WebDriver API

Caius provides a comprehensive API for conducting tests on Web-based applications
through the Selenium WebDriver interface.

## Pre-requisites and General Setup

In order to automate browser sessions with Caius, you need a copy of Selenium
Server. You can download the latest version from
[here](http://docs.seleniumhq.org/download/). Selenium Server is a Java
Application, thus you will also need a Java Runtime Environment.

Selenium Server does not need to be running on the same computer as your
scripts. Caius communicates with the server over a TCP connection via the
[WebDriver Wire Protocol](https://code.google.com/p/selenium/wiki/JsonWireProtocol).
The server in turn is responsible for launching a browser instance using the
appropriate driver engine and passing on the commands it receives.

If you intend to only use Firefox during testing, then you don't need to install
any additional drivers. If you want to control other browsers, then you need to
install the respective drivers, which you can also find on Selenium's [download
page](http://docs.seleniumhq.org/download/).

Launch Selenium Server like this:

    java -jar selenium-server-standalone-2.38.0.jar

## Opening a new Session

In order to start a new browser session, you first have to create a
`WebDriver::Capabilities` object which, as the name suggest, holds information
about the browser you intend to drive and the capabilities you need to be
available. Using the capabilities object, you initiate a session as shown in
the following fragment:

~~~~{.tcl}
set caps [namespace which [WebDriver::Capabilities #auto -browser_name chrome]]
set session [WebDriver::Session #auto http://127.0.0.1:4444/wd/hub $caps]
~~~~

The session constructor takes as arguments the URL on which Selenium Server
is listening for requests and in addition two references to `Capabilities`
objects. The first `Capabilities` object is mandatory and describes the
*desired* capabilities. Desired means, that you would *like* these capabilities
to be available, but that they are not critical. The second Capabilities object
is optional and denotes the *required* capabilities. If the server cannot
satisfy the requested required capabilities, an error will be thrown.

The table below shows the capabilities that can be specified and their default
values upon creation of a `Capabilities` object. These default values do not
represent the defaults offered by any given browser.

<table>
    <thead>
        <tr>
            <th> Capability </th>
            <th> Default value </th>
            <th> Description </th>
        </tr>
    </thead>
    <tbody>
        <tr>
            <td> browser_name </td>
            <td> htmlunit </td>
            <td> the browser to use (htmlunit|chrome|firefox|ie|...) </td>
        </tr>
        <tr>
            <td> javascript_enabled </td>
            <td> true </td>
            <td> enable JavaScript (true|false) </td>
        </tr>
        <tr>
            <td> takes_screenshot </td>
            <td> true </td>
            <td> enable taking screenshots (true|false) </td>
        </tr>
        <tr>
            <td> handles_alerts </td>
            <td> true </td>
            <td> enable alert handling (true|false) </td>
        </tr>
        <tr>
            <td> database_enabled </td>
            <td> true </td>
            <td> enable using browser database storage (true|false) </td>
        </tr>
        <tr>
            <td> location_context_enabled </td>
            <td> true </td>
            <td> allow accessing the browser's location context (true|false) </td>
        </tr>
        <tr>
            <td> application_cache_enabled </td>
            <td> true </td>
            <td> allow session to interact with application cache (true|false) </td>
        </tr>
        <tr>
            <td> browser_connection_enabled </td>
            <td> true </td>
            <td> allow querying and modifying browser connectivity (true|false) </td>
        </tr>
        <tr>
            <td> css_selectors_enabled </td>
            <td> true </td>
            <td> enable use of CSS selectors (true|false) </td>
        </tr>
        <tr>
            <td> web_storage_enabled </td>
            <td> true </td>
            <td> enable interaction with storage objects (true|false) </td>
        </tr>
        <tr>
            <td> rotatable </td>
            <td> true </td>
            <td> enable rotation on mobile platforms (true|false) </td>
        </tr>
        <tr>
            <td> accept_ssl_certs </td>
            <td> true </td>
            <td> accept all SSL certificates by default (true|false) </td>
        </tr>
        <tr>
            <td> native_events </td>
            <td> false </td>
            <td> whether session can generate native input events (true|false) </td>
        </tr>
        <tr>
            <td> proxy </td>
            <td> Direct Connection </td>
            <td> a WebDriver::Proxy object (fully qualified object reference) </td>
        </tr>
    </tbody>
</table>

You can preset capabilties during the creation of the `Capabilities` object as
indicated in the previous example. Or you can modify them later like this:

~~~~{.tcl}
$caps set_native_events true
~~~~

and query them like this

~~~~{.tcl}
set native_events_enabled [$caps native_events]
~~~~

In order to end an on-going session, call the `close` method or delete it
directly:

~~~~{.tcl}
itcl::delete object $session
~~~~

## Turning on Logging

In order to make the WebDriver module log informational messages to standard
output, enable logging on the session object:

~~~~{.tcl}
$session set_logging_enabled true
~~~~

## Resizing and Moving the Window

You can control size and position of the browser window on the screen as shown
in this example:

~~~~{.tcl}
set caps [namespace which [WebDriver::Capabilities #auto]]
set session [WebDriver::Session #auto http://127.0.0.1:4444/wd/hub $caps]
set window [$session active_window]

$window maximize

# position should now be (0, 0)
lassign [$window position] x y

# set size width x height
$window set_size 1000 800

# size should now be 1000 x 800
lassign [$window size] w h

# set position (x, y)
$window set_position 10 10
~~~~

## Loading URLs and Navigating the History

Load a URL using the `Window` object's `set_url` method:

~~~~{.tcl}
set caps [namespace which [WebDriver::Capabilities #auto]]
set session [WebDriver::Session #auto http://127.0.0.1:4444/wd/hub $caps]
$window set_url http://www.example.com
~~~~

You can navigate back and forth in the the history:

~~~~{.tcl}
$window back

# check current URL
set url [$window url]

$window forward
~~~~

## Retrieving and Setting Cookies

Cookies are represented by `WebDriver::Cookie` objects. You can add a `Cookie`
for the currently active domain using the `Window` object's `set_cookie`
method:

~~~~{.tcl}
$window set_cookie -expiry "[expr [clock seconds] + duration]" \
    cookie_name cookie_value
~~~~

You may set the following attributes on the `Cookie` object:

<table>
    <thead>
        <tr>
            <th> Parameter </th>
            <th> Default </th>
            <th> Description </th>
        </tr>
    </thead>
    </tbody>
        <tr>
            <td> -path </td>
            <td> / </td>
            <td> the path for which the Cookie is valid </td>
        </tr>
        <tr>
            <td> -domain </td>
            <td> active domain </td>
            <td> the Cookie domain </td>
        </tr>
        <tr>
            <td> -secure </td>
            <td> not set </td>
            <td> whether the `Cookie` is secure </td>
        </tr>
        <tr>
            <td> -expiry </td>
            <td> not set </td>
            <td> cookie expiration date in seconds since midnight Jan 1, 1970 UTC</td>
        </tr>
    </tbody>
</table>

## Working with Page Elements

### Finding an Element

### Checking if the Element is Being Displayed

### Reading Element Attributes and CSS Properties

### Clicking an Element

### Getting the Text of an Element

### Sending Text to an Input Field

### Determining the State of a Choice Field

### Testing two Page Elements for Equality

## Taking Screenshots


# Convenience Classes and Functions

## Exception Handling

## Serialization to JSON


