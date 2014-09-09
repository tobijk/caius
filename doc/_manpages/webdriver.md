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

### itcl::class WebDriver::Session

* `constructor` *url* *desired_capabilities* ?*required_capabilities*?:
  Establish a connection to Selenium Server at the given URL and request
  a session supporting the specified capabilities.
  
  The *desired_capabilities* parameter is a reference to a
  `WebDriver::Capabilities` object. Desired means in this context that the
  requested session properties are not mandatory for test execution.

  The *required_capablities* parameter is a reference to a
  `WebDriver::RequiredCapabilities` object. Required means in this context
  that the requested session properties are mandatory for test execution.
  If they cannot be full-filled an exception is thrown.

* `method active_window`:
  Return a reference to the active browser window represented by a
  `WebDriver::Window` object. The window reference is managed by the
  session and must not be deleted.

  Throws a `WebDriver::NoSuchWindowError` error, if the window has been
  closed.

* `method capabilities`:
  Query the actual session capabilities. Returns a reference to a
  `WebDriver::Capabilities` object.

* `method get_log` *type*:
   Retreive log items of the given *type* (see also method `log_types`) from the
   *server*. Returns a list of raw log items.

* `method logging_enabled`:
  Return a boolean value indicating whether logging has been enabled on the
  session.

* `method log_types`:
  Return a list of log types available on the *server*.

* `method set_logging_enabled` *bool*:
  Enable logging on the session object. When this is set to true all actions
  within the session will be logged to stdout.

* `method set_async_script_timeout` *ms*:
  Set the time in milliseconds after which an asynchronously executed script
  is considered as having timed out.

* `method set_implicit_wait_timeout` *ms*:
  Set the time in milliseconds that the driver should wait on elements to appear.
  The default is not to wait at all.

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

  Throws a `WebDriver::NoAlertOpenError` if no alert is being displayed.

* `method active_element`:
  Return a `WebDriver::WebElement` reference to the page element that currently
  has the focus.

* `method alert_send_text` *text*:
  Send *text* as keystrokes to the currently displayed JavaScript dialog.

  Throws a `WebDriver::NoAlertOpenError` if no alert is being displayed.

* `method alert_text`:
  Get the text of the currently displayed JavaScript `alert()`, `confirm()`,
  or `prompt()` dialog.

  Throws a `WebDriver::NoAlertOpenError` if no alert is being displayed.

* `method back`:
  Navigate backwards in the history.

* `method button_down` ?*button*?:
  Press a mouse button, where *button* can be one of *left*, *middle* or
  *right*. If *button* is not specified, the left button will be pressed.
  If you just want to click on an element, retrieve the element first and
  use its `click` method instead.

* `method button_up` ?*button*?:
  Releases a mouse button that was previously pressed. *button* can be one
  of *left*, *middle* or *right*. If `button` is not specified, the left
  button is assumed.

* `method close`:
  Close the window. Note that you are not allowed to close the last remaining
  window in a session. If you try to do so a `WebDriver::CloseSessionWindowError`
  will be thrown.

* `method cookies`:
  Return a list of all cookies for the active domain in form of
  `WebDriver::Cookie` object references. The cookies are a property of the
  `Window` object and must *not* be deleted.

* `method delete_cookie` *name*:
  Delete the cookie with the given *name*.

* `method dismiss_alert`:
  Dismiss the currently displayed alert dialog. For `confirm()` and `prompt()`
  dialogs, this is equivalent to clicking the "Cancel" button. For `alert()`
  dialogs, this is equivalent to clicking the "OK" button.

  Throws a `WebDriver::NoAlertOpenError` if no alert is being displayed.

* `method doubleclick`:
  Send a double click event.

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

  Throws a `WebDriver::NoSuchElementError` if the element cannot be found
  and a `WebDriver::XPathLookupError` if an invalid expression was supplied.

* `method elements` *strategy* *locator*:
  Works exactly as method `element` above but, as the name suggests, will
  return a list of all elements that match the given locator. Element 
  references obtained by this method must be explicitly deleted when not
  used anymore.

  May return an empty list. Throws a `WebDriver::XPathLookupError` if an
  invalid expression was supplied.

* `method execute` *script* ?*arg* *arg* ...?:
  Inject a piece of JavaScript into the page and execute it. Any additional
  arguments passed along will be accessible from an array `arguments` inside
  the script.

  Throws a `WebDriver::StaleElementReferenceError` if one of the script
  arguments is a `WebElement` that is not attached to the page's DOM or a
  `WebDriver::JavaScriptError` if the injected script throws an Error.

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

* `method move_to` *xoffset* *yoffset*:
  Move the mouse *relative to the current cursor position*. To move the mouse
  to a specific element instead, first retrieve the element, then use the
  element's own `move_to` method.

