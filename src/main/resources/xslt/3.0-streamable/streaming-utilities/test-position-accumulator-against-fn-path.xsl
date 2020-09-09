<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:map="http://www.w3.org/2005/xpath-functions/map"
    xmlns:mf="http://example.com/mf"
    exclude-result-prefixes="#all"
    expand-text="yes"
    version="3.0">
    
    <xsl:include href="position-accumulator.xsl"/>
    
    <xsl:mode on-no-match="shallow-copy" streamable="no" use-accumulators="position"/>
    
    <xsl:template match="*">
        <xsl:variable name="pos" as="xs:integer">
            <xsl:number/>
        </xsl:variable>
        <xsl:assert test="path() eq '/' || mf:path(.)">{path()} ne {'/' || mf:path(.)}</xsl:assert>
        <xsl:next-match/>
    </xsl:template>
    
</xsl:stylesheet>