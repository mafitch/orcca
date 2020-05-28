<?xml version='1.0'?> <!-- As XML file -->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">


<!-- Thin layer on MathBook XML -->
<xsl:import href="c:/bin/mathbook/xsl/mathbook-latex.xsl" />


<!-- Intend output for rendering by xelatex -->
<xsl:output method="text" />


<!-- Omit objectives, CCOGs, worksheets -->
<xsl:template match="objectives" />
<xsl:template match="appendix[@xml:id='appendix-ccogs']" />
<xsl:template match="worksheet" />


<!-- Omit alternative video lessons; important to increment counter -->
<xsl:template match="figure[contains(child::caption,'Alternative Video Lesson')]">
    <xsl:text>\stepcounter{cthm}&#xa;&#xa;</xsl:text>
</xsl:template>


<!-- Omit solutions/answers -->
<xsl:template match="solutions"/>


<!-- This version for print -->
<!-- <xsl:param name="latex.preamble.early" select="concat(document('latex-preamble/latex.preamble.xml')//latex-preamble-early, document('latex-preamble/print.preamble.xml')//latex-preamble-early)" />
<xsl:param name="latex.preamble.late" select="concat(document('latex-preamble/latex.preamble.xml')//latex-preamble-late, document('latex-preamble/print.preamble.xml')//latex-preamble-late)" /> -->

<!-- This version has color, etc -->
<xsl:param name="latex.preamble.early" select="document('latex-preamble/latex.preamble.xml')//latex-preamble-early" />
<xsl:param name="latex.preamble.late" select="document('latex-preamble/latex.preamble.xml')//latex-preamble-late" />
    


<!-- Temporary page break option -->
<xsl:template match="newpage">
  <xsl:text>\newpage%&#xa;</xsl:text>
</xsl:template>


<!--If all exercises are webwork, and if they all open with the same p, then print that p after the introduction. -->
<!--Later, in each such exercise statement, ignore that p -->
<!-- Exercise Group -->
<!-- We interrupt a run of exercises with short commentary, -->
<!-- typically instructions for a list of similar exercises -->
<!-- Commentary goes in an introduction and/or conclusion   -->
<!-- When we point to these, we use custom hypertarget, etc -->
<xsl:template match="exercisegroup[count(exercise)>1][not(exercise[not(webwork-reps)])][exercise/webwork-reps][count(exercise/webwork-reps/static/statement[not(p[1] = ancestor::exercise/preceding-sibling::exercise/webwork-reps/static/statement/p[1])]) = 1]">
    <xsl:text>\par\medskip\noindent%&#xa;</xsl:text>
    <xsl:if test="title">
        <xsl:text>\textbf{</xsl:text>
        <xsl:apply-templates select="." mode="title-full" />
        <xsl:text>}\space\space</xsl:text>
    </xsl:if>
    <xsl:if test="@xml:id">
        <xsl:apply-templates select="." mode="label"/>
    </xsl:if>
    <xsl:text>%&#xa;</xsl:text>
    <xsl:if test="not(title)">
        <xsl:text>\hrulefill\\%&#xa;</xsl:text>
    </xsl:if>
    <xsl:apply-templates select="introduction" />
    <xsl:apply-templates select="exercise[1]/webwork-reps/static/statement/p[1]" />
    <xsl:choose>
        <xsl:when test="not(@cols) or (@cols = 1)">
            <xsl:text>\begin{exercisegroup}&#xa;</xsl:text>
        </xsl:when>
        <xsl:when test="@cols = 2 or @cols = 3 or @cols = 4 or @cols = 5 or @cols = 6">
            <xsl:text>\begin{exercisegroupcol}</xsl:text>
            <xsl:text>{</xsl:text>
            <xsl:value-of select="@cols"/>
            <xsl:text>}&#xa;</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:message terminate="yes">MBX:ERROR: invalid value <xsl:value-of select="@cols" /> for cols attribute of exercisegroup</xsl:message>
        </xsl:otherwise>
    </xsl:choose>
    <!-- an exercisegroup can only appear in an "exercises" division,    -->
    <!-- the template for exercises//exercise will consult switches for  -->
    <!-- visibility of components when born (not doing "solutions" here) -->
    <xsl:apply-templates select="exercise"/>
    <xsl:choose>
        <xsl:when test="not(@cols) or (@cols = 1)">
            <xsl:text>\end{exercisegroup}&#xa;</xsl:text>
        </xsl:when>
        <xsl:when test="@cols = 2 or @cols = 3 or @cols = 4 or @cols = 5 or @cols = 6">
            <xsl:text>\end{exercisegroupcol}&#xa;</xsl:text>
        </xsl:when>
    </xsl:choose>
    <xsl:if test="conclusion">
        <xsl:text>\par\noindent%&#xa;</xsl:text>
        <xsl:apply-templates select="conclusion" />
    </xsl:if>
    <xsl:text>\par\medskip\noindent&#xa;</xsl:text>
