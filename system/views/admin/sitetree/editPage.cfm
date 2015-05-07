<cfscript>
	page             = prc.page            ?: QueryNew('');
	mainFormName     = prc.mainFormName    ?: ""
	mergeFormName    = prc.mergeFormName   ?: ""
	validationResult = rc.validationResult ?: "";
	formId           = "editForm-" & CreateUUId();
	editPagePrompt    = translateResource( uri="preside-objects.page:editRecord.prompt", defaultValue="" );

	prc.pageIcon     = "pencil";
	prc.pageTitle    = translateResource( uri="cms:sitetree.editPage.title", data=[ prc.page.title ] );

	pageId  = rc.id      ?: "";
	version = rc.version ?: "";

	safeTitle = HtmlEditFormat( page.title );

	allowableChildPageTypes = prc.allowableChildPageTypes ?: "";
	managedChildPageTypes   = prc.managedChildPageTypes   ?: "";
	isSystemPage            = prc.isSystemPage            ?: false;
	canAddChildren          = prc.canAddChildren          ?: false;
	canDeletePage           = prc.canDeletePage           ?: false;
	canSortChildren         = prc.canSortChildren         ?: false;
	canManagePagePerms      = prc.canManagePagePerms      ?: false;

	hasContextMenu = canDeletePage || canSortChildren || canManagePagePerms || managedChildPageTypes.len();
</cfscript>

<cfoutput>
	#renderViewlet( event='admin.datamanager.versionNavigator', args={
		  object         = "page"
		, id             = pageId
		, version        = version
		, baseUrl        = event.buildAdminLink( linkTo="sitetree.editPage", queryString="id=#pageId#&version=" )
		, allVersionsUrl = event.buildAdminLink( linkTo="sitetree.pageHistory", queryString="id=#pageId#" )
	} )#

	<div class="top-right-button-group">
		<cfif hasContextMenu>
			<button data-toggle="dropdown" class="btn btn-sm pull-right inline">
				<span class="fa fa-caret-down"></span>
				<i class="fa fa-fw fa-cog"></i>&nbsp; #translateResource( uri="cms:sitetree.editpage.options.dropdown.btn" )#
			</button>
			<ul class="dropdown-menu pull-right" role="menu" aria-labelledby="dLabel">
				<cfif canDeletePage>
					<li>
						<a data-global-key="d" href="#event.buildAdminLink( linkTo='sitetree.trashPageAction', queryString='id=' & pageId )#" class="confirmation-prompt" title="#translateResource( uri="cms:sitetree.trash.child.page.link", data=[ safeTitle ] )#">
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
			</ul>
		</cfif>

		<a class="pull-right inline" href="#event.buildLink( page=page.id )#" data-global-key="p" target="_blank">
			<button class="btn btn-info btn-sm">
				<i class="fa fa-external-link"></i>
				#translateResource( "cms:sitetree.preview.page.btn" )#
			</button>
		</a>
	</div>

	<cfif Len( Trim( editPagePrompt ) )>
		<p>#editPagePrompt#</p>
		<div class="hr"></div>
	</cfif>

	<form id="#formId#" data-auto-focus-form="true" data-dirty-form="protect" class="form-horizontal" method="post" action="#event.buildAdminLink( linkTo='sitetree.editPageAction' )#">
		<input type="hidden" name="id" value="#event.getValue( name='id', defaultValue='' )#" />

		#renderForm(
			  formName          = mainFormName
			, mergeWithFormName = mergeFormName
			, context           = "admin"
			, formId            = formId
			, savedData         = page
			, validationResult  = validationResult
		)#

		<div class="form-actions row">
			<div class="col-md-offset-2">
				<a href="#event.buildAdminLink( linkTo="sitetree" )#" class="btn btn-default" data-global-key="c">
					<i class="fa fa-reply bigger-110"></i>
					#translateResource( "cms:sitetree.cancel.btn" )#
				</a>

				<button class="btn btn-info" type="submit" tabindex="#getNextTabIndex()#">
					<i class="fa fa-check bigger-110"></i>
					#translateResource( "cms:sitetree.savepage.btn" )#
				</button>
			</div>
		</div>
	</form>
</cfoutput>