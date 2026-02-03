<!---@feature admin and customEmailTemplates--->
<cfscript>
	templateId    = rc.id ?: "";
	canSendTest   = IsTrue( args.canSendTest   ?: "" );
	canSend       = IsTrue( args.canSend       ?: "" );
	canPublish    = IsTrue( args.canPublish    ?: "" );
	canDelete     = IsTrue( args.canDelete     ?: "" );
	canClone      = IsTrue( args.canClone      ?: "" );
	canToggleLock = IsTrue( args.canToggleLock ?: "" );

	if ( canSend ) {
		sendLink = event.buildAdminLink( linkTo="emailcenter.customTemplates.send", queryString="id=" & templateId );
		sendButton = translateResource( "cms:emailcenter.customtemplates.send.btn" );
	}
	if ( canClone ) {
		cloneLink = event.buildAdminLink( linkTo="emailcenter.customTemplates.clone", queryString="id=" & templateId );
		cloneButton = translateResource( "cms:emailcenter.customtemplates.clone.btn" );
	}
	if ( canPublish ) {
		publishLink = event.buildAdminLink( linkTo="emailcenter.customTemplates.publishAction", queryString="id=" & templateId );
		publishButton = translateResource( uri="cms:emailcenter.customtemplates.publish.btn" );
		publishPrompt = translateResource( uri="cms:emailcenter.customtemplates.publish.btn.prompt", data=[ prc.record.name ?: "" ] );
	}
	if ( canSendTest ) {
		previewRecipient   = rc.previewRecipient ?: "";
		sendTestLink       = event.buildAdminLink( linkto="emailcenter.customTemplates.sendTestModalForm", queryString="id=#rc.id#&previewRecipient=#previewRecipient#" );
		sendTestModalTitle = translateResource( "cms:emailcenter.customTemplates.preview.send.test.modal.title" );
		sendTestButton     = translateResource( uri="cms:emailcenter.customTemplates.preview.send.test.btn" );

		event.include( "/js/admin/specific/emailcenter/customtemplates/" );
	}
</cfscript>

<cfoutput>
	<div class="top-right-button-group">
		<cfif canSend>
			<a class="pull-right inline" href="#sendLink#">
				<button class="btn btn-warning btn-sm">
					<i class="fa fa-fw fa-share"></i>
					#sendButton#
				</button>
			</a>
		</cfif>
		<cfif canPublish>
			<a class="pull-right inline confirmation-prompt" href="#publishLink#" title="#HtmlEditFormat( publishPrompt )#">
				<button class="btn btn-warning btn-sm">
					<i class="fa fa-fw fa-globe"></i>
					#publishButton#
				</button>
			</a>
		</cfif>
		<cfif canSendTest>
			<a class="pull-right inline send-test-email-link" href="#sendTestLink#" title="#sendTestModalTitle#">
				<button class="btn btn-default btn-sm">
					<i class="fa fa-fw fa-flask"></i>
					#sendTestButton#
				</button>
			</a>
		</cfif>
		<cfif canClone>
			<a class="pull-right inline" href="#cloneLink#">
				<button class="btn btn-info btn-sm">
					<i class="fa fa-fw fa-clone"></i>
					#cloneButton#
				</button>
			</a>
		</cfif>
	</div>
</cfoutput>