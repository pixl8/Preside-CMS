<cfscript>
	param name="args.id"                  type="string";
	param name="args.parent_page"         type="string";
	param name="args._hierarchy_depth"    type="string";
	param name="args.title"               type="string";
	param name="args.page_type"           type="string";
	param name="args.slug"                type="string";
	param name="args.full_slug"           type="string";
	param name="args.datecreated"         type="date";
	param name="args.datemodified"        type="date";
	param name="args.active"              type="boolean";
	param name="args.hasChildren"         type="boolean";
	param name="args.trashed"             type="boolean";
	param name="args.children"            type="array";
	param name="args.permission_context"  type="array" default=[];
	param name="args.access_restriction"  type="string";
	param name="args.parent_restriction"  type="string" default="none";
	param name="args.applicationPageTree" type="array" default=[];

	args.permission_context.prepend( args.id );
	hasNavigatePermission = hasCmsPermission( permissionKey="sitetree.navigate", context="page", contextKeys=args.permission_context );

	if ( hasNavigatePermission ) {
		pageUrl     = event.buildLink( page=args.id );
		homepageId  = prc.homepage.id ?: "";
		pageType    = translateResource( "page-types.#args.page_type#:name", args.page_type );
		pageIcon    = translateResource( "page-types.#args.page_type#:iconclass", "fa-file-o" );
		safeTitle   = HtmlEditFormat( args.title );
		selected    = rc.selected ?: "";

		if ( args.access_restriction == "inherit" ) {
			args.access_restriction = args.parent_restriction;
		}

		allowableChildPageTypes = getAllowableChildPageTypes( args.page_type );
		managedChildPageTypes   = getManagedChildPageTypes( args.page_type );
		isSystemPage            = isSystemPageType( args.page_type );
		hasChildren             = managedChildPageTypes.len() || args.children.len() || args.applicationPageTree.len();

		hasEditPagePermission    = hasCmsPermission( permissionKey="sitetree.edit"              , context="page", contextKeys=args.permission_context );
		hasAddPagePermission     = hasCmsPermission( permissionKey="sitetree.add"               , context="page", contextKeys=args.permission_context );
		hasDeletePagePermission  = hasCmsPermission( permissionKey="sitetree.trash"             , context="page", contextKeys=args.permission_context ) && args.id neq homepageId && !isSystemPage;
		hasSortPagesPermission   = hasCmsPermission( permissionKey="sitetree.sort"              , context="page", contextKeys=args.permission_context ) && args.hasChildren;
		hasManagePermsPermission = hasCmsPermission( permissionKey="sitetree.manageContextPerms", context="page", contextKeys=args.permission_context );
		hasPageHistoryPermission = hasCmsPermission( permissionKey="sitetree.viewversions"      , context="page", contextKeys=args.permission_context );

		hasDropdown = hasDeletePagePermission || hasSortPagesPermission || hasManagePermsPermission || hasPageHistoryPermission;
	}
</cfscript>

