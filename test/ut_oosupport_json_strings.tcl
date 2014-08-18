#!/usr/bin/tclsh

package require Itcl
package require OOSupport
package require Testing

#
# PREAMBLE
#

::itcl::class ObjectA {

    common attributes {
        {[string]  strings  {}  rw}
    }

    method constructor {} {
        OOSupport::init_attributes
    }

    OOSupport::bless_attributes -json_support
}

set JSON \
{{
	"strings":
	[
		"the sky is the limit...", "°!§$%&\n/{}\"\\()=?", "n\ne\nw\nl\ni\nn\ne"
	]
}}

#
# TEST CASES
#

::itcl::class TestJSONStrings {
    inherit Testing::TestObject

    method test_json_string_escaping {} {
        docstr "Test that newlines, quotes, ... are properly escaped during
        conversion to JSON."

        set obj_a [ObjectA #auto]
        $obj_a from_json $::JSON

        if {[$obj_a to_json] != $::JSON} {
            error "error in JSON"
        }

        return
    }
}

exit [[TestJSONStrings #auto] run $::argv]

