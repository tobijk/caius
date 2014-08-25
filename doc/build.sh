#!/bin/bash

rm -fr _site
rm -fr _api && mkdir _api

# make the TCO for the tutorial
./gen-toc.sh

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

    ronn -5 -f --pipe $__source >> $__target
done

jekyll build


