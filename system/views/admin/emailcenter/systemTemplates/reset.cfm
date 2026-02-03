<!---@feature admin and emailCenter--->
<cfscript>
	cancelLink     = prc.cancelLink     ?: "";
	previewCurrent = prc.previewCurrent ?: {};
	previewDefault = prc.previewDefault ?: {};

	confirmLink   = event.buildAdminLink( linkTo="emailcenter.systemTemplates.resetAction", queryString="template=#prc.template.id#" )
	confirmPrompt = translateResource( uri="cms:emailcenter.systemTemplates.reset.confirm.btn.prompt", data=[ prc.template.name ?: "" ] );

	event.include( "/js/admin/specific/htmliframepreview/" );
	event.include( "/css/admin/specific/htmliframepreview/" );
</cfscript>

<cfoutput>
	<div class="alert alert-info">
		<i class="fa fa-fw fa-info-circle"></i>
		#translateResource( "cms:emailcenter.systemTemplates.reset.existing.content.alert" )#
	</div>

	<div class="row">
		<div class="col-md-6">
			<h3 class="lighter">#translateResource( "cms:emailcenter.systemTemplates.reset.existing.content.title" )#</h3>

			<div class="html-preview no-border">
				<script id="currentHtmlBody" type="text/template">#previewCurrent.htmlBody ?: ""#</script>
				<iframe class="html-message-iframe" data-src="currentHtmlBody" frameBorder="0" style="overflow:hidden;"></iframe>
			</div>
		</div>

		<div class="col-md-6">
			<h3 class=" lighter">#translateResource( "cms:emailcenter.systemTemplates.reset.new.content.title" )#</h3>

			<div class="html-preview no-border">
				<script id="defaultHtmlBody" type="text/template">#previewDefault.htmlBody ?: ""#</script>
				<iframe class="html-message-iframe" data-src="defaultHtmlBody" frameBorder="0" style="overflow:hidden;"></iframe>
			</div>
		</div>
	</div>

	<cfif len( trim( cancelLink ) )>
		<a class="btn btn-default" href="#cancelLink#">
			#translateResource( "cms:cancel.btn" )#
		</a>
	</cfif>

	<a class="btn btn-success pull-right confirmation-prompt" href="#confirmLink#" title="#confirmPrompt#">
		#translateResource( "cms:emailcenter.systemTemplates.reset.confirm.btn" )#
	</a>
</cfoutput>