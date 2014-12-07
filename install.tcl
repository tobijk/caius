#!/usr/bin/env tclsh

#
# Test if we are on the Windows platform.
#
proc windows {} {
    return [expr {$::tcl_platform(platform) eq "windows"}]
}

#
# Run command inside tcl_shell and return subprocess' stdout.
#
proc tcl_shell_eval {tcl_shell command} {
    # file join converts \ to / for the open pipe on Windows.
    set fd [open "|[file join $tcl_shell]" r+]
    fconfigure $fd -buffering line

    # send command (make sure this is one line) and harvest result
    puts $fd $command
    set rval [gets $fd]

    # for some reason this blows up on Debian/Ubuntu currently
    catch {[close $fd]}
    return $rval
}

#
# Check if tcl_shell has the required version and necessary extensions.
#
proc test_tcl_shell {tcl_shell} {
    puts [format "* %-50s" "Checking Tcl shell $tcl_shell..."]

    puts -nonewline [format "  - %-50s " "Check Tcl version >= 8.6:"]
    set result [tcl_shell_eval $tcl_shell {puts $::tcl_version}]

    lassign [split $result .] major minor
    if {$major < 8 || ($major == 8 && $minor < 6)} {
        puts "fail"
        return 0
    }
    puts "ok"

    puts -nonewline [format "  - %-50s " "Check if interpreter is thread-enabled:"]
    set result [tcl_shell_eval $tcl_shell \
        {puts [info exists ::tcl_platform(threaded)]}]

    if {$result ne "1"} {
        puts "fail"
        return 0
    }
    puts "ok"

    puts -nonewline [format "  - %-50s " "Check for the Thread package:"]
    set result [tcl_shell_eval $tcl_shell \
        {puts [catch {package require Thread}]}]

    if {$result ne "0"} {
        puts "fail"
        return 0
    }
    puts "ok"

    puts -nonewline [format "  - %-50s " "Check for tcllib (require json):"]
    set result [tcl_shell_eval $tcl_shell \
        {puts [catch {package require json}]}]

    if {$result ne "0"} {
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

    # Is Expect available for 32 bit Tcl?
    if {![windows]} {
        puts -nonewline [format "  - %-50s " "Check for Expect:"]
        set result [tcl_shell_eval $tcl_shell \
                        {puts [catch {package require Expect}]}]
        if {$result ne "0"} {
            puts "fail"
            return 0
        }
        puts "ok"
    }

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
    if {[windows]} {
        set tcl_shell_names {tclsh.exe tclsh86t.exe}
    } else {
        set tcl_shell_names {tclsh tclsh8.6}
    }

    if {$::tcl_platform(platform) eq "unix"} {
        set os_path_sep ":"
    } else {
        set os_path_sep ";"
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
        puts "Could not find a suitable Tcl shell"
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
        file mkdir $install_dir/bin

        foreach {name} [glob lib/* xsl] {
            file copy $name $install_dir
        }

        set src_fp [open bin/caius r]
        set caius_script [read $src_fp]
        close $src_fp

        # set the right interpreter
        set caius_script [regsub -line {^#!.*$} $caius_script "#!$tcl_shell"]

        set dst_fp [open $install_dir/bin/caius w+]
        puts -nonewline $dst_fp $caius_script
        close $dst_fp

        if {![windows]} {
            # make caius executable
            file attributes $install_dir/bin/caius -permissions 0755
            set caius_symlink /usr/local/bin/caius

            if {[file exists $caius_symlink]} {
                file delete $caius_symlink
            }

            file link -symbolic $caius_symlink $install_dir/bin/caius
        }

    } err ] != 0} {
        puts "fail"
        puts [format "  - %-50s " "Error: $err"]
        exit 1
    }
    puts "done"
}

### MAIN ###

install_caius

