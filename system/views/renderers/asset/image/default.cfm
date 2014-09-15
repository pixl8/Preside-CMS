<cfoutput>
	<img src="#event.buildLink( assetId=args.id ?: '' )#" 
		<cfif Len( Trim( args.label ?: "" ) ) >
			alt="#( args.label )#"
			title="#( args.label )#" 
		</cfif>
		<cfif Len( Trim( args.class ?: "" ) ) >
			class="#( args.class )#" 
		</cfif>
	/>
</cfoutput>