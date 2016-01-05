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
	param name="args.active"                      type="boolean";
	param name="args.trashed"                     type="boolean";
	param name="args.child_count"                 type="numeric";
	param name="args.access_restriction"          type="string";

	param name="args.permission_context"          type="array" default=[];
	param name="args.parent_restriction"          type="string" default="none";

	param name="args.editPageBaseLink"            type="string" default=event.buildAdminLink( linkTo="sitetree.editPage", queryString="id={id}" );
	param name="args.pageTypeDialogBaseLink"      type="string" default=event.buildAdminLink( linkTo="sitetree.pageTypeDialog", queryString="parentPage={id}" );
	param name="args.addPageBaseLink"             type="string" default=event.buildAdminLink( linkTo='sitetree.addPage', querystring='parent_page={id}&page_type={type}' );
	param name="args.trashPageBaseLink"           type="string" default=event.buildAdminLink( linkTo="sitetree.trashPageAction", queryString="id={id}" );
	param name="args.pageHistoryBaseLink"         type="string" default=event.buildAdminLink( linkTo="sitetree.pageHistory", queryString="id={id}" );
	param name="args.editPagePermissionsBaseLink" type="string" default=event.buildAdminLink( linkTo="sitetree.editPagePermissions", queryString="id={id}" );
	param name="args.reorderChildrenBaseLink"     type="string" default=event.buildAdminLink( linkTo="sitetree.reorderChildren", queryString="id={id}" );
	param name="args.previewPageBaseLink"         type="string" default=event.buildAdminLink( linkTo="sitetree.previewPage", queryString="id={id}" );

	permContextKeys = Duplicate( args.permission_context );
	permContextKeys.prepend( args.id );
	hasNavigatePermission = hasCmsPermission( permissionKey="sitetree.navigate", context="page", contextKeys=permContextKeys )

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

		hasEditPagePermission    = hasCmsPermission( permissionKey="sitetree.edit"              , context="page", contextKeys=permContextKeys );
		hasAddPagePermission     = hasCmsPermission( permissionKey="sitetree.add"               , context="page", contextKeys=permContextKeys );
		hasDeletePagePermission  = hasCmsPermission( permissionKey="sitetree.trash"             , context="page", contextKeys=permContextKeys ) && args.id neq homepageId && !isSystemPage;
		hasSortPagesPermission   = hasCmsPermission( permissionKey="sitetree.sort"              , context="page", contextKeys=permContextKeys ) && hasChildren;
		hasManagePermsPermission = hasCmsPermission( permissionKey="sitetree.manageContextPerms", context="page", contextKeys=permContextKeys );
		hasPageHistoryPermission = hasCmsPermission( permissionKey="sitetree.viewversions"      , context="page", contextKeys=permContextKeys );

		hasDropdown = hasDeletePagePermission || hasSortPagesPermission || hasManagePermsPermission || hasPageHistoryPermission;

		selected          = rc.selected ?: "";
		selectedAncestors = prc.selectedAncestors ?: [];
		isSelected        = args.id == selected;
		isOpen            = !isSelected && selectedAncestors.find( args.id );

		dataImage = Len( Trim( args.main_image ) ) ? 'data-image="#event.buildLink( assetId = args.main_image, derivative = 'pageThumbnail'  )#"' : "";
	}
</cfscript>

<cfif hasNavigatePermission>
	<cfoutput>
		<tr class="depth-#args._hierarchy_depth#<cfif isOpen> open</cfif><cfif isSelected> selected</cfif>" data-id="#args.id#" data-parent="#args.parent_page#" data-depth="#args._hierarchy_depth#"<cfif hasChildren> data-has-children="true"</cfif> data-context-container="#args.id#"<cfif isOpen> data-open-on-start="true"</cfif>>
			<td class="page-title-cell">
				<!--- whitespace important here hence one line --->
				<cfif hasChildren><i class="fa fa-lg fa-fw fa-caret-right tree-toggler"></i></cfif><i class="fa fa-fw #pageIcon# page-type-icon" title="#HtmlEditFormat( pageType )#"></i>

				<cfif hasEditPagePermission>
					<a class="page-title" href="#quickBuildLink( args.editPageBaseLink, {id=args.id} )#" title="#translateResource( "cms:sitetree.edit.child.page.link" )#" #dataImage#> #args.title#</a>
				<cfelse>
					<span class="page-title" #dataImage#>#args.title#</span>
				</cfif>

				<div class="actions pull-right btn-group">
					<cfif hasEditPagePermission>
						<a data-context-key="e" href="#quickBuildLink( args.editPageBaseLink, {id=args.id} )#" title="#translateResource( "cms:sitetree.edit.child.page.link" )#"><i class="fa fa-pencil"></i></a>
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
							<cfif hasDeletePagePermission>
								<li>
									<a data-context-key="d" href="#quickBuildLink( args.trashPageBaseLink, {id=args.id} )#" class="confirmation-prompt" title="#translateResource( uri="cms:sitetree.trash.child.page.link", data=[ safeTitle ] )#">
										<i class="fa fa-fw fa-trash-o"></i>
										#translateResource( "cms:sitetree.trash.page.dropdown" )#
									</a>
								</li>
							</cfif>
							<cfif hasPageHistoryPermission>
								<li>
									<a data-context-key="h" href="#quickBuildLink( args.pageHistoryBaseLink, {id=args.id} )#" title="#translateResource( "cms:sitetree.page.history.link" )#">
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
									<a data-context-key="o" href="#quickBuildLink( args.reorderChildrenBaseLink, {id=args.id} )#" title="#translateResource( uri="cms:sitetree.reorder.children.link", data=[ safeTitle ] )#">
										<i class="fa fa-fw fa-sort-amount-asc"></i>
										#translateResource( "cms:sitetree.sort.children.dropdown" )#
									</a>
								</li>
							</cfif>
						</ul>
					</cfif>
				</div>
			</td>
			<td>#pageType#</td>
			<td>#renderField( object="page", property="active", data=args.active, context=[ "adminDataTable", "admin" ] )#</td>
			<td>
				<cfswitch expression="#args.access_restriction#">
					<cfcase value="full">
						<i class="fa fa-fw fa-lock red"></i> &nbsp; #translateResource( "preside-objects.page:access_restriction.option.full" )#
					</cfcase>
					<cfcase value="partial">
						<i class="fa fa-fw fa-unlock red"></i> &nbsp; #translateResource( "preside-objects.page:access_restriction.option.partial" )#
					</cfcase>
					<cfdefaultcase>
						<i class="fa fa-fw fa-unlock green"></i> &nbsp; #translateResource( "preside-objects.page:access_restriction.option.none" )#
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