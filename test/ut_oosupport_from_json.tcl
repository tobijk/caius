#!/usr/bin/tclsh

package require Itcl
package require OOSupport
package require Testing

#
# PREAMBLE
#

::itcl::class ObjectA {
    common attributes {
        {number    number_attr 1              rw}
        {[string]  strings     {abc abb ab a} rw}
    }

    method constructor {} {
        OOSupport::init_attributes
    }

    OOSupport::bless_attributes -json_support -collapse_underscore
}

::itcl::class ObjectB {
    common attributes {
        {[number]   numbers {1 2 3 4 5 6 7} rw}
        {::ObjectA  obj_a   new             rw}
    }

    method constructor {} {
        OOSupport::init_attributes
    }

    OOSupport::bless_attributes -json_support -collapse_underscore
}

::itcl::class CompoundObject {
    common attributes {
        {[::ObjectA]  obj_array {}   rw}
        {::ObjectB    obj_b     null rw}
    }

    method constructor {} {
        OOSupport::init_attributes

        set obj_b [namespace which [::ObjectB #auto]]
        $this set_obj_b $obj_b

        set result ""
        for {set i 0} {$i < 3} {incr i} {
            lappend result [namespace which [::ObjectA #auto]]
        }
        $this set_obj_array $result
    }

    OOSupport::bless_attributes -json_support -collapse_underscore
}

set COMPOUND_OBJ_JSON_DUMP \
{{
	"objArray":
	[
			{
				"numberAttr": 3,
				"strings":
						[
							"ggc", "adb", "hh", "3"
						]
			},
			{
				"numberAttr": 2,
				"strings":
						[
							"vvc", "avv", "vv", "2"
						]
			},
			{
				"numberAttr": 1,
				"strings":
						[
							"ttt", "ttx", "tt", "1"
						]
			}
	],
	"objB":
	{
		"numbers":
			[
				7, 6, 5, 4, 3, 2, 1
			],
		"objA":
			{
				"numberAttr": 2,
				"strings":
						[
							"xxx", "xxx", "xx", "r"
						]
			}
	}
}}

#
# TEST CASES
#

::itcl::class TestDeserializeFromJson {
    inherit Testing::TestObject

    method test_initialize_compound_object_from_json {} {
        docstr "Re-create a compount object structure by reading in the
        corresponding JSON dump."

        set compound_obj [::CompoundObject #auto]
        $compound_obj from_json $::COMPOUND_OBJ_JSON_DUMP

        if {[$compound_obj to_json] != $::COMPOUND_OBJ_JSON_DUMP} {
            error "error in JSON"
        }

        return 0
    }
}

exit [[TestDeserializeFromJson #auto] run $::argv]

