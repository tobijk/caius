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
