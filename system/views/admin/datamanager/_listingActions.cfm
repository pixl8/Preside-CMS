<cfparam name="args.actions" type="array" />

<cfif args.actions.len()>
	<cfoutput>
		<div class="action-buttons btn-group">
			<cfloop array="#args.actions#" index="i" item="action">
				<cfif IsSimpleValue( action )>
					#action#
				<cfelse>
					<cfif structKeyExists(action,"type") && action.type == 'quickForm'>
						<a class="row-link quickFormObject" data-title = "Edit Record"<cfif Len( Trim( action.contextKey ?: "" ))> data-context-key="#action.contextKey#"</cfif> data-url="#( action.link ?: "" )#"<cfif Len( Trim( action.target ?: "" ))> target="#action.target#"</cfif>>
							<i class="fa fa-fw #( action.icon ?: "" )#"></i>
						</a>
					<cfelse>
						<a class="<cfif i == 1>row-link</cfif><cfif Len( Trim( action.class ?: "" ))> #action.class#"</cfif>"<cfif Len( Trim( action.contextKey ?: "" ))> data-context-key="#action.contextKey#"</cfif> href="#( action.link ?: "" )#"<cfif Len( Trim( action.title ?: "" ))> title="#HtmlEditFormat( action.title )#"</cfif><cfif Len( Trim( action.target ?: "" ))> target="#action.target#"</cfif>>
							<i class="fa fa-fw #( action.icon ?: "" )#"></i>
						</a>
					</cfif>
				</cfif>
			</cfloop>
		</div>
	</cfoutput>
</cfif>