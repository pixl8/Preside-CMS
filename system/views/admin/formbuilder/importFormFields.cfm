<cfscript>
	id               = rc.id               ?: "";
	validationResult = rc.validationResult ?: "";
</cfscript>

<cfoutput>
	<form id="formbuilder-import-form" class="form-horizontal" method="post" enctype="multipart/form-data" action="#event.buildAdminLink( linkTo='formbuilder.importFormFieldsAction' )#">
		<input type="hidden" name="id" value="#id#" />

		#renderForm(
			  formName          = "formbuilder.importFormFields"
			, formId            = "formbuilder-import-form-fields"
			, context           = "admin"
			, validationResult  = validationResult
		)#

		<div class="form-actions row">
			<div class="col-md-offset-2">
				<a href="#event.buildAdminLink( linkTo="formbuilder.manageform", queryString="id=#id#" )#" class="btn btn-default" data-global-key="c">
					<i class="fa fa-reply bigger-110"></i>
					#translateResource( "cms:sitetree.cancel.btn" )#
				</a>

				<button type="submit" name="_saveAction" value="publish" class="btn btn-warning">#translateResource( "formbuilder:importFormFields.submit.title" )#</button>
			</div>
		</div>
	</form>
</cfoutput>