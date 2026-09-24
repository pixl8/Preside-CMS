<!---@feature admin and customFields--->
<cfscript>
	formName         = prc.formName   ?: "";
	savedData        = prc.savedData  ?: {};
	objectName       = prc.objectName ?: "";
	recordId         = prc.recordId   ?: "";
	cancelLink       = prc.cancelLink ?: "";
	saveLink         = prc.saveLink   ?: "";
	validationResult = rc.validationResult ?: "";
	formId           = "edit-custom-fields-" & CreateUUId();
</cfscript>

<cfoutput>
	<form id="#formId#" method="post" action="#saveLink#" class="form-horizontal" data-auto-focus-form="true" data-dirty-form="protect">
		<input type="hidden" name="object" value="#EncodeForHTMLAttribute( objectName )#" />
		<input type="hidden" name="id" value="#EncodeForHTMLAttribute( recordId )#" />

		#renderForm(
			  formName         = formName
			, context          = "admin"
			, formId           = formId
			, savedData        = savedData
			, validationResult = validationResult
		)#

		<div class="form-actions row">
			<div class="col-md-offset-2 col-md-10">
				<a href="#cancelLink#" class="btn btn-default">
					<i class="fa fa-reply bigger-110"></i>
					#translateResource( "cms:cancel.btn" )#
				</a>
				<button type="submit" class="btn btn-info">
					<i class="fa fa-save bigger-110"></i>
					#translateResource( "cms:save.btn" )#
				</button>
			</div>
		</div>
	</form>
</cfoutput>
