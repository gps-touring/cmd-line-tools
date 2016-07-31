<?xml version="1.0" encoding="UTF-8"?>
<!--
	 KML can be downloaded from the Camping Municipal site http://www.camping-municipal.org/index.htm
To download it, first select a particular region of France, then enlarge the map to fill the screen by clicking on the iron at the top right of the map. This makes it into a google map application. In the sidebar, there is a drop-down menu with an option to "Télécharger le fichier KML" (download the KML).
It is this KML that this XSLT is designed to process.
It currently generates a GPX file that is suitable for download into the ViewRanger app,
but it will work fine for most other systems that can import GPX.
	 -->
<xsl:stylesheet version="1.0"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:kml="http://www.opengis.net/kml/2.2"
	xmlns:gpx="http://www.topografix.com/GPX/1/0" 
	>
  <xsl:strip-space elements="*" />
  <xsl:output method="xml" indent="yes" />

  <!--
  <xsl:template match="node() | @*">
      <xsl:apply-templates select="node() | @*" />
    <xsl:copy>
      <xsl:apply-templates select="node() | @*" />
    </xsl:copy>
  </xsl:template>
	-->
<xsl:template match="/">
	<gpx xmlns="http://www.topografix.com/GPX/1/0" version="1.0" creator="ViewRanger - http://www.viewranger.com" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.topografix.com/GPX/1/0 http://www.topografix.com/GPX/1/0/gpx.xsd">
		<xsl:apply-templates select="kml:kml/kml:Document/kml:Folder/kml:Placemark"/>
	</gpx>
</xsl:template>
<xsl:variable name="quote">"</xsl:variable>
<xsl:template match="kml:Placemark">
	<wpt xmlns="http://www.topografix.com/GPX/1/0" >
		<xsl:attribute name="lat">
			<xsl:value-of select="substring-before(substring-after(kml:Point/kml:coordinates, ','), ',')" />
		</xsl:attribute>
		<xsl:attribute name="lon">
			<xsl:value-of select="substring-before(kml:Point/kml:coordinates, ',')" />
		</xsl:attribute>
		<xsl:element name="name"><xsl:value-of select='kml:name'/></xsl:element>
		<sym>Camp</sym>
		<xsl:element name="desc">
			<xsl:variable name="places">
				<xsl:value-of select="concat('Places: ', kml:ExtendedData/kml:Data[@name='Emplacements']/kml:value)" />
			</xsl:variable>
			<xsl:variable name="open">
				<xsl:value-of select="concat('Open: ', kml:ExtendedData/kml:Data[@name='Ouverture']/kml:value)" />
			</xsl:variable>
			<xsl:variable name="budget">
				<xsl:value-of select="concat('Budget €/j: ', kml:ExtendedData/kml:Data[@name='Budget €/j']/kml:value)" />
			</xsl:variable>
			<xsl:variable name="addr">
				<xsl:value-of select="concat('Addr: ', kml:ExtendedData/kml:Data[@name='Adresse']/kml:value)" />
			</xsl:variable>
			<xsl:variable name="tel">
				<xsl:value-of select="concat('Tel: ', kml:ExtendedData/kml:Data[@name='Phone']/kml:value)" />
			</xsl:variable>
			<xsl:value-of select="concat($open,'; ',$places,'; ',$budget,'; ',$addr,'; ',$tel)" />
			<!-- <xsl:value-of select="kml:description" /> -->
		</xsl:element>
		<xsl:element name="url">
			<xsl:variable name="str">
				<xsl:value-of select="kml:ExtendedData/kml:Data[@name='Website']/kml:value" />
			</xsl:variable>
			<xsl:variable name="stripped">
				<xsl:choose>
					<xsl:when test="starts-with($str, 'http://')">
						<xsl:value-of select="substring-after($str, 'http://')" />
					</xsl:when>
					<xsl:when test="starts-with($str, '/')">
						<xsl:value-of select="substring-after($str, '/')" />
					</xsl:when>
					<xsl:otherwise>
						<xsl:value-of select="$str" />
					</xsl:otherwise>
				</xsl:choose>
			</xsl:variable>
			<xsl:choose>
				<xsl:when test="string-length($stripped)>0">
					<xsl:value-of select="concat('http://', $stripped)" />
				</xsl:when>
				<xsl:otherwise>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:element>
	</wpt>
</xsl:template>

</xsl:stylesheet>

