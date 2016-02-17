<cfscript>
	configFormName = prc.actionConfig.configFormName ?: "";
	savedData      = prc.savedData ?: {};
	action         = rc.action   ?: "";
	formId         = "configform-" & CreateUUId();
</cfscript>

<cfoutput>
	<form id="#formId#" data-dirty-form="protect" class="form-horizontal formbuilder-item-config-form">
		<input type="hidden" name="action" value="#action#">

		#renderForm(
			  formName          = configFormName
			, context           = "admin"
			, formId            = formId
			, savedData         = savedData
		)#
	</form>
</cfoutput>