<cfscript>
	templateId         = rc.template              ?: "";
	savedTemplate      = prc.template             ?: {};
	formName           = prc.formName             ?: "";
	editTemplateAction = prc.editTemplateAction   ?: "";
	cancelAction       = prc.cancelAction         ?: "";
	canSaveDraft       = IsTrue( prc.canSaveDraft ?: "" )
	canPublish         = IsTrue( prc.canPublish   ?: "" )
	formId             = "edit-system-email-template";
</cfscript>

<cfsavecontent variable="body">
	<cfoutput>
		#renderViewlet( event='admin.datamanager.versionNavigator', args={
			  object           = "email_template"
			, id               = templateId
			, version          = rc.version ?: ""
			, isDraft          = IsTrue( savedTemplate._version_is_draft ?: "" )
			, baseUrl          = event.buildAdminLink( linkto="emailCenter.systemTemplates.edit", queryString="template=#templateId#&version=" )
			, allVersionsUrl   = event.buildAdminLink( linkto="emailCenter.systemTemplates.versionHistory", queryString="template=#templateId#" )
		} )#

		<div class="row">
			<div class="col-md-8 col-lg-7 col-sm-12">
				<form id="#formId#" data-auto-focus-form="true" data-dirty-form="protect" class="form-horizontal edit-object-form" method="post" action="#editTemplateAction#">
					<input type="hidden" name="template" value="#templateId#" />

					#renderForm(
						  formName          = formName
						, context           = "admin"
						, formId            = formId
						, savedData         = savedTemplate
						, validationResult  = rc.validationResult ?: ""
					)#

					<div class="form-actions row">
						<div class="col-md-offset-2">
							<a href="#cancelAction#" class="btn btn-default" data-global-key="c">
								<i class="fa fa-reply bigger-110"></i>
								#translateResource( "cms:datamanager.cancel.btn" )#
							</a>

							<cfif canSaveDraft>
								<button type="submit" name="_saveAction" value="savedraft" class="btn btn-info" tabindex="#getNextTabIndex()#">
									<i class="fa fa-save bigger-110"></i> #translateResource( uri="cms:save.draft.btn" )#
								</button>
							</cfif>
							<cfif canPublish>
								<button type="submit" name="_saveAction" value="publish" class="btn btn-warning" tabindex="#getNextTabIndex()#">
									<i class="fa fa-globe bigger-110"></i> #translateResource( uri="cms:publish.btn" )#
								</button>
							</cfif>
						</div>
					</div>
				</form>
			</div>
			<div class="col-md-4 col-lg-5 col-sm-12">
				#renderViewlet( event="admin.emailcenter.emailParamsHelper", args={
					  systemTemplate = templateId
					, recipientType  = ( savedTemplate.recipient_type ?: "" )
				} )#
			</div>
		</div>
	</cfoutput>
</cfsavecontent>

<cfoutput>
	#renderViewlet( event="admin.emailcenter.systemtemplates._templateTabs", args={ body=body, tab="edit" } )#
</cfoutput>