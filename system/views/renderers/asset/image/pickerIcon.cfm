<!---@feature assetManager and admin--->
<cfscript>
	imgSrc     = event.buildLink( assetId=args.id ?: "", derivative='pickerIcon' );
	imgTitle   = HtmlEditFormat( args.label ?: '' );
	imgAltText = HtmlEditFormat( Len( Trim( args.alt_text ?: "" ) ) ? args.alt_text : ( args.title ?: "" ) );
</cfscript>

<cfoutput><img class="lazy" src="#imgSrc#" alt="#imgAltText#" title="#imgTitle#" /></cfoutput>