* `method name`:
  Return the name of the window.

* `method orientation`:
  Return the current orientation (must be supported by the driver!) as a string
  (either "landscape" or "portrait"). If you get an exception, your driver
  probably doesn't support handling the screen orientation.

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
  Return a reference to the session that the window is a part of.

* `method set_cookie` ?`-path` *string*? ?`-domain` *string*? ?`-secure`? ?`-http_only`? ?`-expiry` *timestamp*? *name*:
  Set a cookie for the active domain or the domain specified via the `-domain`
  parameter. The `-expiry` of the cookie must be a Unix timestamp indicating the
  time of expiry as seconds since midnight Jan 1, 1970 UTC.

  Throws a `WebDriver::InvalidCookieDomainError` if the cookie domain is not
  visible from the current page or a `WebDriver::UnableToSetCookieError` if
  trying to set a cookie on a page that doesn't support cookies.

* `method set_orientation` *orientation*:
  Set the screen orientation (must be supported by the driver!). *orientation*
  is one of the strings "portrait" or "landscape".

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

  Throws a `WebDriver::NoSuchElementError` if the element cannot be found
  and a `WebDriver::XPathLookupError` if an invalid expression was supplied.

* `method descendants` *strategy* *locator*:
  Works analogously to `Window::elements`, but only searches the
  element tree below the current element.

  May return an empty list. Throws a `WebDriver::XPathLookupError` if an
  invalid expression was supplied.

* `method displayed`:
  Determine if the element is currently displayed.

* `method enabled`:
  Check whether the element is currently enabled.

* `method equals` *other*:
  Check if this `WebElement` references the same page object as *other*.

* `method location`:
  Return the element's location on the page as a Tcl list of format `{x y}`.
  The point `{0 0}` refers to the top left corner of the canvas.

* `method move_to` ?*xoffset*? ?*yoffset*?:
  From the top left corner of the element, move the mouse to the specified
  offset. If no offset is given, the mouse is located at the center of the
  element.

* `method selected`:
  Determine if an `option` element, or an `input` element of type checkbox
  or radiobutton is currently selected.

* `method send_keys` *string*:
  Send the characters in the given *string* as keystrokes to the element.

* `method size`:
  Return the element's size in pixels as a Tcl list of format `{width height}`.

* `method submit`:
  Submit a `form` element. This command may also be applied to any element
  that is a descendant of a `form` element.

* `method tag_name`:
  Returns the HTML tag name of the element.

* `method text`:
  Return the text of the element without any markup. The result of this command
  is a string holding the content of all text nodes that are descendants of the
  element.

### itcl::class WebDriver::Cookie

* `constructor` ?`-domain` *name*? ?`-expiry` *timestamp*? ?`-http_only` *bool*? ?`-path` *name*? ?`-secure` *bool*? *name* *value*:
  Typically, it is not necessary to construct a `Cookie` manually. Most of the
  time, you will just retrieve cookies via a `WebDriver::Window` object, or you
  will set cookies using the `Window` class' `set_cookie` convenience method.

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
  Set whether this cookie is for HTTP only.

* `method set_name` *string*:
  Set the cookie's name.

* `method set_path` *string*:
  Set the path of the cookie.

* `method set_secure` *bool*:
  Set whether this is a secure cookie,

* `method set_value` *string*:
  Set the cookie's value.

### itcl::class WebDriver::Capabilities

* `constructor` ?`-browser_name` *string*? ?`-version` *string*? ?`-platform` *string*? ?`-javascript_enabled` *bool*? ?`-takes_screenshot` *bool*? ?`-handles_alerts` *bool*? ?`-database_enabled` *bool*? ?`-location_context_enabled` *bool*? ?`-application_cache_enabled` *bool*? ?`-browser_connection_enabled` *bool*? ?`-css_selectors_enabled` *bool*? ?`-web_storage_enabled` *bool*? ?`-rotatable` *bool*? ?`-accept_ssl_certs` *bool*? ?`-native_events` *bool*? ?`-proxy` *proxy_obj*?:
  `Capabilities` are used to request session properties during initialization of
  a `WebDriver::Session`.

* `method accept_ssl_certs`:
  Query whether the session accepts all SSL certs by default.

* `method application_cache_enabled`:
  Query whether the session can interact with the application cache.

* `method browser_connection_enabled`:
  Determine whether the session can query the browser's connectivity and
  disable it if desired.

* `method browser_name`:
  Return the name of the browser being used.

* `method css_selectors_enabled`:
  Query whether the session supports CSS selectors when searching for elements.

* `method database_enabled`:
  Query whether the session can interact with database storage.

* `method handles_alerts`:
  Query whether the session can interact with modal popups, such as
  `window.alert` and `window.confirm`.

* `method javascript_enabled`:
  Query whether the session supports executing user supplied JavaScript in the
  context of the current page.

