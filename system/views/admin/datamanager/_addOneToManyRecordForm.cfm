<cfscript>
	param name="args.objectName"              type="string";
	param name="args.parentId"                type="string";
	param name="args.relationshipKey"         type="string";
	param name="args.addRecordAction"         type="string";
	param name="args.allowAddAnotherSwitch"   type="boolean";
	param name="args.stripPermissionedFields" type="boolean" default=true;
	param name="args.permissionContext"       type="string"  default=args.objectName;
	param name="args.permissionContextKeys"   type="array"   default=ArrayNew( 1 );
	param name="args.validationResult"        type="any"     default=( rc.validationResult ?: '' );
	param name="args.cancelAction"            type="string"  default=event.buildAdminLink( linkTo="datamanager.manageOneToManyRecords", querystring='object=#args.objectName#&parentId=#args.parentId#&relationshipKey=#args.relationshipKey#' );

	addRecordPrompt     = translateResource( uri="preside-objects.#args.objectName#:addRecord.prompt", defaultValue="" );
	objectTitleSingular = translateResource( uri="preside-objects.#args.objectName#:title.singular", defaultValue=args.objectName );
	addRecordButton     = translateResource( uri="cms:datamanager.addrecord.btn", data=[  objectTitleSingular  ] );
	formId              = "addForm-" & CreateUUId();
</cfscript>

<cfoutput>
	<cfif Len( Trim( addRecordPrompt ) )>
		<p>#addRecordPrompt#</p>
		<div class="hr"></div>
	</cfif>

	<form id="#formId#" data-auto-focus-form="true" data-dirty-form="protect" class="form-horizontal" method="post" action="#args.addRecordAction#">
		<input type="hidden" name="parentId"        value="#args.parentId#"        />
		<input type="hidden" name="relationshipKey" value="#args.relationshipKey#" />

		#renderForm(
			  formName              = "preside-objects.#args.objectName#.admin.add"
			, context               = "admin"
			, formId                = formId
			, validationResult      = args.validationResult
			, savedData             = { "#args.relationshipKey#" = args.parentId }
			, suppressFields        = [ args.relationshipKey ]
			, permissionContext     = args.permissionContext
			, permissionContextKeys = args.permissionContextKeys
		)#

		<div class="form-actions row">
			<cfif args.allowAddAnotherSwitch>
				#renderFormControl(
					  type    = "yesNoSwitch"
					, context = "admin"
					, name    = "_addAnother"
					, id      = "_addAnother"
					, label   = translateResource( uri="cms:datamanager.add.another", data=[ objectTitleSingular ] )
				)#
			</cfif>

			<div class="col-md-offset-2">
				<a href="#args.cancelAction#" class="btn btn-default" data-global-key="c">
					<i class="fa fa-reply bigger-110"></i>
					#translateResource( "cms:datamanager.cancel.btn" )#
				</a>

				<button class="btn btn-info" type="submit" tabindex="#getNextTabIndex()#">
					<i class="fa fa-check bigger-110"></i>
					#addRecordButton#
				</button>
			</div>
		</div>
	</form>
</cfoutput>