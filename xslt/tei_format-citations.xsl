<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:tss="http://www.thirdstreetsoftware.com/SenteXML-1.0"
    xmlns:tei="http://www.tei-c.org/ns/1.0" 
    xmlns:html="http://www.w3.org/1999/xhtml"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:till="http://www.sitzextase.de"
    xmlns:functx="http://www.functx.com"
    exclude-result-prefixes="#all"
    xpath-default-namespace="http://www.tei-c.org/ns/1.0" version="2.0">

    <xsl:output encoding="UTF-8" indent="yes" method="xml" version="1.0"/>


    <!-- this stylesheet takes a TEI XML file as input, searches for <tei:ref> nodes of @type='SenteCitationID' and all text nodes for Sente citation IDs wrapped in curly braces and returns the correctly formatted reference based on a master XML file containing the Sente library defined through pgLibrary
    - footnote or bibliography styles can be toggled via $pgMode -->

 

    <!-- IDEA: instead of reproducing a specific XML tree, I could treat the input as a literal string through the unparsed-text() function -->

    <!-- at the moment, it works with XML (TEI, DOCX), but not with HTML files. WHY? -->
    
    <!-- link xslt functions: this works only with a local copy of functions_core.xsl -->
    <!--    <xsl:include href="https://rawgit.com/tillgrallert/xslt-functions/master/functions_core.xsl"/>-->
    <xsl:include href="/Volumes/Dessau HD/BachUni/BachBibliothek/GitHub/xslt-functions/functions_core.xsl"/>
    
    <xsl:param name="pgLibrarySources"
        select="$pgSources"/>
    <xsl:param name="pgLibrarySecondary"
        select="$pgSecondary"/>
    <!-- toggles between two modes: mSources and mSecondary -->
    <xsl:param name="pgMode" select="'mSecondary'"/>
    

    <xsl:param name="p_mode" select="'fn'"/>
    <xsl:param name="p_output-format" select="'tei'"/>
    <xsl:param name="p_keep-existing-formatting" select="true()"/>
    
    <xsl:template match="/">
            <xsl:copy>
                <xsl:apply-templates/>
            </xsl:copy>
    </xsl:template>
    
    <xsl:template match="tei:ref[@type='SenteCitationID']">
        <xsl:copy>
            <xsl:apply-templates select="@*"/>
            <!-- decide whether to keep existing formatted references or not -->
            <xsl:choose>
                <xsl:when test="child::tei:bibl and $p_keep-existing-formatting=true()">
                    <xsl:apply-templates select="node()"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:variable name="v_citation-id">
                        <xsl:value-of select="replace(replace(@target,'\s+',';'),'\+',' ')"/>
                    </xsl:variable>
                    <xsl:call-template name="funcCitation">
                        <xsl:with-param name="pCitID" select="$v_citation-id"/>
                        <xsl:with-param name="pMode" select="$p_mode"/>
                        <!-- this toggles between the libraries -->
                        <xsl:with-param name="pLibrary">
                            <xsl:choose>
                                <xsl:when test="$pgMode='mSources'">
                                    <xsl:copy-of select="$pgLibrarySources"/>
                                </xsl:when>
                                <xsl:when test="$pgMode='mSecondary'">
                                    <xsl:copy-of select="$pgLibrarySecondary"/>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:message terminate="yes">
                                        <xsl:text>Faulty value of $pgMode</xsl:text>
                                    </xsl:message>
                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:with-param>
                        <xsl:with-param name="pOutputFormat" select="$p_output-format"/>
                        <xsl:with-param name="pBibStyle" select="'C15TillArchBib'"/>
                    </xsl:call-template>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="node()">
        <xsl:copy>
            <xsl:choose>
                <xsl:when test=".=text()">
                    <xsl:call-template name="tCitLookup"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:apply-templates select="@* | node()"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="@*">
        <xsl:copy>
            <xsl:apply-templates/>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="tei:teiHeader">
        <xsl:copy>
            <xsl:choose>
                <xsl:when test="./tei:fileDesc">
                    <xsl:apply-templates select="./tei:fileDesc"/>
                </xsl:when>
            </xsl:choose>
            <xsl:choose>
                <xsl:when test="./tei:encodingDesc">
                    <xsl:apply-templates select="./tei:encodingDesc"/>
                </xsl:when>
                <xsl:otherwise>
                    <tei:encodingDesc>
                        <refsDecl>
                                <tei:p>Bibliographic notes are marked with the <tei:gi>ref</tei:gi> element. This element carries the attribute <tei:att>type</tei:att> identifying the source of the
                                    reference – usually a reference managing software.<tei:tag>ref targ="SenteCitationID"</tei:tag> 
                                    identifies Sente as the reference manager. The <tei:att>target</tei:att>
                                    attribute contains the placeholder tag used by the software
                                    identified in <tei:att>type</tei:att> to refer to an individual reference or a group
                                    of references.</tei:p>
                        </refsDecl>
                   </tei:encodingDesc>
                </xsl:otherwise>
            </xsl:choose>
            <xsl:choose>
                <xsl:when test="./tei:revisionDesc">
                    <xsl:apply-templates select="./tei:revisionDesc"/>
                </xsl:when>
                <xsl:otherwise>
                    <tei:revisionDesc>
                        <xsl:call-template name="tRevision"/>
                    </tei:revisionDesc>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="tei:revisionDesc">
        <xsl:copy>
            <xsl:call-template name="tRevision"/>
            <xsl:apply-templates select="node()"/>
        </xsl:copy>
    </xsl:template>
    
    <!-- revision -->
    <xsl:template name="tRevision">
        <xsl:element inherit-namespaces="no" name="tei:change">
            <xsl:attribute name="when" select="format-date(current-date(),'[Y0001]-[M01]-[D01]')"/>
            <xsl:text>All </xsl:text>
            <tei:tag>ref type="SenteCitationID"</tei:tag>
            <xsl:text>have been automatically formatted using information from </xsl:text>
                <xsl:choose>
                    <xsl:when test="$pgMode='mSources'">
                        <xsl:text>the library of primary sources</xsl:text>
                    </xsl:when>
                    <xsl:when test="$pgMode='mSecondary'">
                        <xsl:text>the library of secondary literature</xsl:text>
                    </xsl:when>
                </xsl:choose>
            <xsl:text>.</xsl:text>
        </xsl:element>
    </xsl:template>

    <!-- text() is not working -->
    <xsl:template name="tCitLookup">
        <!-- <xsl:copy>-->
        <xsl:apply-templates select="@*"/>
        <xsl:variable name="vText" select="normalize-space(.)"/>
        <xsl:choose>
            <xsl:when test="contains($vText,'}') and contains(.,'{')">
                <xsl:for-each select="tokenize($vText,'\}')">
                    <xsl:variable name="vCitID" select="substring-after(.,'{')"/>
                    <xsl:variable name="vTextBefore" select="substring-before(.,'{')"/>
                    <xsl:value-of select="$vTextBefore"/>
                    <xsl:if test="$vCitID!=''">
                        <!-- toggle for TEI files only -->
                        <xsl:element name="tei:ref">
                            <xsl:attribute name="type" select="'SenteCitationID'"/>
                            <xsl:attribute name="target">
                                <xsl:value-of disable-output-escaping="yes" select="$vCitID"/>
                            </xsl:attribute>
                            <xsl:call-template name="funcCitation">
                                <xsl:with-param name="pCitID" select="$vCitID"/>
                                <xsl:with-param name="pMode" select="$p_mode"/>
                                <xsl:with-param name="pLibrary">
                                    <xsl:choose>
                                        <xsl:when test="$pgMode='mSources'">
                                            <xsl:copy-of select="$pgLibrarySources"/>
                                        </xsl:when>
                                        <xsl:when test="$pgMode='mSecondary'">
                                            <xsl:copy-of select="$pgLibrarySecondary"/>
                                        </xsl:when>
                                        <xsl:otherwise>
                                            <xsl:message terminate="yes">
                                                <xsl:text>Faulty value of $pgMode</xsl:text>
                                            </xsl:message>
                                        </xsl:otherwise>
                                    </xsl:choose>
                                </xsl:with-param>
                                <xsl:with-param name="pOutputFormat" select="$p_output-format"/>
                                <xsl:with-param name="pBibStyle" select="'C15TillArchBib'"/>
                            </xsl:call-template>
                        </xsl:element>
                    </xsl:if>
                    <xsl:if test="position()=last()">
                        <xsl:value-of select="."/>
                    </xsl:if>
                </xsl:for-each>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="."/>
            </xsl:otherwise>
        </xsl:choose>
        <!--</xsl:copy>-->
    </xsl:template>

</xsl:stylesheet>
