<!---@feature admin and customEmailTemplates--->
<cfscript>
	recordId                = rc.id                    ?: "";
	version                 = rc.version               ?: "";
	preview                 = prc.preview              ?: {};
	canPreviewWithRecipient = IsTrue( prc.canPreviewWithRecipient ?: "" );
	previewRecipient        = rc.previewRecipient      ?: "";
	previewRecipientName    = prc.previewRecipientName ?: "";

	if ( canPreviewWithRecipient ) {
		previewRecipientPickerLink  = event.buildAdminLink( linkto="emailcenter.customTemplates.previewRecipientPicker", queryString="id=#rc.id#" );
		previewRecipientPickerTitle = translateResource( "cms:emailcenter.customTemplates.preview.choose.recipient.modal.title" );

		if (  Len( Trim( previewRecipientName ) ) ) {
			previewLink = '<a class="preview-recipient-picker-link"  href="#previewRecipientPickerLink#">'
			            & '<i class="fa fa-fw fa-user"></i> '
			            & translateResource( uri="cms:emailcenter.customTemplates.preview.recipient.change.link", data=[ previewRecipientName ] )
			            & '</a>';
		} else {
			previewLink = '<a class="preview-recipient-picker-link"  href="#previewRecipientPickerLink#">'
			            & '<i class="fa fa-fw fa-user"></i> '
			            & translateResource( uri="cms:emailcenter.customTemplates.preview.recipient.choose.link" )
			            & '</a>';
		}
	}

	event.include( "/js/admin/specific/htmliframepreview/" );
	event.include( "/css/admin/specific/htmliframepreview/" );
	event.include( "/js/admin/specific/emailcenter/customtemplates/preview/" );
</cfscript>

<cfsavecontent variable="body">
	<cfoutput>
		<cfif canPreviewWithRecipient>
			<p class="light-grey">
				<i class="fa fa-fw fa-info-circle"></i>
				<cfif Len( Trim( previewRecipientName ) )>
					#translateResource( uri="cms:emailcenter.customTemplates.preview.selected.hint", data=[ previewLink ] )#
				<cfelse>
					#translateResource( uri="cms:emailcenter.customTemplates.preview.anonymous.hint", data=[ previewLink ] )#
				</cfif>
			</p>
		</cfif>

		<h4 class="blue lighter">#translateResource( uri="cms:emailcenter.systemTemplates.template.preview.subject", data=[ preview.subject ] )#</h4>

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