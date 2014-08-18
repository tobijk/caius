#!/bin/bash

echo "this script returns with code 17" >&2

for i in `seq 3`; do
    echo "process & talking..." >&2
    sleep 1
done

exit 17
