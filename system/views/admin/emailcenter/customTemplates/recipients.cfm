<cfscript>
	templateId   = rc.id ?: "";
	formId       = "email-recipient-filter";
	saveAction   = event.buildAdminLink( linkto="emailcenter.customTemplates.saveRecipientsAction" );
	cancelAction = event.buildAdminLink( linkto="emailcenter.customTemplates.preview", queryString="id=" & templateId );
</cfscript>
<cfoutput>
	<cfsavecontent variable="body">
		<form id="#formId#" data-auto-focus-form="true" data-dirty-form="protect" class="form-horizontal" method="post" action="#saveAction#">
			<input type="hidden" name="id" value="#templateId#" />

			#renderForm(
				  formName          = "preside-objects.email_template.configure.recipients"
				, context           = "admin"
				, formId            = formId
				, savedData         = prc.template ?: {}
				, validationResult  = rc.validationResult ?: ""
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

	#renderViewlet( event="admin.emailcenter.customtemplates._customTemplateTabs", args={ body=body, tab="recipients" } )#
</cfoutput>