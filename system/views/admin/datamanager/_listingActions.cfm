<cfparam name="args.actions" type="array" />

<cfif args.actions.len()>
	<cfoutput>
		<div class="action-buttons btn-group">
			<cfloop array="#args.actions#" index="i" item="action">
				<a<cfif Len( Trim( action.class ?: "" ))> class="#action.class#"</cfif><cfif Len( Trim( action.contextKey ?: "" ))> data-context-key="#action.contextKey#"</cfif> href="#( action.link ?: "" )#"<cfif Len( Trim( action.title ?: "" ))>  title="#HtmlEditFormat( action.title )#"</cfif>>
					<i class="fa fa-fw #( action.icon ?: "" )#"></i>
				</a>
			</cfloop>
		</div>
	</cfoutput>
</cfif>