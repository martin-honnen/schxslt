<xsl:transform version="2.0"
               xmlns:report="tag:dmaus@dmaus.name,2020:Example:Report"
               xmlns:runtime="http://www.w3.org/1999/XSL/TransformAlias"
               xmlns:sch="http://purl.oclc.org/dsdl/schematron"
               xmlns:schxslt="https://doi.org/10.5281/zenodo.1495494"
               xmlns:schxslt-api="https://doi.org/10.5281/zenodo.1495494#api"
               xmlns:xs="http://www.w3.org/2001/XMLSchema"
               xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

  <xsl:import href="compile-for-svrl.xsl"/>

  <xsl:namespace-alias stylesheet-prefix="runtime" result-prefix="xsl"/>

  <xsl:template name="schxslt-api:active-pattern">
    <xsl:param name="pattern" as="element(sch:pattern)" required="yes"/>
  </xsl:template>

  <xsl:template name="schxslt-api:fired-rule">
    <xsl:param name="rule" as="element(sch:rule)" required="yes"/>
  </xsl:template>

</xsl:transform>