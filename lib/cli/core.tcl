#
#   Caius Functional Testing Framework
#
#   Copyright 2013 Tobias Koch <tobias.koch@gmail.com>
#
#   This program is free software; you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation; either version 2 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#
#   See the LICENSE file in the source distribution for more information.
#

package require Itcl
package require OS
package require Error
package require Expect

# hack to make Expect use stdout as a channel
catch {
    log_user 0
    log_file -a -leaveopen stdout
}

namespace eval Cli {

    ::itcl::class Core {

        protected variable _spawn_id ""

        constructor {} {}

        destructor {
            $this close
        }

        method close {} {
            set exit_code ""

            if {$_spawn_id ne ""} {
                except {
                    set pid [exp_pid -i $_spawn_id]
                    ::close -i $_spawn_id

                    # if spawn_id was pointing to a process
                    if {$pid} {

                        if {[OS process_exists $pid]} {
                            OS terminate $pid
                            after 500

                            if {[OS process_exists $pid]} {
                                OS kill $pid
                            }
                        }

                        set exit_code [lindex [::wait -i $_spawn_id] 3]
                    }
                } e {} final {
                    set _spawn_id ""
                }
            }

            return $exit_code
        }

        method send {args} {
            uplevel [list exp_send -i $_spawn_id {*}$args]
        }

        method expect {args} {
            uplevel [list expect -i $_spawn_id {*}$args]
        }

        method match_max {{size ""}} {
            return [match_max -i $_spawn_id $size]
        }
    }
}

