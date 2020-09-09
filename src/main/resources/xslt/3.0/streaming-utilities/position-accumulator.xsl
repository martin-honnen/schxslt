<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:map="http://www.w3.org/2005/xpath-functions/map"
    xmlns:mf="http://example.com/mf"
    exclude-result-prefixes="#all"
    version="3.0">
    
    <xsl:function name="mf:path" as="xs:string" streamability="inspection" visibility="public">
        <xsl:param name="node" as="node()"/>
        <xsl:sequence
            select="$node/ancestor-or-self::*
                    !(
                       'Q{' || namespace-uri-from-QName(node-name()) || '}' || local-name() || 
                       '[' || 
                       accumulator-before('position')[last() - 1](node-name())
                       || ']'
                     ) => string-join('/')"/>
    </xsl:function>
    
    <xsl:function name="mf:position" as="xs:integer" streamability="inspection" visibility="public">
        <xsl:param name="node" as="node()"/>
        <xsl:sequence select="$node!accumulator-before('position')[last() - 1](node-name())"/>
    </xsl:function>
    
    <xsl:accumulator name="position" as="map(xs:QName, xs:integer)*" initial-value="map{}" streamable="yes">
        <xsl:accumulator-rule match="*"
          select="let $cm := $value[last()],
                      $node-name := node-name()
                  return
                      if (map:contains($cm, $node-name))
                      then ($value[position() lt last()], map:put($cm, $node-name, $cm($node-name) + 1), map{})
                      else ($value[position() lt last()], map:put($cm, $node-name, 1), map {})"/>
        <xsl:accumulator-rule match="*" phase="end"
          select="$value[position() lt last()]"/>
    </xsl:accumulator>
    
</xsl:stylesheet>