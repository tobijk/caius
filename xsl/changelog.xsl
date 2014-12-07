<?xml version="1.0" encoding="UTF-8"?>
<!--
 -
 - The MIT License (MIT)
 -
 - Copyright (c) 2014 Caius Project
 -
 - Permission is hereby granted, free of charge, to any person obtaining a copy
 - of this software and associated documentation files (the "Software"), to deal
 - in the Software without restriction, including without limitation the rights
 - to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 - copies of the Software, and to permit persons to whom the Software is
 - furnished to do so, subject to the following conditions:
 -
 - The above copyright notice and this permission notice shall be included in
 - all copies or substantial portions of the Software.
 -
 - THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 - IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 - FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 - AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 - LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 - OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 - THE SOFTWARE.
 -
-->
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

  <xsl:output method="text" indent="no" omit-xml-declaration="yes"/>

  <xsl:strip-space elements="
    changelog
    release
    changeset"/>

  <xsl:template match="/changelog">
    <xsl:apply-templates/>
  </xsl:template>

  <xsl:template match="release">
    <!-- section header -->
    <xsl:value-of select="normalize-space(/changelog/@source)"/>
    <xsl:text> (</xsl:text>
    <xsl:value-of select="@version"/>
    <xsl:text>-</xsl:text>
    <xsl:value-of select="@revision"/>
    <xsl:text>) unstable; urgency=low</xsl:text>
    <xsl:text>&#x0a;&#x0a;</xsl:text>

    <!-- section content -->
    <xsl:apply-templates/>
    <xsl:text>&#x0a;</xsl:text>

    <!-- section trailer -->
    <xsl:text> -- </xsl:text>
    <xsl:value-of select="@maintainer"/>
    <xsl:text> &lt;</xsl:text>
    <xsl:value-of select="normalize-space(@email)"/>
    <xsl:text>&gt;  </xsl:text>
    <xsl:value-of select="@date"/>
    <xsl:text>&#x0a;&#x0a;</xsl:text>
  </xsl:template>

  <xsl:template match="comment()">
    <!-- drop comments -->
  </xsl:template>

  <xsl:template match="changeset">
    <xsl:apply-templates/>
    <xsl:if test="following-sibling::changeset">
      <xsl:text>&#x0a;</xsl:text>
    </xsl:if>
  </xsl:template>

  <xsl:template match="li">
    <xsl:text>  * </xsl:text>
    <xsl:value-of select="normalize-space(.)"/>
    <xsl:text>&#x0a;</xsl:text>
  </xsl:template>

  <xsl:template match="*|text()">
    <!-- cut -->
  </xsl:template>

</xsl:stylesheet>
