#!/usr/bin/env tclsh

#
# Run command inside tcl_shell and return subprocess' stdout.
#
proc tcl_shell_eval {tcl_shell command} {
    return [exec echo $command | $tcl_shell]
}

#
# Check if tcl_shell has the required version and necessary extensions.
#
proc test_tcl_shell {tcl_shell} {
    set result [tcl_shell_eval $tcl_shell {puts $::tcl_version}]

    if {$result ne "8.6"} {
        return 0
    }
    puts [format "* %-50s" "Checking Tcl shell $tcl_shell..."]

    puts -nonewline [format "  - %-50s " "Check for thread support:"]
    set result [tcl_shell_eval $tcl_shell \
        {puts [info exists ::tcl_platform(threaded)]}]

    if {$result ne "1"} {
        puts "fail"
        return 0
    }
    puts "ok"

    puts -nonewline [format "  - %-50s " "Check for \[incr Tcl] extension:"]
    set result [tcl_shell_eval $tcl_shell \
        {puts [catch {package require Itcl}]}]

    if {$result ne "0"} {
        puts "fail"
        return 0
    }
    puts "ok"

    puts -nonewline [format "  - %-50s " "Check for tdom extension:"]
    set result [tcl_shell_eval $tcl_shell \
        {puts [catch {package require tdom}]}]

    if {$result ne "0"} {
        puts "fail"
        return 0
    }
    puts "ok"

    return 1
}

#
# Search system path for a compatible Tcl shell.
#
proc find_compatible_tclsh {} {
    set tcl_shell_names {tclsh tclsh8.6}

    if {$::tcl_platform(platform) eq "unix"} {
        set os_path_sep ':'
    } else {
        set os_path_sep ';'
    }

    foreach {shell_name} $tcl_shell_names {
        foreach {dir_name} [split $::env(PATH) $os_path_sep] {
            set tcl_shell "$dir_name[file separator]$shell_name"

            if {[file executable $tcl_shell]} {
                if {[test_tcl_shell $tcl_shell]} {
                    return $tcl_shell
                }
            }
        }
    }

    return {}
}

#
# Install caius into the package path of a compatible Tcl shell.
#
proc install_caius {} {

    if {[set tcl_shell [find_compatible_tclsh]] eq ""} {
        exit 1
    }

    set pkg_path [regexp -inline -all -- {\S+} \
        [tcl_shell_eval $tcl_shell {puts $::auto_path}]]

    set install_dir [lindex $pkg_path 0]

    foreach {dir} $pkg_path {
        if {[regexp {^/usr/local} $dir]} {
            set install_dir $dir
            break
        }
    }

    append install_dir /caius

    puts [format "* %-50s" "Installing to $install_dir..."]

    if {[file exists $install_dir]} {
        while {1} {
            puts -nonewline [format "  + %-50s " \
                "Found a previous installation, replace it? \[y/N] "]
            flush stdout
            gets stdin user_input

            switch [string trim $user_input] {
                y -
                Y {
                    file delete -force $install_dir
                    break
                }
                {} -
                n -
                N {
                    exit 0
                }
            }
        }
    }

    puts -nonewline [format "  - %-50s " "Copying files:"]
    if {[catch {
        file mkdir $install_dir

        foreach {name} [glob lib/* xsl bin] {
            file copy $name $install_dir
        }

        set caius_symlink /usr/local/bin/caius

        if {[file exists $caius_symlink]} {
            file delete $caius_symlink
        }

        file link -symbolic $caius_symlink $install_dir/bin/caius
    } err ] != 0} {
        puts "fail"
        puts [format "  - %-50s " "Error: $err"]
        exit 1
    }
    puts "done"
}

### MAIN ###

install_caius

