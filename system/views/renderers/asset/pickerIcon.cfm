<cfscript>
	ext          = ListLast( args.storage_path ?: "", "." );
	assetRootUrl = getSetting( name="static.outputUrl", defaultValue="/_assets" );
</cfscript>

<cfoutput><img src="#assetRootUrl#/admin/images/asset-type-icons/32px/#LCase( ext )#.png" /></cfoutput>