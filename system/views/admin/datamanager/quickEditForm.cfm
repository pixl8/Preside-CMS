<cfscript>
	param name="args.objectName"       type="string"  default=(rc.object ?: '' );
	param name="args.editRecordAction" type="string"  default=event.buildAdminLink( linkTo='datamanager.quickEditRecordAction', queryString="object=#args.objectName#" );
	param name="args.validationResult" type="any"     default=( rc.validationResult ?: '' );
	param name="args.record"           type="struct"  default=( prc.record ?: {} );

	editRecordPrompt    = translateResource( uri="preside-objects.#args.objectName#:editRecord.prompt", defaultValue="" );
	objectTitleSingular = translateResource( uri="preside-objects.#args.objectName#:title.singular"   , defaultValue=args.objectName );
	formId              = "editForm-" & CreateUUId();

	event.include( "/js/admin/specific/datamanager/quickEditForm/" );
</cfscript>

<cfoutput>
	<form id="#formId#" data-auto-focus-form="true" data-dirty-form="protect" class="form-horizontal quick-edit-form" method="post" action="#args.editRecordAction#">
		<input name="id" type="hidden" value="#( rc.id ?: '' )#" />

		#renderForm(
			  formName         = "preside-objects.#args.objectName#.admin.quickedit"
			, context          = "admin"
			, formId           = formId
			, validationResult = args.validationResult
			, savedData        = args.record
		)#
	</form>
</cfoutput>