<cfscript>
	param name="args.id"               type="string";
	param name="args.parent_page"      type="string";
	param name="args._hierarchy_depth" type="string";
	param name="args.title"            type="string";
	param name="args.page_type"        type="string";
	param name="args.slug"             type="string";
	param name="args.full_slug"        type="string";
	param name="args.datecreated"      type="date";
	param name="args.datemodified"     type="date";
	param name="args.active"           type="boolean";
	param name="args.hasChildren"      type="boolean";
	param name="args.trashed"          type="boolean";
	param name="args.children"         type="array";

	pageUrl     = event.buildLink( page=args.id );
	homepageId  = prc.homepage.id ?: "";
	pageType    = translateResource( "page-types.#args.page_type#:name", args.page_type );
	pageIcon    = translateResource( "page-types.#args.page_type#:iconclass", "fa-file-o" );
	safeTitle   = HtmlEditFormat( args.title );
	hasChildren = args.children.len();
	selected    = rc.selected ?: "";

	allowableChildPageTypes = getAllowableChildPageTypes( args.page_type );
</cfscript>

<cfoutput>
	<tr data-id="#args.id#" data-parent="#args.parent_page#" data-depth="#args._hierarchy_depth#"<cfif hasChildren> data-has-children="true"</cfif> <cfif selected eq args.id> class="selected"</cfif>>
		<td>
			#RepeatString( '&nbsp; &nbsp; &nbsp; &nbsp;', args._hierarchy_depth )#
			<i class="fa fa-fw #pageIcon# page-type-icon" title="#HtmlEditFormat( pageType )#"></i>
			<a href="#event.buildAdminLink( linkTo="sitetree.editPage", queryString="id=#args.id#")#" title="#translateResource( "cms:sitetree.edit.child.page.link" )#">
				#args.title#
			</a>
		</td>
		<td>#pageType#</td>
		<td class="actions">
			<cfif not args.trashed>
				<cfif allowableChildPageTypes eq "*" or ListLen( allowableChildPageTypes ) gt 1>
					<a data-context-key="a" href="#event.buildAdminLink( linkTo="sitetree.pageTypeDialog", queryString="parentPage=#args.id#" )#" data-toggle="bootbox-modal" data-buttons="cancel" data-modal-class="page-type-picker" title="#HtmlEditFormat( translateResource( uri="cms:sitetree.add.child.page.link", data=[ args.title ] ) )#"><span><!--- hack to bypass some brutal css ---></span><i class="fa fa-plus"></i></a>
				<cfelseif allowableChildPageTypes neq "none">
					<a data-context-key="a" href="#event.buildAdminLink( linkTo='sitetree.addPage', querystring='parent_page=#args.id#&page_type=#allowableChildPageTypes#' )#" title="#HtmlEditFormat( translateResource( uri="cms:sitetree.add.child.page.link", data=[ args.title ] ) )#"><span><!--- hack to bypass some brutal css ---></span><i class="fa fa-plus"></i></a>
				</cfif>

				<a data-context-key="e" href="#event.buildAdminLink( linkTo="sitetree.editPage", queryString="id=#args.id#")#" title="#translateResource( "cms:sitetree.edit.child.page.link" )#"><i class="fa fa-pencil"></i></a>
				<cfif args.id neq homepageId>
					<a data-context-key="d" href="#event.buildAdminLink( linkTo="sitetree.trashPageAction", queryString="id=#args.id#")#" class="confirmation-prompt" title="#translateResource( uri="cms:sitetree.trash.child.page.link", data=[ safeTitle ] )#"><i class="fa fa-trash-o"></i></a>
				<cfelse>
					<i class="fa fa-trash-o disabled"></i>
				</cfif>

				<a data-context-key="h" href="#event.buildAdminLink( linkTo="sitetree.pageHistory", queryString="id=#args.id#")#" title="#translateResource( "cms:sitetree.page.history.link" )#"><i class="fa fa-history"></i></a>

				<cfif args.hasChildren>
					<a data-context-key="o" href="#event.buildAdminLink( linkTo="sitetree.reorderChildren", queryString="id=#args.id#")#" title="#translateResource( uri="cms:sitetree.reorder.children.link", data=[ safeTitle ] )#"><i class="fa fa-sort-amount-asc"></i></a>
				<cfelse>
					<i class="fa fa-sort-amount-asc disabled"></i>
				</cfif>

			<cfelse>
				<a data-context-key="r" href="#event.buildAdminLink( linkTo="sitetree.restorePage", queryString="id=#args.id#" )#" title="#translateResource( uri="cms:sitetree.restore.page.link", data=[ safeTitle ] )#"><i class="fa fa-magic"></i></a>
				<a data-context-key="d" href="#event.buildAdminLink( linkTo="sitetree.deletePageAction", queryString="id=#args.id#")#" class="confirmation-prompt" title="#translateResource( uri="cms:sitetree.delete.page.link", data=[ safeTitle ] )#"><i class="fa fa-trash-o"></i></a>
			</cfif>
		</td>
		<td>#renderField( object="page", property="active", data=args.active, context="adminDataTable" )#</td>
		<td><i class="fa fa-unlock green"></i></td>
		<td><a href="#pageUrl#"><cfif Len( Trim( args.slug ) )>#args.slug#.html<cfelse>/</cfif></a></td>
	</tr>

	<cfloop array="#args.children#" index="child">
		#renderView( view="/admin/sitetree/_node", args=child )#
	</cfloop>
</cfoutput>