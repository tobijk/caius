#!/bin/bash

exec > _includes/tutorial_toc.html

for fname in _tutorial/*.md; do
    page_title="`cat $fname | grep '^title: ' | sed 's/^title:[[:space:]]*\"//' | sed 's/\"[[:space:]]*//'`"
    echo "<h3>$page_title</h3>"

    echo $fname > __fname

    cat $fname | sed '/~~~/,/~~~/d' | grep '^#' | while read line
    do
        level=$(($(echo $line | grep -o '^#*' | wc -m) - 1))
        level_diff=$(($previous_level - $level))

        title=$(echo $line | sed 's/^#*//g')
        sanitized_title="` echo $title | tr 'ABCDEFGHIJKLMNOPQRSTUVWXYZ ' 'abcdefghijklmnopqrstuvwxyz-'`"

        html_name="$(basename `cat __fname` .md).html"

        if [ $level_diff -lt 0 ]; then
            if [ "$previous_level" = "" ]; then
                echo "<ul class=\"toc\">"
            else
                echo "<ul>"
            fi
        elif [ $level_diff -gt 0 ]; then
            for i in `seq $(($level_diff))`
            do
                echo "</li></ul>"
            done
            echo "</li>"
        else
            echo "</li>"
        fi
        
        if [ "$previous_level" = "" ]; then
            echo "<li><a href=\"$html_name\">$title</a>"
        else
            echo "<li><a href=\"$html_name#$sanitized_title\">$title</a>"
        fi

        previous_level=$level
        echo "$previous_level" > __previous_level
    done

    if [ -f __previous_level ]; then
        for i in $(seq `cat __previous_level`); do
            echo "</li></ul>"
        done
    fi

    rm -f __previous_level __fname
done
