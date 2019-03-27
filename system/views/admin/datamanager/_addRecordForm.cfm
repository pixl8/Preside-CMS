<cfscript>
	param name="args.objectName"              type="string";
	param name="args.addRecordAction"         type="string";
	param name="args.record"                  type="struct"  default={};
	param name="args.formName"                type="string"  default="preside-objects.#args.objectName#.admin.add";
	param name="args.mergeWithFormName"       type="string"  default="";
	param name="args.allowAddAnotherSwitch"   type="boolean";
	param name="args.validationResult"        type="any"     default=( rc.validationResult ?: '' );
	param name="args.hiddenFields"            type="struct"  default={};
	param name="args.fieldLayout"             type="string"  default="formcontrols.layouts.field";
	param name="args.fieldsetLayout"          type="string"  default="formcontrols.layouts.fieldset";
	param name="args.tabLayout"               type="string"  default="formcontrols.layouts.tab";
	param name="args.formLayout"              type="string"  default="formcontrols.layouts.form";
	param name="args.stripPermissionedFields" type="boolean" default=true;
	param name="args.permissionContext"       type="string"  default=args.objectName;
	param name="args.permissionContextKeys"   type="array"   default=ArrayNew( 1 );
	param name="args.additionalArgs"          type="struct"  default=StructNew();
	param name="args.preForm"                 type="string"  default="";
	param name="args.postForm"                type="string"  default="";
	param name="args.renderedActionButtons"   type="string"  default=renderViewlet( event="admin.datamanager._addRecordActionButtons", args=args );

	addRecordPrompt     = translateResource( uri="preside-objects.#args.objectName#:addRecord.prompt", defaultValue="" );
	objectTitleSingular = translateResource( uri="preside-objects.#args.objectName#:title.singular", defaultValue=args.objectName );
	formId              = "addForm-" & CreateUUId();

	args.record.append( args.hiddenFields, false );
</cfscript>

<cfoutput>
	<cfif Len( Trim( addRecordPrompt ) )>
		<p>#addRecordPrompt#</p>
		<div class="hr"></div>
	</cfif>

	<form id="#formId#" data-auto-focus-form="true" data-dirty-form="protect" class="form-horizontal" method="post" action="#args.addRecordAction#" enctype="multipart/form-data">
		<cfloop collection="#args.hiddenFields#" item="hiddenField">
			<cfif !listFindNoCase( "object,id,version", hiddenField )>
				<input type="hidden" name="#hiddenField#" value="#HTMLEditFormat( args.hiddenFields[ hiddenField ] )#" />
			</cfif>
		</cfloop>

		#args.preForm#

		#renderForm(
			  formName              = args.formName
			, mergeWithFormName     = args.mergeWithFormName
			, context               = "admin"
			, formId                = formId
			, savedData             = args.record
			, validationResult      = args.validationResult
			, fieldLayout           = args.fieldLayout
			, fieldsetLayout        = args.fieldsetLayout
			, tabLayout             = args.tabLayout
			, formLayout            = args.formLayout
			, permissionContext     = args.permissionContext
			, permissionContextKeys = args.permissionContextKeys
			, additionalArgs        = args.additionalArgs
		)#

		#args.postForm#

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

			#args.renderedActionButtons#
		</div>
	</form>
</cfoutput>