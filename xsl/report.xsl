<?xml version="1.0" encoding="UTF-8"?>
<!--
 -
 - Caius Functional Testing Framework
 -
 - Copyright (c) 2013, Tobias Koch <tobias.koch@gmail.com>
 - All rights reserved.
 -
 - Redistribution and use in source and binary forms, with or without modifi-
 - cation, are permitted provided that the following conditions are met:
 -
 - 1. Redistributions of source code must retain the above copyright notice,
 -    this list of conditions and the following disclaimer.
 -
 - 2. Redistributions in binary form must reproduce the above copyright notice,
 -    this list of conditions and the following disclaimer in the documentation
 -    and/or other materials provided with the distribution.
 -
 - THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDER ``AS IS'' AND ANY EXPRESS
 - OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
 - OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN
 - NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
 - INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUD-
 - ING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF
 - USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 - THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUD-
 - ING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFT-
 - WARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 -
-->
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
    <xsl:output method="xml" indent="yes" encoding="UTF-8" omit-xml-declaration="yes"/>

    <xsl:template match="/">
        <html lang="en" dir="ltr">
            <head>
                <meta http-equiv="Content-Type" content="text/html; charset=UTF-8"/>
                <meta name="viewport" content="width=device-width,initial-scale=1.0" />
                <meta name="generator" content="Caius Test Report Generator"/>

                <title>Test Report</title>

                <style type="text/css">

body {
    font-family: sans-serif;
    font-size: 14px;
    background-color: #ddddcc;
}

.l1 {
    font-weight: bold;
    padding: 10px;
    margin: 2px 0px 1px 0px;
    overflow: auto;
}

.linkify {
    cursor: pointer;
}

.l2 {
    font-weight: normal;
    padding: 5px 10px 5px 10px;
    margin: 1px 10px;
    overflow: auto;
}

.testset-fail {
    background-color: #880707;
    color: white;
}

.testset-pass {
    background-color: #116611;
    color: white;
}

.fail {
    background-color: #aa1111;
    color: white;
}

.pass {
    background-color: #449944;
    color: white;
}

.timeout {
    background-color: #b1610c;
    color: white;
}

.info {
    border: 1px dotted #aaaaaa;
    background-color: #ffffff;
}

.verbatim {
    font-family: monospace;
    white-space: pre-wrap;
    padding: 10px;
}

a {
    color: white;
}

a.action-button {
    text-decoration: underline;
    cursor: pointer;
}

ul.list {
    margin: 0;
    padding: 0;
    float: right;
}

ul.list li {
    display: inline-block;
    margin: 0px 5px 0px 10px;
}

li.count {
    width: 5em;
    text-align: right;
}

