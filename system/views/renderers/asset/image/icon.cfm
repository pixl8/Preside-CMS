<cfscript>
	imgSrc     = event.buildLink( assetId=args.id ?: "", derivative='icon' );
	imgTitle   = HtmlEditFormat( args.label ?: '' );
	loadingGif = event.getSystemAssetsUrl() & "/images/loading-gifs/small.gif";
</cfscript>

<cfoutput><img class="lazy" src="#loadingGif#" data-src="#imgSrc#" alt="#imgTitle#" title="#imgTitle#" /></cfoutput>