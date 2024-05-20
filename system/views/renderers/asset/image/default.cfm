<!---@feature assetManager--->
<cfscript>
	imageUrl = event.buildLink( assetId=args.id ?: '', derivative=args.derivative ?: "" );
	altText  = Len( Trim( args.alt_text ?: "" ) ) ? args.alt_text : ( args.title ?: "" );
</cfscript>
<cfoutput>
	<img src="#imageUrl#"
		<cfif Len( Trim( altText ) ) > alt="#( altText )#"</cfif>
		<cfif Len( Trim( args.label ?: "" ) ) > title="#( args.label )#"</cfif>
		<cfif Len( Trim( args.class ?: "" ) ) > class="#( args.class )#"</cfif>
	/>
</cfoutput>