span.action {
    color: #bbbbbb;
}

                </style>
                <script type="text/javascript">
                    <xsl:text disable-output-escaping="yes">
                        &lt;!--
                    </xsl:text>

                    <xsl:text disable-output-escaping="yes">
                    function toggle_visibility(target)
                    {
                        var visibility = "none";
                        var el = document.getElementById(target);

                        if(el.style.display == "none")
                        {
                            visibility = "block";
                        }

                        el.style.display = visibility;
                    }

                    function toggle_expand(target_list)
                    {
                        for(var i = 0; i &lt; target_list.length; i++)
                        {
                            var visibility = "none";
                            var el = document.getElementById(target_list[i]);

                            if(el.style.display == "none")
                            {
                                visibility = "block";
                            }

                            el.style.display = visibility;

                            if(visibility == "none")
                            {
                                el = el.nextElementSibling || el.nextSibling;

                                while(el != null &amp;&amp; el.className != undefined &amp;&amp;
                                        el.className.split(' ')[1] == "info")
                                {
                                    if(el.tagName == undefined) { continue };

                                    el.style.display = visibility;
                                    el = el.nextElementSibling || el.nextSibling;
                                }
                            }
                        }
                    }
                    </xsl:text>

                    <xsl:text disable-output-escaping="yes">
                        // --&gt;
                    </xsl:text>
                </script>
            </head>
            <body>
                <xsl:apply-templates/>
            </body>
        </html>
    </xsl:template>

    <xsl:template match="testsuite">
        <xsl:apply-templates/>
    </xsl:template>

    <xsl:template match="testset">
        <xsl:variable name="testset.total_count" select="count(test)"/>
        <xsl:variable name="testset.fail_count"  select="count(test[@verdict != 'PASS'])"/>
        <xsl:variable name="testset.pass_count"  select="count(test[@verdict = 'PASS'])"/>

        <xsl:variable name="testset.class">
            <xsl:choose>
                <xsl:when test="$testset.fail_count &gt; 0">
                    <xsl:text>testset-fail</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:text>testset-pass</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>

        <xsl:variable name="testset.tests">
            <xsl:text>[</xsl:text>
            <xsl:for-each select="test">
                <xsl:text>'</xsl:text>
                <xsl:value-of select="concat('test::', generate-id(.))"/>
                <xsl:text>'</xsl:text>
                <xsl:if test="position() != last()">
                    <xsl:text>,</xsl:text>
                </xsl:if>
            </xsl:for-each>
            <xsl:text>]</xsl:text>
        </xsl:variable>

        <div id="testset::{generate-id(.)}" class="l1 {$testset.class} linkify"
                onClick="toggle_expand({$testset.tests})">
            <b><u><xsl:value-of select="@name"/></u></b>
            <ul class="list">
                <li class="count">
                    <xsl:value-of select="$testset.pass_count"/>  pass
                </li>
                <li class="count">
                    <xsl:value-of select="$testset.fail_count"/>  fail
                </li>
                <li class="count">
                    <xsl:value-of select="$testset.total_count"/> total
                </li>
            </ul>
        </div>

        <xsl:apply-templates/>
    </xsl:template>

    <xsl:template match="test">
        <xsl:variable name="test.class">
            <xsl:value-of select="translate(@verdict, 'PASSFAILTIMEOUT', 'passfailtimeout')"/>
        </xsl:variable>

        <xsl:variable name="test.description.class">
            <xsl:choose>
                <xsl:when test="description">
                    <xsl:text>active</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:text>inactive</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>

        <div id="test::{generate-id(.)}" class="l2 {$test.class}" style="display: none;">
            <xsl:value-of select="@name"/>
            <ul class="list">
                <li>
                    <xsl:choose>
                        <xsl:when test="description">
                            <a class="action-button" onClick="toggle_visibility('test::{
                                generate-id(.)}::description')">description</a>
                        </xsl:when>
                        <xsl:otherwise>
                            <span class="action">description</span>
                        </xsl:otherwise>
                    </xsl:choose>
                </li>
                <li>
                    <xsl:choose>
                        <xsl:when test="log">
                            <a class="action-button" onClick="toggle_visibility('test::{
                                generate-id(.)}::log')">log</a>
                        </xsl:when>
                        <xsl:otherwise>
                            <span class="action">log</span>
                        </xsl:otherwise>
                    </xsl:choose>
                </li>
                <li>
                    <xsl:choose>
                        <xsl:when test="error">
                            <a class="action-button" onClick="toggle_visibility('test::{
                                generate-id(.)}::error')">error</a>
                        </xsl:when>
                        <xsl:otherwise>
                            <span class="action">error</span>
                        </xsl:otherwise>
                    </xsl:choose>
                </li>
                <li>
                    <xsl:choose>
                        <xsl:when test="ancestor::testset/@artifacts_path">
                            <a href="{ancestor::testset/@artifacts_path}">artifacts</a>
                        </xsl:when>
                        <xsl:otherwise>
                            <span class="action">artifacts</span>
                        </xsl:otherwise>
                    </xsl:choose>
                </li>
                <li>
                    <xsl:value-of select="@time"/>
                </li>
            </ul>
        </div>

        <xsl:if test="description">
            <div id="test::{generate-id(.)}::description" class="l2 info" style="display: none;">
                <xsl:comment>//</xsl:comment>
                <xsl:copy-of select="description/*"/>
            </div>
        </xsl:if>

        <xsl:if test="log">
            <div id="test::{generate-id(.)}::log" class="l2 info verbatim" style="display: none;">
                <xsl:comment>//</xsl:comment>
                <xsl:value-of select="log"/>
            </div>
        </xsl:if>

        <xsl:if test="error">
            <div id="test::{generate-id(.)}::error" class="l2 info verbatim" style="display: none;">
                <xsl:comment>//</xsl:comment>
                <xsl:value-of select="error"/>
            </div>
        </xsl:if>
    </xsl:template>

</xsl:stylesheet>
