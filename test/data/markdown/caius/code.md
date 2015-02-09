Test code blocks
===

There is some code coming up. There is some code
coming up. There is some code coming up. There is
some code coming up.

    import os

    fp = file("test.text", "rb")
    buf = fp.read()

There is some code coming up. There is some code
coming up. There is some code coming up. There is
some code coming up.

    <?xml version="1.0" encoding="utf-8"?>
    <html>
        <head>
            <title>Title</title>
        </head>
        <body>
            Body text...
        </body>
    </html>

Now we are going to test fenced code Blocks:

~~~{.tcl}
package require Itcl
package require Testing

::itcl::class MyTest {
    inherit ::Testing::TestObject

    method test1 {} {}
}
~~~

And now using backticks:

`````tcl

package require Itcl
package require Testing

::itcl::class MyTest {
    inherit ::Testing::TestObject

    method test1 {} {}
}

`````

~~~
```

a fenced code block documenting itself.

```
~~~

```
~~~
a fenced code block documenting itself.
~~~
```
