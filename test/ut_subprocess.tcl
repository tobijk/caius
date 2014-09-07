#!/usr/bin/tclsh8.6

package require Subprocess
package require Testing
package require OutputStream
package require Error

set SCRIPT_DIR "[file dirname [file normalize $::argv0]]/data/scripts"
set ERR17      "$SCRIPT_DIR/err.sh"
set NOSTDOUT   "$SCRIPT_DIR/no-stdout.sh"

itcl::class TestSubprocess {
    inherit Testing::TestObject

    method test_run_command_check_exit_code {} {
        docstr "Run a subprocess and harvest the exit code."

        set ps [Subprocess #auto $::ERR17]

        if {[$ps wait] != 17} {
            error "expected script to return with code 17"
        }

        ::itcl::delete object $ps
    }

    method test_run_command_timout {} {
        docstr "Run a subprocess and let it timeout."

        set ps [Subprocess #auto -timeout 1500 $::ERR17]
        $ps wait

        if {![$ps timeout_occurred]} {
            error "a timeout error should have occurred."
        }
    }

    method test_run_command_nostdout_timeout {} {
        docstr "Run a subprocess which closes its stdout and let it timeout."

        set ps [Subprocess #auto -timeout 1500 $::NOSTDOUT]
        $ps wait

        if {![$ps timeout_occurred]} {
            error "a timeout error should have occurred."
        }
    }

    method test_variables_and_quotation_marks {} {
        docstr "Run a complicated command with pipes, variables, quotes..."

        set command [list bash -c {for i in `seq 1 3`; do echo "$i"; done | cat}]

        set ps [Subprocess #auto {*}$command]
        $ps wait
    }

    method test_process_exists_and_pid_of {} {
        docstr "Test that subprocess existence is determined correctly."

        set command [list bash -c {echo "start"; sleep 2; echo "stop"}]
        set ps [Subprocess #auto {*}$command]

        if {![$ps process_exists]} {
            error "Process must exist."
        }
        $ps wait

        if {[$ps process_exists]} {
            error "Process must not exist."
        }
    }
}

exit [[TestSubprocess #auto] run $::argv]

