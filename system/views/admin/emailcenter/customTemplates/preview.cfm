<cfscript>
	recordId             = rc.id                    ?: "";
	version              = rc.version               ?: "";
	preview              = prc.preview              ?: {};
	previewRecipient     = rc.previewRecipient      ?: "";
	previewRecipientName = prc.previewRecipientName ?: "";

	previewRecipientPickerLink  = event.buildAdminLink( linkto="emailcenter.customTemplates.previewRecipientPicker", queryString="id=#rc.id#" );
	previewRecipientPickerTitle = translateResource( "cms:emailcenter.customTemplates.preview.choose.recipient.modal.title" );

	sendTestFormLink   = event.buildAdminLink( linkto="emailcenter.customTemplates.sendTestModalForm", queryString="id=#rc.id#&previewRecipient=#previewRecipient#" );
	sendTestModalTitle = translateResource( "cms:emailcenter.customTemplates.preview.send.test.modal.title" );

	event.include( "/js/admin/specific/htmliframepreview/" );
	event.include( "/css/admin/specific/htmliframepreview/" );
	event.include( "/js/admin/specific/emailcenter/customtemplates/preview/" );
</cfscript>

<cfsavecontent variable="body">
	<cfoutput>
		#renderViewlet( event='admin.datamanager.versionNavigator', args={
			  object         = "email_template"
			, id             = recordId
			, version        = version
			, isDraft        = IsTrue( prc.record._version_is_draft ?: "" )
			, baseUrl        = event.buildAdminLink( linkto="emailCenter.customTemplates.preview", queryString="id=#recordId#&version={version}" )
			, allVersionsUrl = event.buildAdminLink( linkto="emailCenter.customTemplates.versionHistory", queryString="id=#recordId#" )
		} )#

		<div class="alert alert-info">

			<p>
				<i class="fa fa-fw fa-info-circle fa-lg"></i>
				<cfif Len( Trim( previewRecipientName ) )>
					#translateResource( uri="cms:emailcenter.customTemplates.preview.selected.hint", data=[ "<strong>" & previewRecipientName & "</strong>" ] )#
				<cfelse>
					#translateResource( uri="cms:emailcenter.customTemplates.preview.anonymous.hint")#
				</cfif>
				<br>
				<br>
			</p>

			<p>
				<i class="fa fa-fw fa-lg"></i> <!--- alignment icon --->

				<a class="btn btn-info preview-recipient-picker-link" href="#previewRecipientPickerLink#" title="#previewRecipientPickerTitle#">
					<i class="fa fa-fw fa-user"></i>

					#translateResource( uri="cms:emailcenter.customTemplates.preview.choose.recipient.btn")#
				</a>

				<a class="btn btn-warning send-test-email-link" href="#sendTestFormLink#" title="#sendTestModalTitle#">
					<i class="fa fa-fw fa-paper-plane"></i>

					#translateResource( uri="cms:emailcenter.customTemplates.preview.send.test.btn")#
				</a>
			</p>
		</div>

		<div class="page-header">
			<h4 class="blue">#translateResource( uri="cms:emailcenter.systemTemplates.template.preview.subject", data=[ preview.subject ] )#</h4>
		</div>

		<div class="tabbable tabs-left">
			<ul class="nav nav-tabs">
				<li class="active">
					<a data-toggle="tab" href="##tab-html">
						<i class="fa fa-fw fa-code blue"></i>&nbsp;
						#translateResource( "cms:emailcenter.systemTemplates.template.preview.html" )#
					</a>
				</li>
				<li>
					<a data-toggle="tab" href="##tab-text">
						<i class="fa fa-fw fa-file-text-o grey"></i>&nbsp;
						#translateResource( "cms:emailcenter.systemTemplates.template.preview.text" )#
					</a>
				</li>
			</ul>

			<div class="tab-content">
				<div class="tab-pane active" id="tab-html">
					<div class="html-preview">
						<script id="htmlBody" type="text/template">#preview.htmlBody#</script>
						<iframe class="html-message-iframe" data-src="htmlBody" frameBorder="0" style="overflow:hidden;"></iframe>
					</div>
				</div>
				<div class="tab-pane" id="tab-text">
					<p><pre>#Trim( preview.textBody )#</pre></p>
				</div>
			</div>
		</div>
	</cfoutput>
</cfsavecontent>

<cfoutput>
	#renderViewlet( event="admin.emailcenter.customtemplates._customTemplateTabs", args={ body=body, tab="preview" } )#
</cfoutput>