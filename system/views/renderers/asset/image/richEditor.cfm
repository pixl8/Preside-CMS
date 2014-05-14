<cfscript>
	imgSrc     = event.buildLink( ( assetId=args.id ?: "" ), derivative=( args.derivative ?: "" ) );
	imgTitle   = HtmlEditFormat( args.alt_text ?: '' );
	style      = ListFindNoCase( "left,right", args.alignment ?: "" ) ? "float:#LCase( args.alignment )#" : "";
</cfscript>

<cfoutput><img src="#imgSrc#" alt="#imgTitle#" title="#imgTitle#" style="#style#" /></cfoutput>