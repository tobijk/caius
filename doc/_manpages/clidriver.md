CliDriver(3caius) -- execute and control subprocesses with Expect
==============================================================================

## EXAMPLE

    package require CliDriver

    set p [CliDriver::Spawn #auto telnet localhost]

    set count 0
    set timeout 5

    $p expect {
        "*assword*:*" {
            $p send "password\n"
            exp_continue
        }
        "*ogin*:*" {
            $p send "user\n"
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

## DESCRIPTION

The `CliDriver` API is an object-oriented wrapper around `expect`(1). It allows
you to automate shell sessions by launching and controlling interactive command
line applications from a Tcl script.

The main goal of the module is to alleviate the need for juggling with spawn
ids and to encapsulate and simplify initialization sequences and subprocess
management.

## API
<p></p>

### itcl::class CliDriver::Core

* `method expect` ??*-opts*? *pat1* *body1*? ... ?*-opts*? *patn* *bodyn*:
  <p>
  Works exactly like the traditional `expect` call described in `expect`(1) but
  is always bound to the subprocess associated with this object.
  </p>

* `method send` ?*-flags*? *string*:
  <p>
  Works exactly like the traditional `send` call described in `expect`(1) but
  is always bound to the subprocess associated with this object.
  </p>

* `method close`:
  <p>
  Closes the connection to and terminates the subprocess associated with this
  object.
  </p>

* `method kill`:
  <p>
  Kills the subprocess. On Unix this is equivalent to sending a SIGKILL.
  </p>

* `method match_max` ?*size*?:
  <p>
  Sets or gets the maximum match buffer size for the `spawn_id` associated with
  this object.
  </p>

* `method pid`:
  <p>
  Returns the process ID of the subprocess.
  </p>

* `method process_exists`:
  <p>
  Returns true while the subprocess has not exited.
  </p>

* `method terminate`:
  <p>
  Terminates the subprocess. On Unix this is equivalent to sending a SIGTERM.
  </p>

### itcl::class CliDriver::Spawn

Inherits all methods from `CliDriver::Core`.

* `constructor` *cmd* ?*arg* *arg* ...?:
  <p>
  Launch *cmd* and pass on any additional arguments unmodified.
  </p>

### itcl::class CliDriver::Telnet

Inherits all methods from `CliDriver::Core`.

* `constructor` ?*arg* *arg* ...? *host*:
  <p>
  Launch the `telnet` command installed on the system and pass on any additional
  arguments unmodified.
  </p>

### itcl::class CliDriver::Ssh

Inherits all methods from `CliDriver::Core`.

* `constructor` ?*arg* *arg* ...? *user*@*host*:
  <p>
  Launch the `ssh` command installed on the system and pass on any additional
  arguments unmodified.
  </p>

### itcl::class CliDriver::Stty

Inherits all methods from `CliDriver::Core`.

* `constructor` ?`-baud` *int*? ?`-parity` *bool*? ?`-data_bits` *int*? ?`-stop_bits` *int*? *port*:
  <p>
  Create an expect session on the given serial *port* to talk to a program at the other
  end of a serial line, where *port* denotes a serial device node, such as `/dev/ttyS0`.
  </p>
  
## ADDITIONAL HINTS

Deleting a driver object that is associated with an active process, using
`itcl::delete object`, will implicitely terminate the process.

## SEE ALSO

`expect`(1), `itcl`(3)
