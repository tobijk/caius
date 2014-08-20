CliDriver(3caius) -- execute and control subprocesses with Expect
==============================================================================

## SYNOPSIS

    package require CliDriver

    set app [CliDriver::Spawn #auto cmd ?arg arg ...?]

    set ssh [CliDriver::Ssh #auto ?arg arg ...? user@host]

    set telnet [CliDriver::Telnet #auto ?arg arg ...? host]

    set serial [CliDriver::Stty #auto stty ?-baud int? ?-parity [y/n]? ?-data_bits int? ?stop_bits int?]

    $telnet expect "User*:"
    $telnet send   "jonathan\n"
    $telnet expect "Password:*"
    $telnet send   "secret\n"

## DESCRIPTION

The CliDriver API is an object-oriented wrapper around Expect. It allows you
to automate complete shell sessions by launching and controlling interactive
command line applications from a Tcl script.

## API

### itcl::class CliDriver::Core

* `method expect [[-opts] pat1 body1] ... [-opts] patn [bodyn]`:
  Works exactly like the traditional `expect` call described in `expect`(1) but
  is bound to the subprocess associated with this object.

* `method send [-flags] string`:
  Works exactly like the traditional `send` call described in `expect`(1) but
  is bound to the subprocess associated with this object.

* `method close`:
  Closes the connection to and terminates the subprocess associated with this
  spawn object.

* `method match_max ?size?`:
  Sets or gets the maximum match buffer size for the `spawn_id` associated with
  this object.

### itcl::class CliDriver::Spawn

Inherits all methods from `CliDriver::Core`.

* `constructor cmd ?arg arg ...?`:
  Launch cmd and pass on any additional parameters as arguments to the
  executable.

### itcl::class CliDriver::Telnet

Inherits all methods from `CliDriver::Core`.

* `constructor ?arg arg ...? host`:
  Launch the `telnet` command installed on the system and pass on any supplied
  parameters.

### itcl::class CliDriver::Ssh

Inherits all methods from `CliDriver::Core`.

* `constructor ?arg arg ...? user@host`:
  Launch the `ssh` command installed on the system and pass on any supplied
  parameters.

### itcl::class CliDriver::Serial

Inherits all methods from `CliDriver::Core`.

* `constructor stty ?-baud int? ?-parity [y/n]? ?-data_bits int? ?stop_bits int?`:
  Create an expect session on the given stty to talk to a program at the other
  end of a serial line.

## ADDITIONAL HINTS

Deleting a driver object that is associated with an active process, using
`itcl::delete object`, will implicitely terminate the process.

## SEE ALSO

`expect`(1), `itcl`(3)
