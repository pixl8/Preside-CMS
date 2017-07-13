<cfscript>
	param name="args.addRecordAction"  type="string"  default=event.buildAdminLink( linkTo='rulesEngine.quickAddFilterAction' );
	param name="args.validationResult" type="any"     default=( rc.validationResult ?: '' );

	formId = "addForm-" & CreateUUId();
</cfscript>

<cfoutput>
	<form id="#formId#" data-auto-focus-form="true" data-dirty-form="protect" class="form-horizontal quick-add-form" method="post" action="#args.addRecordAction#">
		#renderForm(
			  formName         = "preside-objects.rules_engine_condition.admin.quickadd.filter"
			, context          = "admin"
			, formId           = formId
			, validationResult = args.validationResult
			, additionalArgs   = { fields={ expressions={
				  contextData           = prc.contextData          ?: {}
				, preSavedFilters       = rc.preSavedFilters       ?: ""
				, preRulesEngineFilters = rc.preRulesEngineFilters ?: ""
			  } } }
		)#
	</form>
</cfoutput>