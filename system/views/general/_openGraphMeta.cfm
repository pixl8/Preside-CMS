<cfscript>
	local.teaser       = Trim( event.getPageProperty( "teaser"        ) );
	local.description  = Trim( event.getPageProperty( "description"   ) );
	local.browsertitle = Trim( event.getPageProperty( "browser_title" ) );
	local.title        = Trim( event.getPageProperty( "label"         ) );
	local.mainImage    = Trim( event.getPageProperty( "main_image"    ) );

	local.title  = Len( local.browserTitle ) ? local.browserTitle : local.title;
	local.teaser = Len( local.teaser       ) ? local.teaser       : local.description;
</cfscript>

<cfoutput>
	<meta name="og:title" content="#XmlFormat( local.title )#" />
	<meta name="og:url"   content="#event.getBaseUrl()##HtmlEditFormat( event.getCurrentUrl() )#" />
	<cfif Len( local.teaser )>
		<meta name="og:description" content="#HtmlEditFormat( local.teaser )#" />
	</cfif>
	<cfif Len( local.mainImage )>
		<meta name="og:image" content="#event.buildLink( assetId=local.mainImage )#" />
	</cfif>
</cfoutput>