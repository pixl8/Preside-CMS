<cfscript>
	param name="args.id"        type="string";
	param name="args.children"  type="array";
	param name="args.depth"     type="numeric" default=1;
	param name="args.parent_id" type="string"  default="";

	hasChildren = args.children.len();
	selected    = rc.selected ?: "";

	pageName = translateResource( "application-pages:#args.id#.name", args.id );
	pageIcon = translateResource( "application-pages:#args.id#.icon", "fa-page" );
	pageType = translateResource( "cms:application.pages.pagetype" );

	hasEditPagePermission = true; // TODO!
	na = translateResource( "cms:not.applicable" );
</cfscript>

<cfoutput>
	<tr data-id="#args.id#" data-parent="#args.parent_id#" data-depth="#args.depth#"<cfif hasChildren> data-has-children="true"</cfif> <cfif selected eq args.id> class="selected"</cfif> data-context-container="#args.id#">
		<td>
			#RepeatString( '&nbsp; &nbsp; &nbsp; &nbsp;', args.depth )#
			<i class="fa fa-fw #pageIcon# page-type-icon" title="#HtmlEditFormat( pageType )#"></i>

			<cfif hasEditPagePermission>
				<a href="#event.buildAdminLink( linkTo="sitetree.editApplicationPage", queryString="id=#args.id#")#" title="#translateResource( "cms:sitetree.edit.child.page.link" )#">
					#pageName#
				</a>
			<cfelse>
				#pageName#
			</cfif>

			<div class="actions pull-right btn-group">
				<cfif hasEditPagePermission>
					<a data-context-key="e" href="#event.buildAdminLink( linkTo="sitetree.editApplicationPage", queryString="id=#args.id#")#" title="#translateResource( "cms:sitetree.edit.child.page.link" )#"><i class="fa fa-pencil"></i></a>
				<cfelse>
					<i class="fa fa-pencil disabled"></i>
				</cfif>
				<i class="fa fa-plus disabled"></i>
				<i class="fa fa-caret-down disabled"></i>
			</div>
		</td>
		<td>#pageType#</td>
		<td class="disabled">#na#</td>
		<td class="disabled">#na#</td>
		<td class="disabled">#na#</td>
	</tr>

	<cfloop array="#args.children#" index="child">
		<cfset child.depth     = args.depth+1 />
		<cfset child.parent_id = args.id      />

		#renderView( view="/admin/sitetree/_applicationPageNode", args=child )#
	</cfloop>
</cfoutput>
