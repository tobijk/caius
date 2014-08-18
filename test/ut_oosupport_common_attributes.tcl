#!/usr/bin/tclsh

package require Itcl
package require OOSupport
package require Testing

#
# PREAMBLE
#

::itcl::class ClassBlessed {

    common attributes {
        {string read_only_attr  "read only"  ro}
        {string write_only_attr "write only" wo}
        {string read_write_attr "read/write" rw}
    }

    method constructor {} {
        OOSupport::init_attributes
    }

    OOSupport::bless_attributes
}

#
# TEST CASES
#

::itcl::class TestOOSupportAttributes {
    inherit Testing::TestObject

    method test_attribute_accessor_generation {} {
        set obj [ClassBlessed #auto]

        set rval [catch {
            $obj set_read_only_attr "overwritten"
        } err ]
        if {$rval == 0} {
            error "read-only attribute is writable"
        }

        if {[$obj read_only_attr] ne "read only"} {
            error "read-only attribute changed"
        }

        set rval [catch {
            $obj write_only_attr
        } err ]
        if {$rval == 0} {
            error "write-only attribute is readable"
        }

        set rval [catch {
            $obj read_write_attr
        } err ]
        if {$rval != 0} {
            error "read/write attribute is not readable"
        }

        set rval [catch {
            $obj set_read_write_attr "overwritten"
        } err ]
        if {$rval != 0} {
            error "read/write attribute is not writeable"
        }

        set val [$obj read_write_attr]
        if {$val != "overwritten"} {
            error "read/write attribute was not successfully changed"
        }

        return
    }
}

exit [[TestOOSupportAttributes #auto] run $::argv]

