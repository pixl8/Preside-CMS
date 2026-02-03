<!---@feature admin and customEmailTemplates--->
<cfscript>
	recordId    = args.id ?: "";
	templateId  = rc.id ?: "";
	previewLink = event.buildAdminLink( linkto="emailcenter.customtemplates.preview", queryString="id=#templateId#&previewRecipient=#recordId#" );
</cfscript>

<cfoutput>
	<div class="action-buttons btn-group">
		<a href="#previewLink#" target="_parent">
			<i class="fa fa-eye blue"></i>
		</a>
	</div>
</cfoutput>