* `method location_context_enabled`:
  Query whether the session can set and query the browser's location context.

* `method native_events`:
  Query whether the session is capable of generating native events when
  simulating user input.

* `method platform`:
  Return a key specifying which platform the browser is running on.

* `method proxy`:
  Returns a `WebDriver::Proxy` object that indicates the connection type.

* `method rotatable`:
  Query whether the session can rotate the current page's layout between
  portrait and landscape orientations (only applies to mobile platforms).

* `method takes_screenshot`:
  Query whether the session supports taking screenshots of the current page.

* `method version`:
  The browser version, or the empty string if unknown.

* `method web_storage_enabled`:
  Query whether the session supports interactions with storage objects.

* `method set_accept_ssl_certs` *bool*:
  Set whether the session should accept all SSL certs by default.

* `method set_application_cache_enabled` *bool*:
  Set whether the session should be able to interact with the application
  cache.

* `method set_browser_connection_enabled` *bool*:
  Set whether the session should be allowed to query for the browser's
  connectivity and disable it if desired.

* `method set_browser_name` *string*:
  Set the name of the browser to be used; should be one of
  `{chrome|firefox|htmlunit|internet explorer|iphone}`.

* `method set_css_selectors_enabled` *bool*:
  Specify whether the session should support CSS selectors when searching for
  elements.

* `method set_database_enabled` *bool*:
  Set whether the session should be able to interact with database storage.

* `method set_handles_alerts` *bool*:
  Set whether the session should be able to interact with modal popups, such as
  `window.alert` and `window.confirm`.

* `method set_javascript_enabled` *bool*:
  Set whether the session needs to support executing user supplied JavaScript
  in the context of a page.

* `method set_location_context_enabled` *bool*:
  Set whether the session should be able to set and query the browser's
  location context.

* `method set_native_events` *bool*:
  Set whether the session should generate native events when simulating user
  input.

* `method set_platform` *string*:
  Specify which platform the tests should run on. This value should be one of
  `{WINDOWS|XP|VISTA|MAC|LINUX|UNIX}`. When requesting a new session, the
  client may specify `ANY` to indicate any available platform may be used.

* `method set_proxy` *proxy_object*:
  Specify the connection type (only necessary, if not direct) via a
  `WebDriver::Proxy` object.

* `method set_rotatable` *bool*:
  Set whether the session should be able to rotate the current page's layout
  between portrait and landscape orientations (only applies to some mobile
  platforms).

* `method set_takes_screenshot` *bool*:
  Set whether the session should be able to take screenshots of the loaded
  pages.

* `method set_version` *string*:
  Set the version string of the browser to use.

* `method set_web_storage_enabled` *bool*:
  Specify whether the session should support interation with storage objects.

### itcl::class WebDriver::RequiredCapabilities

The `RequiredCapabilities` class is identical to the `Capabilities` class with
the sole difference being that `RequiredCapabilities` objects don't carry any
default values.

### itcl::class WebDriver::Proxy

* `constructor` ?`-ftp_proxy` *url*? ?`-http_proxy` *url*? ?`-proxy_type` *type*? ?`-proxy_autoconfig_url` *url*? ?`-ssl_proxy` *url*?:
  The `Proxy` object is passed to the session constructor as part of the desired
  or required capabilities.

* `method ftp_proxy`:
  Return the configured FTP proxy URL.

* `method http_proxy`:
  Return the configured HTTP proxy URL.

* `method proxy_type`:
  Return the proxy type, which is one of *direct*, *manual*, *pac*, *autodetect*
  or *system*.

* `method proxy_autoconfig_url`:
  If proxy method is set to *pac*, this should return the autoconfiguration URL.

* `method ssl_proxy`:
  Return the configured SSL proxy URL.

* `method set_ftp_proxy` *url*:
  Set the FTP proxy URL.

* `method set_http_proxy` *url*:
  Set the HTTP proxy URL.

* `method set_proxy_type type`:
  Set the proxy type being used. Possible values are: a) *direct* - a direct connection -
  no proxy in use, b) *manual* - manual proxy settings configured, c) *pac* - proxy
  autoconfiguration from a URL, d) *autodetect* - proxy autodetection, probably with WPAD,
  e) *system* - Use system settings.

* `method set_proxy_autoconfig_url` *url*:
  Set the proxy autoconfiguration URL in case proxy type is set to *pac*.

* `method set_ssl_proxy` *url*:
  Set the SSL proxy URL.

## ADDITIONAL HINTS

While the `Session` methods `logging_enabled` and `set_logging_enabled` deal
with local logging functionality of the `WebDriver` package itself, the methods
`log_types` and `get_log` are for retrieving logs from the *server* instead.

## SEE ALSO

`itcl`(3), `error`(3caius)

