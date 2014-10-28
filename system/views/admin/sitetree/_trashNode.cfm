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
	param name="args.permission_context" type="array" default=[];

	args.permission_context.prepend( args.id );
	hasNavigatePermission = hasCmsPermission( permissionKey="sitetree.navigate", context="page", contextKeys=args.permission_context );

	if ( hasNavigatePermission ) {
		pageType    = translateResource( "page-types.#args.page_type#:name", args.page_type );
		pageIcon    = translateResource( "page-types.#args.page_type#:iconclass", "fa-file-o" );
		safeTitle   = HtmlEditFormat( args.title );
		hasChildren = args.children.len();
		selected    = rc.selected ?: "";

		hasRestorePagePermission = hasCmsPermission( permissionKey="sitetree.restore" );
		hasDeletePagePermission  = hasCmsPermission( permissionKey="sitetree.delete" );
	}
</cfscript>

<cfif hasNavigatePermission>
	<cfoutput>
		<tr data-id="#args.id#" data-parent="#args.parent_page#" data-depth="#args._hierarchy_depth#"<cfif hasChildren> data-has-children="true"</cfif> <cfif selected eq args.id> class="selected"</cfif> data-context-container="#args.id#">
			<td>
				#RepeatString( '&nbsp; &nbsp; &nbsp; &nbsp;', args._hierarchy_depth )#
				<i class="fa fa-fw #pageIcon# page-type-icon" title="#HtmlEditFormat( pageType )#"></i>


				#args.title#


				<div class="actions pull-right btn-group">
					<cfif hasRestorePagePermission>
						<a data-context-key="r" href="#event.buildAdminLink( linkTo="sitetree.restorePage", queryString="id=#args.id#" )#" title="#translateResource( uri="cms:sitetree.restore.page.link", data=[ safeTitle ] )#"><i class="fa fa-magic"></i></a>
					<cfelse>
						<i class="fa fa-magic disabled"></i>
					</cfif>

					<cfif hasDeletePagePermission>
						<a data-context-key="d" href="#event.buildAdminLink( linkTo="sitetree.deletePageAction", queryString="id=#args.id#")#" class="confirmation-prompt" title="#translateResource( uri="cms:sitetree.delete.page.link", data=[ safeTitle ] )#"><i class="fa fa-trash-o"></i></a>
					<cfelse>
						<i class="fa fa-trash-o disabled"></i>
					</cfif>
				</div>
			</td>
		</tr>

		<cfloop array="#args.children#" index="child">
			<cfset child.permission_context = duplicate( args.permission_context ) />

			#renderView( view="/admin/sitetree/_trashNode", args=child )#
		</cfloop>
	</cfoutput>
</cfif>