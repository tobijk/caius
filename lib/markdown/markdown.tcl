#
# The MIT License (MIT)
#
# Copyright (c) 2014 Caius Project
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#

package require textutil

namespace eval Markdown {

    namespace export convert

    proc convert {markdown} {
        set markdown [regsub {\r\n?} $markdown {\n}]
        set markdown [::textutil::untabify2 $markdown 4]
        set markdown [string trimright $markdown]

        # COLLECT REFERENCES
        array unset ::Markdown::_references
        array set ::Markdown::_references [collect_references markdown]

        # PROCESS
        return [apply_templates markdown]
    }

    proc collect_references {markdown_var} {
        upvar $markdown_var markdown

        set lines [split $markdown \n]
        set no_lines [llength $lines]
        set index 0

        array set references {}

        while {$index < $no_lines} {
            set line [lindex $lines $index]

            if {[regexp \
                {^[ ]{0,3}\[((?:[^\]]|\[[^\]]*?\])+)\]:\s*(\S+)(?:\s+(([\"\']).*\4|\(.*\))\s*$)?} \
                $line match ref link title]} \
            {
                set title [string trim [string range $title 1 end-1]]
                if {$title eq {}} {
                    set next_line [lindex $lines [expr $index + 1]]

                    if {[regexp \
                        {^(?:\s+(?:([\"\']).*\1|\(.*\))\s*$)} \
                        $next_line]} \
                    {
                        set title [string range [string trim $next_line] 1 end-1]
                        incr index
                    }
                }
                set ref [string tolower $ref]
                set link [string trim $link {<>}]
                set references($ref) [list $link $title]
            }

            incr index
        }

        return [array get references]
    }

    proc apply_templates {markdown_var {parent {}}} {
        upvar $markdown_var markdown

        set lines    [split $markdown \n]
        set no_lines [llength $lines]
        set index    0
        set result   {}

        set re_ulist   {^[ ]{0,3}(?:\*(?!\s*\*\s*\*\s*$)|-(?!\s*-\s*-\s*$)|\+) }
        set re_olist   {^[ ]{0,3}\d+\. }
        set re_htmltag {<(/)?(\w+)(?:\s+\w+=(?:\"[^\"]+\"|'[^']+'))*\s*(/)?>|<!\[(CDATA)\[.*?\]\]>}

        # PROCESS MARKDOWN
        while {$index < $no_lines} {
            set line [lindex $lines $index]

            switch -regexp $line {
                {^\s*$} {
                    # EMPTY LINES
                    if {![regexp {^\s*$} [lindex $lines [expr $index - 1]]]} {
                        append result "\n"
                    }

                    incr index
                }
                {^[ ]{0,3}\[(?:[^\]]|\[[^\]]*?\])+\]:\s*\S+(?:\s+(?:([\"\']).*\1|\(.*\))\s*$)?} {
                    # SKIP REFERENCES
                    set next_line [lindex $lines [expr $index + 1]]

                    if {[regexp \
                        {^(?:\s+(?:([\"\']).*\1|\(.*\))\s*$)} \
                        $next_line]} \
                    {
                        incr index
                    }

                    incr index
                }
                {^[ ]{0,3}([-_*])\s*\1\s*\1(?:\1|\s)*$} {
                    # HORIZONTAL RULES
                    append result <hr/> \n
                    incr index
                }
                {^[ ]{0,3}#{1,6}(?:\s+|$)} {
                    # ATX STYLE HEADINGS
                    regexp {^\s*(#+)} $line m hash_marks
                    set h_level [string length $hash_marks]

                    set h_result [parse_inline \
                        [string trim [regsub -all {^\s*#+|\s+#+\s*$} $line {}]] \
                    ]

                    append result "<h$h_level>$h_result</h$h_level>\n"
                    incr index
                }
                {^[ ]{0,3}\>} {
                    # BLOCK QUOTES
                    set bq_result {}

                    while {$index < $no_lines} {
                        set next_line [lindex $lines [incr index]]

                        lappend bq_result [regsub {^[ ]{0,3}\>[ ]?} $line {}]

                        if {[is_empty_line $next_line]} {
                            set eoq 0

                            # check if the next content line is a blockquote
                            for {set peek [expr $index + 1]} \
                                    {$peek < $no_lines} {incr peek} \
                            {
                                set line [lindex $lines $peek]

                                if {![is_empty_line $line]} {
                                    if {![regexp {^[ ]{0,3}\>} $line]} {
                                        set eoq 1
                                    }
                                    break
                                }
                            }

                            if {$eoq} { break }
                        } else {
                            # horizontal rule breaks running blockquote
                            if {[regexp {^[ ]{0,3}([-_*])\s*\1\s*\1(?:\1|\s)*$} $next_line]} {
                                break
                            }
                        }

                        set line [lindex $lines $index]
                    }
                    set bq_result [string trim [join $bq_result \n]]

                    append result <blockquote>\n [apply_templates bq_result] \
                        </blockquote> \n
                }
                {^\s{4,}\S+} {
                    # CODE BLOCKS
                    set code_result {}

                    while {$index < $no_lines} {
                        incr index

                        append code_result \
                            [html_escape [regsub {^    } $line {}]] "\n"

                        set eoc 0
                        for {set peek $index} {$peek < $no_lines} {incr peek} {
                            set line [lindex $lines $peek]

                            if {![is_empty_line $line]} {
                                if {![regexp {^\s{4,}} $line]} {
                                    set eoc 1
                                }
                                break
                            }
                        }

                        if {$eoc} { break }

                        set line [lindex $lines $index]
                    }

                    append result <pre><code> $code_result </code></pre> \n
                }
                {^[ ]{0,3}(`{3,}|~{3,})\s*(?:[^`~\s]+)?(?:\s+[^`~\s]+)*\s*$} {
                    # FENCED CODE BLOCKS
                    set code_result {}

                    # end marker: same char at least as long as start marker
                    regexp "^(\\s*)([string index [string trim $line] 0]+)\\s*(\\S+)?" \
                        $line match indent end_match language

                    while {[incr index] < $no_lines} \
                    {
                        set line [regsub "^$indent" [lindex $lines $index] {}]

                        if {[regexp "^\[ \]{0,3}$end_match+\\s*$" $line]} {
                            incr index
                            break
                        }

                        append code_result [html_escape $line] "\n"
                    }

                    if {$language ne {}} {
                        append result "<pre><code class=\"language-[html_escape $language]\">"
                    } else {
                        append result <pre><code>
                    }
                    
                    append result $code_result </code></pre> \n
                }
                {^[ ]{0,3}(?:\*|-|\+) |^[ ]{0,3}\d+\. } {
                    # LISTS
                    set list_result {}

                    # continue matching same list type
                    if {[regexp $re_olist $line]} {
                        set list_type ol
                        set list_match $re_olist
                    } else {
                        set list_type ul
                        set list_match $re_ulist
                        set list_bullet [string index [string trimleft $line] 0]
                    }

                    set last_line AAA

                    while {$index < $no_lines} {
                        if {![regexp $list_match [lindex $lines $index]]} {
                            break
                        }

                        set item_result {}
                        set in_p 1
                        set p_count 1

                        if {[is_empty_line $last_line]} {
                            incr p_count
                        }

                        set last_line $line
                        set line [regsub "$list_match\\s*" $line {}]

                        # prevent recursion on same line
                        if {$list_type eq {ol}} {
                            set line [regsub {\A(\d+)\.(\s+)} $line {\1\\.\2}]
                        } else {
                            set line [regsub "\\A(\\$list_bullet)(\\s+)" $line {\\\1\2}]
                        }

                        lappend item_result $line

                        # peek ahead to determine whether list continues or not
                        for {set peek [expr $index + 1]} {$peek < $no_lines} {incr peek} {
                            set line [lindex $lines $peek]

                            if {[is_empty_line $line]} {
                                set in_p 0
                            } elseif {[regexp {^    } $line]} {
                                if {!$in_p} { incr p_count }
                                set in_p 1
                            } elseif {[regexp {^[ ]{0,3}([-_*])\s*\1\s*\1(?:\1|\s)*$} $line]} {
                                if {!$in_p} { incr p_count }
                                break
                            } elseif {[regexp $list_match $line]} {
                                if {!$in_p} { incr p_count }
                                break
                            } else {
                                if {!$in_p} { break }
                            }

                            set last_line $line
                            lappend item_result [regsub {^    } $line {}]
                        }

                        set item_result [join $item_result \n]

                        if {$p_count > 1} {
                            set item_result [apply_templates item_result li]
                        } else {
                            if {[regexp -lineanchor \
                                {(\A.*?)((?:^[ ]{0,3}(?:\*|-|\+) |^[ ]{0,3}\d+\. ).*\Z)} \
                                $item_result \
                                match para rest]} \
                            {
                                set item_result [parse_inline $para]
                                append item_result [apply_templates rest]
                            } else {
                                set item_result [parse_inline $item_result]
                            }
                        }

                        lappend list_result "<li>$item_result</li>"
                        set index $peek
                    }

                    append result <$list_type>\n \
                        [join $list_result \n] </$list_type>\n\n
                }
                {(?i)^[ ]{0,3}<(?:article|header|aside|hgroup|blockquote|hr|iframe|body|li|map|button|object|canvas|ol|caption|output|col|p|colgroup|pre|dd|progress|div|section|dl|table|td|dt|tbody|embed|textarea|fieldset|tfoot|figcaption|th|figure|thead|footer|tr|form|ul|h1|h2|h3|h4|h5|h6|video|script|style|!\[CDATA\[)} {
                    # HTML BLOCKS
                    set buffer {}
                    append buffer $line \n
                    incr index

                    while {$index < $no_lines} \
                    {
                        # fast forward to next blank line
                        while {1} \
                        {
                            set line [lindex $lines $index]

                            if {[is_empty_line $line]} {
                                break
                            }

                            append buffer $line \n
                            incr index
                        }

                        set tags [regexp -inline -all $re_htmltag $buffer]
                        set stack_count 0

                        foreach {match type name self_closing cdata} $tags {
                            if {$cdata ne {}} {
                                continue
                            }

                            if {$self_closing eq {}} {
                                if {$type eq {}} {
                                    if {[lsearch -exact {link track param area
                                            command col base meta hr source img
                                            keygen br wbr input} $name] < 0} \
                                    {
                                        incr stack_count +1
                                    }
                                } else {
                                    incr stack_count -1
                                }
                            }
                        }

                        if {$stack_count == 0} {
                            break
                        } else {
                            append buffer $line \n
                            incr index
                        }
                    }

                    append result $buffer
                }
                {(?:^[ ]{0,3}|[^\\]+)\|} {
                    # SIMPLE TABLES
                    set cell_align {}
                    set row_count 0

                    while {$index < $no_lines} {
                        # insert a space between || to handle empty cells
                        set row_cols [regexp -inline -all {(?:[^|]|\\\|)+} \
                            [regsub -all {\|(?=\|)} [string trim $line] {| }] \
                        ]

                        if {$row_count == 0} {
                            set sep_cols [lindex $lines [expr $index + 1]]

                            # check if we have a separator row
                            if {[regexp {^[ ]{0,3}\|?(?:\s*:?-+:?(?:\s*$|\s*\|))+} $sep_cols]} {
                                set sep_cols [regexp -inline -all {(?:[^|]|\\\|)+} \
                                    [string trim $sep_cols]]

                                foreach {cell_data} $sep_cols \
                                {
                                    switch -regexp $cell_data {
                                        {:-*:} {
                                            lappend cell_align center
                                        }
                                        {:-+} {
                                            lappend cell_align left
                                        }
                                        {-+:} {
                                            lappend cell_align right
                                        }
                                        default {
                                            lappend cell_align {}
                                        }
                                    }
                                }
                                incr index
                            }

                            append result "<table class=\"table\">\n"
                            append result "<thead>\n"
                            append result "  <tr>\n"

                            if {$cell_align ne {}} {
                                set num_cols [llength $cell_align]
                            } else {
                                set num_cols [llength $row_cols]
                            }

                            for {set i 0} {$i < $num_cols} {incr i} \
                            {
                                if {[set align [lindex $cell_align $i]] ne {}} {
                                    append result "    <th style=\"text-align: $align\">"
                                } else {
                                    append result "    <th>"
                                }

                                append result [parse_inline [string trim \
                                    [lindex $row_cols $i]]] </th> "\n"
                            }

                            append result "  </tr>\n"
                            append result "</thead>\n"
                        } else {
                            if {$row_count == 1} {
                                append result "<tbody>\n"
                            }
                            append result "  <tr>\n"

                            if {$cell_align ne {}} {
                                set num_cols [llength $cell_align]
                            } else {
                                set num_cols [llength $row_cols]
                            }

                            for {set i 0} {$i < $num_cols} {incr i} \
                            {
                                if {[set align [lindex $cell_align $i]] ne {}} {
                                    append result "    <td style=\"text-align: $align\">"
                                } else {
                                    append result "    <td>"
                                }

                                append result [parse_inline [string trim \
                                    [lindex $row_cols $i]]] </td> "\n"
                            }
                            append result "  </tr>\n"
                        }

                        incr row_count
                        set line [lindex $lines [incr index]]

                        if {![regexp {(?:^[ ]{0,3}|[^\\]+)\|} $line]} {
                            switch $row_count {
                                1 {
                                    append result "</table>\n"
                                }
                                default {
                                    append result "</tbody>\n"
                                    append result "</table>\n"
                                }
                            }

                            break
                        }
                    }
                }
                default {
                    # PARAGRAPHS AND SETTEXT STYLE HEADERS
                    set p_type p
                    set p_result {}

                    while {($index < $no_lines) && ![is_empty_line $line]} \
                    {
                        incr index

                        switch -regexp $line {
                            {^[ ]{0,3}(?:=+|-+)$} {
                                switch [llength $p_result] {
                                    0 {
                                        lappend p_result $line
                                    }
                                    1 {
                                        if {[string first = $line] != -1} {
                                            set p_type h1
                                        } else {
                                            set p_type h2
                                        }
                                        break
                                    }
                                    default {
                                        if {[string first = $line] != -1} {
                                            lappend p_result $line
                                        } else {
                                            incr index -1
                                            break
                                        }
                                    }
                                }
                            }
                            {^[ ]{0,3}(?:\*|-|\+) |^[ ]{0,3}\d+\. } {
                                if {$parent eq {li}} {
                                    incr index -1
                                    break
                                } else {
                                    lappend p_result $line
                                }
                            }
                            {^[ ]{0,3}([-_*])\s*\1\s*\1(?:\1|\s)*$} -
                            {^[ ]{0,3}#{1,6}(?:\s+|$)} -
                            {^[ ]{0,3}(`{3,}|~{3,})\s*(?:[^`~\s]+)?(?:\s+[^`~\s]+)*\s*$} \
                            {
                                incr index -1
                                break
                            }
                            default {
                                lappend p_result $line
                            }
                        }

                        set line [lindex $lines $index]
                    }

                    set p_result [\
                        parse_inline [\
                            string trim [join $p_result \n]\
                        ]\
                    ]

                    if {[is_empty_line [regsub -all {<!--.*?-->} $p_result {}]]} {
                        # Do not make a new paragraph for just comments.
                        append result $p_result \n
                    } else {
                        append result "<$p_type>$p_result</$p_type>\n"
                    }
                }
            }
        }

        return $result
    }

    proc parse_inline {text} {
        #set text [regsub -all -lineanchor {[ ]{2,}\n(?!\Z)\s*} $text <br/>]

        set index 0
        set result {}

        set re_backticks   {\A`+}
        set re_whitespace  {\s}
        set re_inlinelink  {\A\!?\[((?:[^\]]|\[[^\]]*?\])+)\]\s*\(\s*((?:[^\s\)]+|\([^\s\)]+\))+)?(\s+([\"'])(.*)?\4)?\s*\)}
        set re_reflink     {\A\!?\[((?:[^\]]|\[[^\]]*?\])+)\](?:\s*\[((?:[^\]]|\[[^\]]*?\])*)\])?}
        set re_htmltag     {\A</?\w+\s*>|\A<\w+(?:\s+\w+=(?:\"[^\"]+\"|\'[^\']+\'))*\s*/?>|<!\[(CDATA)\[.*?\]\]>}
        set re_autolink    {\A<(?:(\S+@\S+)|(\S+://\S+))>}
        set re_comment     {\A<!--.*?-->}
        set re_entity      {\A\&\S+;}

        while {[set chr [string index $text $index]] ne {}} {
            switch $chr {
                \\ {
                    # Peek at next character to decide.
                    set next_chr [string index $text [expr $index + 1]]

                    # HARD BREAK
                    if {$next_chr eq "\n"} {
                        append result <br />
                        while {[string is space -strict [string index $text \
                            [incr index]]]} {}
                        continue
                    }

                    # ESCAPES
                    if {[string first $next_chr {!\"#$%&'()*+,-./:;<=>?@[\\]^_`\{|\}~}] != -1} {
                        set chr $next_chr
                        incr index
                    }
                }
                {_} -
                {*} {
                    # EMPHASIS
                    if {[regexp $re_whitespace [string index $result end]] &&
                        [regexp $re_whitespace [string index $text [expr $index + 1]]]} \
                    {
                        #do nothing
                    } \
                    elseif {[regexp -start $index \
                        "\\A(\\$chr{1,3})((?:\[^\\$chr\\\\]|\\\\\\$chr)*)\\1" \
                        $text m del sub]} \
                    {
                        if {![regexp {^\s*$} $sub]} {
                            switch [string length $del] {
                                1 {
                                    append result "<em>[parse_inline $sub]</em>"
                                }
                                2 {
                                    append result "<strong>[parse_inline $sub]</strong>"
                                }
                                3 {
                                    append result "<strong><em>[parse_inline $sub]</em></strong>"
                                }
                            }

                            incr index [string length $m]
                            continue
                        }
                    }
                }
                {`} {
                    # CODE
                    regexp -start $index $re_backticks $text m
                    set start [expr $index + [string length $m]]

                    if {[regexp -start $start -indices $m $text m]} {
                        set stop [expr [lindex $m 0] - 1]

                        set sub [string trim [string range $text $start $stop]]

                        append result "<code>[html_escape $sub]</code>"
                        set index [expr [lindex $m 1] + 1]
                        continue
                    }
                }
                {!} -
                {[} {
                    # LINKS AND IMAGES
                    if {$chr eq {!}} {
                        set ref_type img
                    } else {
                        set ref_type link
                    }

                    set match_found 0

                    if {[regexp -start $index $re_inlinelink $text m txt url ign del title]} {
                        # INLINE
                        incr index [string length $m]

                        set url [html_escape [string trim $url {<> }]]
                        set txt [parse_inline $txt]
                        set title [parse_inline $title]

                        set match_found 1
                    } elseif {[regexp -start $index $re_reflink $text m txt lbl]} {
                        if {$lbl eq {}} {
                            set lbl [regsub -all {\s+} $txt { }]
                        }

                        set lbl [string tolower $lbl]

                        if {[info exists ::Markdown::_references($lbl)]} {
                            lassign $::Markdown::_references($lbl) url title

                            set url [html_escape [string trim $url {<> }]]
                            set txt [parse_inline $txt]
                            set title [parse_inline $title]

                            # REFERENCED
                            incr index [string length $m]
                            set match_found 1
                        }
                    }

                    # PRINT IMG, A TAG
                    if {$match_found} {
                        if {$ref_type eq {link}} {
                            if {$title ne {}} {
                                append result "<a href=\"$url\" title=\"$title\">$txt</a>"
                            } else {
                                append result "<a href=\"$url\">$txt</a>"
                            }
                        } else {
                            if {$title ne {}} {
                                append result "<img src=\"$url\" alt=\"$txt\" title=\"$title\"/>"
                            } else {
                                append result "<img src=\"$url\" alt=\"$txt\"/>"
                            }
                        }

                        continue
                    }
                }
                {<} {
                    # HTML TAGS, COMMENTS AND AUTOLINKS
                    if {[regexp -start $index $re_comment $text m]} {
                        append result $m
                        incr index [string length $m]
                        continue
                    } elseif {[regexp -start $index $re_autolink $text m email link]} {
                        if {$link ne {}} {
                            set link [html_escape $link]
                            append result "<a href=\"$link\">$link</a>"
                        } else {
                            set mailto_prefix "mailto:"
                            if {![regexp "^${mailto_prefix}(.*)" $email mailto email]} {
                                # $email does not contain the prefix "mailto:".
                                set mailto "mailto:$email"
                            }
                            append result "<a href=\"$mailto\">$email</a>"
                        }
                        incr index [string length $m]
                        continue
                    } elseif {[regexp -start $index $re_htmltag $text m]} {
                        append result $m
                        incr index [string length $m]
                        continue
                    }
                }
                {&} {
                    # ENTITIES
                    if {[regexp -start $index $re_entity $text m]} {
                        append result $m
                        incr index [string length $m]
                        continue
                    }
                }
                " " {
                    if {[regexp -start $index -- {\A[ ]{2,}\n} $text m]} {
                        append result <br /> \n
                        incr index [string length $m]
                        continue
                    }
                }
                {>} -
                {'} -
                "\"" {
                    # OTHER SPECIAL CHARACTERS
                }
                default {}
            }

            append result [html_escape $chr]
            incr index
        }

        return $result
    }

    proc is_empty_line {line} {
        return [regexp {^\s*$} $line]
    }

    proc html_escape {text} {
        return [string map {& &amp; < &lt; > &gt; \" &quot;} $text]
    }
}

