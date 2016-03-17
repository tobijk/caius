#!/usr/bin/tclsh

package require Itcl
package require WebDriver
package require Error
package require OOSupport
package require Testing

package require tdom

set DATA_DIR "[file dirname [file normalize $::argv0]]/data"
set URL1 "file://$DATA_DIR/html/page1.html"

set NORMALIZE_XSLT {<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

<xsl:template match="text()">
    <xsl:value-of select="normalize-space(.)"/>
</xsl:template>

<xsl:template match="*|comment()">
    <xsl:copy>
        <xsl:for-each select="@*">
            <xsl:copy/>
        </xsl:for-each>
        <xsl:apply-templates/>
    </xsl:copy>
</xsl:template>

</xsl:stylesheet>
}

#
# TEST CASES
#

::itcl::class TestWebDriverPage {
    inherit Testing::TestObject

    method test_access_page_source_and_title {} {
        docstr "Test getting the page source and title."

        set cap [namespace which [WebDriver::Capabilities #auto]]
        $cap set_browser_name "chrome"

        set session [WebDriver::Session #auto http://127.0.0.1:4444/wd/hub $cap]
        $session set_logging_enabled 1
        set window  [$session active_window]

        set fp [open [string range $::URL1 7 end] "rb"]
        set file_source [read $fp]
        close $fp

        $window set_url $::URL1
        set page_source [$window page_source]

        set file_doc [dom parse $file_source]
        set page_doc [dom parse $page_source]

        set norm_style [dom parse $::NORMALIZE_XSLT]
        $norm_style toXSLTcmd norm

        $norm transform $file_doc file_doc
        $norm transform $page_doc page_doc

        set file_xml [$file_doc asXML -indent 1]
        set page_xml [$page_doc asXML -indent 1]

        if {$file_xml ne $page_xml} {
            error "DOM trees are not the same."
        }

        if {[string trim [$window page_title]] ne "Page I"} {
            error "page title should have been 'Page I'."
        }

        $file_doc delete
        $page_doc delete
        $norm     delete
        ::itcl::delete object $session

        return
    }
}

exit [[TestWebDriverPage #auto] run $::argv]

