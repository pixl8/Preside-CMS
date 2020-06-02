<cfscript>
	param name="args.id"                          type="string";
	param name="args.parent_page"                 type="string";
	param name="args._hierarchy_depth"            type="string";
	param name="args.title"                       type="string";
	param name="args.page_type"                   type="string";
	param name="args.main_image"                  type="string";
	param name="args.slug"                        type="string";
	param name="args.full_slug"                   type="string";
	param name="args.datecreated"                 type="date";
	param name="args.datemodified"                type="date";
	param name="args.embargo_date"                type="any" default="";
	param name="args.expiry_date"                 type="any" default="";
	param name="args.active"                      type="boolean";
	param name="args.trashed"                     type="boolean";
	param name="args.child_count"                 type="numeric";
	param name="args.access_restriction"          type="string";
	param name="args.is_draft"                    type="string";
	param name="args.has_drafts"                  type="string";

	param name="args.permission_context"          type="array" default=[];
	param name="args.parent_restriction"          type="string" default="none";

	param name="args.editPageBaseLink"            type="string" default=event.buildAdminLink( linkTo="sitetree.editPage"            , queryString="id={id}&child_count={child_count}" );
	param name="args.pageTypeDialogBaseLink"      type="string" default=event.buildAdminLink( linkTo="sitetree.pageTypeDialog"      , queryString="parentPage={id}"                   );
	param name="args.addPageBaseLink"             type="string" default=event.buildAdminLink( linkTo="sitetree.addPage"             , querystring="parent_page={id}&page_type={type}" );
	param name="args.trashPageBaseLink"           type="string" default=event.buildAdminLink( linkTo="sitetree.trashPageAction"     , queryString="id={id}"                           );
	param name="args.activatePageBaseLink"        type="string" default=event.buildAdminLink( linkTo="sitetree.activatePageAction"  , queryString="id={id}"                           );
	param name="args.deactivatePageBaseLink"      type="string" default=event.buildAdminLink( linkTo="sitetree.deactivatePageAction", queryString="id={id}"                           );
	param name="args.pageHistoryBaseLink"         type="string" default=event.buildAdminLink( linkTo="sitetree.pageHistory"         , queryString="id={id}"                           );
	param name="args.editPagePermissionsBaseLink" type="string" default=event.buildAdminLink( linkTo="sitetree.editPagePermissions" , queryString="id={id}"                           );
	param name="args.reorderChildrenBaseLink"     type="string" default=event.buildAdminLink( linkTo="sitetree.reorderChildren"     , queryString="id={id}"                           );
	param name="args.previewPageBaseLink"         type="string" default=event.buildAdminLink( linkTo="sitetree.previewPage"         , queryString="id={id}"                           );
	param name="args.clearCacheBaseLink"          type="string" default=event.buildAdminLink( linkTo="sitetree.clearPageCacheAction", queryString="id={id}"                           );
	param name="args.cloneBaseLink"               type="string" default=event.buildAdminLink( linkTo="sitetree.clonePage"           , queryString="id={id}"                           );

	permContextKeys = Duplicate( args.permission_context );
	permContextKeys.prepend( args.id );
	permissions = hasCmsPermissions( context="page", contextKeys=permContextKeys, permissionKeys=[
		  "sitetree.navigate"
		, "sitetree.edit"
		, "sitetree.add"
		, "sitetree.trash"
		, "sitetree.sort"
		, "sitetree.manageContextPerms"
		, "sitetree.viewversions"
		, "sitetree.activate"
		, "sitetree.clearcaches"
		, "sitetree.clone"
	] );

	hasNavigatePermission = permissions[ "sitetree.navigate" ];

	if ( hasNavigatePermission ) {
		pageUrl     = quickBuildLink( args.previewPageBaseLink, { id=args.id } );
		homepageId  = prc.homepage.id ?: "";
		pageType    = translateResource( "page-types.#args.page_type#:name", args.page_type );
		pageIcon    = translateResource( "page-types.#args.page_type#:iconclass", "fa-file-o" );
		safeTitle   = HtmlEditFormat( args.title );

		if ( args.access_restriction == "inherit" ) {
			args.access_restriction = args.parent_restriction;
		}

		allowableChildPageTypes = getAllowableChildPageTypes( args.page_type );
		managedChildPageTypes   = getManagedChildPageTypes( args.page_type );
		isSystemPage            = isSystemPageType( args.page_type );
		hasChildren             = managedChildPageTypes.len() || args.child_count;
		isDraft                 = IsTrue( args.is_draft );
		hasDrafts               = IsTrue( args.has_drafts );

		hasEditPagePermission    = permissions[ "sitetree.edit"               ];
		hasAddPagePermission     = permissions[ "sitetree.add"                ];
		hasDeletePagePermission  = permissions[ "sitetree.trash"              ] && args.id neq homepageId && !isSystemPage;
		hasSortPagesPermission   = permissions[ "sitetree.sort"               ] && hasChildren;
		hasManagePermsPermission = permissions[ "sitetree.manageContextPerms" ];
		hasPageHistoryPermission = permissions[ "sitetree.viewversions"       ];
		hasActivatePermission    = permissions[ "sitetree.activate"           ] && !isSystemPage && !isDraft;
		hasClearCachePermission  = permissions[ "sitetree.clearcaches"        ];
		hasClonePermission       = permissions[ "sitetree.clone"              ] && !isSystemPage;

		hasDropdown = hasDeletePagePermission || hasSortPagesPermission || hasManagePermsPermission || hasPageHistoryPermission || hasClearCachePermission;

		selected          = rc.selected ?: "";
		selectedAncestors = prc.selectedAncestors ?: [];
		isSelected        = args.id == selected;
		isOpen            = !isSelected && selectedAncestors.find( args.id );

		dataImage            = Len( Trim( args.main_image ) ) ? 'data-image="#event.buildLink( assetId = args.main_image, derivative = 'pageThumbnail'  )#"' : "";

		usesDateRestrictions = IsDate( args.embargo_date ) || IsDate( args.expiry_date );
		outOfDate            = ( IsDate( args.embargo_date ) && args.embargo_date > Now() ) || ( IsDate( args.expiry_date ) && args.expiry_date < Now() );

		if ( isDraft ) {
			redClass   = greenClass = "light-grey";
		} else {
			redClass   = "red";
			greenClass = "green";
		}

		status = renderView( view="/admin/sitetree/_nodeStatus", args=args );
	}
