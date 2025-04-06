WebDriver(3caius) -- automate browser interaction with Selenium WebDriver
==============================================================================

## EXAMPLE

    package require WebDriver

    set caps [WebDriver::Capabilities #auto -browser_name firefox]
    set session [WebDriver::Session #auto \
        http://127.0.0.1:4444/wd/hub \
        [namespace which $caps] \
    ]

    $session set_logging_enabled true

    set window [$session active_window]
    $window maximize

    $window set_url http://www.example.com

    set element [$window element by_id username]

    $element click
    $element clear
    $element send_keys "jonathan"

    itcl::delete object $element
    itcl::delete object $session

## DESCRIPTION

The `WebDriver` module implements the Selenium WebDriver protocol. In order to
execute WebDriver tests, you will also need a copy of Selenium Server, which
you can download from `http://seleniumhq.org`.

Server and test scripts can run on different systems as the server is
controlled via remote procedure calls over a TCP connection. It is the server's
responsibility to launch a browser instance and to forward the commands it
receives from a test script.

## API

### namespace WebDriver

### Errors

All errors in the WebDriver module inherit from `WebDriver::Error`.

On protocol level, errors are reported with a 4xx or 5xx HTTP status code
and information about the error in JSON format. The framework automatically
converts such errors to exceptions of type `WebDriver::HTTPError`, which has
the following specializations:

A status code of 400 is translated to and thrown as a
`WebDriver::InvalidRequestError` and a status code of 404 is translated to
a `WebDriver::NotFoundError`. A status 5xx is translated to a
`WebDriver::ServerError`.

Even if not mentioned explicitly in the documentation below, operations on
non-existant windows or page items or incorrect element queries will trigger
one of the errors above.

### itcl::class WebDriver::Session

* `constructor` *url* *capabilities*:
  Establish a connection to Selenium Server at the given URL and request
  a session supporting the specified capabilities.
  
  The *capablities* parameter is a reference to a
  `WebDriver::Capabilities` object. The requested session properties are
  mandatory for test execution. If they cannot be full-filled an exception of
  type `WebDriver::ServerError` is thrown.

* `method active_window`:
  Return a reference to the active browser window represented by a
  `WebDriver::Window` object. The window reference is managed by the
  session and must not be deleted.

* `method logging_enabled`:
  Return a boolean value indicating whether logging has been enabled on the
  session.

* `method set_logging_enabled` *bool*:
  Enable logging on the session object. When this is set to true all actions
  within the session will be logged to stdout.

* `method set_async_script_timeout` *ms*:
  Set the time in milliseconds after which an asynchronously executed script
  is considered as having timed out.

* `method set_implicit_wait_timeout` *ms*:
  Set the time in milliseconds that the driver should wait on elements to appear.
  Consult the WebDriver documentation for more information.

* `method set_page_load_timeout` *ms*:
  Set the time in milliseconds after which a page load is considered as having
  timed out.

* `method windows`:
  Return a list of all windows in the current session. A window in the
  background can be activated by calling its `focus` method. The window
  references are managed by the session and must not be deleted.

### itcl::class WebDriver::Window

* `constructor`:
  Windows are always the property of a session object and should be retrieved
  with `Session` methods `active_window` and `windows`. There is absolutely no
  point in constructing a window manually.

* `method accept_alert`:
  Accept the currently displayed alert dialog. Usually, this is equivalent to
  clicking on the "OK" button in the dialog.

* `method active_element`:
  Return a `WebDriver::WebElement` reference to the page element that currently
  has the focus.

* `method alert_send_text` *text*:
  Send *text* as keystrokes to the currently displayed JavaScript dialog.

* `method alert_text`:
  Get the text of the currently displayed JavaScript `alert()`, `confirm()`,
  or `prompt()` dialog.

* `method back`:
  Navigate backwards in the history.

* `method close`:
  Close the window. Note that you are not allowed to close the last remaining
  window in a session. If you try to do so a `WebDriver::CloseSessionWindowError`
  will be thrown. The window will be closed, when the 

* `method cookies`:
  Return a list of all cookies for the active domain in form of
  `WebDriver::Cookie` object references. The cookies are a property of the
  `Window` object and must *not* be deleted.

* `method delete_cookie` *name*:
  Delete the cookie with the given *name*.

* `method dismiss_alert`:
  Dismiss the currently displayed alert dialog. For `confirm()` and `prompt()`
  dialogs, this is equivalent to clicking the "Cancel" button.

* `method element` *strategy* *locator*:
  Locate and return a reference to an element on the page in form of a
  `WebDriver::WebElement` instance. The *strategy* can be one of

  \* by_class_name,<br/>
  \* by_css_selector,<br/>
  \* by_id,<br/>
  \* by_name,<br/>
  \* by_link_text,<br/>
  \* by_partial_link_text,<br/>
  \* by_tag_name,<br/>
  \* by_xpath

  and the *locator* would be the corresponding specifier. This method only
  ever returns one element (the first one that matches). Element references
  obtained by this method must be explicitly deleted when not used anymore.

  Throws a `WebDriver::NotFoundEror` if the element cannot be found and a
  `WebDriver::InvalidRequestError` if an invalid expression was supplied.

* `method elements` *strategy* *locator*:
  Works exactly as method `element` above but, as the name suggests, will
  return a list of all elements that match the given locator. Element 
  references obtained by this method must be explicitly deleted when not
  used anymore.

  May return an empty list. Throws a `WebDriver::InvalidRequestError` if an
  invalid expression was supplied.

* `method execute` *script* ?*arg* *arg* ...?:
  Inject a piece of JavaScript into the page and execute it. Any additional
  arguments passed along will be accessible from an array `arguments` inside
  the script.

* `method execute_async` ?`-joinable`? ?`-result` *varname* *element*? ?`-error` *varname* *element*? *script*:
  Inject a piece of JavaScript into the page and execute it asynchronously.
  Returns the id of the thread which is handling the script execution. If the
  `-joinable` flag is set, the thread can be waited on with `thread::join`. The
  `-result` parameter specifies the name of a thread shared variable, as described
  in `tsv`(3tcl), under which to store the script result. In the same way an
  error variable can be specified, which will hold information about any error
  that occurred during script execution.

  This method is processed in a separate thread. If an error occurrs during
  script execution, the thread shared variable specified via the `-error`
  parameter will contain a description of the error.

* `method focus`:
  Activate the window and bring it to the foreground.

* `method forward`:
  Navigate forward in the history.

* `method maximize`:
  Maximize the window.

* `method name`:
  Return the name of the window.

* `method page_source`:
  Return the full source of the current page.

* `method page_title`:
  Return the current page's title.

* `method position`:
  Return the current position of the window as a Tcl list of format
  `{x y}`.

* `method refresh`:
  Reload the current page.

* `method screenshot` ?`-decode`?:
  Return a screenshot of the page in PNG format. If the `-decode` parameter
  is given, the return value is the raw PNG, otherwise the image is
  Base64-encoded.

* `method select_frame` ?*id*?:
  Select a frame inside the window by its id, where *id* is either the literal
  id of the frame or a reference to a `WebDriver::WebElement` object
  identifying the frame. If *id* is not specified, Selenium Server will select
  the *default* content of the page.

* `method session`:
  Return a reference to the `WebDriver::Session` that the window is a part of.

* `method set_cookie` ?`-path` *string*? ?`-domain` *string*? ?`-secure`? ?`-http_only`? ?`-expiry` *timestamp*? *name*:
  Set a cookie for the active domain or the domain specified via the `-domain`
  parameter. The `-expiry` of the cookie must be a Unix timestamp indicating the
  time of expiry as seconds since midnight Jan 1, 1970 UTC.

* `method set_position` *x* *y*:
  Move the window so that the upper left corner is positioned at pixel
  coordinates *x* and *y* on the desktop.

* `method set_size` *width* *height*:
  Resize the window to the given dimensions.

* `method set_url` *url*:
  Load the given URL.

* `method size`:
  Return the size of the window as a Tcl list of the format `{width height}`.

* `method url`:
  Return the currently loaded URL.

### itcl::class WebDriver::WebElement

* `constructor`:
  `WebElement` instances are obtained by calling the `element` or `elements`
  methods on a `WebDriver::Window` object. Elements cannot be injected into the
  page (you can of course inject JavaScript to do something like that). Thus
  there is no point in constructing a `WebElement` manually.

* `method attribute` *name*:
  Return the value of the attribute with the given `name`.

* `method clear`:
  Clear a `textarea` or an `input` element's value.

  Throws a `WebDriver::StaleElementReferenceError` if the element is no longer
  attached to the page's DOM, a `WebDriver::ElementNotVisibleError` if the
  element is not visible on the page or a `WebDriver::InvalidElementStateError`
  if the referenced element is disabled.

* `method click`:
  Click on the element.

  Throws a `WebDriver::StaleElementReferenceError` if the element is no longer
  attached to the page's DOM or a `WebDriver::ElementNotVisibleError` if the
  element is not visible on the page.

* `method css_property` *name*:
  Return the value of the CSS property *name*.

* `method descendant` *strategy* *locator*:
  Works analogously to `Window::element`, but only searches the
  element tree below the current element.

* `method descendants` *strategy* *locator*:
  Works analogously to `Window::elements`, but only searches the element tree
  below the current element. May return an empty list.

* `method displayed`:
  Determine if the element is currently displayed.

* `method enabled`:
  Check whether the element is currently enabled.

* `method location`:
  Return the element's location on the page as a Tcl list of format `{x y}`.
  The point `{0 0}` refers to the top left corner of the canvas.

* `method selected`:
  Determine if an `option` element, or an `input` element of type checkbox
  or radiobutton is currently selected.

* `method send_keys` *string*:
  Send the characters in the given *string* as keystrokes to the element.

* `method size`:
  Return the element's size in pixels as a Tcl list of format `{width height}`.

* `method tag_name`:
  Returns the HTML tag name of the element.

* `method text`:
  Return the text of the element without any markup. The result of this command
  is a string holding the content of all text nodes that are descendants of the
  element.

### itcl::class WebDriver::Cookie

* `constructor` ?`-domain` *name*? ?`-expiry` *timestamp*? ?`-http_only`? ?`-path` *name*? ?`-secure`? *name* *value*:
  Typically, it is not necessary to construct a `Cookie` manually. Most of the
  time, you will just retrieve cookies via a `WebDriver::Window` object, or you
  will set cookies using the `Window` class' `set_cookie` method.

* `method domain`:
  Return the cookie domain.

* `method expiry`:
  Return the expiration date as a timestamp since Jan 1, 1970 UTC.

* `method http_only`:
  Check whether the cookie is marked as being for HTTP only.

* `method name`:
  Return the name of the cookie.

* `method path`:
  Return the path of the cookie.

* `method secure`:
  Determine whether the cookie is a secure cookie.

* `method value`:
  Retrieve the cookie's value.

* `method set_domain` *string*:
  Set the cookie domain.

* `method set_expiry` *timestamp*:
  Set the expiration date of the cookie, where *timestamp* is the number of seconds
  since Jan 1, 1970 UTC.

* `method set_http_only` *bool*:
  Mark the cookie as http-only.

* `method set_name` *string*:
  Set the cookie's name.

* `method set_path` *string*:
  Set the path of the cookie.

* `method set_secure`:
  Mark as a secure cookie.

* `method set_value` *string*:
  Set the cookie's value.

### itcl::class WebDriver::Capabilities

* `constructor` ?`-browser_name` *string*? ?`-browser_version` *string*? ?`-platform_name` *string*? ?`-accept_insecure_certs` *bool*?:
  `Capabilities` are used to request session properties during initialization of
  a `WebDriver::Session`.

* `method accept_insecure_certs`:
  Query whether the session accepts invalid or insecure SSL certificates.

* `method browser_name`:
  Return the name of the selected browser engine.

* `method browser_version`:
  The selected browser version, or the empty string if unknown.

* `method page_load_strategy`:
  Return the selected page load strategy.

* `method platform_name`:
  Return the name of the selected platform.

* `method set_accept_insecure_certs` *bool*:
  Enable insecure SSL certificates, useful for testing e.g. with self-signed
  certificates.

* `method set_browser_name` *string*:
  Set the name of the browser to be used, e.g.
  `{chrome|firefox|...}`. Consult the WebDriver documentation for supported
  browsers.

* `method set_browser_version` *string*:
  Set the version string of the browser to use.

* `method set_page_load_strategy` *string*:
  Set the page load strategy, which can be one of `{normal|eager|none}`.
  Consult the WebDriver documentation for a thorough explanation of these.

* `method set_platform_name` *string*:
  Specify which platform the tests should run on, e.g.
  `{windows|linux|mac|...}`. Consult the WebDriver documentation for valid
  platform names. When requesting a new session, the client may specify `ANY`
  to indicate any available platform may be used.

## SEE ALSO

`itcl`(3), `error`(3caius)
