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

package require json

namespace eval OOSupport {

    namespace export \
        attr_reader \
        attr_writer \
        attr_accessor \
        json_support \
        json_escape_chars \
        bless_attributes \
        init_attributes

    proc attr_reader {args} {
         foreach property $args {
            uplevel "method ${property} {} {
                return \$_$property
            }"
        }
    }

    proc attr_writer {args} {
         foreach property $args {
            uplevel "method set_${property} {val} {
                set _$property \$val
                return \$this 
            }"
        }
    }

    proc attr_accessor {args} {
         foreach property $args {
            uplevel "method ${property} {} {
                return \$_$property
            }"
            uplevel "method set_${property} {val} {
                set _$property \$val
                return \$this
            }"
        }
    }

    proc __collapse_underscores {text} {
        set parts  [split $text "_"]
        set result [lindex $parts 0]

        foreach p [lrange $parts 1 end] {
            append result [string totitle $p]
        }
        return $result
    }

    proc __stub__json_load {json} {
        $this from_tcl [::json::json2dict $json]
        return $this
    }

    proc __stub__tcl_load {__data_dict} {
        foreach {__attr} $attributes {
            set __attr_type [lindex $__attr 0]
            set __attr_name [lindex $__attr 1]
            set __attr_is_array 0

            if {[string index $__attr_type 0] == "\["} {
                set __attr_type [string trim $__attr_type "\[\]"]
                set __attr_is_array 1
            }

            set __attr_is_object [::itcl::is class $__attr_type]

            if {$__collapse_underscore} {
                set __lookup_name [::OOSupport::__collapse_underscores $__attr_name]
            } else {
                set __lookup_name $__attr_name
            }

            if {[dict exists $__data_dict $__lookup_name]} {
                set __value [dict get $__data_dict $__lookup_name]
                set __result ""

                if {$__attr_is_array} {
                    foreach {__item} $__value {
                        if {$__attr_is_object} {
                            set __obj [::itcl::code [$__attr_type #auto]]
                            $__obj from_tcl $__item
                            lappend __result $__obj
                        } else {
                            lappend __result $__item
                        }
                    }
                } elseif {$__attr_is_object} {
                    set __result [::itcl::code [$__attr_type #auto]]
                    $__result from_tcl $__value
                } else {
                    set __result $__value
                }

                set _$__attr_name $__result
            }
        }

        return $this
    }

    proc __stub__json_dump {args} {
        set __result {}

        while {[string index [lindex $args 0] 0] == "-"} {
            switch [lindex $args 0] {
                "-skip_undefined" {
                    set __skip_undefined 1
                    set args [lreplace $args 0 0]
                }
                "-collapse_underscore" {
                    set __collapse_underscore 1
                    set args [lreplace $args 0 0]
                }
                "-indent" {
                    set __indent [lindex $args 1]
                    set args [lreplace $args 0 1]
                }
                default {
                    error "unknown option '$tmp_arg'"
                }
            }
        }

        proc __print_array {__array_type __array_content {__indent 0}} {
            set __result {}
            set __array_of_objects [::itcl::is class $__array_type]

            foreach {__val} $__array_content {
                if {$__array_of_objects} {
                    if {$__val != "null"} {
                        lappend __result [$__val to_json -indent [expr $__indent + 1]]
                    } else {
                        lappend __result null
                    }
                } elseif {$__array_type == "string"} {
                    lappend __result "\"[::OOSupport::json_escape_chars $__val]\""
                } else {
                    lappend __result "$__val"
                }
            }

            if {$__array_of_objects} {
                set __result "\[\n[join $__result ",\n"]\n]"
            } else {
                set __result "\[\n\t[join $__result ", "]\n]"
            }
            regsub -all -lineanchor {^} $__result \
                [string repeat "\t" $__indent] __result
            return $__result
        }

        foreach {__attr} $attributes {
            set __attr_type [lindex $__attr 0]
            set __attr_name [lindex $__attr 1]
            set __attr_is_array false

            if {[string index $__attr_type 0] == "\["} {
                set __attr_type [string trim $__attr_type "\[\]"]
                set __attr_is_array true
            }

            set __attr_is_object [::itcl::is class $__attr_type]

            if {![info exists _$__attr_name]} {
                continue
            }

            if 1 "set __attr_val \$_$__attr_name"

            if {$__skip_undefined} {
                if {($__attr_val == "null" && $__attr_type != "string") ||
                    ($__attr_val == "")} \
                {
                    continue
                }
            }

            if {$__collapse_underscore} {
                set __attr_name \
                    [::OOSupport::__collapse_underscores $__attr_name]
            }

            if {$__attr_is_array} {
                lappend __result "\t\"$__attr_name\":\n[
                    __print_array $__attr_type $__attr_val [expr $__indent + 1]]"
            } else {
                if {$__attr_type == "string"} {
                    lappend __result "\t\"$__attr_name\": \"[\
                        ::OOSupport::json_escape_chars $__attr_val]\""
                } elseif {$__attr_is_object} {
                    lappend __result "\t\"$__attr_name\":\n[\
                        $__attr_val to_json -indent [expr $__indent + 1]]"
                } else {
                    lappend __result "\t\"$__attr_name\": $__attr_val"
                }
            }
        }

        set __result "{\n[join $__result ",\n"]\n}"
        regsub -all -lineanchor {^} $__result [string repeat "\t" $__indent] __result
        return $__result
    }

    proc json_support {{skip_undefined 0} {collapse_underscore 0}} {

        uplevel "method to_json {args} {
            set __skip_undefined $skip_undefined
            set __collapse_underscore $collapse_underscore
            set __indent 0

            [info body ::OOSupport::__stub__json_dump]
        }"

        uplevel "method from_json {json} {
            set __skip_undefined $skip_undefined
            set __collapse_underscore $collapse_underscore

            [info body ::OOSupport::__stub__json_load]
        }"

        uplevel "method from_tcl {__data_dict} {
            set __skip_undefined $skip_undefined
            set __collapse_underscore $collapse_underscore

            [info body ::OOSupport::__stub__tcl_load]
        }"
    }

    proc json_escape_chars {str} {
        return [string map {"\\" "\\\\" "\n" "\\n" "\"" "\\\""} $str]
    }

    proc init_attributes {} {
        upvar attributes attributes

        foreach {attr} $attributes {
            set attr_type      [lindex $attr 0]
            set attr_name      [lindex $attr 1]
            set attr_default   [lindex $attr 2]
            set attr_is_object [::itcl::is class $attr_type]

            if {$attr_is_object &&
                $attr_default != "null" &&
                $attr_default != ""} \
            {
                uplevel "set _$attr_name \"[::itcl::code [$attr_type #auto]]\""
            } else {
                uplevel "set _$attr_name \"$attr_default\""
            }
        }
    }

    proc bless_attributes {args} {
        upvar attributes attributes

        set json_support 0
        set skip_undefined 0
        set collapse_underscore 0

        while {[string index [lindex $args 0] 0] == "-"} {
            switch [lindex $args 0] {
                "-skip_undefined" {
                    set skip_undefined 1
                    set args [lreplace $args 0 0]
                }
                "-collapse_underscore" {
                    set collapse_underscore 1
                    set args [lreplace $args 0 0]
                }
                "-json_support" {
                    set json_support true
                    set args [lreplace $args 0 0]
                }
                default {
                    error "unknown option '$tmp_arg'"
                }
            }
        }

        foreach {attr} $attributes {
            set attr_name   [lindex $attr 1]
            set attr_access [lindex $attr 3]

            uplevel "private variable _$attr_name"

            if {[string trim $attr_access ro-] == "w"} {
                uplevel "OOSupport::attr_writer $attr_name"
            }
            if {[string trim $attr_access wo-] == "r"} {
                uplevel "OOSupport::attr_reader $attr_name"
            }
        }

        if {$json_support} {
            uplevel "OOSupport::json_support \
                $skip_undefined $collapse_underscore"
        }
    }
}

