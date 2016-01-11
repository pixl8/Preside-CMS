<cfscript>
	configFormName = prc.itemTypeConfig.configFormName ?: "";
	formId         = "configform-" & CreateUUId();
</cfscript>

<cfoutput>
	<form id="#formId#" data-dirty-form="protect" class="form-horizontal formbuilder-item-config-form">
		#renderForm(
			  formName          = configFormName
			, context           = "admin"
			, formId            = formId
			, savedData         = {}
		)#
	</form>
</cfoutput>