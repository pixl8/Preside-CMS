<cfscript>
	templateId    = rc.id ?: "";
	canSendTest   = IsTrue( args.canSendTest   ?: "" );
	canSend       = IsTrue( args.canSend       ?: "" );
	canDelete     = IsTrue( args.canDelete     ?: "" );
	canToggleLock = IsTrue( args.canToggleLock ?: "" );
	isRepeat      = ( args.scheduleType ?: "" ) == "repeat";
	sendDate      = args.nextSendDate;

	if ( canSend ) {
		sendLink = event.buildAdminLink( linkTo="emailcenter.customTemplates.send", queryString="id=" & templateId );
		sendButton = translateResource( "cms:emailcenter.customtemplates.send.btn" );
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
		<cfif isRepeat>
			<cfif IsDate( sendDate )>
				<span class="alert alert-info"><i class="fa fa-fw fa-info-circle"></i>#translateResource( uri="cms:emailcenter.next.send.date.alert", data=[ DateTimeFormat( sendDate, "d mmm, yyyy HH:nn") ])#</span>
			<cfelse>
				<span class="alert alert-warning"><i class="fa fa-fw fa-exclamation-triangle"></i>#translateResource( uri="cms:emailcenter.next.send.date.unknown.alert" )#</span>
			</cfif>
		</cfif>
		<cfif canSend>
			<a class="pull-right inline" href="#sendLink#">
				<button class="btn btn-warning btn-sm">
					<i class="fa fa-share"></i>
					#sendButton#
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
	</div>
</cfoutput>