</cfscript>

<cfif hasNavigatePermission>
	<cfoutput>
		<tr class="depth-#args._hierarchy_depth#<cfif isOpen> open</cfif><cfif isSelected> selected</cfif><cfif isDraft> draft light-grey<cfelseif hasDrafts> has-drafts</cfif>" data-id="#args.id#" data-parent="#args.parent_page#" data-depth="#args._hierarchy_depth#"<cfif hasChildren> data-has-children="true"</cfif> data-context-container="#args.id#"<cfif isOpen> data-open-on-start="true"</cfif>>
			<td class="page-title-cell">
				<!--- whitespace important here hence one line --->
				<cfif hasChildren><i class="fa fa-lg fa-fw fa-caret-right tree-toggler"></i></cfif><i class="fa fa-fw #pageIcon# page-type-icon" title="#HtmlEditFormat( pageType )#"></i>

				<cfif hasEditPagePermission>
					<a class="page-title" href="#quickBuildLink( args.editPageBaseLink, {id=args.id, child_count=args.child_count} )#" title="#translateResource( "cms:sitetree.edit.child.page.link" )#" #dataImage#> #args.title#</a>
				<cfelse>
					<span class="page-title" #dataImage#>#args.title#</span>
				</cfif>

				<div class="actions pull-right btn-group">
					<cfif hasEditPagePermission>
						<a data-context-key="e" href="#quickBuildLink( args.editPageBaseLink, {id=args.id, child_count=args.child_count} )#" title="#translateResource( "cms:sitetree.edit.child.page.link" )#"><i class="fa fa-pencil"></i></a>
					<cfelse>
						<i class="fa fa-pencil disabled"></i>
					</cfif>

					<cfif hasAddPagePermission>
						<cfif allowableChildPageTypes eq "*" or ListLen( allowableChildPageTypes ) gt 1>
							<a data-context-key="a" href="#quickBuildLink( args.pageTypeDialogBaseLink, {id=args.id} )#" data-toggle="bootbox-modal" data-buttons="cancel" data-modal-class="page-type-picker" title="#HtmlEditFormat( translateResource( uri="cms:sitetree.add.child.page.link", data=[ args.title ] ) )#"><span><!--- hack to bypass some brutal css ---></span><i class="fa fa-plus"></i></a>
						<cfelseif allowableChildPageTypes neq "none">
							<a data-context-key="a" href="#quickBuildLink( args.addPageBaseLink, { id=args.id, type=allowableChildPageTypes} )#" title="#HtmlEditFormat( translateResource( uri="cms:sitetree.add.child.page.link", data=[ args.title ] ) )#"><span><!--- hack to bypass some brutal css ---></span><i class="fa fa-plus"></i></a>
						</cfif>
					<cfelse>
						<i class="fa fa-plus disabled"></i>
					</cfif>

					<cfif not hasDropdown>
						<i class="fa fa-caret-down disabled"></i>
					<cfelse>

						<a class="dropdown-toggle" data-toggle="dropdown" href="##">
							<i class="fa fa-caret-down"></i>
						</a>
						<ul class="dropdown-menu">
							<cfif hasClonePermission>
								<li>
									<a href="#quickBuildLink( args.cloneBaseLink, {id=args.id} )#">
										<i class="fa fa-fw fa-clone"></i>
										#translateResource( "cms:sitetree.clone.page.dropdown" )#
									</a>
								</li>
							</cfif>
							<cfif hasActivatePermission>
								<li>
									<cfif IsTrue( args.active )>
										<a href="#quickBuildLink( args.deactivatePageBaseLink, {id=args.id} )#" class="confirmation-prompt" title="#htmlEditFormat( translateResource( uri="cms:sitetree.deactivate.child.page.link", data=[ safeTitle ] ) )#">
											<i class="fa fa-fw fa-times-circle"></i>
											#translateResource( "cms:sitetree.deactivate.page.dropdown" )#
										</a>
									<cfelse>
										<a href="#quickBuildLink( args.activatePageBaseLink, {id=args.id} )#" class="confirmation-prompt" title="#htmlEditFormat( translateResource( uri="cms:sitetree.activate.child.page.link", data=[ safeTitle ] ) )#">
											<i class="fa fa-fw fa-check-circle"></i>
											#translateResource( "cms:sitetree.activate.page.dropdown" )#
										</a>
									</cfif>
								</li>
							</cfif>
							<cfif hasDeletePagePermission>
								<li>
									<a data-context-key="d" href="#quickBuildLink( args.trashPageBaseLink, {id=args.id} )#" class="confirmation-prompt" title="#htmlEditFormat( translateResource( uri="cms:sitetree.trash.child.page.link", data=[ safeTitle ] ) )#" data-has-children="#args.child_count#">
										<i class="fa fa-fw fa-trash-o"></i>
										#translateResource( "cms:sitetree.trash.page.dropdown" )#
									</a>
								</li>
							</cfif>
							<cfif hasPageHistoryPermission>
								<li>
									<a data-context-key="h" href="#quickBuildLink( args.pageHistoryBaseLink, {id=args.id} )#" title="#htmlEditFormat( translateResource( "cms:sitetree.page.history.link" ) )#">
										<i class="fa fa-fw fa-history"></i>
										#translateResource( "cms:sitetree.page.history.dropdown" )#
									</a>
								</li>
							</cfif>

							<cfif hasManagePermsPermission>
								<li>
									<a data-context-key="m" href="#quickBuildLink( args.editPagePermissionsBaseLink, {id=args.id} )#">
										<i class="fa fa-fw fa-lock"></i>
										#translateResource( "cms:sitetree.page.permissioning.dropdown" )#
									</a>
								</li>
							</cfif>

							<cfif hasSortPagesPermission>
								<li>
									<a data-context-key="o" href="#quickBuildLink( args.reorderChildrenBaseLink, {id=args.id} )#" title="#htmlEditFormat( translateResource( uri="cms:sitetree.reorder.children.link", data=[ safeTitle ] ) )#">
										<i class="fa fa-fw fa-sort-amount-asc"></i>
										#translateResource( "cms:sitetree.sort.children.dropdown" )#
									</a>
								</li>
							</cfif>
							<cfif hasClearCachePermission>
								<li>
									<a href="#quickBuildLink( args.clearCacheBaseLink, {id=args.id} )#" class="confirmation-prompt" title="#htmlEditFormat( translateResource( uri="cms:sitetree.flush.page.cache.prompt", data=[ safeTitle ] ) )#">
										<i class="fa fa-fw fa-refresh"></i>
										#translateResource( "cms:sitetree.flush.page.cache.link" )#
									</a>
								</li>
							</cfif>
						</ul>
					</cfif>
				</div>
			</td>
			<td>#pageType#</td>
			<td>#status#</td>
			<td>
				<cfswitch expression="#args.access_restriction#">
					<cfcase value="full">
						<i class="fa fa-fw fa-lock #redClass#"></i> &nbsp; #translateResource( "preside-objects.page:access_restriction.option.full" )#
					</cfcase>
					<cfcase value="partial">
						<i class="fa fa-fw fa-unlock #redClass#"></i> &nbsp; #translateResource( "preside-objects.page:access_restriction.option.partial" )#
					</cfcase>
					<cfdefaultcase>
						<i class="fa fa-fw fa-unlock #greenClass#"></i> &nbsp; #translateResource( "preside-objects.page:access_restriction.option.none" )#
					</cfdefaultcase>
				</cfswitch>
			</td>
			<td>
				<a class="preview-link" href="#pageUrl#" data-context-key="p" title="#translateResource( 'cms:sitetree.preview.page.link' )#" target="_blank">
					<i class="fa fa-fw fa-external-link"></i>
					<cfif Len( Trim( args.slug ) )>#args.slug#.html<cfelse>/</cfif>
				</a>
			</td>
		</tr>
	</cfoutput>
</cfif>