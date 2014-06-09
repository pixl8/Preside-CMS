<cfscript>
	ext          = ListLast( args.storage_path ?: "", "." );
	assetRootUrl = event.getSystemAssetsUrl();
</cfscript>

<cfoutput><img src="#assetRootUrl#/images/asset-type-icons/32px/#LCase( ext )#.png" /></cfoutput>