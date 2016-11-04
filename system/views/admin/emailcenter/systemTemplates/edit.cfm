<cfscript>
	templateId         = rc.template              ?: "";
	savedTemplate      = prc.template             ?: {};
	formName           = prc.formName             ?: "";
	editTemplateAction = prc.editTemplateAction   ?: "";
	cancelAction       = prc.cancelAction         ?: "";
	canSaveDraft       = true; // IsTrue( prc.canSaveDraft ?: "" )
	canPublish         = true; // IsTrue( prc.canPublish   ?: "" )
	formId             = "edit-system-email-template";
</cfscript>

<cfsavecontent variable="body">
	<cfoutput>
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
	</cfoutput>
</cfsavecontent>

<cfoutput>#renderView( view="/admin/emailcenter/systemtemplates/_templateTabs", args={ body=body, tab="edit" } )#</cfoutput>