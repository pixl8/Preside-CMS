<cfscript>
    templateid    = rc.template  ?: "";
    version       = rc.version   ?: "";
    savedTemplate = prc.template ?: {};
	preview       = prc.preview  ?: {};

	event.include( "/js/admin/specific/htmliframepreview/" );
	event.include( "/css/admin/specific/htmliframepreview/" );
</cfscript>

<cfsavecontent variable="body">
	<cfoutput>
		<h4 class="blue lighter">#translateResource( uri="cms:emailcenter.systemTemplates.template.preview.subject", data=[ preview.subject ] )#</h4>
		<div class="row">
			<div class="col-lg-7 col-md-12">
				<h4 class="blue lighter">#translateResource( "cms:emailcenter.systemTemplates.template.preview.html" )#</h4>
				<div class="html-preview">
					<script id="htmlBody" type="text/template">#preview.htmlBody#</script>
					<iframe class="html-message-iframe" data-src="htmlBody" frameBorder="0" style="overflow:hidden;"></iframe>
				</div>
			</div>
			<div class="col-lg-5 col-md-12">
				<h4 class="blue lighter">#translateResource( "cms:emailcenter.systemTemplates.template.preview.text" )#</h4>
				<p><pre>#Trim( preview.textBody )#</pre></p>
			</div>
		</div>
	</cfoutput>
</cfsavecontent>

<cfoutput>
	#renderViewlet( event='admin.datamanager.versionNavigator', args={
		  object           = "email_template"
		, id               = templateId
		, version          = rc.version ?: ""
		, isDraft          = IsTrue( savedTemplate._version_is_draft ?: "" )
		, baseUrl          = event.buildAdminLink( linkto="emailCenter.systemTemplates.template", queryString="template=#templateId#&version=" )
		, allVersionsUrl   = event.buildAdminLink( linkto="emailCenter.systemTemplates.versionHistory", queryString="template=#templateId#" )
	} )#

	#renderViewlet( event="admin.emailcenter.systemtemplates._templateTabs", args={ body=body, tab="preview" } )#
</cfoutput>