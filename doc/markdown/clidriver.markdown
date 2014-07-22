# Driving the Command Line with Expect

Expect has been copied many times, and bindings to libexpect exist for many
other programming language. But none of them achieves the same deep integration
with the language, the ease of use and the versatility of Expect for Tcl.

Caius simplifies working with Expect by wrapping the most commonly used
functionality in an object-oriented programming interface.

## Spawning a Process

In order to spawn a process and interact with it through the standard channels,
create a `CliDriver::Spawn` instance like this:

~~~~{.tcl}
package require CliDriver

set p [CliDriver::Spawn #auto telnet localhost]
~~~~

You can then invoke `send` and `expect` on the object `p` as you would with
classic expect:

~~~~{.tcl}

set count 0
set timeout 5

$p expect {
    "*assword*:*" {
        $p send "password\n"
        exp_continue
    }
    "*ogin*:*" {
        $p send "username\n"
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

itcl::delete object $p
~~~~

The advantages of working with objects become more apparent when you start
spawning multiple processes. With classic expect you need to keep track of the
spawn ids and set the global `spawn_id` variable each time you switch to another
process. Caius does this for you implicitly.

If you need to, you can still access the spawn id like this

~~~~{.tcl}
set spawn_id [$p spawn_id]
~~~~

and use classic expect calls, for example to wait on multiple channels at the
same time. Note also how we used `timeout` and `exp_continue` just as if we
were working with Expect directly.

When you delete a `Spawn` object while the process it represents is still
active, then the process will be terminated. If the process has ended, it will
be waited on.

## Connecting via SSH and Telnet

Since Expect is often used to log into remote machines using SSH or Telnet,
the convenience classes `CliDriver::Telnet` and `CliDriver:Ssh` are available.
They are used in the same way as `Spawn` but implicitely invoke the `telnet`
or `ssh` command installed in the system.

~~~~{.tcl}
package require CliDriver

set ssh [CliDriver::Ssh #auto user@host]

$ssh expect "*Password:*"
...
~~~~

## Using a Serial Line

Last but not least, there is the `CliDriver::Stty` class. As the name implies, this
one is for running Expect on a serial connection. The constructor takes various
optional parameters, such as the baud rate, that are used to configure the
terminal device, as shown in the following example:

~~~~{.tcl}
package require CliDriver

set serial [CliDriver::Stty #auto /dev/ttyS0 \
    -baud 56000 -parity n -data_bits 8 -stop_bits 1]
~~~~

The settings in the example above are actually the default settings. So in case
they match your requirements, it is sufficient to specify the port.

## Expecting from Multiple Sources

If you need to expect from multiple processes simultaneously, you currently
have to harvest the spawn ids from your CliDriver objects and use a traditional
expect call. A more user-friendly way of doing this may be implemented in future
versions of Caius.

## Important Notes

Caius calls `log_user` and `log_file` to ensure that Expect logs all output
through a Tcl channel. Be aware that modifying either of those settings may
break logging in your test scripts in unexpected ways.

