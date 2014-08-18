#!/bin/bash

exec >&-

for i in `seq 3`; do
    echo "process & talking..." >&2
    sleep 1
done

