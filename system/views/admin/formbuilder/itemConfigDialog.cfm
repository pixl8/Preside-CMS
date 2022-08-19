<cfscript>
	savedData          = prc.savedData          ?: {};
	additionalFormArgs = prc.additionalFormArgs ?: {};
	formName           = prc.formName           ?: "";
	itemType           = rc.itemType            ?: "";
	formId             = "configform-" & CreateUUId();
</cfscript>

<cfoutput>
	<form id="#formId#" data-dirty-form="protect" class="form-horizontal formbuilder-item-config-form">
		<input type="hidden" name="itemType" value="#itemType#">
		#renderForm(
			  formName       = formName
			, context        = "admin"
			, formId         = formId
			, savedData      = savedData
			, additionalArgs = additionalFormArgs
		)#
	</form>
</cfoutput>