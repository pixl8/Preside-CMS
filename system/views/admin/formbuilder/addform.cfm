<cfscript>
	formId = "addForm-" & CreateUUId();
	formAction = event.buildAdminLink( 'formbuilder.addFormAction' );
</cfscript>

<cfoutput>
	<form id="#formId#" data-auto-focus-form="true" data-dirty-form="protect" class="form-horizontal" method="post" action="#formAction#">
		#renderForm(
			  formName         = "preside-objects.formbuilder_form.admin.add"
			, context          = "admin"
			, formId           = formId
			, validationResult = ( rc.validationResult ?: "" )
		)#

		<div class="form-actions row">
			<div class="col-md-offset-2">
				<a href="#event.buildAdminLink( 'formbuilder' )#" class="btn btn-default" data-global-key="c">
					<i class="fa fa-reply bigger-110"></i>
					#translateResource( "cms:cancel.btn" )#
				</a>

				<button class="btn btn-info" type="submit" tabindex="#getNextTabIndex()#">
					<i class="fa fa-check bigger-110"></i>
					#translateResource( "formbuilder:add.form.submit.btn" )#
				</button>
			</div>
		</div>
	</form>
</cfoutput>