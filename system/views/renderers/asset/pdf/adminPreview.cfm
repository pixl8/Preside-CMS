<cfscript>
	imgSrc     = event.buildLink( assetId=args.id ?: "", derivative='adminThumbnail' );
	imgTitle   = HtmlEditFormat( args.label ?: '' );
	loadingGif = event.getSystemAssetsUrl() & "/images/loading-gifs/large.gif";
</cfscript>
<cfoutput><img class="lazy" src="#loadingGif#" data-src="#imgSrc#" alt="#imgTitle#" title="#imgTitle#" /></cfoutput>