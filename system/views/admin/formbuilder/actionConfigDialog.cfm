<cfscript>
	configFormName = prc.actionConfig.configFormName ?: "";
	savedData      = prc.savedData ?: {};
	action         = rc.action     ?: "";
	fbFormId       = rc.formId     ?: "";
	formId         = "configform-" & CreateUUId();
</cfscript>

<cfoutput>
	<form id="#formId#" data-dirty-form="protect" class="form-horizontal formbuilder-item-config-form">
		<input type="hidden" name="action" value="#action#">

		#renderForm(
			  formName          = "formbuilder.actions._baseActionConfig"
			, mergeWithFormName = configFormName
			, context           = "admin"
			, formId            = formId
			, savedData         = savedData
			, additionalArgs    = { fields={ condition={ rulesEngineContextData={ fbform=fbFormId } } } }
		)#
	</form>
</cfoutput>