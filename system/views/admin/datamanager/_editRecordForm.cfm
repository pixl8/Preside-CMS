<cfscript>
	param name="args.editRecordAction"  type="string" default=event.buildAdminLink( linkTo='datamanager.editRecordAction' );
	param name="args.object"            type="string";
	param name="args.id"                type="string";
	param name="args.version"           type="string"  default="";
	param name="args.record"            type="struct"  default={};
	param name="args.formName"          type="string"  default="preside-objects.#args.object#.admin.edit";
	param name="args.mergeWithFormName" type="string"  default="";
	param name="args.useVersioning"     type="boolean" default=false;
	param name="args.draftsEnabled"     type="boolean" default=false;
	param name="args.canPublish"        type="boolean" default=false;
	param name="args.canSaveDraft"      type="boolean" default=false;
	param name="args.cancelAction"      type="string"  default=event.buildAdminLink( linkTo="datamanager.object", querystring='id=#args.object#' );

	objectTitleSingular = translateResource( uri="preside-objects.#args.object#:title.singular", defaultValue=args.object );
	editRecordPrompt    = translateResource( uri="preside-objects.#args.object#:editRecord.prompt", defaultValue="" );
	formId              = "editForm-" & CreateUUId();

	actions = [];
	if ( args.draftsEnabled ) {
		if ( args.canSaveDraft ) {
			actions.append( { key="savedraft", title=translateResource( uri="cms:datamanager.edit.record.draft.btn", data=[ LCase( objectTitleSingular ) ] ) } );
		}
		if ( args.canPublish ) {
			actions.append( { key="publish", title=translateResource( uri="cms:datamanager.edit.record.publish.btn", data=[ LCase( objectTitleSingular ) ] ) } );
		}
	} else {
		actions.append( { key="add", title=translateResource( uri="cms:datamanager.savechanges.btn", data=[ LCase( objectTitleSingular ) ] ) } );
	}
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
				<div class="btn-group">
					<a href="#args.cancelAction#" class="btn btn-default" data-global-key="c">
						<i class="fa fa-reply bigger-110"></i>
						#translateResource( "cms:datamanager.cancel.btn" )#
					</a>
				</div>

				<input name="_saveAction" type="hidden" value="#actions[1].key#">
				<cfif actions.len() == 1>
					<div class="btn-group">
						<button class="btn btn-info" type="submit" tabindex="#getNextTabIndex()#">
							<i class="fa fa-save bigger-110"></i>
							#actions[1].title#
						</button>
					</div>
				<cfelse>
					<div class="btn-group" data-multi-submit-field="_saveAction">
						<button type="submit" class="btn btn-info">
							<i class="fa fa-save bigger-110"></i> #actions[1].title#
						</button>
						<button type="button" class="btn btn-info dropdown-toggle" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false">
							<i class="fa fa-caret-down bigger-110"></i><span class="sr-only">Toggle Dropdown</span>
						</button>
						<ul class="dropdown-menu">
							<cfloop array="#actions#" index="i" item="action">
								<li><a href="##" data-action-key="#action.key#">#action.title#</a></li>
							</cfloop>
						</ul>
					</div>
				</cfif>
			</div>
		</div>
	</form>
</cfoutput>