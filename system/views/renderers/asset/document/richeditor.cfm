<cfscript>
	ext       = ListLast( args.storage_path ?: "", "." );
	iconUrl   = event.buildLink( systemStaticAsset = "/images/asset-type-icons/32px/#LCase( ext )#.png" );
	assetLink = event.buildLink( assetId=args.id );
	linkTitle = Len( Trim( args.link_text ?: "" ) ) ? args.link_text : ( args.title ?: "" );
</cfscript>

<cfoutput>
	<a href="#assetLink#">
		<img src="#iconUrl#" />
		#linkTitle#
	</a>
</cfoutput>