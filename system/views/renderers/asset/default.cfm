<cfscript>
	ext          = ListLast( args.storage_path ?: "", "." );
	assetRootUrl = getSetting( name="cfstatic_generated_url", defaultValue="/_assets" );
</cfscript>

<cfoutput><img src="#assetRootUrl#/images/asset-type-icons/48px/#LCase( ext )#.png" /></cfoutput>