<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:dts="https://w3id.org/dts/api#"
  xmlns:xlink="http://www.w3.org/1999/xlink"
  xmlns="http://www.tei-c.org/ns/1.0"
  xpath-default-namespace="http://www.tei-c.org/ns/1.0"
  exclude-result-prefixes="xs"
  expand-text="yes"
  version="3.0">
  <xsl:output method="html" html-version="5" indent="no"/>
  
  <xsl:param name="dir">./</xsl:param>
  
  <!-- Generates a table of contents used as an index page and a sidebar -->
  <xsl:variable name="toc">
    <xsl:apply-templates select="//refsDecl" mode="toc"/>
  </xsl:variable>
  <xsl:variable name="root" select="/TEI"/>
  
  <!-- Generates a copy of the document with IDs added to all elements -->
  <xsl:variable name="doc-with-ids">
    <xsl:apply-templates select="/*" mode="add-ids"/>
  </xsl:variable>
  
  <!-- A tree consisting of citable elements plus their (partial) reference strings -->
  <xsl:variable name="citables">
    <xsl:apply-templates select="$doc-with-ids//refsDecl/citeStructure" mode="citables"/>
  </xsl:variable>
  
  <!-- A list of IDs that can be used to check if a given element has a reference string -->
  <xsl:variable name="citable-list" as="item()*">
    <xsl:variable name="list">
      <xsl:apply-templates select="$doc-with-ids//refsDecl/citeStructure" mode="citable-list"/>
    </xsl:variable>
    <xsl:sequence select="tokenize($list, '\s+')"></xsl:sequence>
  </xsl:variable>
  
  <xsl:template match="/">
    <html>
      <head>
        <meta charset="UTF-8"/>
        <meta http-equiv="X-UA-Compatible" content="IE=edge"/>
        <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
        <title>{//text/front/titlePage/docTitle/titlePart}</title>
        <link rel="stylesheet" href="../css/tei-html.css"/>
        <script>
          let citables = {{<xsl:apply-templates select="$doc-with-ids//refsDecl/citeStructure" mode="citations"/>}}
          let resolveCite = function() {{
          window.location = citables[document.querySelector("input[name=getcite]").value.toString()];
          }}
        </script>
      </head>
      <body>
        <div id="tei">
          <xsl:apply-templates select="//titlePage"/>
          <div class="toc">
            <xsl:copy-of select="$toc"/>
          </div>
        </div>
        <xsl:for-each select="$doc-with-ids//refsDecl//citeStructure[citeData[@property='function' and contains(@use,'split')]]">
          <xsl:apply-templates select="." mode="split"/>
        </xsl:for-each>
        <div id="citesearch">
          <form>
            <label for="getcite">Find citation</label> <input type="text" name="getcite"/> <button onclick="resolveCite(); return false;">Go</button>
          </form>
        </div>
      </body>
      <xsl:result-document href="../index.html" method="html" html-version="5">
        <xsl:call-template name="index"/>
      </xsl:result-document>
    </html>
  </xsl:template>
  
  <xsl:template name="index">
    <html>
      <head>
        <meta charset="UTF-8"/>
        <meta http-equiv="X-UA-Compatible" content="IE=edge"/>
        <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
        <title>Library of Digital Latin Texts</title>
        <link rel="stylesheet" href="css/tei-html.css"/>
      </head>
      <body>
        <h1>Library of Digital Latin Texts</h1>
        <div class="toc">
          <ul>
            <xsl:for-each select="uri-collection('../sources?select=*.xml')">
              <li><a href="{replace(.,'.*/([^/]+).xml','$1')}">{translate(replace(.,'.*/([^/]+).xml','$1'),'_',' ')}</a></li>
            </xsl:for-each>
          </ul>
        </div>
        
      </body>
    </html>
  </xsl:template>
  
  <!-- Convert TEI elements to CETEIcean-style -->
  <xsl:template match="*">
    <xsl:element name="tei-{local-name(.)}">
      <xsl:for-each select="@*">
        <xsl:choose>
          <xsl:when test="name(.) = 'xml:id' and not(starts-with(., 'tmp'))">
            <xsl:attribute name="xml:id" select="."/>
            <xsl:attribute name="id" select="."/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:copy-of select="."/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:for-each>
      <xsl:attribute name="data-origname" select="local-name(.)"/>
      <xsl:if test="not(.//text())">
        <xsl:attribute name="data-empty"/>
      </xsl:if>
      <xsl:if test="$citable-list = xs:string(@xml:id)">
        <xsl:attribute name="data-citation">{dts:resolve_citation(.)}</xsl:attribute>
      </xsl:if>
      <xsl:apply-templates/>
    </xsl:element>
  </xsl:template>
  
  <!-- Resolve internal cross-references into the correct split-out document. -->
  <xsl:template match="ref[starts-with(@target, '#')]">
    <xsl:variable name="target" select="substring-after(@target,'#')"/>
    <tei-ref target="{$root/id($target)/ancestor::div[@type = ('section','textpart','bibliography')][1]/@xml:id}.html{@target}">
      <xsl:apply-templates/>
    </tei-ref>
  </xsl:template>
  
  <!-- Called by $doc-with-ids -->
  <xsl:template match="*" mode="add-ids">
    <xsl:copy>
      <xsl:copy-of select="@*"/>
      <xsl:if test="not(@xml:id)">
        <xsl:attribute name="xml:id" select="generate-id(.)"/>
      </xsl:if>
      <xsl:apply-templates select="node()" mode="add-ids"/>
    </xsl:copy>
  </xsl:template>
  
  <!-- Table of Contents -->
  <xsl:template match="refsDecl" mode="toc">
    <ul>
      <xsl:call-template name="process-toc">
        <xsl:with-param name="citestructures" select="citeStructure"/>
      </xsl:call-template>
    </ul>
  </xsl:template>
  
  <xsl:template name="process-toc">
    <xsl:param name="context" select="/TEI"/>
    <xsl:param name="citestructures"/>
    <xsl:variable name="matches" select="string-join($citestructures/@match, ' | ')"/>
    <xsl:variable name="structures">
      <xsl:evaluate context-item="$context" xpath="$matches"/>
    </xsl:variable>
    <xsl:for-each select="$structures/*">
      <xsl:variable name="current" select="."/>
      <xsl:for-each select="$citestructures">
        <xsl:variable name="resolved" select="dts:resolve_citestructure($context,.)"/>
        <xsl:if test="$resolved = $current">
          <xsl:apply-templates select="." mode="toc">
            <xsl:with-param name="context" select="$context"/>
            <xsl:with-param name="matched" select="$current"/>
          </xsl:apply-templates>
        </xsl:if>
      </xsl:for-each>
    </xsl:for-each>
  </xsl:template>
  
  <!-- Generate the list items in the table of contents -->
  <xsl:template match="citeStructure" mode="toc">
    <xsl:param name="context" select="."/>
    <xsl:param name="matched"/>
    <xsl:variable name="current" select="."/>
    <xsl:variable name="match" select="@match"/>
    <xsl:variable name="matches">
      <xsl:choose>
        <xsl:when test="$matched">
          <xsl:sequence select="$matched"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:evaluate xpath="$match" context-item="$context"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:if test="dts:resolve_citedata(.,.,'function') = 'toc-entry'">
      <xsl:for-each select="$matches/*">
        <li>
          <!-- When a toc-entry has an ancestor that's will be split into a separate document, make a link to split_document.html#id, 
               when it's to be split out itself, do split_document.html. No link otherwise. -->
          <xsl:choose>
            <xsl:when test="$current/citeData[@property='function' and contains(@use,'split')] or $current/ancestor::citeStructure[citeData[@property='function' and contains(@use,'split')]] ">
              <a>
                <xsl:variable name="link">
                  <xsl:variable name="split" select="$current/ancestor::citeStructure[citeData[@property='function' and contains(@use,'split')]]"/>
                  <xsl:choose>
                    <xsl:when test="$split">
                      <xsl:variable name="ancestor" select="dts:resolve_id($context,$split)"/>
                      <xsl:value-of select="$ancestor|| '.html#'|| dts:resolve_id(., $current)"/>
                    </xsl:when>
                    <xsl:otherwise>
                      <xsl:value-of select="dts:resolve_id(.,$current) || '.html'"/>
                    </xsl:otherwise>
                  </xsl:choose>
                </xsl:variable>
                <xsl:choose>
                  <xsl:when test="$current/citeData[@property='dc:title']">
                    <xsl:attribute name="href" select="$link"/>
                    <xsl:value-of select="dts:resolve_citedata(., $current, 'dc:title')"/>
                  </xsl:when>
                  <xsl:when test="$current/citeData[@property='dc:identifier']">
                    <xsl:variable name="use" select="$current/@use"/>
                    <xsl:attribute name="href" select="$link"></xsl:attribute>
                    <xsl:evaluate xpath="$use" context-item="."/>
                  </xsl:when>
                  <xsl:otherwise>
                    <xsl:variable name="use" select="$current/@use"/>
                    <xsl:attribute name="href" select="$link"></xsl:attribute>
                    <xsl:evaluate xpath="$use" context-item="." _xpath-default-namespace="http://www.tei-c.org/ns/1.0"/>
                  </xsl:otherwise>
                </xsl:choose>
              </a>
            </xsl:when>
            <xsl:otherwise>
              <xsl:choose>
                <xsl:when test="$current/citeData[@property='dc:title']">
                  <xsl:value-of select="dts:resolve_citedata(., $current, 'dc:title')"/>
                </xsl:when>
                <xsl:otherwise>
                  <xsl:variable name="use" select="$current/@use"/>
                  <xsl:evaluate xpath="$use" context-item="." _xpath-default-namespace="http://www.tei-c.org/ns/1.0"/>
                </xsl:otherwise>
              </xsl:choose>
            </xsl:otherwise>
          </xsl:choose>
          <xsl:if test="$current/citeStructure[dts:resolve_citedata(.,.,'function') = 'toc-entry']">
            <ul>
              <xsl:call-template name="process-toc">
                <xsl:with-param name="citestructures" select="$current/citeStructure[dts:resolve_citedata(.,.,'function') = 'toc-entry']"/>
                <xsl:with-param name="context" select="."></xsl:with-param>
              </xsl:call-template>
            </ul>
          </xsl:if>
        </li>
      </xsl:for-each>
    </xsl:if>
  </xsl:template>
  
  <!-- Generate a separate HTML document for each citeStructure -->
  <xsl:template match="citeStructure" mode="split">
    <xsl:variable name="current" select="."/>
    <xsl:variable name="doc" select="$doc-with-ids/TEI"/>
    <xsl:variable name="match">
      <xsl:choose>
        <xsl:when test="starts-with(@match,'/')">{@match}</xsl:when>
        <xsl:otherwise>{string-join(ancestor::citeStructure/@match, '/') || '/' || @match}</xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="matches">
      <xsl:evaluate xpath="$match" context-item="$doc"/>
    </xsl:variable>
    <xsl:for-each select="$matches/*">
      <xsl:result-document href="{dts:resolve_id(.,$current)}.html" method="html" html-version="5">
        <html>
          <head>
            <meta charset="UTF-8"/>
            <meta http-equiv="X-UA-Compatible" content="IE=edge"/>
            <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
            <title>{$doc//text/front/titlePage/docTitle/titlePart}: {head}</title>
            <link rel="stylesheet" href="../css/tei-html.css"/>
            <link rel="stylesheet" href="../js/jquery-ui-1.11.4.custom/jquery-ui.css"/>
            <script type="text/javascript" src="../js/CETEI.js"></script>
            <script type="text/javascript" src="../js/jquery/jquery-1.11.3.js"></script>
            <script type="text/javascript" src="../js/jquery-ui-1.11.4.custom/jquery-ui.js"></script>
            <script type="text/javascript" src="../js/appcrit.js"></script>
            <script type="text/javascript" src="../js/behaviors.js"></script>
          </head>
          <body>
            <svg class="svg-icon" style="display:none;">
              <symbol id="note-icon" viewBox="0 0 20 20">
                <path d="M14.999,8.543c0,0.229-0.188,0.417-0.416,0.417H5.417C5.187,8.959,5,8.772,5,8.543s0.188-0.417,0.417-0.417h9.167C14.812,8.126,14.999,8.314,14.999,8.543 M12.037,10.213H5.417C5.187,10.213,5,10.4,5,10.63c0,0.229,0.188,0.416,0.417,0.416h6.621c0.229,0,0.416-0.188,0.416-0.416C12.453,10.4,12.266,10.213,12.037,10.213 M14.583,6.046H5.417C5.187,6.046,5,6.233,5,6.463c0,0.229,0.188,0.417,0.417,0.417h9.167c0.229,0,0.416-0.188,0.416-0.417C14.999,6.233,14.812,6.046,14.583,6.046 M17.916,3.542v10c0,0.229-0.188,0.417-0.417,0.417H9.373l-2.829,2.796c-0.117,0.116-0.71,0.297-0.71-0.296v-2.5H2.5c-0.229,0-0.417-0.188-0.417-0.417v-10c0-0.229,0.188-0.417,0.417-0.417h15C17.729,3.126,17.916,3.313,17.916,3.542 M17.083,3.959H2.917v9.167H6.25c0.229,0,0.417,0.187,0.417,0.416v1.919l2.242-2.215c0.079-0.077,0.184-0.12,0.294-0.12h7.881V3.959z"></path>
              </symbol>
              <symbol id="rdg-icon" viewBox="0 0 20 20">
                <path d="M17.659,3.681H8.468c-0.211,0-0.383,0.172-0.383,0.383v2.681H2.341c-0.21,0-0.383,0.172-0.383,0.383v6.126c0,0.211,0.172,0.383,0.383,0.383h1.532v2.298c0,0.566,0.554,0.368,0.653,0.27l2.569-2.567h4.437c0.21,0,0.383-0.172,0.383-0.383v-2.681h1.013l2.546,2.567c0.242,0.249,0.652,0.065,0.652-0.27v-2.298h1.533c0.211,0,0.383-0.172,0.383-0.382V4.063C18.042,3.853,17.87,3.681,17.659,3.681 M11.148,12.87H6.937c-0.102,0-0.199,0.04-0.27,0.113l-2.028,2.025v-1.756c0-0.211-0.172-0.383-0.383-0.383H2.724V7.51h5.361v2.68c0,0.21,0.172,0.382,0.383,0.382h2.68V12.87z M17.276,9.807h-1.533c-0.211,0-0.383,0.172-0.383,0.383v1.755L13.356,9.92c-0.07-0.073-0.169-0.113-0.27-0.113H8.851v-5.36h8.425V9.807z"></path>
              </symbol>
              <symbol id="redo-icon" viewBox="0 0 20 20">
                <path d="M16.76,7.51l-5.199-5.196c-0.234-0.239-0.633-0.066-0.633,0.261v2.534c-0.267-0.035-0.575-0.063-0.881-0.063c-3.813,0-6.915,3.042-6.915,6.783c0,2.516,1.394,4.729,3.729,5.924c0.367,0.189,0.71-0.266,0.451-0.572c-0.678-0.793-1.008-1.645-1.008-2.602c0-2.348,1.93-4.258,4.303-4.258c0.108,0,0.215,0.003,0.321,0.011v2.634c0,0.326,0.398,0.5,0.633,0.262l5.199-5.193C16.906,7.891,16.906,7.652,16.76,7.51 M11.672,12.068V9.995c0-0.185-0.137-0.341-0.318-0.367c-0.219-0.032-0.49-0.05-0.747-0.05c-2.78,0-5.046,2.241-5.046,5c0,0.557,0.099,1.092,0.292,1.602c-1.261-1.111-1.979-2.656-1.979-4.352c0-3.331,2.77-6.041,6.172-6.041c0.438,0,0.886,0.067,1.184,0.123c0.231,0.043,0.441-0.134,0.441-0.366V3.472l4.301,4.3L11.672,12.068z"></path>
              </symbol>
              <symbol id="undo-icon" viewBox="0 0 20 20">
                <path d="M3.24,7.51c-0.146,0.142-0.146,0.381,0,0.523l5.199,5.193c0.234,0.238,0.633,0.064,0.633-0.262v-2.634c0.105-0.007,0.212-0.011,0.321-0.011c2.373,0,4.302,1.91,4.302,4.258c0,0.957-0.33,1.809-1.008,2.602c-0.259,0.307,0.084,0.762,0.451,0.572c2.336-1.195,3.73-3.408,3.73-5.924c0-3.741-3.103-6.783-6.916-6.783c-0.307,0-0.615,0.028-0.881,0.063V2.575c0-0.327-0.398-0.5-0.633-0.261L3.24,7.51 M4.027,7.771l4.301-4.3v2.073c0,0.232,0.21,0.409,0.441,0.366c0.298-0.056,0.746-0.123,1.184-0.123c3.402,0,6.172,2.709,6.172,6.041c0,1.695-0.718,3.24-1.979,4.352c0.193-0.51,0.293-1.045,0.293-1.602c0-2.76-2.266-5-5.046-5c-0.256,0-0.528,0.018-0.747,0.05C8.465,9.653,8.328,9.81,8.328,9.995v2.074L4.027,7.771z"></path>
              </symbol>
              <symbol id="reload-icon" viewBox="0 0 20 20">
                <path d="M12.319,5.792L8.836,2.328C8.589,2.08,8.269,2.295,8.269,2.573v1.534C8.115,4.091,7.937,4.084,7.783,4.084c-2.592,0-4.7,2.097-4.7,4.676c0,1.749,0.968,3.337,2.528,4.146c0.352,0.194,0.651-0.257,0.424-0.529c-0.415-0.492-0.643-1.118-0.643-1.762c0-1.514,1.261-2.747,2.787-2.747c0.029,0,0.06,0,0.09,0.002v1.632c0,0.335,0.378,0.435,0.568,0.245l3.483-3.464C12.455,6.147,12.455,5.928,12.319,5.792 M8.938,8.67V7.554c0-0.411-0.528-0.377-0.781-0.377c-1.906,0-3.457,1.542-3.457,3.438c0,0.271,0.033,0.542,0.097,0.805C4.149,10.7,3.775,9.762,3.775,8.76c0-2.197,1.798-3.985,4.008-3.985c0.251,0,0.501,0.023,0.744,0.069c0.212,0.039,0.412-0.124,0.412-0.34v-1.1l2.646,2.633L8.938,8.67z M14.389,7.107c-0.34-0.18-0.662,0.244-0.424,0.529c0.416,0.493,0.644,1.118,0.644,1.762c0,1.515-1.272,2.747-2.798,2.747c-0.029,0-0.061,0-0.089-0.002v-1.631c0-0.354-0.382-0.419-0.558-0.246l-3.482,3.465c-0.136,0.136-0.136,0.355,0,0.49l3.482,3.465c0.189,0.186,0.568,0.096,0.568-0.245v-1.533c0.153,0.016,0.331,0.022,0.484,0.022c2.592,0,4.7-2.098,4.7-4.677C16.917,9.506,15.948,7.917,14.389,7.107 M12.217,15.238c-0.251,0-0.501-0.022-0.743-0.069c-0.212-0.039-0.411,0.125-0.411,0.341v1.101l-2.646-2.634l2.646-2.633v1.116c0,0.174,0.126,0.318,0.295,0.343c0.158,0.024,0.318,0.034,0.486,0.034c1.905,0,3.456-1.542,3.456-3.438c0-0.271-0.032-0.541-0.097-0.804c0.648,0.719,1.022,1.659,1.022,2.66C16.226,13.451,14.428,15.238,12.217,15.238"></path>
              </symbol>
            </svg>
            
            <div class="container">
              
              <div id="controls">
                <div id="citesearch">
                  <form>
                    <label for="getcite">Find citation</label> <input type="text" name="getcite"/> <button onclick="resolveCite(); return false;">Go</button>
                  </form>
                </div>
                
                <div id="editing">
                  <ul>
                    <li><button onclick="app.undo()" title="undo"><svg class="svg-icon">
                      <use xlink:href="#undo-icon"></use>
                    </svg></button></li>
                    <li><button onclick="app.redo()" title="redo"><svg class="svg-icon">
                      <use xlink:href="#redo-icon"></use>
                    </svg></button></li>
                    <li><button onclick="while (app.log.length > 0) {{app.undo();}}" title="undo all"><svg class="svg-icon">
                      <use xlink:href="#reload-icon"></use>
                    </svg></button></li>
                  </ul>
                </div>
                
                <div id="display">
                  <form class="">
                    <ul>
                      <li><input type="checkbox" name="orthographical" value="true"/><label for="orthographical">Hide orthographical variants</label></li>
                      <li><input type="checkbox" name="morphological" value="true"/><label for="morphological">Hide morphological variants</label></li>
                      <li><input type="checkbox" name="lexical" value="true"/><label for="lexical">Hide lexical variants</label></li>
                    </ul>
                  </form>
                </div>
                
                <div id="navigation">
                  <xsl:copy-of select="$toc"/>
                </div>
              </div>
              <div class="TEI" id="tei">
                <xsl:apply-templates select="$doc//teiHeader"/>
                <xsl:apply-templates select="."/>
                <xsl:for-each select="dts:resolve_citedata($doc,$current,'dc:requires')">
                  <div style="display:none;">
                    <xsl:apply-templates select="."/>
                  </div>
                </xsl:for-each>
              </div>              
            </div>
            <script>
              let c = new CETEI();
              let app = new appcrit(c);
              c.addBehaviors(behaviors);
              c.processPage();
              $("tei-listwit,tei-witness,tei-bibl,tei-listBibl,tei-handnote,tei-person,tei-item").each(function(i, el) {{
                if (el.hasAttribute("id")) {{
                  let val = el.querySelector("tei-abbr[type=siglum]")?.innerHTML;
                  if (val) {{
                    app.references['#' + el.getAttribute("id")] = val;
                  }} else {{
                    app.references['#' + el.getAttribute("id")] = el.getAttribute("id");
                  }}
                }}
              }});
              let tei = document.querySelector('div<xsl:text disable-output-escaping="yes">&gt;</xsl:text>tei-div[type="textpart"],[type="edition"]');
              app.loadData(tei);
              app.doSection($(tei));
              let citables = {{<xsl:apply-templates select="$doc-with-ids//refsDecl/citeStructure" mode="citations"/>}}
              let resolveCite = function() {{
                window.location = citables[document.querySelector("input[name=getcite]").value.toString()];
              }}
            </script>
          </body>
        </html>
      </xsl:result-document>
    </xsl:for-each>
  </xsl:template>
  
  <!-- Produces a tree containing copies of just the citable elements without 
       their full content plus their partial citation -->
  <xsl:template match="citeStructure" mode="citables">
    <xsl:param name="context" select="$doc-with-ids/TEI"/>
    <xsl:variable name="current" select="."/>
    <xsl:variable name="use" select="'xs:string(' || @use || ')'"/>
    <xsl:choose>
      <xsl:when test="@unit">
        <xsl:for-each select="dts:resolve_citestructure($context, .)">
          <xsl:copy>
            <xsl:copy-of select="@*"/>
            <dts-cite><xsl:value-of select="$current/@delim"/><xsl:evaluate context-item="." xpath="$use"/></dts-cite>
            <xsl:apply-templates select="$current/citeStructure" mode="citables">
              <xsl:with-param name="context" select="."/>
            </xsl:apply-templates>
          </xsl:copy>
        </xsl:for-each>
      </xsl:when>
      <xsl:otherwise>
        <xsl:apply-templates select="$current/citeStructure" mode="citables">
          <xsl:with-param name="context" select="."/>
        </xsl:apply-templates>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <!-- Produces a list of IDs for citable elements -->
  <xsl:template match="citeStructure" mode="citable-list">
    <xsl:param name="context" select="$doc-with-ids/TEI"/>
    <xsl:variable name="current" select="."/>
    <xsl:variable name="use" select="'xs:string(' || @use || ')'"/>
    <xsl:choose>
      <xsl:when test="@unit">
        <xsl:for-each select="dts:resolve_citestructure($context,.)">
          <xsl:sequence select="xs:string(@xml:id)"/>
          <xsl:apply-templates select="$current/citeStructure" mode="citable-list">
            <xsl:with-param name="context" select="."/>
          </xsl:apply-templates>
        </xsl:for-each>
      </xsl:when>
      <xsl:otherwise>
        <xsl:apply-templates select="$current/citeStructure" mode="citable-list">
          <xsl:with-param name="context" select="."/>
        </xsl:apply-templates>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <!-- Build a list of citations pointing to the file containing the cite and the cite itself -->
  <xsl:template match="citeStructure" mode="citations">
    <xsl:param name="context" select="$doc-with-ids/TEI"/>
    <xsl:param name="parentcite" select="''"/>
    <xsl:param name="parenttarget" select="''"/>
    <xsl:param name="parentmatch" select="''"/>
    <xsl:variable name="current" select="."/>
    <xsl:choose>
      <xsl:when test="@unit">
        <xsl:variable name="use" select="'xs:string(' || @use || ')'"/>
        <xsl:variable name="delim" select="@delim"/>
        <xsl:variable name="matches" select="dts:resolve_citestructure($context,.)"/>
        <xsl:for-each select="$matches">
          <xsl:variable name="citationpart">
            <xsl:evaluate context-item="." xpath="$use"/>
          </xsl:variable>
          <!-- when function is split do {@xml:id}.html -->
          <xsl:choose>
            <xsl:when test="dts:resolve_citedata(.,$current,'function') = 'split'">"{$parentcite || $delim || $citationpart}": "{dts:resolve_citedata(.,$current,'dc:identifier')}.html",<xsl:apply-templates select="$current/citeStructure" mode="citations">
                <xsl:with-param name="context" select="."/>
                <xsl:with-param name="parentcite" select="$parentcite || $delim || $citationpart"/>
                <xsl:with-param name="parenttarget">{dts:resolve_citedata(.,$current,'dc:identifier')}.html</xsl:with-param>
                <xsl:with-param name="parentmatch" select="$current/@match"/>
              </xsl:apply-templates>
            </xsl:when>
            <xsl:otherwise>"{$parentcite || $delim || $citationpart}": "{$parenttarget}#{$parentcite || $delim || $citationpart}",<xsl:apply-templates select="$current/citeStructure" mode="citations">
                <xsl:with-param name="context" select="."/>
                <xsl:with-param name="parentcite" select="$parentcite || $delim || $citationpart"/>
                <xsl:with-param name="parenttarget">{$parenttarget}</xsl:with-param>
                <xsl:with-param name="parentmatch" select="$parentmatch || $current/@match"/>
              </xsl:apply-templates>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:for-each>
      </xsl:when>
      <xsl:otherwise>
        <xsl:apply-templates select="citeStructure" mode="citations"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <!-- Given a context element and a citeStructure, find the corresponding element(s) in the document -->
  <xsl:function name="dts:resolve_citestructure">
    <xsl:param name="context"/>
    <xsl:param name="current"/>
    <xsl:variable name="match" select="$current/@match"/>
    <xsl:evaluate xpath="$match" context-item="$context"/>
  </xsl:function>
  
  <!-- Given a context element and a citeStructure, get the value indicated -->
  <xsl:function name="dts:resolve_citedata">
    <xsl:param name="context"/>
    <xsl:param name="current"/>
    <xsl:param name="property"/>
    <xsl:for-each select="$current/citeData[@property=$property]/@use">
      <xsl:variable name="use" select="string(.)"/>
      <xsl:choose>
        <xsl:when test="$use = ''"><xsl:text></xsl:text></xsl:when>
        <xsl:when test="starts-with($use,'@')">
          <xsl:evaluate xpath="$use" context-item="$context" _xpath-default-namespace=""/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:evaluate xpath="$use" context-item="$context" _xpath-default-namespace="http://www.tei-c.org/ns/1.0"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:for-each>
  </xsl:function>
  
  <!-- Special (common) case of dts:resolve_citedata, get the identifier -->
  <xsl:function name="dts:resolve_id">
    <xsl:param name="context"/>
    <xsl:param name="current"/>
    <xsl:choose>
      <xsl:when test="$current/citeData[@property='dc:identifier']">
        <xsl:sequence select="dts:resolve_citedata($context,$current,'dc:identifier')"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:variable name="use" select="$current/@use"/>
        <xsl:evaluate context-item="$context" xpath="$use"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>
  
  <!-- Given an element, use the $citables global variable to get a full citation -->
  <xsl:function name="dts:resolve_citation" as="xs:string">
    <xsl:param name="current"/>
    <xsl:variable name="id" select="$current/@xml:id"/>
    <xsl:variable name="citable" select="$citables//*[@xml:id=$id]"/>
    <xsl:value-of select="string-join($citable/ancestor-or-self::*/dts-cite)"/>
  </xsl:function>
  
</xsl:stylesheet>