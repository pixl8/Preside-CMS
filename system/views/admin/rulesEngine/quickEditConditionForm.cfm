<cfscript>
	param name="args.addRecordAction"  type="string"  default=event.buildAdminLink( linkTo='rulesEngine.quickEditConditionAction' );
	param name="args.validationResult" type="any"     default=( rc.validationResult ?: '' );

	formId      = "addForm-" & CreateUUId();
	conditionId = rc.id ?: "";
	isFilter    = Len( Trim( prc.record.filter_object ?: "" ) );
	isLocked    = IsTrue( prc.record.is_locked ?: "" );
	formName    = prc.formName ?: "";
</cfscript>

<cfoutput>
	<cfif isLocked>
		#renderView(
			  view = "/admin/datamanager/rules_engine_condition/_lockedMessage"
			, args = { record=prc.record }
		)#
	</cfif>
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