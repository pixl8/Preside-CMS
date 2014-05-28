<cfscript>
	param name="args.editRecordAction"  type="string" default=event.buildAdminLink( linkTo='datamanager.editRecordAction' );
	param name="args.object"            type="string";
	param name="args.id"                type="string";
	param name="args.record"            type="struct"  default={};
	param name="args.formName"          type="string"  default="preside-objects.#args.object#.admin.edit";
	param name="args.mergeWithFormName" type="string"  default="";
	param name="args.useVersioning"     type="boolean" default=false;
	param name="args.cancelAction"      type="string"  default=event.buildAdminLink( linkTo="datamanager.object", querystring='id=#args.object#' );

	objectTitleSingular = translateResource( uri="preside-objects.#args.object#:title.singular", defaultValue=args.object );
	editRecordPrompt    = translateResource( uri="preside-objects.#args.object#:editRecord.prompt", defaultValue="" );
	saveButton          = translateResource( uri="cms:datamanager.savechanges.btn", data=[ LCase( objectTitleSingular ) ] );
	formId              = "editForm-" & CreateUUId();
</cfscript>

<cfoutput>
	<cfif Len( Trim( editRecordPrompt ) )>
		<p>#editRecordPrompt#</p>
		<div class="hr"></div>
	</cfif>

	<form id="#formId#" data-auto-focus-form="true" data-dirty-form="protect" class="form-horizontal edit-object-form" method="post" action="#args.editRecordAction#">
		<input type="hidden" name="object" value="#args.object#" />
		<input type="hidden" name="id"     value="#args.id#" />

		#renderForm(
			  formName          = args.formName
			, mergeWithFormName = args.mergeWithFormName
			, context           = "admin"
			, formId            = formId
			, savedData         = args.record
			, validationResult  = rc.validationResult ?: ""
		)#

		<div class="form-actions row">
			<div class="col-md-offset-2">
				<a href="#args.cancelAction#" class="btn btn-default" data-global-key="c">
					<i class="fa fa-reply bigger-110"></i>
					#translateResource( "cms:datamanager.cancel.btn" )#
				</a>

				<button class="btn btn-info" type="submit" tabindex="#getNextTabIndex()#">
					<i class="fa fa-check bigger-110"></i>
					#saveButton#
				</button>
			</div>
		</div>
	</form>
</cfoutput>