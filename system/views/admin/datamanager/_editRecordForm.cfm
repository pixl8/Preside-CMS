<cfscript>
	param name="args.editRecordAction"        type="string" default=event.buildAdminLink( linkTo='datamanager.editRecordAction' );
	param name="args.object"                  type="string";
	param name="args.id"                      type="string";
	param name="args.version"                 type="string"  default="";
	param name="args.record"                  type="struct"  default={};
	param name="args.formName"                type="string"  default="preside-objects.#args.object#.admin.edit";
	param name="args.mergeWithFormName"       type="string"  default="";
	param name="args.useVersioning"           type="boolean" default=false;
	param name="args.draftsEnabled"           type="boolean" default=false;
	param name="args.canPublish"              type="boolean" default=false;
	param name="args.canSaveDraft"            type="boolean" default=false;
	param name="args.cancelAction"            type="string"  default=event.buildAdminLink( linkTo="datamanager.object", querystring='id=#args.object#' );
	param name="args.cancelLabel"             type="string"  default=translateResource( "cms:datamanager.cancel.btn" );
	param name="args.hiddenFields"            type="struct"  default={};
	param name="args.fieldLayout"             type="string"  default="formcontrols.layouts.field";
	param name="args.fieldsetLayout"          type="string"  default="formcontrols.layouts.fieldset";
	param name="args.tabLayout"               type="string"  default="formcontrols.layouts.tab";
	param name="args.formLayout"              type="string"  default="formcontrols.layouts.form";
	param name="args.stripPermissionedFields" type="boolean" default=true;
	param name="args.permissionContext"       type="string"  default=args.object;
	param name="args.permissionContextKeys"   type="array"   default=ArrayNew( 1 );

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

	<form id="#formId#" data-auto-focus-form="true" data-dirty-form="protect" class="form-horizontal edit-object-form" method="post" action="#args.editRecordAction#">
		<input type="hidden" name="object" value="#args.object#" />
		<input type="hidden" name="id"     value="#args.id#" />
		<cfif args.useVersioning>
			<input type="hidden" name="version" value="#args.version#" />
		</cfif>
		<cfloop collection="#args.hiddenFields#" item="hiddenField">
			<cfif !listFindNoCase( "object,id,version", hiddenField )>
				<input type="hidden" name="#hiddenField#" value="#HTMLEditFormat( args.hiddenFields[ hiddenField ] )#" />
			</cfif>
		</cfloop>

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
		)#

		<div class="form-actions row">
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
						<i class="fa fa-save bigger-110"></i> #args.editRecordLabel#
					</button>
				</cfif>
			</div>
		</div>
	</form>
</cfoutput>