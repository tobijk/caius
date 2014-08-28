Subprocess(3caius) -- launch and manage subprocesses
==============================================================================

## EXAMPLE

    package require Subprocess

    set p [Subprocess #auto cmd]

    set rval [$p wait]

## DESCRIPTION

## API

### ictl::class Subprocess

* `constructor` ?`-stdout` *chan*? ?`-stderr` *chan*? ?`-stdin` *chan*? ?`-timeout` *ms*?:
  Launch a subprocess and optionally redirect its standard input and output
  streams to alternative Tcl channels. If a timeout is specified, the process will
  be forcefully terminated when it exceeds the timeout.

* `kill`:
  Kill the subprocess. On Unix this is equivalent to sending a SIGKILL.

* `process_exists`:
  Check if the process is still alive.

* `timeout_occurred`:
  Check if a timeout occurred.

* `terminate`:
  Terminate the subprocess. On Unix this is equivalent to sending a SIGTERM.

* `wait`:
  Wait on the subprocess to end and return its exit code.

## SEE ALSO

`signal`(7)

