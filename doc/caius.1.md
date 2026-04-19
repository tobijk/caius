caius(1) -- functional testing harness
======================================

## SYNOPSIS

`caius` <command> [<options>] [<arguments>]

## DESCRIPTION

`caius` is the command line entry point to the Caius functional testing
framework. It can execute individual test programs, orchestrate larger
testplans, and generate human-readable HTML reports from the resulting
XML output.

## COMMANDS

  * `run` [<options>] <executable>:
    Execute a single test program and capture its result. The program
    may be a native Caius test written in Tcl or any other executable
    that emits results on standard output.

  * `runplan` [<options>] <testplan>:
    Execute the set of tests described in <testplan>, an XML document
    that lists test programs together with per-test settings.

  * `report` [<options>] <directory>:
    Generate an HTML report from the Caius XML test results found in
    <directory>.

Type `caius` <command> `--help` for command-specific options.

## EXIT STATUS

`caius` exits with status `0` on success and a non-zero status if an
internal error occurs or if any of the executed tests reports a
failure.

## SEE ALSO

testing(3caius), clidriver(3caius), subprocess(3caius),
oosupport(3caius), error(3caius), webdriver(3caius)

The project homepage is at <https://tobijk.github.io/caius/>.

## AUTHOR

Tobias Koch &lt;tobias.koch@gmail.com&gt;
