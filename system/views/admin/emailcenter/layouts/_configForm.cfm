<cfscript>
	formId           = "configure-layout";
	layoutId         = args.layoutId ?: "";
	templateId       = args.templateId ?: "";
	formAction       = args.formAction ?: "";
	layoutFormName   = args.layoutFormName ?: "";
	savedConfig      = args.savedConfig ?: {};
	validationResult = rc.validationResult ?: "";

	isTemplateConfig = Len( Trim( templateId ) ) > 0;
</cfscript>
<cfoutput>
	<form id="#formId#" method="post" action="#formAction#" data-auto-focus-form="true" data-dirty-form="protect" class="form-horizontal">
		<input type="hidden" name="layout"   value="#layoutId#">
		<cfif Len( Trim( templateId ) )>
			<input type="hidden" name="template" value="#templateId#">
		</cfif>

		#renderForm(
			  formName         = layoutFormName
			, context          = "admin"
			, formId           = formId
			, savedData        = savedConfig
			, validationResult = validationResult
			, fieldLayout      = isTemplateConfig ? "formcontrols.layouts.fieldWithOverrideOption"    : NullValue()
			, fieldsetLayout   = isTemplateConfig ? "formcontrols.layouts.fieldsetWithOverrideOption" : NullValue()
		)#

		<div class="form-actions row">
			<div class="col-md-offset-2">
				<button class="btn btn-info" type="submit" tabindex="#getNextTabIndex()#">
					<i class="fa fa-check bigger-110"></i>
					#translateResource( "cms:save.btn" )#
				</button>
			</div>
		</div>
	</form>
</cfoutput>