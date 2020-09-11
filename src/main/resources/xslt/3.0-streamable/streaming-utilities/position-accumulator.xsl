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
            select="$node/ancestor-or-self::node()
                    !(
                       mf:step(.) || 
                       mf:positional-predicate(.)
                     ) => string-join('/')"/>
    </xsl:function>

  <xsl:function name="mf:step" as="xs:string" streamability="inspection" visibility="public">
    <xsl:param name="node" as="node()"/>
    <xsl:sequence select="if ($node instance of element())
                          then $node!('Q{' || namespace-uri-from-QName(node-name()) || '}' || local-name())
                          else if ($node instance of text())
                          then mf:node-type($node)
                          else if ($node instance of comment())
                          then mf:node-type($node)
                          else if ($node instance of processing-instruction())
                          then 'processing-instruction(' || node-name($node) || ')'
                          else if ($node instance of document-node())
                          then ''
                          else error(QName('http://example.com/mf', 'type-error'), 'Unknown node type')"/>
  </xsl:function>

  <xsl:function name="mf:positional-predicate" as="xs:string" streamability="inspection" visibility="public">
    <xsl:param name="node" as="node()"/>
    <xsl:sequence select="if ($node instance of document-node())
                          then ''
                          else $node ! ('[' || mf:position(.) || ']')"/>
  </xsl:function>

    <xsl:variable name="mf:empty-child-nodes-map" as="map(xs:string, map(xs:QName, xs:integer)?)"
                select="map { 'element()' : map {}, 'text()' : map{ QName('', 'text') : 0 }, 'comment()' : map{ QName('', 'comment') : 0 }, 'processing-instruction()' : map{} }"/>
    
    <xsl:function name="mf:position" as="xs:integer" streamability="inspection" visibility="public">
        <xsl:param name="node" as="node()"/>
        <xsl:sequence select="if ($node instance of element())
                              then $node!accumulator-before('position')[last() - 1]('element()')(node-name())
                              else if ($node instance of text())
                              then $node!accumulator-before('position')[last()]('text()')(QName('', 'text'))
                              else if ($node instance of comment())
                              then $node!accumulator-before('position')[last()]('comment()')(QName('', 'comment'))
                              else if ($node instance of processing-instruction())
                              then $node!accumulator-before('position')[last()]('processing-instruction()')(node-name())
                              else error(QName('http://example.com/mf', 'type-error'), 'Unknown node type')"/>
    </xsl:function>
    
    <xsl:accumulator name="position" as="map(xs:string, map(xs:QName, xs:integer))*" initial-value="map{}" streamable="yes">
        <xsl:accumulator-rule match="document-node()" select="$mf:empty-child-nodes-map"/>
        <xsl:accumulator-rule match="*"
          select="let $cm := $value[last()],
                      $cem := $cm('element()'),
                      $node-name := node-name()
                  return
                      if (map:contains($cem, $node-name))
                      then ($value[position() lt last()], map:put($cm, 'element()', map:put($cem, $node-name, $cem($node-name) + 1)), $mf:empty-child-nodes-map)
                      else ($value[position() lt last()], map:put($cm, 'element()', map:put($cem, $node-name, 1)), $mf:empty-child-nodes-map)"/>
        <xsl:accumulator-rule match="text()"
          select="let $cm := $value[last()],
                      $ctm := $cm('text()'),
                      $node-name := QName('', 'text')
                  return
                      if (map:contains($ctm, $node-name))
                      then ($value[position() lt last()], map:put($cm, 'text()', map:put($ctm, $node-name, $ctm($node-name) + 1)))
                      else ($value[position() lt last()], map:put($cm, 'text()', map:put($ctm, $node-name, 1)))"/>
        <xsl:accumulator-rule match="comment()"
          select="let $cm := $value[last()],
                      $ccm := $cm('comment()'),
                      $node-name := QName('', 'comment')
                  return
                      if (map:contains($ccm, $node-name))
                      then ($value[position() lt last()], map:put($cm, 'comment()', map:put($ccm, $node-name, $ccm($node-name) + 1)))
                      else ($value[position() lt last()], map:put($cm, 'comment()', map:put($ccm, $node-name, 1)))"/>
        <xsl:accumulator-rule match="processing-instruction()"
          select="let $cm := $value[last()],
                      $cpm := $cm('processing-instruction()'),
                      $node-name := node-name()
                  return
                      if (map:contains($cpm, $node-name))
                      then ($value[position() lt last()], map:put($cm, 'processing-instruction()', map:put($cpm, $node-name, $cpm($node-name) + 1)))
                      else ($value[position() lt last()], map:put($cm, 'processing-instruction()', map:put($cpm, $node-name, 1)))"/>
        <xsl:accumulator-rule match="*" phase="end"
          select="$value[position() lt last()]"/>
    </xsl:accumulator>

    <xsl:function name="mf:node-type" as="xs:string" streamability="inspection" visibility="public">
      <xsl:param name="node" as="node()"/>
      <xsl:sequence
        select="if ($node instance of document-node())
                then 'document-node()'
                else if ($node instance of element())
                then 'element()'
                else if ($node instance of text())
                then 'text()'
                else if ($node instance of comment())
                then 'comment()'
                else if ($node instance of processing-instruction())
                then 'processing-instruction()'
                else error(QName('http://example.com/mf', 'type-error'), 'Unknown node type')"/>
    </xsl:function>
    
</xsl:stylesheet>