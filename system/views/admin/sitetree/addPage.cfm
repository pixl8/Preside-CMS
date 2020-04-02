<cfscript>
	parentPage       = prc.parentPage      ?: QueryNew('');
	mainFormName     = prc.mainFormName    ?: "";
	mergeFormName    = prc.mergeFormName   ?: "";
	validationResult = rc.validationResult ?: "";
	formId           = "addForm-" & CreateUUId();
	addPagePrompt    = translateResource( uri="preside-objects.page:addRecord.prompt", defaultValue="" );

	prc.pageIcon     = "plus";
	if ( parentPage.recordCount ) {
		prc.pageTitle    = translateResource( uri="cms:sitetree.addChildPage.title", data=[ parentPage.title ] );
	} else {
		prc.pageTitle    = translateResource( "cms:sitetree.addPage.title" );
	}

	canPublish   = IsTrue( prc.canPublish   ?: "" );
	canSaveDraft = IsTrue( prc.canSaveDraft ?: "" );
	cancelLink   = Len( Trim( prc.cancelLink ?: "" ) ) ? prc.cancelLink : event.buildAdminLink( linkTo="sitetree" );
</cfscript>

<cfoutput>
	<cfif Len( Trim( addPagePrompt ) )>
		<p>#addPagePrompt#</p>
		<div class="hr"></div>
	</cfif>

	<form id="#formId#" data-auto-focus-form="true" data-dirty-form="protect" class="form-horizontal" method="post" action="#event.buildAdminLink( linkTo='sitetree.addPageAction' )#">
		<input type="hidden" name="parent_page" value="#( rc.parent_page ?: '')#" />
		<input type="hidden" name="page_type"   value="#( rc.page_type   ?: '')#" />

		#renderForm(
			  formName                = mainFormName
			, mergeWithFormName       = mergeFormName
			, context                 = "admin"
			, formId                  = formId
			, validationResult        = validationResult
			, stripPermissionedFields = true
			, permissionContext       = "page"
			, permissionContextKeys   = ( prc.pagePermissionContext ?: [] )
		)#

		<div class="form-actions row">
			#renderFormControl(
				  type    = "yesNoSwitch"
				, context = "admin"
				, name    = "_addAnother"
				, id      = "_addAnother"
				, label   = translateResource( uri="cms:sitetree.add.another" )
			)#

			<div class="col-md-offset-2">
				<a href="#cancelLink#" class="btn btn-default" data-global-key="c">
					<i class="fa fa-reply bigger-110"></i>
					#translateResource( "cms:sitetree.cancel.btn" )#
				</a>

				<cfif canSaveDraft>
					<button type="submit" name="_saveAction" value="savedraft" class="btn btn-info" tabindex="#getNextTabIndex()#">
						<i class="fa fa-save bigger-110"></i> #translateResource( "cms:sitetree.addpage.draft.btn" )#
					</button>
				</cfif>
				<cfif canPublish>
					<button type="submit" name="_saveAction" value="publish" class="btn btn-warning" tabindex="#getNextTabIndex()#">
						<i class="fa fa-globe bigger-110"></i> #translateResource( "cms:sitetree.addpage.btn" )#
					</button>
				</cfif>
			</div>
		</div>
	</form>
</cfoutput>