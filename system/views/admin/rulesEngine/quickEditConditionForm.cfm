<cfscript>
	param name="args.addRecordAction"  type="string"  default=event.buildAdminLink( linkTo='rulesEngine.quickEditConditionAction' );
	param name="args.validationResult" type="any"     default=( rc.validationResult ?: '' );

	formId      = "addForm-" & CreateUUId();
	conditionId = rc.id ?: "";
	isFilter    = Len( Trim( prc.record.filter_object ?: "" ) );
	formName    = "preside-objects.rules_engine_condition.admin.quickedit" & ( isFilter ? ".filter" : "" );
</cfscript>

<cfoutput>
	<form id="#formId#" data-auto-focus-form="true" data-dirty-form="protect" class="form-horizontal quick-edit-form" method="post" action="#args.addRecordAction#">
		<input name="id" type="hidden" value="#conditionId#">

		#renderForm(
			  formName         = formName
			, context          = "admin"
			, formId           = formId
			, savedData        = prc.record ?: {}
			, validationResult = args.validationResult
		)#
	</form>
</cfoutput>