<cfscript>
	param name="args.object"                  type="string";
	param name="args.id"                      type="string";
	param name="args.editRecordAction"        type="string"  default=event.buildAdminLink( objectName=args.object, operation="editRecordAction", recordId=args.id );
	param name="args.version"                 type="string"  default="";
	param name="args.record"                  type="struct"  default={};
	param name="args.formName"                type="string"  default="preside-objects.#args.object#.admin.edit";
	param name="args.mergeWithFormName"       type="string"  default="";
	param name="args.useVersioning"           type="boolean" default=false;
	param name="args.hiddenFields"            type="struct"  default={};
	param name="args.fieldLayout"             type="string"  default="formcontrols.layouts.field";
	param name="args.fieldsetLayout"          type="string"  default="formcontrols.layouts.fieldset";
	param name="args.tabLayout"               type="string"  default="formcontrols.layouts.tab";
	param name="args.formLayout"              type="string"  default="formcontrols.layouts.form";
	param name="args.stripPermissionedFields" type="boolean" default=true;
	param name="args.permissionContext"       type="string"  default=args.object;
	param name="args.permissionContextKeys"   type="array"   default=ArrayNew( 1 );
	param name="args.additionalArgs"          type="struct"  default=StructNew();
	param name="args.resultAction"            type="string"  default="";
	param name="args.preForm"                 type="string"  default="";
	param name="args.postForm"                type="string"  default="";
	param name="args.objectName"              type="string"  default=args.object;
	param name="args.renderedActionButtons"   type="string"  default=renderViewlet( event="admin.datamanager._editRecordActionButtons", args=args );

	objectTitleSingular = translateResource( uri="preside-objects.#args.object#:title.singular", defaultValue=args.object );
	editRecordPrompt    = translateResource( uri="preside-objects.#args.object#:editRecord.prompt", defaultValue="" );
	formId              = "editForm-" & CreateUUId();

	param name="args.editRecordLabel"   type="string"  default=translateResource( uri="cms:datamanager.savechanges.btn"        , data=[ objectTitleSingular ] );
	param name="args.publishLabel"      type="string"  default=translateResource( uri="cms:datamanager.edit.record.publish.btn", data=[ objectTitleSingular ] );
	param name="args.saveDraftLabel"    type="string"  default=translateResource( uri="cms:datamanager.edit.record.draft.btn"  , data=[ objectTitleSingular ] );

	args.record.append( args.hiddenFields, false );
</cfscript>

<cfoutput>
	<cfif Len( Trim( editRecordPrompt ) )>
		<p>#editRecordPrompt#</p>
		<div class="hr"></div>
	</cfif>

	<form id="#formId#" data-auto-focus-form="true" data-dirty-form="protect" class="form-horizontal edit-object-form" method="post" action="#args.editRecordAction#" enctype="multipart/form-data">
		<input type="hidden" name="object" value="#args.object#" />
		<input type="hidden" name="id"     value="#args.id#" />
		<cfif args.useVersioning>
			<input type="hidden" name="version" value="#args.version#" />
		</cfif>
		<cfif args.resultAction.len()>
			<input type="hidden" name="__resultAction" value="#args.resultAction#" />
		</cfif>
		<cfloop collection="#args.hiddenFields#" item="hiddenField">
			<cfif !listFindNoCase( "object,id,version", hiddenField )>
				<input type="hidden" name="#hiddenField#" value="#HTMLEditFormat( args.hiddenFields[ hiddenField ] )#" />
			</cfif>
		</cfloop>

		#args.preForm#

		#renderForm(
			  formName                = args.formName
			, mergeWithFormName       = args.mergeWithFormName
			, context                 = "admin"
			, formId                  = formId
			, savedData               = args.record
			, validationResult        = rc.validationResult ?: ""
			, fieldLayout             = args.fieldLayout
			, fieldsetLayout          = args.fieldsetLayout
			, tabLayout               = args.tabLayout
			, formLayout              = args.formLayout
			, stripPermissionedFields = args.stripPermissionedFields
			, permissionContext       = args.permissionContext
			, permissionContextKeys   = args.permissionContextKeys
			, additionalArgs          = args.additionalArgs
		)#
		#args.postForm#

		<div class="form-actions row">
			#args.renderedActionButtons#
		</div>
	</form>
</cfoutput>