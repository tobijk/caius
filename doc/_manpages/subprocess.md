Subprocess(3caius) -- launch and manage subprocesses
==============================================================================

## EXAMPLE

    package require Subprocess

    set p [Subprocess::Popen #auto cmd]
    set rval [$p wait]

    ::itcl::delete object $p

## DESCRIPTION

The `Popen` class takes the pain out of executing subprocesses with Tcl's
`open` command. You can launch a process, monitor its status and redirect its
standard input and output streams to alternative Tcl channels. With the use of
pipes, you may even communicate with the process directly, even though you might
prefer to use the `CliDriver`(3caius) module in that case. 

## API

### ictl::class Subprocess::Popen

* `constructor` ?`-stdout` *chan*? ?`-stderr` *chan*? ?`-stdin` *chan*? ?`-timeout` *ms*?:
  Launch a subprocess and optionally redirect its standard input and output
  streams to alternative Tcl channels. If a timeout is specified, the process will
  be forcefully terminated when it exceeds the timeout.

  Raises a `Subprocess::Error` if invocation fails for some reason.

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

Deleting a `Popen` object that is associated with an active process, using
`itcl::delete object`, will implicitely terminate the process. If the process
was terminated pre-maturely, wait will return -1.

## SEE ALSO

`signal`(7)

