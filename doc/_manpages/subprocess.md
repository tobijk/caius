Subprocess(3caius) -- launch and manage subprocesses
==============================================================================

## EXAMPLE

    package require Subprocess

    set p [Subprocess #auto cmd]

    set rval [$p wait]

## DESCRIPTION

The `Subprocess` class takes the pain out of executing subprocesses with Tcl's
`open` command. You can launch a process, monitor its status and redirect its
standard input and output streams to alternative Tcl channels. With the use of
pipes, you may even communicate with the process directly, even though you might
prefer to use the `CliDriver`(3caius) module in that case. 

## API

### ictl::class Subprocess

* `constructor` ?`-stdout` *chan*? ?`-stderr` *chan*? ?`-stdin` *chan*? ?`-timeout` *ms*?:
  Launch a subprocess and optionally redirect its standard input and output
  streams to alternative Tcl channels. If a timeout is specified, the process will
  be forcefully terminated when it exceeds the timeout.

* `method kill`:
  Kill the subprocess. On Unix this is equivalent to sending a SIGKILL.

* `method pid`:
  Return the process ID of the subprocess.

* `method process_exists`:
  Check if the process is still alive.

* `method timeout_occurred`:
  Check if a timeout occurred.

* `method terminate`:
  Terminate the subprocess. On Unix this is equivalent to sending a SIGTERM.

* `method wait`:
  Wait on the subprocess to end and return its exit code.

## ADDITIONAL HINTS

If an error occurred on invocation, `wait` will return -1.

## SEE ALSO

`signal`(7)

