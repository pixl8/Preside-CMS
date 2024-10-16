<!---@feature admin--->
<cfscript>
	param name="args.objectName"              type="string"  default=(rc.object ?: '' );
	param name="args.formName"                type="string"  default=( prc.formName ?: '' );
	param name="args.addRecordAction"         type="string"  default=event.buildAdminLink( linkTo='datamanager.quickAddRecordAction', queryString="object=#args.objectName#" );
	param name="args.allowAddAnotherSwitch"   type="boolean" default=true;
	param name="args.validationResult"        type="any"     default=( rc.validationResult ?: '' );
	param name="args.stripPermissionedFields" type="boolean" default=true;
	param name="args.permissionContext"       type="string"  default=args.objectName;
	param name="args.permissionContextKeys"   type="array"   default=ArrayNew( 1 );
	param name="args.preForm"                 type="string"  default=( prc.preForm ?: '' );
	param name="args.postForm"                type="string"  default=( prc.postForm ?: '' );

	addRecordPrompt     = translateResource( uri="preside-objects.#args.objectName#:addRecord.prompt", defaultValue="" );
	objectTitleSingular = translateResource( uri="preside-objects.#args.objectName#:title.singular", defaultValue=args.objectName );
	formId              = "addForm-" & CreateUUId();

	event.include( "/js/admin/specific/datamanager/quickAddForm/" );
</cfscript>

<cfoutput>
	<form id="#formId#" data-auto-focus-form="true" data-dirty-form="protect" class="form-horizontal quick-add-form" method="post" action="#args.addRecordAction#">

		#args.preForm#
		
		#renderForm(
			  formName                = args.formName
			, context                 = "admin"
			, formId                  = formId
			, validationResult        = args.validationResult
			, stripPermissionedFields = args.stripPermissionedFields
			, permissionContext       = args.permissionContext
			, permissionContextKeys   = args.permissionContextKeys
		)#

		#args.postForm#
		
		<cfif args.allowAddAnotherSwitch>
			<div class="form-actions row">
				#renderFormControl(
					  type         = "yesNoSwitch"
					, context      = "admin"
					, name         = "_addAnother"
					, id           = "_addAnother"
					, savedValue   = true
					, defaultValue = true
					, label        = translateResource( uri="cms:datamanager.quick.add.another", data=[ objectTitleSingular ] )
				)#
			</div>
		</cfif>
	</form>
</cfoutput>