<cfscript>
	templateId    = rc.id ?: "";
	canSend       = IsTrue( args.canSend       ?: "" );
	canDelete     = IsTrue( args.canDelete     ?: "" );
	canToggleLock = IsTrue( args.canToggleLock ?: "" );

	if ( canSend ) {
		sendLink = event.buildAdminLink( linkTo="emailcenter.customTemplates.send", queryString="id=" & templateId );
		sendButton = translateResource( "cms:emailcenter.customtemplates.send.btn" );
	}
</cfscript>

<cfoutput>
	<div class="top-right-button-group">
		<cfif canSend>
			<a class="pull-right inline" href="#sendLink#">
				<button class="btn btn-warning btn-sm">
					<i class="fa fa-share"></i>
					#sendButton#
				</button>
			</a>
		</cfif>
	</div>
</cfoutput>