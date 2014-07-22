#!/bin/bash

# cleanup
rm -fr spool && mkdir spool

# inject markup to generate the TOC
echo "[TOC]" > spool/tutorial.markdown

# cat all parts into one document
ls rc/ | sort -n | while read f; do
    cat "rc/$f" >> spool/tutorial.markdown
done

# run python markdown
markdown_py -x toc -x codehilite -x fenced_code spool/tutorial.markdown \
    >> spool/tutorial.html

