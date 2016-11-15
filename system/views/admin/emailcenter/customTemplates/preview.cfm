<cfscript>
	recordId = rc.id      ?: "";
	version  = rc.version ?: "";
	preview  = prc.preview  ?: {};

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
		  object         = "email_template"
		, id             = recordId
		, version        = version
		, isDraft        = IsTrue( prc.record._version_is_draft ?: "" )
		, baseUrl        = event.buildAdminLink( linkto="emailCenter.customTemplates.preview", queryString="id=#recordId#&version=" )
		, allVersionsUrl = event.buildAdminLink( linkto="emailCenter.customTemplates.versionHistory", queryString="id=#recordId#" )
	} )#

	#renderViewlet( event="admin.emailcenter.customtemplates._customTemplateTabs", args={ body=body, tab="preview" } )#
</cfoutput>