<cfparam name="args.actions" type="array" />

<cfoutput>
	<cfloop array="#args.actions#" index="i" item="action">
		<cfif IsSimpleValue( action )>
			#action#
		<cfelse>
			<button class="btn #( action.class ?: "" )#<cfif Len( Trim( action.prompt ?: "" ) )> confirmation-prompt</cfif>" type="submit" name="#( action.name ?: '' )#" disabled="disabled" <cfif Len( Trim( action.globalKey ?: "" ) )> data-global-key="#action.globalKey#"</cfif><cfif Len( Trim( action.prompt ?: "" ))> title="#action.prompt#"</cfif><cfif Len( Trim( action.match ?: "" ))>  data-confirmation-match="#action.match#"</cfif>>
				<cfif Len( Trim( action.iconClass ?: "" ) )>
					<i class="fa #action.iconClass# bigger-110"></i>
				</cfif>
				#( action.label ?: "" )#
			</button>
		</cfif>
	</cfloop>
</cfoutput>