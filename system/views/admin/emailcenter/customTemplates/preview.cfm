<cfscript>
	recordId = rc.id      ?: "";
	version  = rc.version ?: "";
	body     = "";
</cfscript>

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