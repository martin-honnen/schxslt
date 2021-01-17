<!-- Compile preprocessed Schematron to validation stylesheet -->
<xsl:transform version="2.0" xmlns="http://www.w3.org/1999/XSL/TransformAlias"
  xmlns:sch="http://purl.oclc.org/dsdl/schematron"
  xmlns:error="https://doi.org/10.5281/zenodo.1495494#error"
  xmlns:schxslt-api="https://doi.org/10.5281/zenodo.1495494#api"
  xmlns:schxslt="https://doi.org/10.5281/zenodo.1495494"
  xmlns:str="https://hiltonroscoe.com/ns/streamatron/v1"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

  <xsl:import href="api-3.0.xsl"/>

  <doc xmlns="http://www.oxygenxml.com/ns/doc/xsl">
    <desc>
      <p>Compile preprocessed Schematron to validation stylesheet</p>
    </desc>
    <param name="phase">Validation phase</param>
  </doc>

  <xsl:namespace-alias stylesheet-prefix="#default" result-prefix="xsl"/>
  <xsl:output indent="yes"/>

  <xsl:include href="functions.xsl"/>
  <xsl:include href="templates.xsl"/>
  <xsl:include href="../../version.xsl"/>

  <xsl:param name="phase" as="xs:string">#DEFAULT</xsl:param>

  <xsl:template match="/">
    <xsl:call-template name="schxslt:compile">
      <xsl:with-param name="schematron" as="element(sch:schema)" select="sch:schema"/>
    </xsl:call-template>
  </xsl:template>

  <xsl:template name="schxslt:compile">
    <xsl:param name="schematron" as="element(sch:schema)" required="yes"/>

    <xsl:variable name="effective-phase" select="schxslt:effective-phase($schematron, $phase)" as="xs:string"/>
    <xsl:variable name="active-patterns" select="schxslt:active-patterns($schematron, $effective-phase)" as="element(sch:pattern)+"/>

    <xsl:variable name="validation-stylesheet-body">
      <xsl:call-template name="schxslt:validation-stylesheet-body">
        <xsl:with-param name="patterns" as="element(sch:pattern)+" select="$active-patterns"/>
      </xsl:call-template>
    </xsl:variable>

    <transform version="{schxslt:xslt-version($schematron)}">
      <xsl:for-each select="$schematron/sch:ns">
        <xsl:namespace name="{@prefix}" select="@uri"/>
      </xsl:for-each>
      <xsl:sequence select="$schematron/@xml:base"/>

      <xsl:call-template name="schxslt:version"/>

      <xsl:call-template name="schxslt-api:validation-stylesheet-body-top-hook">
        <xsl:with-param name="schema" as="element(sch:schema)" select="$schematron"/>
      </xsl:call-template>

      <output indent="yes"/>
      <import-schema namespace="http://itl.nist.gov/ns/voting/1500-103/v1"
        schema-location="NIST_V0_cast_vote_records.xsd"/>
      <mode streamable="yes" use-accumulators="#all"/>

      <xsl:for-each select="$schematron//str:reference">
        <accumulator name="{@name}" as="node()?" initial-value="()" streamable="yes">
          <accumulator-rule match="{@context}" select="." phase="end" saxon:capture="yes"
            xmlns:saxon="http://saxon.sf.net/"/>
        </accumulator>
      </xsl:for-each>


      <xsl:sequence select="$schematron/xsl:key[not(preceding-sibling::sch:pattern)]"/>
      <xsl:sequence select="$schematron/xsl:function[not(preceding-sibling::sch:pattern)]"/>

      <!-- See https://github.com/dmj/schxslt/issues/25 -->
      <xsl:variable name="global-bindings" as="element(sch:let)*" select="($schematron/sch:let, $schematron/sch:phase[@id eq $effective-phase]/sch:let, $active-patterns/sch:let)"/>
      <xsl:call-template name="schxslt:check-multiply-defined">
        <xsl:with-param name="bindings" select="$global-bindings" as="element(sch:let)*"/>
      </xsl:call-template>

      <xsl:call-template name="schxslt:let-param">
        <xsl:with-param name="bindings" select="$schematron/sch:let"/>
      </xsl:call-template>

      <xsl:call-template name="schxslt:let-variable">
        <xsl:with-param name="bindings" select="($schematron/sch:phase[@id eq $effective-phase]/sch:let, $active-patterns/sch:let)"/>
      </xsl:call-template>

      <template match="/">
        <xsl:sequence select="$schematron/sch:phase[@id eq $effective-phase]/@xml:base"/>

        <xsl:call-template name="schxslt:let-variable">
          <xsl:with-param name="bindings" select="$schematron/sch:phase[@id eq $effective-phase]/sch:let"/>
        </xsl:call-template>

        <variable name="report" as="element(schxslt:report)">
          <schxslt:report>
            <fork>
              <xsl:for-each
                select="$validation-stylesheet-body/xsl:mode[@name[not(ends-with(., '-entry'))]]">
                <sequence>
                  <apply-templates select="." mode="{@name}-entry"/>
                </sequence>
              </xsl:for-each>
            </fork>
          </schxslt:report>
        </variable>

        <!-- Unwrap the intermediary report -->
        <variable name="schxslt:report" as="node()*">
          <for-each select="$report/schxslt:pattern">
            <sequence select="node()"/>
            <sequence select="$report/schxslt:rule[@pattern = current()/@id]/node()"/>
          </for-each>
        </variable>

        <xsl:call-template name="schxslt-api:report">
          <xsl:with-param name="schema" as="element(sch:schema)" select="$schematron"/>
          <xsl:with-param name="phase" as="xs:string" select="$effective-phase"/>
        </xsl:call-template>

      </template>

      <template match="text() | @*" mode="#all" priority="-10"/>
      <template match="*" mode="#all" priority="-10">
        <apply-templates mode="#current" select="@*"/>
        <apply-templates mode="#current"/>
      </template>

      <xsl:sequence select="$validation-stylesheet-body"/>

      <xsl:call-template name="schxslt-api:validation-stylesheet-body-bottom-hook">
        <xsl:with-param name="schema" as="element(sch:schema)" select="$schematron"/>
      </xsl:call-template>

    </transform>

  </xsl:template>

  <doc xmlns="http://www.oxygenxml.com/ns/doc/xsl">
    <desc>
      <p>Return rule template</p>
    </desc>
    <param name="mode">Template mode</param>
  </doc>
  <!-- handles no streaming rules (default) TODO FIX IT -->
  <xsl:template match="sch:rule[not(@str:streaming) or @str:streaming = ('on','off','inherit')]">
    <xsl:param name="mode" as="xs:string" required="yes"/>
    <xsl:variable name="modeExtension" select="if(@str:streaming='on') then '' else '-grounded'" />
    <xsl:apply-templates select="." mode="create-template-mode">
      <xsl:with-param name="mode" select="$mode || $modeExtension"/>
    </xsl:apply-templates>

    <xsl:call-template name="schxslt:check-multiply-defined">
      <xsl:with-param name="bindings" select="sch:let" as="element(sch:let)*"/>
    </xsl:call-template>
  </xsl:template>
  <!-- handles bursting -->
  <xsl:template match="sch:rule[@str:streaming = ('copy-of','snapshot')]">
    <xsl:param name="mode" as="xs:string" required="yes"/>

    <xsl:call-template name="schxslt:check-multiply-defined">
      <xsl:with-param name="bindings" select="sch:let" as="element(sch:let)*"/>
    </xsl:call-template>
    <xsl:variable name="groundedMode" select="$mode || '-grounded' || generate-id(.)"/>
    <xsl:apply-templates select="." mode="create-template-mode-switch">
      <xsl:with-param name="mode" select="$groundedMode"/>      
    </xsl:apply-templates>
    
      <template match="{@context}" priority="{count(following::sch:rule)}" mode="{$mode}">
        <param name="schxslt:isBursting" select="false()" tunnel="yes"/>
       
        <xsl:sequence select="(@xml:base, ../@xml:base)"/>

        <!-- Check if a context node was already matched by a rule of the current pattern. -->
        <param name="schxslt:rules" as="element(schxslt:rule)*"/>

        <choose>
          <when test="not($schxslt:isBursting)">
            <variable name="burstData" select="{@str:streaming}()" />          
            <apply-templates select="$burstData" mode="{$groundedMode}">          
              <with-param name="schxslt:rules" select="$schxslt:rules"/>
              <with-param name="schxslt:streamed-context" select="'{{generate-id()}}'"/>
            </apply-templates>
            <!-- rule rules again to catch any motionless streaming rules -->
            <apply-templates select="$burstData" mode="{$mode}">
              <with-param name="schxslt:isBursting" tunnel="yes" select="true()"/>
              <with-param name="schxslt:rules" select="$schxslt:rules"/>
              <with-param name="schxslt:streamed-context" select="'{{generate-id()}}'"/>
            </apply-templates>
          </when>
          <otherwise>
            <apply-templates mode="#current" />
          </otherwise>
        </choose>
      </template>      
    
  </xsl:template>

  <xsl:template match="sch:rule" mode="create-template-mode">
    <xsl:param name="mode" as="xs:string" required="yes"/>

    <xsl:call-template name="schxslt:check-multiply-defined">
      <xsl:with-param name="bindings" select="sch:let" as="element(sch:let)*"/>
    </xsl:call-template>

    <template match="{@context}" priority="{count(following::sch:rule)}" mode="{$mode}">
      <xsl:sequence select="(@xml:base, ../@xml:base)"/>

      <!-- Check if a context node was already matched by a rule of the current pattern. -->
      <param name="schxslt:rules" as="element(schxslt:rule)*"/>

      <xsl:for-each select="//str:reference">
        <variable name="{@name}" select="accumulator-after('{@name}')"/>
      </xsl:for-each>

      <xsl:call-template name="schxslt:let-variable">
        <xsl:with-param name="bindings" as="element(sch:let)*" select="sch:let"/>
      </xsl:call-template>      

      <choose>
        <when
          test="empty($schxslt:rules[@pattern = '{generate-id(..)}'][@context = generate-id(current())])">
          <schxslt:rule pattern="{generate-id(..)}@{{base-uri(.)}}">
            <xsl:call-template name="schxslt-api:fired-rule">
              <xsl:with-param name="rule" as="element(sch:rule)" select="."/>
            </xsl:call-template>
            <xsl:apply-templates select="sch:assert | sch:report"/>
          </schxslt:rule>
        </when>
        <otherwise>
          <schxslt:rule pattern="{generate-id(..)}@{{base-uri(.)}}">
            <xsl:call-template name="schxslt-api:suppressed-rule">
              <xsl:with-param name="rule" as="element(sch:rule)" select="."/>
            </xsl:call-template>
          </schxslt:rule>
        </otherwise>
      </choose>

      <next-match>
        <with-param name="schxslt:rules" as="element(schxslt:rule)*">
          <sequence select="$schxslt:rules"/>
          <schxslt:rule context="{{generate-id()}}" pattern="{generate-id(..)}"/>
        </with-param>
      </next-match>
    </template>

  </xsl:template>

  <xsl:template match="sch:rule" mode="create-template-mode-switch">
    <xsl:param name="mode" as="xs:string" required="yes"/>
            
    <xsl:call-template name="schxslt:check-multiply-defined">
      <xsl:with-param name="bindings" select="sch:let" as="element(sch:let)*"/>
    </xsl:call-template>

    <template match="{@context}" priority="{count(following::sch:rule)}" mode="{$mode}">      
      <xsl:sequence select="(@xml:base, ../@xml:base)"/>

      <!-- Check if a context node was already matched by a rule of the current pattern. -->
      <param name="schxslt:rules" as="element(schxslt:rule)*"/>
      <param name="schxslt:streamed-context"/>
      
      <xsl:for-each select="//str:reference">
        <variable name="{@name}" select="accumulator-after('{@name}')"/>
      </xsl:for-each>

      <xsl:call-template name="schxslt:let-variable">
        <xsl:with-param name="bindings" as="element(sch:let)*" select="sch:let"/>
      </xsl:call-template>

      <choose>
        <when test="empty($schxslt:rules[@pattern = '{generate-id(..)}'][@context = $schxslt:streamed-context])">
          <schxslt:rule pattern="{generate-id(..)}@{{base-uri(.)}}">
            <xsl:call-template name="schxslt-api:fired-rule">
              <xsl:with-param name="rule" as="element(sch:rule)" select="."/>
            </xsl:call-template>
            <xsl:apply-templates select="sch:assert | sch:report"/>
          </schxslt:rule>
        </when>
        <otherwise>
          <schxslt:rule pattern="{generate-id(..)}@{{base-uri(.)}}">
            <xsl:call-template name="schxslt-api:suppressed-rule">
              <xsl:with-param name="rule" as="element(sch:rule)" select="."/>
            </xsl:call-template>
          </schxslt:rule>
        </otherwise>
      </choose>

      <next-match>
        <with-param name="schxslt:rules" as="element(schxslt:rule)*">
          <sequence select="$schxslt:rules"/>
          <schxslt:rule context="{{$schxslt:streamed-context}}" pattern="{generate-id(..)}"/>
        </with-param>
      </next-match>
    </template>

  </xsl:template>

  <doc xmlns="http://www.oxygenxml.com/ns/doc/xsl">
    <desc>
      <p>Return body of validation stylesheet</p>
    </desc>
    <param name="patterns">Sequence of active patterns</param>
  </doc>
  <xsl:template name="schxslt:validation-stylesheet-body">
    <xsl:param name="patterns" as="element(sch:pattern)+"/>

    <xsl:for-each-group select="$patterns" group-by="string-join((base-uri(.), @documents), '&lt;')">
      <xsl:variable name="mode" as="xs:string" select="generate-id()"/>
      <xsl:variable name="baseUri" as="xs:anyURI" select="base-uri(.)"/>

      <mode name="{$mode}" streamable="yes" use-accumulators="#all"/>
      <mode name="{$mode}-entry" streamable="yes" use-accumulators="#all"/>

      <template match="/" mode="{$mode}-entry">
        <xsl:sequence select="@xml:base"/>

        <xsl:call-template name="schxslt:let-variable">
          <xsl:with-param name="bindings" as="element(sch:let)*" select="sch:let"/>
        </xsl:call-template>

        <variable name="documents" as="item()+">
          <xsl:choose>
            <xsl:when test="@documents">
              <for-each select="{@documents}">
                <sequence select="document(resolve-uri(., '{$baseUri}'))"/>
              </for-each>
            </xsl:when>
            <xsl:otherwise>
              <sequence select="/"/>
            </xsl:otherwise>
          </xsl:choose>
        </variable>

        <for-each select="$documents">
          <xsl:for-each select="current-group()">
            <schxslt:pattern id="{generate-id()}@{{base-uri(.)}}">
              <xsl:call-template name="schxslt-api:active-pattern">
                <xsl:with-param name="pattern" as="element(sch:pattern)" select="."/>
              </xsl:call-template>
            </schxslt:pattern>
          </xsl:for-each>

          <apply-templates mode="{$mode}" select="."/>        
        </for-each>
        <!-- I don't understand the doc stuff, so putting this here for now -->
        <!-- move somewhere else so order of fired-rules makes more sense? -->
        <xsl:for-each select="//str:reference[@apply-rules='yes']">
          <apply-templates select="accumulator-after('{@name}')" mode="{$mode}-grounded" />
        </xsl:for-each>

      </template>

      <xsl:apply-templates select="current-group()/sch:rule">
        <xsl:with-param name="mode" as="xs:string" select="$mode"/>
      </xsl:apply-templates>

    </xsl:for-each-group>

  </xsl:template>

</xsl:transform>
