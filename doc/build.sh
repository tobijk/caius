#!/bin/sh

rm -fr _site
rm -fr _api && mkdir _api
rm -f  _manpages/*.gz

# make the TCO for the tutorial
./gen-toc.sh

# build the css
(cd assets && ./build.sh css)

# pre-process manpages with ronn
ls _manpages | while read page
do
    __ptitle="`basename $page .md | tr 'abcdefghijklmnopqrstuvwxyz' 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'`"
    __source="_manpages/$page"
    __target="_api/`basename $page .md`.html"

    echo "\
---
title: $__ptitle
layout: api
---
    " > $__target

    # generate HTML fragment
    ronn -5 -f --pipe $__source >> $__target

    # generate man page
    ronn --pipe -r $__source | gzip > _manpages/`basename $page .md`.3caius.gz
done

jekyll build

