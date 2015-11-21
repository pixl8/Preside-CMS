<!---
	This view outputs common html head meta tags (title, description and author)
--->

<cfscript>
	local.site = event.getSite();
	local.hideFromRobots = IsBoolean( local.site.hide_from_search ?: "" ) && local.site.hide_from_search;

	if ( !local.hideFromRobots ) {
		local.searchEngineAccess = event.getPageProperty( propertyName="search_engine_access", default="inherit", cascading=true );
		local.hideFromRobots     = local.searchEngineAccess == "block";
	}
	local.robots = local.hideFromRobots ? "noindex,nofollow" : "index,follow";

	local.author       = Trim( event.getPageProperty( propertyName="author", cascading=true ) );
	if ( !Len( Trim( local.author ) ) ) {
		local.author = local.site.author ?: "";
	}

	local.description  = Trim( event.getPageProperty( "description" ) );
	local.keywords     = Trim( event.getPageProperty( "keywords" ) );
	local.browserTitle = Trim( event.getPageProperty( "browser_title" ) );
	local.title        = Trim( event.getPageProperty( "title"         ) );

	local.title  = Len( local.browserTitle ) ? local.browserTitle : local.title;

	local.titlePrefix = local.site.browser_title_prefix ?: "";
	local.titleSuffix = local.site.browser_title_suffix ?: "";

	local.title = Trim( local.titlePrefix & " " & local.title & " " & local.titleSuffix );

	if ( !event.canPageBeCached() ) {
		event.preventPageCache();
	}
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

	<meta name="robots" content="#local.robots#" />

	#renderView( "/general/_openGraphMeta" )#
</cfoutput>

