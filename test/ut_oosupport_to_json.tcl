#!/usr/bin/tclsh

package require Itcl
package require OOSupport
package require Testing

#
# For compound objects serialization test
#

::itcl::class Vertex {

    common attributes {
        {number x null rw}
        {number y null rw}
        {number z null rw}
    }

    method constructor {x y z} {
        OOSupport::init_attributes

        set _x $x
        set _y $y
        set _z $z
    }

    OOSupport::bless_attributes -json_support
}

::itcl::class Triangle {

    common attributes {
        {::Vertex v1 null rw}
        {::Vertex v2 null rw}
        {::Vertex v3 null rw}
    }

    method constructor {v1 v2 v3} {
        OOSupport::init_attributes

        set _v1 $v1
        set _v2 $v2
        set _v3 $v3
    }

    OOSupport::bless_attributes -json_support
}

::itcl::class 3DMesh {

    common attributes {
        {[::Triangle] triangles {} rw}
    }

    method constructor {} {
        OOSupport::init_attributes
    }

    OOSupport::bless_attributes -json_support
}

::itcl::class LinkedList {

    common attributes {
        {::LinkedList next null rw}
        {number node_id 1 rw}
    }

    method constructor {} {
        OOSupport::init_attributes
    }

    OOSupport::bless_attributes -json_support
}

set 3DMESH_JSON \
{{
	"triangles":
	[
			{
				"v1":
						{
							"x": 0.0,
							"y": 0.0,
							"z": 0.0
						},
				"v2":
						{
							"x": 1.0,
							"y": 1.0,
							"z": 0.0
						},
				"v3":
						{
							"x": 0.0,
							"y": 1.0,
							"z": 0.0
						}
			},
			{
				"v1":
						{
							"x": 0.0,
							"y": 0.0,
							"z": 0.0
						},
				"v2":
						{
							"x": 1.0,
							"y": 0.0,
							"z": 0.0
						},
				"v3":
						{
							"x": 1.0,
							"y": 1.0,
							"z": 0.0
						}
			}
	]
}}

#
# For array serialization test
#

::itcl::class SomeObject {

    common attributes {
        {string name "" rw}
    }

    method constructor {name} {
        OOSupport::init_attributes
        $this set_name $name
    }

    OOSupport::bless_attributes -json_support -collapse_underscore
}

::itcl::class LotsOfArrays {

    common attributes {
        {[bool]          array_of_bools {true false false true} rw}
        {[number]        array_of_nums  {1.0 2.0 3.0 4.0 5.0}   rw}
        {[::SomeObject]  array_of_objs  {}                      rw}
        {[string]        array_of_strs  {a abc aaze aaks aa s}  rw}
    }

    method constructor {} {
        OOSupport::init_attributes
    }

    OOSupport::bless_attributes -json_support -collapse_underscore
}

set OBJ_OF_ARRAYS_JSON \
{{
	"arrayOfBools":
	[
		true, false, false, true
	],
	"arrayOfNums":
	[
		1.0, 2.0, 3.0, 4.0, 5.0
	],
	"arrayOfObjs":
	[
			{
				"name": "object 1"
			},
			{
				"name": "object 2"
			}
	],
	"arrayOfStrs":
	[
		"a", "abc", "aaze", "aaks", "aa", "s"
	]
}}

#
# TEST CASES
#

::itcl::class TestJSONSupport {
    inherit Testing::TestObject

    method test_json_serialization_of_composed_objects {} {
        docstr "Test the serialization of a compound object representing a 3D
        triangle mesh to JSON."

        set v1 [namespace which [Vertex #auto 0.0 0.0 0.0]]
        set v2 [namespace which [Vertex #auto 1.0 1.0 0.0]]
        set v3 [namespace which [Vertex #auto 0.0 1.0 0.0]]
        set v4 [namespace which [Vertex #auto 1.0 0.0 0.0]]

        set t1 [namespace which [Triangle #auto $v1 $v2 $v3]]
        set t2 [namespace which [Triangle #auto $v1 $v4 $v2]]

        set mesh [3DMesh #auto]
        $mesh set_triangles [list $t1 $t2]

        if {[$mesh to_json] != $::3DMESH_JSON} {
            error "error in JSON"
        }

        return
    }

    method test_json_serialization_of_arrays {} {
        docstr "Test the serialization of nested arrays to JSON."

        set obj1 [namespace which [SomeObject #auto "object 1"]]
        set obj2 [namespace which [SomeObject #auto "object 2"]]

        set loas [LotsOfArrays #auto]
        $loas set_array_of_objs [list $obj1 $obj2]

        if {[$loas to_json] != $::OBJ_OF_ARRAYS_JSON} {
            error "error in JSON"
        }

        return
    }

    method test_json_serialization_of_nulls {} {
        docstr "Test that things don't blow up when something is 'null'."

set expected_result {{
	"v1": null,
	"v2": null,
	"v3": null
}}

        # serialize nulls
        set triangle1 [Triangle #auto null null null]
        if {[$triangle1 to_json] ne $expected_result} {
            error "expected something like this: $expected_result"
        }

set expected_result {{
	"triangles":
	[
	
	]
}}

        # load empty array
        set mesh [3DMesh #auto]
        $mesh from_json "{ \"triangles\": \[\] }"
        if {[$mesh to_json] ne $expected_result} {
            error "expected something like this: $expected_result"
        }

set expected_result {{
	"next": null,
	"node_id": 1
}}

        # load null reference
        set llist [LinkedList #auto]
        $llist from_json "{ \"next\": null }"
        if {[$llist to_json] ne $expected_result} {
            error "expected something like this: $expected_result"
        }
        return
    }
}

exit [[TestJSONSupport #auto] run $::argv]

