<cfscript>
	imgSrc   = event.buildLink( assetId=args.id ?: "", derivative='icon' );
	imgTitle = HtmlEditFormat( args.title ?: '' );
</cfscript>

<cfoutput><img src="#imgSrc#" alt="#imgTitle#" title="#imgTitle#" class="icon-derivative" /></cfoutput>