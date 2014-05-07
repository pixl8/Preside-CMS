<!---
	This view outputs common html head meta tags (title, description and author)
--->

<cfoutput>
	<cfset local.browsertitle = Trim( event.getPageProperty( "browser_title" ) ) />
	<cfset local.title        = Trim( event.getPageProperty( "label"         ) ) />
	<cfset local.author       = Trim( event.getPageProperty( propertyName="author", cascading=true ) ) />

	<title>#Len( Trim( local.browserTitle ) ) ? local.browserTitle : local.title#</title>

	<cfif Len( Trim( event.getPageProperty( "description" ) ) )>
		<meta name="description" content="#XmlFormat( Trim( event.getPageProperty( "description") ) )#" />
	</cfif>

	<cfif Len( Trim( event.getPageProperty( "keywords" ) ) )>
		<meta name="keywords" content="#XmlFormat( Trim( event.getPageProperty( "keywords" ) ) )#" />
	</cfif>

	<cfif Len( local.author )>
		<meta name="author" content="#XmlFormat( local.author )#" />
	</cfif>
</cfoutput>

