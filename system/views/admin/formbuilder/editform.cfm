<cfscript>
	formId = "editForm-" & CreateUUId();
	formAction = event.buildAdminLink( 'formbuilder.editFormAction' );
	theForm    = prc.form ?: {};
</cfscript>

<cfoutput>
	#renderViewlet( event="admin.formbuilder.statusControls", args=theForm )#

	<div class="tabbable">
		#renderViewlet( event="admin.formbuilder.managementTabs", args={ activeTab="settings" } )#

		<div class="tab-content">
			<div class="tab-pane active">
				<form id="#formId#" data-auto-focus-form="true" data-dirty-form="protect" class="form-horizontal" method="post" action="#formAction#">
					<input name="id" type="hidden" value="#theForm.id#">

					#renderForm(
						  formName         = "preside-objects.formbuilder_form.admin.edit"
						, context          = "admin"
						, formId           = formId
						, savedData        = theForm
						, validationResult = ( rc.validationResult ?: "" )
					)#

					<div class="form-actions row">
						<div class="col-md-offset-2">
							<a href="#event.buildAdminLink( linkto='formbuilder.manageForm', queryString='id=' & theForm.id )#" class="btn btn-default" data-global-key="c">
								<i class="fa fa-reply bigger-110"></i>
								#translateResource( "cms:cancel.btn" )#
							</a>

							<button class="btn btn-info" type="submit" tabindex="#getNextTabIndex()#">
								<i class="fa fa-check bigger-110"></i>
								#translateResource( "formbuilder:edit.form.submit.btn" )#
							</button>
						</div>
					</div>
				</form>
			</div>
		</div>
	</div>
</cfoutput>