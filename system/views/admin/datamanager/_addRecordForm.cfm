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
				<a href="#args.cancelAction#" class="btn btn-default" data-global-key="c">
					<i class="fa fa-reply bigger-110"></i>
					#translateResource( "cms:datamanager.cancel.btn" )#
				</a>

				<cfif args.draftsEnabled>
					<cfif args.canSaveDraft>
						<button type="submit" name="_saveAction" value="savedraft" class="btn btn-info" tabindex="#getNextTabIndex()#">
							<i class="fa fa-save bigger-110"></i> #translateResource( uri="cms:datamanager.add.record.draft.btn", data=[ LCase( objectTitleSingular ) ] )#
						</button>
					</cfif>
					<cfif args.canPublish>
						<button type="submit" name="_saveAction" value="publish" class="btn btn-warning" tabindex="#getNextTabIndex()#">
							<i class="fa fa-globe bigger-110"></i> #translateResource( uri="cms:datamanager.add.record.publish.btn", data=[ LCase( objectTitleSingular ) ] )#
						</button>
					</cfif>
				<cfelse>
					<button type="submit" name="_saveAction" value="add" class="btn btn-info" tabindex="#getNextTabIndex()#">
						<i class="fa fa-save bigger-110"></i> #translateResource( uri="cms:datamanager.addrecord.btn", data=[ LCase( objectTitleSingular ) ] )#
					</button>
				</cfif>
			</div>
		</div>

	</form>
</cfoutput>