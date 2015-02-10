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

This package provides a markdown processor that supports the original syntax
as defined by John Gruber on his homepage at

    http://daringfireball.net/projects/markdown/syntax 

In addition, PHP Markdown Extra's syntax for fenced code blocks and for
setting simple tables is supported. Other extensions are currently not
available.

### Fenced Code Blocks

Fenced code blocks allow you to list source code without having to indent
it by four spaces as required by standard Markdown. Instead, fenced code
blocks are delimited by three or more backticks ` ``` ` or tildes `~~~` on
a single line.

Example:

    ~~~tcl
    #include <stdio.h>

    int main(int argc, char **argv)
    {
        printf("Hello world!\n");
        return 0;
    }
    ~~~

You may additionally specify the programming language displayed in the block
as shown above. Currently this has no effect, but future versions of this
module may use this information to run the code block through a syntax
highlighter.

### Tables

The table syntax is simple and intuitive. Columns are delimited by the pipe |
character and the header row is separated from the table body as shown in this
example:

    | Name | Gender | Age |
    |------|--------|-----|
    | John | male   | 40  |
    | Mary | female | 35  |

The leading and trailing pipe characters in a row are optional. But a table row
must contain at least one pipe character in order to be recognized as such.
That means, if you want to set a table with just one column, you either need a
leading or a trailing pipe in every row.

Alignment can be controlled per column and is indicated by colons before or
after the dashes in the cells separating table header and table body.

     Left Aligned | Centered | Right Aligned
     :------------|:--------:|-------------:
     John         |   male   |            40
     Mary         |  female  |            35

A leading colon indicates left-alignment, a colon at the beginning *and* the
end indicates that cell contents shall be centered, and a trailing colon causes
content to be right-aligned. Also note how we omitted the pipe characters at
the beginning and end of each row in this example.

Table elements are rendered with attribute `class="table"` to allow for easier
styling via CSS.

## API

* `Markdown::convert` *markdown*:
  Transform *markdown* to HTML. The result of the conversion is an XHTML 1.0
  fragment.

## SEE ALSO

`markdown`(1)

