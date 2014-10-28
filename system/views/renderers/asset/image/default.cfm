<cfscript>
	imageUrl = event.buildLink( assetId=args.id ?: '', derivative=args.derivative ?: "" );
</cfscript>
<cfoutput>
	<img src="#imageUrl#"<cfif Len( Trim( args.label ?: "" ) ) > alt="#( args.label )#" title="#( args.label )#"</cfif><cfif Len( Trim( args.class ?: "" ) ) > class="#( args.class )#"</cfif> />
</cfoutput>