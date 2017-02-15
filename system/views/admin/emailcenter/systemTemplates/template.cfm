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
		#renderViewlet( event='admin.datamanager.versionNavigator', args={
			  object           = "email_template"
			, id               = templateId
			, version          = rc.version ?: ""
			, isDraft          = IsTrue( savedTemplate._version_is_draft ?: "" )
			, baseUrl          = event.buildAdminLink( linkto="emailCenter.systemTemplates.template", queryString="template=#templateId#&version=" )
			, allVersionsUrl   = event.buildAdminLink( linkto="emailCenter.systemTemplates.versionHistory", queryString="template=#templateId#" )
		} )#

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
	#renderViewlet( event="admin.emailcenter.systemtemplates._templateTabs", args={ body=body, tab="preview" } )#
</cfoutput>