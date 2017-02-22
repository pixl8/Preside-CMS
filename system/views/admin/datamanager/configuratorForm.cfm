<cfscript>
	param name="args.objectName"            type="string"  default=( rc.object ?: '' );
	param name="args.formName"              type="string"  default=( rc.formName ?: '' );
	param name="args.validationResult"      type="any"     default=( rc.validationResult ?: '' );
	param name="args.savedData"             type="struct"  default={};

	formId   = "addForm-" & CreateUUId();
	formName = len( args.formName ) ? args.formName : "preside-objects.#args.objectName#.admin.quickadd";

	event.include( "/js/admin/specific/datamanager/configuratorForm/" );
</cfscript>

<cfoutput>
	<form id="#formId#" data-auto-focus-form="true" data-dirty-form="protect" class="form-horizontal configurator-form">
		<cfif len( rc.id ?: "" )>
			<input type="hidden" name="id" value="#rc.id#">
		</cfif>
		<cfif len( rc.configurator__index ?: "" )>
			<input type="hidden" name="configurator__index" value="#rc.configurator__index#">
		</cfif>

		#renderForm(
			  formName         = formName
			, context          = "admin"
			, formId           = formId
			, validationResult = args.validationResult
			, savedData        = args.savedData
		)#
	</form>
</cfoutput>