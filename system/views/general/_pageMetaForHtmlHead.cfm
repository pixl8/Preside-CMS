<!---
	This view outputs common html head meta tags (title, description and author)
--->

<cfscript>
	local.author       = Trim( event.getPageProperty( propertyName="author", cascading=true ) );
	local.description  = Trim( event.getPageProperty( "description" ) );
	local.keywords     = Trim( event.getPageProperty( "keywords" ) );
	local.browserTitle = Trim( event.getPageProperty( "browser_title" ) );
	local.title        = Trim( event.getPageProperty( "label"         ) );

	local.title  = Len( local.browserTitle ) ? local.browserTitle : local.title;
</cfscript>

<cfoutput>
	<title>#local.title#</title>

	<cfif Len( local.description )>
		<meta name="description" content="#XmlFormat( local.description )#" />
	</cfif>

	<cfif Len( local.keywords )>
		<meta name="keywords" content="#XmlFormat( local.keywords )#" />
	</cfif>

	<cfif Len( local.author )>
		<meta name="author" content="#XmlFormat( local.author )#" />
	</cfif>

	#renderView( "/general/_openGraphMeta" )#
</cfoutput>

