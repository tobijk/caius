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
standard input and output streams to alternative Tcl channels. By using pipes,
you may even communicate with the process directly, even though you might
prefer to use the `CliDriver`(3caius) module in that case. 

## API
<p></p>

### itcl::class Subprocess::Popen

* `constructor` ?`-stdout` *chan*? ?`-stderr` *chan*? ?`-stdin` *chan*? ?`-timeout` *ms*?:
  <p>
  Launch a subprocess and optionally redirect its standard input and output
  streams to alternative Tcl channels. If a timeout is specified, the process will
  be forcefully terminated when it exceeds the timeout.
  Raises a `Subprocess::Error` if invocation fails for some reason.
  </p>

* `method kill`:
  <p>
  Kill the subprocess. On Unix this is equivalent to sending a SIGKILL.
  </p>

* `method pid`:
  <p>
  Return the process ID of the subprocess.
  </p>

* `method process_exists`:
  <p>
  Check if the process is still alive.
  </p>

* `method timeout_occurred`:
  <p>
  Check if a timeout occurred.
  </p>

* `method terminate`:
  <p>
  Terminate the subprocess. On Unix this is equivalent to sending a SIGTERM.
  </p>

* `method wait`:
  <p>
  Wait on the subprocess to end and return its exit code.
  </p>

## ADDITIONAL HINTS

Deleting a `Popen` object that is associated with an active process, using
`itcl::delete object`, will implicitely terminate the process. If the process
was terminated pre-maturely, wait will return -1.

Channel descriptors passed as parameters to the `Popen` command are
effectively moved to another thread and are hence-forth not accessible anymore
in the calling thread. This does not apply to the standard channels *stdout*,
*stderr* and *stdin*. They keep functioning as expected.

## SEE ALSO

`error`(3caius), `signal`(7)

