<!---@feature assetManager and admin--->
<cfscript>
	ext     = ListLast( args.storage_path ?: "", "." );
	iconUrl = event.buildLink( systemStaticAsset = "/images/asset-type-icons/48px/#LCase( ext )#.png" );
</cfscript>

<cfoutput><img src="#iconUrl#" /></cfoutput>