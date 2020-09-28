<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:map="http://www.w3.org/2005/xpath-functions/map"
    xmlns:str="https://hiltonroscoe.com/ns/streamatron/v1"
    exclude-result-prefixes="#all"
    expand-text="yes"
    version="3.0">

  <xsl:include href="position-accumulator.xsl"/>

  <xsl:mode on-no-match="shallow-copy" streamable="yes" use-accumulators="position"/>

  <xsl:template match="node()">
    <xsl:comment>{str:node-type(.)}: {accumulator-before('position')[last()] => serialize(map { 'method' : 'adaptive' })}</xsl:comment>
    <xsl:next-match/>
  </xsl:template>

</xsl:stylesheet>