WebDriver(3caius) -- automate browser interaction with Selenium WebDriver
==============================================================================

## SYNOPSIS

    set caps [itcl::code [WebDriver::Capabilities #auto -browser_name firefox]]
    set session [WebDriver::Session #auto http://127.0.0.1:4444/wd/hub $caps]

    $session set_logging_enabled true

    set window [$session active_window]
    $window maximize

    $window set_url http://www.example.com

    set element [$window element by_id username]
    $element click
    $element clear
    $element send_keys "jonathan"
    itcl::delete $element

## DESCRIPTION

The `WebDriver` module implements the Selenium WebDriver protocol. In order to
execute WebDriver tests, you will also need a copy of Selenium Server, which
you can download from `http://seleniumhq.org`.

Server and test scripts can run on different systems as the server is
controlled via remote procedure calls over a TCP connection. It is the server's
responsibility to launch a browser instance and to forward the commands it
receives from a test script.

## API

### itcl::class WebDriver::Session

* `constructor url desired_capabilities ?required_capabilities?`:
  Establish a connection to Selenium Server at the given URL and request a
  session supporting the specified capabilities.
  
  The `desired_capabilities` parameter expects a reference to a
  `WebDriver::Capabilities` object. Desired means in this context that the
  requested session properties are not mandatory for test execution.

  The `required_capablities` parameter expects a reference to a
  `WebDriver::RequiredCapabilities` object. Required means in this context
  that the requested session properties are mandatory for test execution.
  If they cannot be full-filled an exception is thrown.

* `method capabilities`:
  Query the actual session capabilities. Returns a reference to a
  `WebDriver::Capabilities` object.

* `method get_log type`:
   Retreive log items of the given type (see also method `log_types`) from the
   *server*. Returns a list of raw log items.

* `method logging_enabled`:
  Return a boolean value indicating whether logging has been enabled on the
  session.

* `method log_types`:
  Return a list of log types available on the *server*.

* `method set_logging_enabled bool`:
  Enable logging on the session object. When this is set to true all actions
  within the session will be logged to stdout.

* `method set_async_script_timeout ms`:
  Set the time in milliseconds after which an asynchronously executed script
  is considered as having timed out.

* `method set_implicit_wait_timeout ms`:
  Set the time in milliseconds after which an ongoing operation is considered
  as having timed out.

* `method set_page_load_timeout ms`:
  Set the time in milliseconds after which a page load is considered as having
  timed out.

* `method active_window`:
  Return a reference to the active browser window represented by a
  `WebDriver::Window` object. The window reference is managed by the
  session and must not be deleted.

* `method windows`:
  Return a list of all windows in the current session. A window in the
  background can be activated by calling its `focus` method. The window
  references are managed by the session and must not be deleted.

### itcl::class WebDriver::Window

* `constructor`:
  Windows are always the property of a session object and should be retrieved
  with `Session` methods `active_window` and `windows`. Don't try to construct
  a window manually.

* `method back`:
  Navigate backwards in the history.

* `method close`:
  Closes the window. Note that you are not allowed to close the last remaining
  window in a session. If you try to do so a `WebDriver::CloseSessionWindowError`
  will be thrown.

* `method cookies`:
  Return a list of all cookies for the active domain in form of
  `WebDriver::Cookie` object references. The cookies are a property of the
  `Window` object and must *not* be deleted.

* `method delete_cookie name`:
  Delete the cookie with the given name.

* `method element strategy locator`:
  Locate and return a reference to an element on the page in form of a
  `WebDriver::WebElement` instance. The `strategy` can be one of

  by_class_name,<br/>
  by_css_selector,<br/>
  by_id,<br/>
  by_name,<br/>
  by_link_text,<br/>
  by_partial_link_text,<br/>
  by_tag_name,<br/>
  by_xpath

  and the `locator` would be the corresponding specifier. This method only
  ever returns one element (the first one that matches). Element references
  obtained by this method must be explicitly deleted when not used anymore.

* `method elements strategy locator`:
  Works exactly as method `element` above but, as the name suggests, will
  return a list of all elements that match the given locator. Element 
  references obtained by this method must be explicitly deleted when not
  used anymore.

* `method execute script ?arg arg ...?`:
  Inject a piece of Javascript into the page and execute it. Any additional
  arguments passed along will be accessible from an array `arguments` inside
  the script.

* `method execute_async ?-joinable? ?-result varname element? ?-error varname element? script`:
  Inject a piece of Javascript into the page and execute it asynchronously.
  Returns the id of the thread which is handling the script execution. If the
  `-joinable` flag is set, the thread can be waited on with `thread::join`. The
  `-result` parameter specifies the name of a thread shared value, as described
  in `tsv`(3tcl), under which to store the script result. In the same way an
  error variable can be specified, which will hold information about any error
  that occurred during script execution.

* `method focus`:
  Activate the window and bring it to the foreground.

* `method forward`:
  Navigate forward in the history.

* `method maximize`:
  Maximize the window.

* `method name`:
  Return the name of the window.

* `method position`:
  Return the current position of the window as a Tcl list of format
  `{x y}`.

* `method refresh`:
  Reload the current page.

* `method page_source`:
  Return the full source of the current page.

* `method page_title`:
  Return the current page's title.

* `method screenshot ?-decode?`:
  Return a screenshot of the page in PNG format. If the `-decode` parameter
  is given, the return value is the raw PNG, otherwise the image data is
  Base64-encoded.

* `method select_frame ?id?`:
  Select a frame inside the window by its id, where id is either the literal
  id of the frame or a reference to a `WebDriver::WebElement` object
  identifying the frame. If no id is specified, Selenium Server will select
  the "default" content of the page.

* `method session`:
  Return a reference to the session that the window is a part of.

* `method set_cookie ?-path string? ?-domain string? ?-secure? ?-http_only? ?-expiry sec? name`:
  Set a cookie for the active domain or the domain specified via the `-domain`
  parameter. The `-expiry` of the cookie must be a Unix timestamp indicating the
  time of expiry as seconds since midnight Jan 1, 1970 UTC.

* `method set_position x y`:
  Move the window so that the upper left corner is positioned at pixel
  coordinates x and y on the desktop.

* `method set_size width height`:
  Resize the window to the given dimensions.

* `method set_url url`:
  Load the given URL.

* `method size`:
  Return the size of the window as a Tcl list of the format `{width height}`.

* `method url`:
  Return the currently loaded URL.

## ADDITIONAL HINTS

While the `Session` methods `logging_enabled` and `set_logging_enabled` deal
with local logging functionality of the `WebDriver` package itself, the methods
`log_types` and `get_log` are for retrieving logs from the *server* instead.

## SEE ALSO

`itcl`(3), `error`(3caius)

