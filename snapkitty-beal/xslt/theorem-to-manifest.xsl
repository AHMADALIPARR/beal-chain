<?xml version="1.0" encoding="UTF-8"?>
<!-- Copyright (C) 2026 AHMADALIPARR -->
<!-- SPDX-License-Identifier: AGPL-3.0-only -->
<!-- Deterministic XML-to-manifest transform. Reads the canonical spec and
     emits a manifest listing the theorem and its open holes. -->
<xsl:stylesheet version="1.0"
 xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
 xmlns:t="urn:snapkitty:theorem:1">
 <xsl:output method="xml" indent="yes" encoding="UTF-8"/>
 <xsl:template match="/">
  <manifest theorem="{t:theorem-source/@id}"
    version="{t:theorem-source/@version}"
    status="{t:theorem-source/@status}"
    logic="{t:theorem-source/@logic}">
   <xsl:for-each select="t:theorem-source/t:holes/t:hole">
    <obligation id="{@id}" kind="{@kind}" blocks="{@blocks}" status="open"/>
   </xsl:for-each>
  </manifest>
 </xsl:template>
</xsl:stylesheet>
