<cfscript>
	param name="args.id"                 type="string";
	param name="args.parent_page"        type="string";
	param name="args._hierarchy_depth"   type="string";
	param name="args.title"              type="string";
	param name="args.page_type"          type="string";
	param name="args.slug"               type="string";
	param name="args.full_slug"          type="string";
	param name="args.datecreated"        type="date";
	param name="args.datemodified"       type="date";
	param name="args.active"             type="boolean";
	param name="args.hasChildren"        type="boolean";
	param name="args.trashed"            type="boolean";
	param name="args.children"           type="array";
	param name="args.access_restriction" type="string";
	param name="args.parent_restriction" type="string" default="none";

	pageUrl     = event.buildLink( page=args.id );
	homepageId  = prc.homepage.id ?: "";
	pageType    = translateResource( "page-types.#args.page_type#:name", args.page_type );
	pageIcon    = translateResource( "page-types.#args.page_type#:iconclass", "fa-file-o" );
	safeTitle   = HtmlEditFormat( args.title );
	hasChildren = args.children.len();
	selected    = rc.selected ?: "";

	if ( args.access_restriction == "inherit" ) {
		args.access_restriction = args.parent_restriction;
	}

	allowableChildPageTypes = getAllowableChildPageTypes( args.page_type );
</cfscript>

<cfoutput>
	<tr data-id="#args.id#" data-parent="#args.parent_page#" data-depth="#args._hierarchy_depth#"<cfif hasChildren> data-has-children="true"</cfif> <cfif selected eq args.id> class="selected"</cfif> data-context-container="#args.id#">
		<td>
			#RepeatString( '&nbsp; &nbsp; &nbsp; &nbsp;', args._hierarchy_depth )#
			<i class="fa fa-fw #pageIcon# page-type-icon" title="#HtmlEditFormat( pageType )#"></i>
			<a href="#event.buildAdminLink( linkTo="sitetree.editPage", queryString="id=#args.id#")#" title="#translateResource( "cms:sitetree.edit.child.page.link" )#">
				#args.title#
			</a>

			<div class="actions pull-right btn-group">
				<cfif not args.trashed>
					<a data-context-key="e" href="#event.buildAdminLink( linkTo="sitetree.editPage", queryString="id=#args.id#")#" title="#translateResource( "cms:sitetree.edit.child.page.link" )#"><i class="fa fa-pencil"></i></a>
					<cfif allowableChildPageTypes eq "*" or ListLen( allowableChildPageTypes ) gt 1>
						<a data-context-key="a" href="#event.buildAdminLink( linkTo="sitetree.pageTypeDialog", queryString="parentPage=#args.id#" )#" data-toggle="bootbox-modal" data-buttons="cancel" data-modal-class="page-type-picker" title="#HtmlEditFormat( translateResource( uri="cms:sitetree.add.child.page.link", data=[ args.title ] ) )#"><span><!--- hack to bypass some brutal css ---></span><i class="fa fa-plus"></i></a>
					<cfelseif allowableChildPageTypes neq "none">
						<a data-context-key="a" href="#event.buildAdminLink( linkTo='sitetree.addPage', querystring='parent_page=#args.id#&page_type=#allowableChildPageTypes#' )#" title="#HtmlEditFormat( translateResource( uri="cms:sitetree.add.child.page.link", data=[ args.title ] ) )#"><span><!--- hack to bypass some brutal css ---></span><i class="fa fa-plus"></i></a>
					</cfif>

					<a class="dropdown-toggle" data-toggle="dropdown" href="##">
						<i class="fa fa-caret-down"></i>
					</a>
					<ul class="dropdown-menu">
						<cfif args.id neq homepageId>
							<li>
								<a data-context-key="d" href="#event.buildAdminLink( linkTo="sitetree.trashPageAction", queryString="id=#args.id#")#" class="confirmation-prompt" title="#translateResource( uri="cms:sitetree.trash.child.page.link", data=[ safeTitle ] )#">
									<i class="fa fa-fw fa-trash-o"></i>
									#translateResource( "cms:sitetree.trash.page.dropdown" )#
								</a>
							</li>
						</cfif>
						<li>
							<a data-context-key="h" href="#event.buildAdminLink( linkTo="sitetree.pageHistory", queryString="id=#args.id#")#" title="#translateResource( "cms:sitetree.page.history.link" )#">
								<i class="fa fa-fw fa-history"></i>
								#translateResource( "cms:sitetree.page.history.dropdown" )#
							</a>
						</li>
						<li>
							<a data-context-key="m" href="#event.buildAdminLink( linkTo="sitetree.editPagePermissions", queryString="id=#args.id#" )#">
								<i class="fa fa-fw fa-lock"></i>
								#translateResource( "cms:sitetree.page.permissioning.dropdown" )#
							</a>
						</li>

						<cfif args.hasChildren>
							<li>
								<a data-context-key="o" href="#event.buildAdminLink( linkTo="sitetree.reorderChildren", queryString="id=#args.id#")#" title="#translateResource( uri="cms:sitetree.reorder.children.link", data=[ safeTitle ] )#">
									<i class="fa fa-sort-amount-asc"></i>
									#translateResource( "cms:sitetree.sort.children.dropdown" )#
								</a>
							</li>
						</cfif>
					<cfelse>
						<li><a data-context-key="r" href="#event.buildAdminLink( linkTo="sitetree.restorePage", queryString="id=#args.id#" )#" title="#translateResource( uri="cms:sitetree.restore.page.link", data=[ safeTitle ] )#"><i class="fa fa-magic"></i></a></li>
						<li><a data-context-key="d" href="#event.buildAdminLink( linkTo="sitetree.deletePageAction", queryString="id=#args.id#")#" class="confirmation-prompt" title="#translateResource( uri="cms:sitetree.delete.page.link", data=[ safeTitle ] )#"><i class="fa fa-trash-o"></i></a></li>
					</cfif>
				</ul>
			</div>
		</td>
		<td>#pageType#</td>
		<td>#renderField( object="page", property="active", data=args.active, context="adminDataTable" )#</td>
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
		<td><a href="#pageUrl#" data-context-key="p" title="#translateResource( 'cms:sitetree.preview.page.link' )#"><cfif Len( Trim( args.slug ) )>#args.slug#.html<cfelse>/</cfif></a></td>
	</tr>

	<cfloop array="#args.children#" index="child">
		<cfset child.parent_restriction = args.access_restriction />
		#renderView( view="/admin/sitetree/_node", args=child )#
	</cfloop>
</cfoutput>