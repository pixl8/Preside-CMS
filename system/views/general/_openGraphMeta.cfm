<cfscript>
	local.site         = event.getSite();
	local.teaser       = Trim( event.getPageProperty( "teaser"             ) );
	local.description  = Trim( event.getPageProperty( "description"        ) );
	local.browsertitle = Trim( event.getPageProperty( "browser_title"      ) );
	local.title        = Trim( event.getPageProperty( "title"              ) );
	local.mainImage    = Trim( event.getPageProperty( "main_image"         ) );
	local.ogType       = local.site.og_type ?: "website";

	local.title  = Len( local.browserTitle ) ? local.browserTitle : local.title;
	local.teaser = Len( local.teaser       ) ? local.teaser       : local.description;
</cfscript>

<cfoutput>
	<meta property="og:title" content="#XmlFormat( local.title )#" />
	<meta property="og:type"  content="#local.ogType#" />
	<meta property="og:url"   content="#event.getSiteUrl( includeLanguageSlug=false )##HtmlEditFormat( event.getCurrentUrl() )#" /> 
	<cfif Len( local.teaser )>
		<meta property="og:description" content="#HtmlEditFormat( local.teaser )#" />
	</cfif>
	<cfif Len( local.mainImage )>
		<meta property="og:image" content="#event.buildLink( assetId=local.mainImage )#" />
	</cfif>
</cfoutput>