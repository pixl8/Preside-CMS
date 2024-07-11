<!---@feature admin and assetManager--->
<cfscript>
	imgSrc     = event.buildLink( assetId=args.id ?: "", derivative='adminThumbnail', versionId=args.versionId ?: "" );
	imgTitle   = HtmlEditFormat( args.label ?: '' );
	imgAltText = HtmlEditFormat( Len( Trim( args.alt_text ?: "" ) ) ? args.alt_text : ( args.title ?: "" ) );
	loadingGif = event.buildLink( systemStaticAsset="/images/loading-gifs/large.gif" );
</cfscript>
<cfoutput><img class="lazy transparent-image-bg" src="#loadingGif#" data-src="#imgSrc#" alt="#imgAltText#" title="#imgTitle#" /></cfoutput>