<cfoutput>
	<fieldset>
		<cfif Len( Trim( args.title ?: "" ) )>
			<h3 class="header smaller lighter green">#translateResource( uri=args.title, defaultValue=args.title )#</h3>
		</cfif>
		<cfif Len( Trim( args.description ?: "" ) )>
			<p>#translateResource( uri=args.description, defaultValue=args.description )#</p>
		</cfif>

		#( args.content ?: "" )#
	</fieldset>
</cfoutput>