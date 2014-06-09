<cfscript>
	ext          = ListLast( args.storage_path ?: "", "." );
	assetRootUrl = event.getSystemAssetsUrl();
</cfscript>

<cfoutput><img src="#assetRootUrl#/images/asset-type-icons/48px/#LCase( ext )#.png" /></cfoutput>