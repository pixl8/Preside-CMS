<cfscript>
	page             = prc.page            ?: QueryNew('');
	mainFormName     = prc.mainFormName    ?: "";
	mergeFormName    = prc.mergeFormName   ?: "";
	validationResult = rc.validationResult ?: "";
	formId           = "editForm-" & CreateUUId();
	editPagePrompt    = translateResource( uri="preside-objects.page:editRecord.prompt", defaultValue="" );

	prc.pageIcon     = "pencil";
	prc.pageTitle    = translateResource( uri="cms:sitetree.editPage.title", data=[ prc.page.title ] );

	pageId     = rc.id      ?: "";
	version    = rc.version ?: "";
	childCount = prc.childCount ?: 0;

	safeTitle = HtmlEditFormat( page.title );

	allowableChildPageTypes = prc.allowableChildPageTypes ?: "";
	managedChildPageTypes   = prc.managedChildPageTypes   ?: "";
	isSystemPage            = prc.isSystemPage            ?: false;
	canAddChildren          = prc.canAddChildren          ?: false;
	canDeletePage           = prc.canDeletePage           ?: false;
	canSortChildren         = prc.canSortChildren         ?: false;
	canManagePagePerms      = prc.canManagePagePerms      ?: false;
	canClone                = prc.canClone                ?: false;
	canActivate             = prc.canActivate             ?: false;
	translations            = prc.translations            ?: [];
	translateUrlBase        = event.buildAdminLink( linkTo="sitetree.translatePage", queryString="id=#pageId#&language=" );

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

	<div class="top-right-button-group">
		<div class="pull-right">
			<button data-toggle="dropdown" class="btn btn-sm inline">
				<span class="fa fa-caret-down"></span>
				<i class="fa fa-fw fa-cog"></i>&nbsp; #translateResource( uri="cms:sitetree.editpage.options.dropdown.btn" )#
			</button>
			<ul class="dropdown-menu pull-right" role="menu" aria-labelledby="dLabel">
				<cfif canClone>
					<li>
						<a href="#event.buildAdminLink( linkTo='sitetree.clonePage', queryString='id=' & pageId )#">
							<i class="fa fa-fw fa-clone"></i>&nbsp;
							#translateResource( "cms:sitetree.clone.page.dropdown" )#
						</a>
					</li>
				</cfif>
				<cfif canAddChildren>
					<cfset addPageLinkTitle = translateResource( uri="cms:sitetree.add.child.page.link", data=[ safeTitle ] ) />
					<li>
						<cfif allowableChildPageTypes eq "*" or ListLen( allowableChildPageTypes ) gt 1>
							<a data-context-key="a" href="#event.buildAdminLink( linkTo='sitetree.pageTypeDialog', queryString='parentPage=' & pageId )#" data-toggle="bootbox-modal" data-buttons="cancel" data-modal-class="page-type-picker" title="#HtmlEditFormat( addPageLinkTitle )#">
								<i class="fa fa-fw fa-plus"></i>&nbsp;
								#addPageLinkTitle#
							</a>
						<cfelse>
							<a data-context-key="a" href="#event.buildAdminLink( linkTo='sitetree.addPage', querystring='parent_page=#pageId#&page_type=#allowableChildPageTypes#' )#" title="#HtmlEditFormat( addPageLinkTitle )#">
								<i class="fa fa-fw fa-plus"></i>&nbsp;
								#addPageLinkTitle#
							</a>
						</cfif>
					</li>
				</cfif>

				<cfif canActivate>
					<li>
						<cfif IsTrue( page.active )>
							<a href="#event.buildAdminLink( linkTo='sitetree.deactivatePageAction', queryString='id=#page.id#' )#" class="confirmation-prompt" title="#translateResource( uri="cms:sitetree.deactivate.child.page.link", data=[ safeTitle ] )#">
								<i class="fa fa-fw fa-times-circle"></i>&nbsp;
								#translateResource( "cms:sitetree.deactivate.page.dropdown" )#
							</a>
						<cfelse>
							<a href="#event.buildAdminLink( linkTo='sitetree.activatePageAction', queryString='id=#page.id#' )#" class="confirmation-prompt" title="#translateResource( uri="cms:sitetree.activate.child.page.link", data=[ safeTitle ] )#">
								<i class="fa fa-fw fa-check-circle"></i>&nbsp;
								#translateResource( "cms:sitetree.activate.page.dropdown" )#
							</a>
						</cfif>
					</li>
				</cfif>

				<cfif canDeletePage>
					<li>
						<a data-global-key="d" href="#event.buildAdminLink( linkTo='sitetree.trashPageAction', queryString='id=' & pageId )#" class="confirmation-prompt" title="#translateResource( uri="cms:sitetree.trash.child.page.link", data=[ safeTitle ] )#" data-has-children="#childCount#">
							<i class="fa fa-fw fa-trash-o"></i>&nbsp;
							#translateResource( "cms:sitetree.trash.page.dropdown" )#
						</a>
					</li>
				</cfif>
				<cfif canSortChildren>
					<li>
						<a data-global-key="o" href="#event.buildAdminLink( linkTo='sitetree.reorderChildren', queryString='id=' & pageId )#" title="#translateResource( uri="cms:sitetree.reorder.children.link", data=[ safeTitle ] )#">
							<i class="fa fa-fw fa-sort-amount-asc"></i>&nbsp;
							#translateResource( "cms:sitetree.sort.children.dropdown" )#
						</a>
					</li>
				</cfif>
				<cfif canManagePagePerms>
					<li>
						<a data-global-key="m" href="#event.buildAdminLink( linkTo='sitetree.editPagePermissions', queryString='id=' & pageId )#">
							<i class="fa fa-fw fa-lock"></i>&nbsp;
							#translateResource( "cms:sitetree.page.permissioning.dropdown" )#
						</a>
					</li>
				</cfif>
				<cfloop list="#managedChildPageTypes#" index="i" item="managedPageType">
					<li>
						<a href="#event.buildAdminLink( linkTo='sitetree.managedChildren', queryString='parent=#pageId#&pageType=#managedPageType#' )#">
							<i class="fa fa-fw fa-ellipsis-h"></i>&nbsp;
							#translateResource( uri="cms:sitetree.manage.type", data=[ LCase( translateResource( "page-types.#managedPageType#:name" ) ) ] )#
						</a>
					</li>
				</cfloop>

				<li>
					<a data-global-key="p" href="#event.buildAdminLink( linkTo='sitetree.previewPage', queryString='id=#pageId#' )#">
						<i class="fa fa-fw fa-external-link"></i>&nbsp;
						#translateResource( "cms:sitetree.preview.page.btn" )#
					</a>
				</li>
			</ul>
		</div>

		<cfif translations.len()>
			<div class="pull-right">
				<button data-toggle="dropdown" class="btn btn-sm btn-info inline">
					<span class="fa fa-caret-down"></span>
					<i class="fa fa-fw fa-globe"></i>&nbsp; #translateResource( uri="cms:sitetree.translate.page.btn" )#
				</button>

				<ul class="dropdown-menu pull-right" role="menu" aria-labelledby="dLabel">
					<cfloop array="#translations#" index="i" item="language">
						<li>
							<a href="#translateUrlBase##language.id#">
								<i class="fa fa-fw fa-pencil"></i>&nbsp; #language.name# (#translateResource( 'cms:multilingal.status.#language.status#' )#)
							</a>
						</li>
					</cfloop>
				</ul>
			</div>
		</cfif>

		<div class="pull-right">
			<a href="#backToTreeLink#"><i class="fa fa-fw fa-reply"></i> #backToTreeTitle#</a>
		</div>
	</div>

	<cfif Len( Trim( editPagePrompt ) )>
		<p>#editPagePrompt#</p>
		<div class="hr"></div>
	</cfif>

	<form id="#formId#" data-auto-focus-form="true" data-dirty-form="protect" class="form-horizontal" method="post" action="#event.buildAdminLink( linkTo='sitetree.editPageAction' )#">
		<input type="hidden" name="id" value="#event.getValue( name='id', defaultValue='' )#" />

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