<cfscript>
	param name="args.addRecordAction"  type="string"  default=event.buildAdminLink( linkTo='rulesEngine.quickEditFilterAction' );
	param name="args.validationResult" type="any"     default=( rc.validationResult ?: '' );

	formId   = "addForm-" & CreateUUId();
	filterId = rc.id ?: "";
	formName = prc.formName ?: "preside-objects.rules_engine_condition.admin.quickedit.filter";
	isLocked = IsTrue( prc.record.is_locked ?: "" );
</cfscript>

<cfoutput>
	<cfif isLocked>
		#renderView(
			  view = "/admin/datamanager/rules_engine_condition/_lockedMessage"
			, args = { record=prc.record }
		)#
	</cfif>
	<form id="#formId#" data-auto-focus-form="true" data-dirty-form="protect" class="form-horizontal quick-edit-form" method="post" action="#args.addRecordAction#">
		<input name="id" type="hidden" value="#filterId#">

		#renderForm(
			  formName         = formName
			, context          = "admin"
			, formId           = formId
			, savedData        = prc.record ?: {}
			, validationResult = args.validationResult
			, additionalArgs   = { fields={ expressions={
				  contextData           = prc.contextData          ?: {}
				, preSavedFilters       = rc.preSavedFilters       ?: ""
				, preRulesEngineFilters = rc.preRulesEngineFilters ?: ""
			  } } }
		)#
	</form>
</cfoutput>