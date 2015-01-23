<cfscript>
	imgSrc   = event.buildLink( assetId=args.id ?: "", derivative='icon' );
	imgTitle = HtmlEditFormat( args.title ?: '' );
</cfscript>

<cfoutput><img src="#imgSrc#" alt="" title="#imgTitle#" class="lazy icon-derivative" /></cfoutput>