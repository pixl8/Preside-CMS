<cfscript>
	param name="args.objectName"            type="string"  default=(rc.object ?: '' );
	param name="args.addRecordAction"       type="string"  default=event.buildAdminLink( linkTo='datamanager.quickAddRecordAction', queryString="object=#args.objectName#" );
	param name="args.allowAddAnotherSwitch" type="boolean" default=true;
	param name="args.validationResult"      type="any"     default=( rc.validationResult ?: '' );

	addRecordPrompt     = translateResource( uri="preside-objects.#args.objectName#:addRecord.prompt", defaultValue="" );
	objectTitleSingular = translateResource( uri="preside-objects.#args.objectName#:title.singular", defaultValue=args.objectName );
	formId              = "addForm-" & CreateUUId();

	event.include( "/js/admin/specific/datamanager/quickAddForm/" );
</cfscript>

<cfoutput>
	<form id="#formId#" data-auto-focus-form="true" data-dirty-form="protect" class="form-horizontal quick-add-form" method="post" action="#args.addRecordAction#">
		#renderForm(
			  formName         = "preside-objects.#args.objectName#.admin.quickadd"
			, context          = "admin"
			, formId           = formId
			, validationResult = args.validationResult
		)#

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