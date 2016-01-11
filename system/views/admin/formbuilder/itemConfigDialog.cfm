<cfscript>
	configFormName = prc.itemTypeConfig.configFormName ?: "";
	savedData      = prc.savedData ?: {};
	itemType       = rc.itemType ?: "";
	formId         = "configform-" & CreateUUId();
</cfscript>

<cfoutput>
	<form id="#formId#" data-dirty-form="protect" class="form-horizontal formbuilder-item-config-form">
		<input type="hidden" name="itemType" value="#itemType#">
		#renderForm(
			  formName          = configFormName
			, context           = "admin"
			, formId            = formId
			, savedData         = savedData
		)#
	</form>
</cfoutput>