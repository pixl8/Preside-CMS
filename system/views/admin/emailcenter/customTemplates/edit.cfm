<cfscript>
	recordId           = rc.id      ?: "";
	version            = rc.version ?: "";
	blueprint          = prc.blueprint ?: QueryNew('');
	additionalFormArgs = prc.additionalFormArgs ?: {};
	recipientType      = blueprint.recordCount ? blueprint.recipient_type : ( prc.record.recipient_type ?: "" );
</cfscript>

<cfoutput>
	<cfsavecontent variable="body">
		#renderViewlet( event='admin.datamanager.versionNavigator', args={
			  object         = "email_template"
			, id             = recordId
			, version        = version
			, isDraft        = IsTrue( prc.record._version_is_draft ?: "" )
			, baseUrl        = event.buildAdminLink( linkto="emailCenter.customTemplates.edit", queryString="id=#recordId#&version={version}" )
			, allVersionsUrl = event.buildAdminLink( linkto="emailCenter.customTemplates.versionHistory", queryString="id=#recordId#" )
		} )#

		<div class="row">
			<div class="col-md-8 col-lg-7 col-sm-12">
				#renderView( view="/admin/datamanager/_editRecordForm", args={
					  object           = "email_template"
					, id               = rc.id      ?: ""
					, record           = prc.record ?: {}
					, editRecordAction = event.buildAdminLink( linkTo='emailCenter.customTemplates.editAction' )
					, cancelAction     = event.buildAdminLink( linkTo='emailCenter.customTemplates' )
					, useVersioning    = true
					, draftsEnabled    = true
					, canPublish       = IsTrue( prc.canSaveDraft ?: "" )
					, canSaveDraft     = IsTrue( prc.canPublish   ?: "" )
					, additionalArgs   = additionalFormArgs
				} )#
			</div>
			<div class="col-md-4 col-lg-5 col-sm-12">
				#renderViewlet( event="admin.emailcenter.emailParamsHelper", args={ recipientType = recipientType } )#
			</div>
		</div>
	</cfsavecontent>

	#renderViewlet( event="admin.emailcenter.customtemplates._customTemplateTabs", args={ body=body, tab="edit" } )#
</cfoutput>