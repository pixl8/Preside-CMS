<!---@feature admin--->
<cfscript>
	param name="args.object"                  type="string";
	param name="args.id"                      type="string";
	param name="args.cloneRecordAction"       type="string"  default=event.buildAdminLink( objectName=args.object, operation="cloneRecordAction" );
	param name="args.version"                 type="string"  default="";
	param name="args.cloneableData"           type="struct"  default={};
	param name="args.formName"                type="string"  default="preside-objects.#args.object#.admin.clone";
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
	param name="args.resultAction"            type="string"  default="";
	param name="args.preForm"                 type="string"  default="";
	param name="args.postForm"                type="string"  default="";
	param name="args.objectName"              type="string"  default=args.object;
	param name="args.renderedActionButtons"   type="string"  default=renderViewlet( event="admin.datamanager._cloneRecordActionButtons", args=args );
	param name="args.additionalArgs"          type="struct"  default=StructNew();

	objectTitleSingular = prc.objectTitle ?: "";
	cloneRecordPrompt   = translateResource( uri="preside-objects.#args.object#:cloneRecord.prompt", defaultValue="" );
	formId              = "cloneForm-" & CreateUUId();

	args.cloneableData.append( args.hiddenFields, false );
</cfscript>

<cfoutput>
	<cfif Len( Trim( cloneRecordPrompt ) )>
		<p>#cloneRecordPrompt#</p>
		<div class="hr"></div>
	</cfif>

	<form id="#formId#" data-auto-focus-form="true" data-dirty-form="protect" class="form-horizontal edit-object-form" method="post" action="#args.cloneRecordAction#" enctype="multipart/form-data">
		<input type="hidden" name="object" value="#args.object#" />
		<input type="hidden" name="id"     value="#args.id#" />
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
			, savedData               = args.cloneableData
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