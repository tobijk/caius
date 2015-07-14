---
title:  "Part III: Driving the Web Browser"
previous: part02
previous_title: "Driving the Command Line"
next: part04
next_title: "Extension Modules"
layout: tutorial
---

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
`WebDriver::Capabilities` object which, as the name suggests, holds information
about the browser you intend to drive and the capabilities you need to be
available. Using the capabilities object, you initiate a session as shown in
the following fragment:

~~~~{tcl}
set caps [namespace which [WebDriver::Capabilities #auto -browser_name firefox]]
set session [WebDriver::Session #auto http://127.0.0.1:4444/wd/hub $caps]
~~~~

The `Session` constructor takes as arguments

* the URL on which Selenium Server is listening for requests,
* a *mandatory* references to a `Capabilities` object and
* an *optional* reference to a `RequiredCapabilities` object.

The first `Capabilities` object describes the *desired* capabilities. Desired
means, that you would *like* these capabilities to be available, but that they
are not critical. The `RequiredCapabilities` object is optional and denotes 
capabilities which *must* be available. If the server cannot satisfy the requested
required capabilities, an error will be thrown.

The table below shows the capabilities that can be specified and their default
values upon creation of a `Capabilities` object. These default values *do not*
represent the defaults offered by any given browser. Adjust them to your needs.

<table class="table">
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

~~~~{tcl}
$caps set_native_events true
~~~~

and query them like this

~~~~{tcl}
set native_events_enabled [$caps native_events]
~~~~

In order to end an on-going session, call the `close` method or delete it
directly:

~~~~{tcl}
itcl::delete object $session
~~~~

## Turning on Logging

In order to make the WebDriver module log informational messages to standard
output, enable logging on the session object:

~~~~{tcl}
$session set_logging_enabled true
~~~~

## Resizing and Moving the Window

You can control size and position of the browser window on the screen as shown
in this example:

~~~~{tcl}
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

~~~~{tcl}
set caps [namespace which [WebDriver::Capabilities #auto]]
set session [WebDriver::Session #auto http://127.0.0.1:4444/wd/hub $caps]
$window set_url http://www.example.com
~~~~

You can navigate back and forth in the the history:

~~~~{tcl}
$window back

# check current URL
set url [$window url]

$window forward
~~~~

## Retrieving and Setting Cookies

Cookies are represented by `WebDriver::Cookie` objects. You can add a `Cookie`
for the currently active domain using the window object's `set_cookie`
method:

~~~~{tcl}
$window set_cookie -expiry "[expr [clock seconds] + duration]" \
    cookie_name cookie_value
~~~~

You may set the following attributes on the `Cookie` object:

<table class="table">
    <thead>
        <tr>
            <th> Parameter </th>
            <th> Default </th>
            <th> Description </th>
        </tr>
    </thead>
    <tbody>
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
            <td> whether the <code>Cookie</code> is secure </td>
        </tr>
        <tr>
            <td> -expiry </td>
            <td> not set </td>
            <td> cookie expiration date in seconds since midnight Jan 1, 1970 UTC</td>
        </tr>
    </tbody>
</table>

You can obtain a list of cookies set for the currently active domain, by
calling the `cookies` method on the window object:

~~~~{tcl}
set cookie_list [$window cookies]

foreach {c_obj} $cookie_list {
    puts "[$c_obj name]: [$c_obj value]"
}
~~~~

The result is a list of `WebDriver::Cookie` objects, whose name, value and
additional attributes you may query. The cookie object references are
maintained internally by the window, you *must not* delete them.

## Working with Page Elements

In order to test anything about your Web application, you need to be able to
access page elements and query and manipulate their states.

### Finding an Element

For looking up page elements, Selenium supports a number of
so-called locator strategies, listed in the table below.

<table class="table">
    <thead>
        <tr>
            <th>Strategy</th>
            <th>Description</th>
        </tr>
    </thead>
    <tbody>
        <tr>
            <td>by_class_name</td><td>Class name</td>
        </tr>
        <tr>
            <td>by_css_selector</td><td>A CSS selector</td>
        </tr>
        <tr>
            <td>by_id</td><td>The unique ID of an element</td>
        </tr>
        <tr>
            <td>by_name</td><td>The name of an element</td>
        </tr>
        <tr>
            <td>by_link_text</td><td>The text of a hyperlink</td>
        </tr>
        <tr>
            <td>by_partial_link_text</td><td>Partial text of a hyperlink</td>
        </tr>
        <tr>
            <td>by_tag_name</td><td>The name of the HTML element</td>
        </tr>
        <tr>
            <td>by_xpath</td><td>An XPATH expression</td>
        </tr>
    </tbody>
</table>

In order to get a reference to an input field with the id *username*, you
would call the `element` method on the window object like this:

~~~~{tcl}
set username_field [$window element by_id username]
~~~~

A call to `element` will only ever return a single object reference (the first
one that matches), even if multiple objects match the locator. To get a list of
all objects matching the locator, simply call `elements` instead.

Once you are done with an object reference, you have to manually delete it by
calling `itcl::delete object` on it.

### Checking if the Element is Being Displayed

Once you have obtained an element reference, you may want to check if the
element is actually displayed within the visibile canvas:

~~~~{tcl}
set username_field [$window element by_id username]
set is_displayed [$username_field displayed]
::itcl::delete object $username_field
~~~~

Note how we explicitely delete the reference object, once we have obtained
the information that we needed.

### Reading Element Attributes and CSS Properties

You can read the value of an element's attribute by calling

~~~~{tcl}
set value [$element attribute <attribute_name>]
~~~~

### Clicking an Element

Clicking an element is as simple as

~~~~{tcl}
$element click
~~~~

Depending on your application and the dimensions of its layout, you may want
to ensure that the element is actually on the visible canvas, for example by
issuing a `move_to` or by checking the return value of `displayed`.

### Getting the Text of an Element

The text of an element can be retrieved with a simple call:

~~~~{tcl}
puts [$element text]
~~~~

### Sending Text to an Input Field

In order to send input to an element, make sure it is focused then use the
`send_keys` method:

~~~~{tcl}
set element [$window element by_id username]
$element click
$element clear
$element send_keys "jonathan"
itcl::delete object $element
~~~~

### Determining the State of a Choice Field

In order to check the state of an input field of type checkbox or of a
combobox, call

~~~~{tcl}
$element selected
~~~~

### Testing two Page Elements for Equality

Using the `element` or `elements` methods on the window object, you can retrieve
multiple references representing the same element.

In order to find out, if any given two references are for the same element, call
the `equals` method:

~~~~{tcl}
if {[$element1 equals $element2]} {
    puts "same element"
} else {
    puts "different elements"
}
~~~~

Be aware that `$element2` must be a fully qualified object reference obtained
by a call to `namespace which`.

## Taking Screenshots

You may take a screenshot of the active page at any time by calling

~~~~{tcl}
set screenshot [$window screenshot -decode]

set fp [open "test.png" "w+b"]
puts $fp $screenshot
close $fp
~~~~

Without the `-decode` parameter, the `screenshot` method returns the image
Base64 encoded.

