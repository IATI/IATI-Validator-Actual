<?xml version="1.0" encoding="UTF-8"?>

<xsl:stylesheet version='3.0' xmlns:xsl='http://www.w3.org/1999/XSL/Transform'
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:me="http://iati.me"
  xmlns:functx="http://www.functx.com"
  exclude-result-prefixes="xs functx"
  expand-text="yes">

  <xsl:template match="period" mode="rules" priority="8.6">
    
    <xsl:if test="period-start/@iso-date gt period-end/@iso-date">
      <me:feedback type="danger" class="performance" id="8.6.1">
        <me:src ref="iati" versions="any"/>
        <me:message>The start of the period is after the end of the period.</me:message>
      </me:feedback>
    </xsl:if>
    
    <xsl:next-match/>
  </xsl:template>

  <xsl:template match="budget|total-budget|total-expenditure|recipient-org-budget|recipient-country-budget|recipient-region-budget|planned-disbursement" mode="rules" priority="8.6">
    
    <xsl:if test="period-start/@iso-date gt period-end/@iso-date">
      <me:feedback type="danger" class="financial" id="8.6.3">
        <me:src ref="iati" versions="any"/>
        <me:message>The start of the period is after the end of the period.</me:message>
      </me:feedback>
    </xsl:if>
    
    <xsl:next-match/>
  </xsl:template>
</xsl:stylesheet>
