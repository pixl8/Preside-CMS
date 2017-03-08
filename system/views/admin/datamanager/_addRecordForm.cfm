<cfscript>
	param name="args.objectName"              type="string";
	param name="args.addRecordAction"         type="string";
	param name="args.record"                  type="struct"  default={};
	param name="args.formName"                type="string"  default="preside-objects.#args.objectName#.admin.add";
	param name="args.mergeWithFormName"       type="string"  default="";
	param name="args.allowAddAnotherSwitch"   type="boolean";
	param name="args.draftsEnabled"           type="boolean" default=false;
	param name="args.canPublish"              type="boolean" default=false;
	param name="args.canSaveDraft"            type="boolean" default=false;
	param name="args.validationResult"        type="any"     default=( rc.validationResult ?: '' );
	param name="args.cancelAction"            type="string"  default=event.buildAdminLink( linkTo="datamanager.object", querystring='id=#args.objectName#' );
	param name="args.cancelLabel"             type="string"  default=translateResource( "cms:datamanager.cancel.btn" );
	param name="args.hiddenFields"            type="struct"  default={};
	param name="args.fieldLayout"             type="string"  default="formcontrols.layouts.field";
	param name="args.fieldsetLayout"          type="string"  default="formcontrols.layouts.fieldset";
	param name="args.tabLayout"               type="string"  default="formcontrols.layouts.tab";
	param name="args.formLayout"              type="string"  default="formcontrols.layouts.form";
	param name="args.stripPermissionedFields" type="boolean" default=true;
	param name="args.permissionContext"       type="string"  default=args.objectName;
	param name="args.permissionContextKeys"   type="array"   default=ArrayNew( 1 );

	addRecordPrompt     = translateResource( uri="preside-objects.#args.objectName#:addRecord.prompt", defaultValue="" );
	objectTitleSingular = translateResource( uri="preside-objects.#args.objectName#:title.singular", defaultValue=args.objectName );
	formId              = "addForm-" & CreateUUId();

	param name="args.addRecordLabel"        type="string"  default=translateResource( uri="cms:datamanager.addrecord.btn"         , data=[ objectTitleSingular ] );
	param name="args.publishLabel"          type="string"  default=translateResource( uri="cms:datamanager.add.record.publish.btn", data=[ objectTitleSingular ] );
	param name="args.saveDraftLabel"        type="string"  default=translateResource( uri="cms:datamanager.add.record.draft.btn"  , data=[ objectTitleSingular ] );

	args.record.append( args.hiddenFields, false );
</cfscript>

<cfoutput>
	<cfif Len( Trim( addRecordPrompt ) )>
		<p>#addRecordPrompt#</p>
		<div class="hr"></div>
	</cfif>

	<form id="#formId#" data-auto-focus-form="true" data-dirty-form="protect" class="form-horizontal" method="post" action="#args.addRecordAction#">
		<cfloop collection="#args.hiddenFields#" item="hiddenField">
			<cfif !listFindNoCase( "object,id,version", hiddenField )>
				<input type="hidden" name="#hiddenField#" value="#HTMLEditFormat( args.hiddenFields[ hiddenField ] )#" />
			</cfif>
		</cfloop>

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
					#args.cancelLabel#
				</a>

				<cfif args.draftsEnabled>
					<cfif args.canSaveDraft>
						<button type="submit" name="_saveAction" value="savedraft" class="btn btn-info" tabindex="#getNextTabIndex()#">
							<i class="fa fa-save bigger-110"></i> #args.saveDraftLabel#
						</button>
					</cfif>
					<cfif args.canPublish>
						<button type="submit" name="_saveAction" value="publish" class="btn btn-warning" tabindex="#getNextTabIndex()#">
							<i class="fa fa-globe bigger-110"></i> #args.publishLabel#
						</button>
					</cfif>
				<cfelse>
					<button type="submit" name="_saveAction" value="add" class="btn btn-info" tabindex="#getNextTabIndex()#">
						<i class="fa fa-save bigger-110"></i> #args.addRecordLabel#
					</button>
				</cfif>
			</div>
		</div>

	</form>
</cfoutput>