<cfif hasNavigatePermission>
	<cfoutput>
		<tr data-id="#args.id#" data-parent="#args.parent_page#" data-depth="#args._hierarchy_depth#"<cfif hasChildren> data-has-children="true"</cfif> <cfif selected eq args.id> class="selected"</cfif> data-context-container="#args.id#">
			<td class="page-title-cell">
				#RepeatString( '&nbsp; &nbsp; &nbsp; &nbsp;', args._hierarchy_depth )#
				<i class="fa fa-fw #pageIcon# page-type-icon" title="#HtmlEditFormat( pageType )#"></i>

				<cfif hasEditPagePermission>
					<a class="page-title" href="#event.buildAdminLink( linkTo="sitetree.editPage", queryString="id=#args.id#")#" title="#translateResource( "cms:sitetree.edit.child.page.link" )#">
						#args.title#
					</a>
				<cfelse>
					<span class="page-title">#args.title#</span>
				</cfif>

				<div class="actions pull-right btn-group">
					<cfif hasEditPagePermission>
						<a data-context-key="e" href="#event.buildAdminLink( linkTo="sitetree.editPage", queryString="id=#args.id#")#" title="#translateResource( "cms:sitetree.edit.child.page.link" )#"><i class="fa fa-pencil"></i></a>
					<cfelse>
						<i class="fa fa-pencil disabled"></i>
					</cfif>

					<cfif hasAddPagePermission>
						<cfif allowableChildPageTypes eq "*" or ListLen( allowableChildPageTypes ) gt 1>
							<a data-context-key="a" href="#event.buildAdminLink( linkTo="sitetree.pageTypeDialog", queryString="parentPage=#args.id#" )#" data-toggle="bootbox-modal" data-buttons="cancel" data-modal-class="page-type-picker" title="#HtmlEditFormat( translateResource( uri="cms:sitetree.add.child.page.link", data=[ args.title ] ) )#"><span><!--- hack to bypass some brutal css ---></span><i class="fa fa-plus"></i></a>
						<cfelseif allowableChildPageTypes neq "none">
							<a data-context-key="a" href="#event.buildAdminLink( linkTo='sitetree.addPage', querystring='parent_page=#args.id#&page_type=#allowableChildPageTypes#' )#" title="#HtmlEditFormat( translateResource( uri="cms:sitetree.add.child.page.link", data=[ args.title ] ) )#"><span><!--- hack to bypass some brutal css ---></span><i class="fa fa-plus"></i></a>
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
									<a data-context-key="d" href="#event.buildAdminLink( linkTo="sitetree.trashPageAction", queryString="id=#args.id#")#" class="confirmation-prompt" title="#translateResource( uri="cms:sitetree.trash.child.page.link", data=[ safeTitle ] )#">
										<i class="fa fa-fw fa-trash-o"></i>
										#translateResource( "cms:sitetree.trash.page.dropdown" )#
									</a>
								</li>
							</cfif>
							<cfif hasPageHistoryPermission>
								<li>
									<a data-context-key="h" href="#event.buildAdminLink( linkTo="sitetree.pageHistory", queryString="id=#args.id#")#" title="#translateResource( "cms:sitetree.page.history.link" )#">
										<i class="fa fa-fw fa-history"></i>
										#translateResource( "cms:sitetree.page.history.dropdown" )#
									</a>
								</li>
							</cfif>

							<cfif hasManagePermsPermission>
								<li>
									<a data-context-key="m" href="#event.buildAdminLink( linkTo="sitetree.editPagePermissions", queryString="id=#args.id#" )#">
										<i class="fa fa-fw fa-lock"></i>
										#translateResource( "cms:sitetree.page.permissioning.dropdown" )#
									</a>
								</li>
							</cfif>

							<cfif hasSortPagesPermission>
								<li>
									<a data-context-key="o" href="#event.buildAdminLink( linkTo="sitetree.reorderChildren", queryString="id=#args.id#")#" title="#translateResource( uri="cms:sitetree.reorder.children.link", data=[ safeTitle ] )#">
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

		<cfloop list="#managedChildPageTypes#" index="pageType">
			<tr data-id="#args.id#_#pageType#" data-parent="#args.id#" data-depth="#args._hierarchy_depth+1#" data-context-container="#args.id#_#pageType#">
				<td colspan="5" class="managed-page-type-link-cell">
					#RepeatString( '&nbsp; &nbsp; &nbsp; &nbsp;', args._hierarchy_depth+1 )#
					<i class="fa fa-fw fa-ellipsis-h page-type-icon"></i>
					<a href="#event.buildAdminLink( linkTo="sitetree.managedChildren", queryString="parent=#args.id#&pageType=#pageType#" )#">#translateResource( uri="cms:sitetree.manage.type", data=[ LCase( translateResource( "page-types.#pageType#:name" ) ) ] )#</a>
				</td>
			</tr>
		</cfloop>

		<cfloop array="#args.children#" index="child">
			<cfset child.parent_restriction = duplicate( args.access_restriction ) />
			<cfset child.permission_context = duplicate( args.permission_context ) />

			#renderView( view="/admin/sitetree/_node", args=child )#
		</cfloop>

		<cfloop array="#args.applicationPageTree#" index="node">
			<cfset node.parent_id = args.id />
			#renderView( view="/admin/sitetree/_applicationPageNode", args=node )#
		</cfloop>
	</cfoutput>
</cfif>