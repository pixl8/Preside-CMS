<cfscript>
	imgSrc     = event.buildLink( assetId=args.id ?: "", derivative='pickerIcon' );
	imgTitle   = HtmlEditFormat( args.label ?: '' );
</cfscript>

<cfoutput><img class="lazy" src="#imgSrc#" alt="#imgTitle#" title="#imgTitle#" /></cfoutput>