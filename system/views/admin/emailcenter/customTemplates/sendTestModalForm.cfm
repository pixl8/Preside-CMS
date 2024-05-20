<!---@feature admin and customEmailTemplates--->
<cfscript>
	formAction = prc.formAction ?: "";
	formName   = prc.formName   ?: "";
	savedData  = prc.savedData  ?: {};
	formId     = "send-test-email-" & CreateUUId();
</cfscript>

<cfoutput>
	<form id="#formId#" action="#formAction#" method="POST" class="form-horizontal send-test-email-form" target="_parent">
		#renderForm(
			  formName = formName
			, context  = "admin"
			, formId   = formId
			, savedData = savedData
		)#
	</form>
</cfoutput>