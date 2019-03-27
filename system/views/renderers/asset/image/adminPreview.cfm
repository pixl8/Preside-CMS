<cfscript>
	imgSrc     = event.buildLink( assetId=args.id ?: "", derivative='adminThumbnail', versionId=args.versionId ?: "" );
	imgTitle   = HtmlEditFormat( args.label ?: '' );
	loadingGif = event.buildLink( systemStaticAsset="/images/loading-gifs/large.gif" );
</cfscript>
<cfoutput><img class="lazy transparent-image-bg" src="#loadingGif#" data-src="#imgSrc#" alt="#imgTitle#" title="#imgTitle#" /></cfoutput>