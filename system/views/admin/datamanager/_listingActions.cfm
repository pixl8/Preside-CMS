<!---@feature admin--->
<cfparam name="args.actions" type="array" />

<cfif args.actions.len()>
	<cfoutput>
		<div class="action-buttons btn-group">
			<cfloop array="#args.actions#" index="i" item="action">
				<cfif IsSimpleValue( action )>
					#action#
				<cfelse>
					<a href="#( action.link ?: "" )#"
					   class="<cfif i == 1>row-link</cfif><cfif Len( Trim( action.class ?: "" ))> #action.class#</cfif>"
					   <cfif Len( Trim( action.contextKey ?: "" ))> data-context-key="#action.contextKey#"</cfif>
					   <cfif Len( Trim( action.title ?: "" ))>title="#EncodeForHtmlAttribute( action.title )#"</cfif>
					   <cfif Len( Trim( action.target ?: "" ))>target="#action.target#"</cfif>
					   <cfif Len( action.match ?: "")>data-confirmation-match="#action.match#"</cfif>
					   <cfif isTrue( action.modal ?: "" )>data-toggle="bootbox-modal" data-buttons="ok" data-modal-class="full-screen-dialog" data-title="#EncodeForHtmlAttribute( action.modalTitle ?: '' )#"</cfif>
					>
						<i class="fa fa-fw #( action.icon ?: "" )#"></i>
					</a>
				</cfif>
			</cfloop>
		</div>
	</cfoutput>
</cfif>