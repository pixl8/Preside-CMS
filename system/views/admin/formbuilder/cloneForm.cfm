<cfscript>
	var basedOnFormId    = rc.id ?: "";
	var validationResult = rc.validationResult ?: "";
</cfscript>

<cfoutput>
	<form id="formbuilder-clone-form" data-auto-focus-form="true" data-dirty-form="protect" class="form-horizontal" method="post" action="#event.buildAdminLink( linkTo='formbuilder.cloneFormAction' )#">
		<input type="hidden" name="basedOnFormId" value="#basedOnFormId#" />

		#renderForm(
			  formName          = "preside-objects.formbuilder_form.admin.cloneForm"
			, context           = "admin"
			, formId            = "formbuilder-clone-form"
			, validationResult  = validationResult
		)#

		<div class="form-actions row">
			<div class="col-md-offset-2">
				<a href="#event.buildAdminLink( linkTo="formbuilder" )#" class="btn btn-default" data-global-key="c">
					<i class="fa fa-reply bigger-110"></i>
					#translateResource( "cms:sitetree.cancel.btn" )#
				</a>

				<button type="submit" name="_saveAction" value="publish" class="btn btn-warning">#translateResource( "formbuilder:cloneForm.save" )#</button>
			</div>
		</div>
	</form>
</cfoutput>