</xsl:template>

<xsl:template match="statement[ancestor::webwork-reps][count(ancestor::exercisegroup/exercise)>1][count(ancestor::exercisegroup/exercise/webwork-reps/static/statement[not(p[1] = ancestor::exercise/preceding-sibling::exercise/webwork-reps/static/statement/p[1])]) = 1]">
    <xsl:apply-templates select="*[not(self::p and position()=1)]" />
</xsl:template>

<!-- When the first common p was moved in exercisegroup statements above, we need the second (new first) p to *not* be preceded by a \par -->
<xsl:template match="p[position()=2][ancestor::webwork-reps][parent::statement][count(ancestor::exercisegroup/exercise/webwork-reps/static/statement[not(p[1] = ancestor::exercise/preceding-sibling::exercise/webwork-reps/static/statement/p[1])]) = 1]">
    <xsl:apply-templates select="." mode="label" />
    <xsl:text>%&#xa;</xsl:text>
    <xsl:apply-templates />
    <xsl:text>%&#xa;</xsl:text>
</xsl:template>

<!-- Except when the above is only containing an answer blank and nothing else... -->
<xsl:template match="p[not(normalize-space(text()))][count(fillin)=1 and count(*)=1][not(parent::li)]|p[not(normalize-space(text()))][count(fillin)=1 and count(*)=1][parent::li][preceding-sibling::*]" />


<!-- For an ol that was in a webwork that was authored in PTX source, -->
<!-- if there was a @cols, it has not survived the extraction. So go  -->
<!-- looking for the @cols from the authored source.                  -->
<xsl:template match="ol[ancestor::webwork-reps/authored]">
    <xsl:choose>
        <xsl:when test="not(ancestor::ol or ancestor::ul or ancestor::dl or parent::objectives or parent::outcomes)">
            <xsl:call-template name="leave-vertical-mode" />
        </xsl:when>
        <xsl:otherwise>
            <xsl:text>%&#xa;</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
    <!-- what number ol is this in static output? -->
    <xsl:variable name="nth-ol">
        <xsl:number from="static" level="any"/>
    </xsl:variable>
    <!-- get all the ol's from the authored -->
    <xsl:variable name="authored-ols" select="ancestor::webwork-reps/authored//ol"/>
    <!-- find that same number ol in authored source and get its @cols, if that exists -->
    <xsl:variable name="cols">
        <xsl:choose>
            <xsl:when test="$authored-ols[position()=$nth-ol]/@cols">
                <xsl:value-of select="$authored-ols[position()=$nth-ol]/@cols"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>1</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:if test="$cols != '1'">
        <xsl:text>\begin{multicols}{</xsl:text>
        <xsl:value-of select="$cols" />
        <xsl:text>}&#xa;</xsl:text>
    </xsl:if>
    <xsl:text>\begin{enumerate}</xsl:text>
    <!-- override LaTeX defaults as indicated -->
    <xsl:if test="@label or ancestor::exercises or ancestor::worksheet or ancestor::reading-questions or ancestor::references">
        <xsl:text>[label=</xsl:text>
        <xsl:apply-templates select="." mode="latex-list-label" />
        <xsl:text>]</xsl:text>
    </xsl:if>
    <xsl:text>&#xa;</xsl:text>
     <xsl:apply-templates />
    <xsl:text>\end{enumerate}&#xa;</xsl:text>
    <xsl:if test="$cols != '1'">
        <xsl:text>\end{multicols}&#xa;</xsl:text>
    </xsl:if>
</xsl:template>


</xsl:stylesheet>
