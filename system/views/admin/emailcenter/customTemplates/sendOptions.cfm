<cfscript>
	templateId   = rc.id ?: "";
	formId       = "email-send-options";
	formName     = prc.formName ?: "";
	saveAction   = event.buildAdminLink( linkto="emailcenter.customTemplates.saveSendOptionsAction" );
	cancelAction = event.buildAdminLink( linkto="emailcenter.customTemplates.preview", queryString="id=" & templateId );

	event.include( "/js/admin/specific/emailcenter/customTemplates/sendOptions/" );
</cfscript>
<cfoutput>
	<cfsavecontent variable="body">
		<form id="#formId#" data-auto-focus-form="true" data-dirty-form="protect" class="form-horizontal" method="post" action="#saveAction#">
			<input type="hidden" name="id" value="#templateId#" />

			#renderForm(
				  formName          = formName
				, context           = "admin"
				, formId            = formId
				, savedData         = prc.template ?: {}
				, validationResult  = rc.validationResult ?: ""
				, additionalArgs    = prc.formAdditionalArgs ?: {}
			)#

			<div class="form-actions row">
				<div class="col-md-offset-2">
					<a href="#cancelAction#" class="btn btn-default" data-global-key="c">
						<i class="fa fa-reply bigger-110"></i>
						#translateResource( "cms:cancel.btn" )#
					</a>

					<button type="submit" class="btn btn-info" tabindex="#getNextTabIndex()#">
						<i class="fa fa-save bigger-110"></i> #translateResource( uri="cms:save.btn" )#
					</button>
				</div>
			</div>
		</form>
	</cfsavecontent>

	#renderViewlet( event="admin.emailcenter.customtemplates._customTemplateTabs", args={ body=body, tab="sendoptions" } )#
</cfoutput>