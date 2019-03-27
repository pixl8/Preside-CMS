<cfscript>
	param name="args.addRecordAction"  type="string"  default=event.buildAdminLink( linkTo='rulesEngine.superQuickAddFilterAction' );
	param name="args.validationResult" type="any"     default=( rc.validationResult ?: '' );

	formId = "addForm-" & CreateUUId();

	event.include( "/js/admin/specific/datamanager/quickAddForm/" );
</cfscript>

<cfoutput>
	<form id="#formId#" data-auto-focus-form="true" data-dirty-form="protect" class="form-horizontal quick-add-form" method="post" action="#args.addRecordAction#">
		#renderForm(
			  formName         = "preside-objects.rules_engine_condition.admin.superquickaddfilter"
			, context          = "admin"
			, formId           = formId
			, validationResult = args.validationResult
		)#
	</form>
</cfoutput>