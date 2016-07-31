# Command line tools for GPS

This folder contains some command line tools that have been of use when planning cycle tours.
 
## convert-camp-muni-kml-to-gpx

Information about Camping Municipal sites is provided via google map applications on the [web site](http://www.camping-municipal.org/index.htm).
KML can be downloaded from the web site. There's a XSLT script which converts the KML into GPX.
To download KML, first select a particular region of France, then enlarge the map to fill the screen by clicking on the iron at the top right of the map. This makes it into a google map application. In the sidebar, there is a drop-down menu with an option to `Télécharger le fichier KML` (download the KML).
It is this KML that this XSLT is designed to process.
It currently generates a GPX file that is suitable for download into the ViewRanger app,
but it will work fine for most other systems that can import GPX.

Downloaded KML is provided in the directory `camp-muni-data`, but this may become out of date. Here is a command for processing all of the KML files at once:

    for i in camp-muni-data/*.kml; do xsltproc convert-camp-muni-kml-to-gpx.xsl $i > $i.gpx; done

## gpx-wpt-filter-by-lat-lon.rb

Script for filtering `<wpt>` elements from a GPX file. Only those within a "rectangle" defined by min/max latitude/longitude will be kept in the result.

## gpx-wpt-set-child.rb

For setting the value of a sub-element of a `<wpt>` element in a GPX file. 
