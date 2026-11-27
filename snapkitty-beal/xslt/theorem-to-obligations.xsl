<?xml version="1.0" encoding="UTF-8"?>
<!-- Copyright (C) 2026 AHMADALIPARR -->
<!-- SPDX-License-Identifier: AGPL-3.0-only -->
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:t="urn:snapkitty:theorem:1" exclude-result-prefixes="t">
  <xsl:output method="xml" indent="yes" encoding="UTF-8"/>
  <xsl:template match="/">
    <obligation-set theorem="{t:theorem-source/@id}" source-version="{t:theorem-source/@version}">
      <xsl:for-each select="t:theorem-source/t:holes/t:hole">
        <obligation id="{@id}" kind="{@kind}" blocks="{@blocks}" status="open"/>
      </xsl:for-each>
      <dependency from="BEAL-PROOF" to="BEAL-FORMALIZATION" relation="formalizes"/>
      <dependency from="BEAL-PROOF" to="FLT-DESCENT-001" relation="supports-specialization"/>
      <dependency from="PROVENANCE-REVIEW" to="BEAL-PROOF" relation="grounds-claim"/>
    </obligation-set>
  </xsl:template>
</xsl:stylesheet>
