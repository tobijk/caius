Markdown(3caius) -- basic Markdown processor
==============================================================================

## EXAMPLE

### Script:

    package require Markdown

    set markdown "
    Lorem ipsum dolor sit amet, consectetur adipisicing elit,
 
    * sed do eiusmod tempor incididunt
        * ut labore et dolore magna aliqua.
    * Ut enim ad minim veniam, quis nostrud
        * exercitation ullamco laboris nisi ut
        * aliquip ex ea commodo consequat.
 
    Duis aute irure dolor in reprehenderit in voluptate velit
    esse cillum dolore eu fugiat nulla pariatur...
    "

    puts [::Markdown::convert $markdown]

### Result:

    <p>Lorem ipsum dolor sit amet, consectetur adipisicing elit,</p>

    <ul>
        <li>sed do eiusmod tempor incididunt
            <ul>
                <li>ut labore et dolore magna aliqua.</li>
            </ul>
        </li>
        <li>Ut enim ad minim veniam, quis nostrud
            <ul>
                <li>exercitation ullamco laboris nisi ut</li>
                <li>aliquip ex ea commodo consequat.</li>
            </ul>
        </li>
    </ul>

    <p>Duis aute irure dolor in reprehenderit in voluptate velit
    esse cillum dolore eu fugiat nulla pariatur...</p>

## DESCRIPTION

This package provides a markdown processor that supports the original basic
syntax as defined by John Gruber on his homepage at

http://daringfireball.net/projects/markdown/syntax 

Common extensions are *not* supported at this time.

## API

* `Markdown::convert` *markdown*:
  Transform *markdown* to HTML. The result of the conversion is an XHTML 1.0
  fragment.

## SEE ALSO

`markdown`(1)

