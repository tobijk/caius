#!/usr/bin/tclsh

package require Itcl
package require Error
package require Testing

#
# PREAMBLE
#

::itcl::class ExceptionA {
    inherit ::Exception

    constructor {msg} {
        ::Exception::constructor $msg
    } {}

    destructor {}
}

::itcl::class ExceptionAA {
    inherit ::ExceptionA

    constructor {msg} {
        ::ExceptionA::constructor $msg
    } {}

    destructor {}
}

#
# TEST CASES
#

::itcl::class TestExceptions {
    inherit Testing::TestObject

    method test_catch_exception_by_exact_class_name {} {
        docstr "Test catching an exception by its exact class name."

        except {
            raise ::ExceptionA "class A exception"
        } e {
            ::ExceptionA {
                if {[$e info class] == "::ExceptionA"} {
                    return
                }

                error "exception has wrong type"
            }
        }

        error "exception was not caught"
    }

    method test_catch_exception_by_base_class {} {
        docstr "Test catching an exception by a base class' name."

        except {
            raise ::ExceptionAA "class AA exception"
        } e {
            ::ExceptionA {
                if {[$e info class] == "::ExceptionAA"} {
                    return
                }

                error "exception has wrong type"
            }
        }

        error "exception was not caught"
    }

    method test_catch_exception_on_first_base_class_match_1st_occurence {} {
        docstr "Test that exception is caught by first valid base class in
        list."

        except {
            raise ::ExceptionAA "class AA exception"
        } e {
            ::Exception {
                return
            }
            ::ExceptionA {
                error "exception caught incorrectly as ExceptionA"
            }
            ::ExceptionAA {
                error "exception caught incorrectly as ExceptionAA"
            }
        }

        error "exception was not caught"
    }

    method test_catch_exception_on_first_base_class_match_in_between {} {
        docstr "Test that exception is caught by base class match in between
        unrelated handler clauses."

        except {
            raise ::ExceptionA "class AA exception"
        } e {
            ::ExceptionAA {
                error "exception caught incorrectly as ExceptionAA"
            }
            ::Exception {
                return
            }
            ::ExceptionA {
                error "exception caught incorrectly as ExceptionA"
            }
        }

        error "exception was not caught"
    }

    method test_catch_exception_by_exact_class_match_in_between {} {
        docstr "Test that exception is caught be exact class name match in
        between unrelated handler clauses."

        except {
            raise ::ExceptionA "class A exception"
        } e {
            ::ExceptionAA {
                error "caught exception with derived class name"
            }
            ::ExceptionA {
                return 0
            }
            ::Exception {
                error "exception not caught with exact class name"
            }
        }

        error "exception was not caught"
    }

    method test_catch_a_tcl_error_as_tclerror_exception_object {} {
        docstr "Test catching a Tcl error as a `TclError` object."

        except {
            error "this is an ordinary Tcl error"
        } e {
            ::TclError {
                if {[$e info class] ne "::TclError"} {
                    error "expected exception object of class ::Exception::TclError"
                }

                return
            }
        }

        error "Tcl error was not caught"
    }

    method test_uncaught_exceptions_propagate_through_except_blocks {} {
        docstr "Test that uncaught exceptions propagate through except blocks."

        except {
            except {
                raise ::ValueError "catch me if you can..."
            } e1 {
                ::TclError {
                    error "exception was caught in wrong spot."
                }
            }
        } e2 {
            ::ValueError {
                return
            }
        }

        error "exception was not caught"
    }

    method test_execute_final_clause_when_exception_occurs_and_is_caught {} {
        docstr "Test that final clause is executed when exception is caught."

        set exception_caught 0
        set final_run 0

        except {
            raise ExceptionA "catch me and run final clause"
        } e {
            ::Exception {
                set exception_caught 1
            }
        } final {
            set final_run 1
        }

        if {!$exception_caught} {
            error "exception wasn't caught"
        }

        if {!$final_run} {
            error "final clause was not run"
        }

        return
    }

    method test_execute_final_clause_when_exception_occurs_and_is_not_caught {} {
        docstr "Test that final clause is also executed when exception is not
        caught."

        set exception_caught 0
        set final_run 0

        except {
            except {
                raise ExceptionA "catch me and run final clause"
            } e1 {
                ::RuntimeError {
                    set exception_caught 1
                }
            } final {
                set final_run 1
            }
        } e2 {
            ::ExceptionA {
                #pass
            }
        }

        if {$exception_caught} {
            error "exception was caught but shouldn't have"
        }

        if {!$final_run} {
            error "final clause was not run"
        }

        return
    }

    method test_handle_empty_catch_block {} {
        docstr "Test that catch block can be empty."

        set exception_propagated 0
        set final_run 0

        except {
            except {
                raise ExceptionA "catch me and run final clause"
            } e1 {

            } final {
                set final_run 1
            }
        } e2 {
            ::ExceptionA {
                set exception_propagated 1
            }
        }

        if {$exception_propagated == 0} {
            error "exception didn't propagate"
        }

        if {!$final_run} {
            error "final clause was not run"
        }

        return
    }

    method test_execute_final_clause_when_no_exception_occurs {} {
        docstr "Test that the final clause is executed when no exception occurs."

        set final_run 0

        except {

        } e1 {

        } final {
            set final_run 1
        }

        if {!$final_run} {
            error "final clause was not run"
        }

        return
    }

    method test_caught_exception_objects_are_deleted {} {
        docstr "Test that exceptions that are caught are properly cleaned up."

        except {
            raise ::RuntimeError "something happened..."
        } e {
            ::RuntimeError {

            }
        }

        if {[::itcl::is object $e]} {
            error "exception object should have been recycled"
        }

        return
    }
}

exit [[TestExceptions #auto] run $::argv]

