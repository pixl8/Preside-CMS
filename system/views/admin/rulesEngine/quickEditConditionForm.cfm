<cfscript>
	param name="args.addRecordAction"  type="string"  default=event.buildAdminLink( linkTo='rulesEngine.quickEditConditionAction' );
	param name="args.validationResult" type="any"     default=( rc.validationResult ?: '' );

	formId      = "addForm-" & CreateUUId();
	conditionId = rc.id ?: "";
</cfscript>

<cfoutput>
	<form id="#formId#" data-auto-focus-form="true" data-dirty-form="protect" class="form-horizontal quick-edit-form" method="post" action="#args.addRecordAction#">
		<input name="id" type="hidden" value="#conditionId#">

		#renderForm(
			  formName         = "preside-objects.rules_engine_condition.admin.quickedit"
			, context          = "admin"
			, formId           = formId
			, savedData        = prc.record ?: {}
			, validationResult = args.validationResult
		)#
	</form>
</cfoutput>