<cfscript>
	ext     = ListLast( args.storage_path ?: "", "." );
	iconUrl = event.buildLink( systemStaticAsset = "/images/asset-type-icons/16px/#LCase( ext )#.png" );
</cfscript>

<cfoutput><img src="#iconUrl#" class="icon-derivative" /></cfoutput>