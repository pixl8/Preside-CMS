<cfscript>
	param name="args.objectName"            type="string";
	param name="args.addRecordAction"       type="string";
	param name="args.allowAddAnotherSwitch" type="boolean";
	param name="args.draftsEnabled"         type="boolean" default=false;
	param name="args.canPublish"            type="boolean" default=false;
	param name="args.canSaveDraft"          type="boolean" default=false;
	param name="args.validationResult"      type="any"     default=( rc.validationResult ?: '' );
	param name="args.cancelAction"          type="string"  default=event.buildAdminLink( linkTo="datamanager.object", querystring='id=#args.objectName#' );

	addRecordPrompt     = translateResource( uri="preside-objects.#args.objectName#:addRecord.prompt", defaultValue="" );
	objectTitleSingular = translateResource( uri="preside-objects.#args.objectName#:title.singular", defaultValue=args.objectName );
	formId              = "addForm-" & CreateUUId();

	actions = [];
	if ( args.draftsEnabled ) {
		if ( args.canSaveDraft ) {
			actions.append( { key="savedraft", title=translateResource( uri="cms:datamanager.add.record.draft.btn", data=[ LCase( objectTitleSingular ) ] ) } );
		}
		if ( args.canPublish ) {
			actions.append( { key="publish", title=translateResource( uri="cms:datamanager.add.record.publish.btn", data=[ LCase( objectTitleSingular ) ] ) } );
		}
	} else {
		actions.append( { key="add", title=translateResource( uri="cms:datamanager.addrecord.btn", data=[ LCase( objectTitleSingular ) ] ) } );
	}
</cfscript>

<cfoutput>
	<cfif Len( Trim( addRecordPrompt ) )>
		<p>#addRecordPrompt#</p>
		<div class="hr"></div>
	</cfif>

	<form id="#formId#" data-auto-focus-form="true" data-dirty-form="protect" class="form-horizontal" method="post" action="#args.addRecordAction#">
		#renderForm(
			  formName         = "preside-objects.#args.objectName#.admin.add"
			, context          = "admin"
			, formId           = formId
			, validationResult = args.validationResult
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