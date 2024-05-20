<!---@feature admin and sitetree--->
<cfscript>
	page             = prc.page            ?: QueryNew( "" );
	mainFormName     = prc.mainFormName    ?: "";
	mergeFormName    = prc.mergeFormName   ?: "";
	validationResult = rc.validationResult ?: "";
	formId           = "editForm-" & CreateUUID();
	editPagePrompt    = translateResource( uri="preside-objects.page:editRecord.prompt", defaultValue="" );

	prc.pageIcon     = "pencil";
	prc.pageTitle    = translateResource( uri="cms:sitetree.editPage.title", data=[ prc.page.title ] );

	pageId  = rc.id      ?: "";
	version = rc.version ?: "";

	topRightButtons = prc.topRightButtons ?: "";

	backToTreeLink  = prc.backToTreeLink  ?: "";
	backToTreeTitle = prc.backToTreeTitle ?: "";

	canPublish   = IsTrue( prc.canPublish   ?: "" );
	canSaveDraft = IsTrue( prc.canSaveDraft ?: "" );
</cfscript>

<cfoutput>
	#renderViewlet( event='admin.datamanager.versionNavigator', args={
		  object           = "page"
		, id               = pageId
		, version          = version
		, isDraft          = IsTrue( page._version_is_draft ?: "" )
		, baseUrl          = event.buildAdminLink( linkTo="sitetree.editPage", queryString="id=#pageId#&version={version}" )
		, allVersionsUrl   = event.buildAdminLink( linkTo="sitetree.pageHistory", queryString="id=#pageId#" )
		, discardDraftsUrl = ( canSaveDraft ? event.buildAdminlink( linkTo="sitetree.discardDraftsAction", queryString="id=#pageId#" ) : "" )
	} )#

	<cfif not isEmptyString( topRightButtons )>
		<div class="top-right-button-group">#topRightButtons#</div>
	</cfif>

	<cfif Len( Trim( editPagePrompt ) )>
		<p>#editPagePrompt#</p>
		<div class="hr"></div>
	</cfif>

	<form id="#formId#" data-auto-focus-form="true" data-dirty-form="protect" class="form-horizontal" method="post" action="#event.buildAdminLink( linkTo='sitetree.editPageAction' )#">
		<input type="hidden" name="id" value="#event.getValue( name="id", defaultValue="" )#" />

		#renderForm(
			  formName                = mainFormName
			, mergeWithFormName       = mergeFormName
			, context                 = "admin"
			, formId                  = formId
			, savedData               = page
			, validationResult        = validationResult
			, stripPermissionedFields = true
			, permissionContext       = "page"
			, permissionContextKeys   = ( prc.pagePermissionContext ?: [] )
		)#

		#renderFormControl(
			  type    = "yesNoSwitch"
			, context = "admin"
			, name    = "_backToEdit"
			, id      = "_backToEdit"
			, label   = translateResource( uri="cms:sitetree.editPage.backToEdit" )
		)#

		<div class="form-actions row">
			<div class="col-md-offset-2">
				<a href="#backToTreeLink#" class="btn btn-default" data-global-key="c">
					<i class="fa fa-reply bigger-110"></i>
					#translateResource( "cms:sitetree.cancel.btn" )#
				</a>

				<cfif canSaveDraft>
					<button type="submit" name="_saveAction" value="savedraft" class="btn btn-info" tabindex="#getNextTabIndex()#">
						<i class="fa fa-save bigger-110"></i> #translateResource( "cms:sitetree.savepage.draft.btn" )#
					</button>
				</cfif>

				<cfif canPublish>
					<button type="submit" name="_saveAction" value="publish" class="btn btn-warning" tabindex="#getNextTabIndex()#">
						<i class="fa fa-globe bigger-110"></i> #translateResource( "cms:sitetree.savepage.btn" )#
					</button>
				</cfif>
			</div>
		</div>
	</form>
</cfoutput>