<cfscript>
	param name="args.id"            type="string";
	param name="args.label"         type="string";
	param name="args.page_type"     type="string";
	param name="args.slug"          type="string";
	param name="args.full_slug"     type="string";
	param name="args.datecreated"   type="date";
	param name="args.datemodified"  type="date";
	param name="args.active"        type="boolean";
	param name="args.hasChildren"   type="boolean";
	param name="args.trashed"       type="boolean";
	param name="args.children"      type="array";

	safeTitle  = HtmlEditFormat( args.label );
	na         = translateResource( "cms:not.applicable" );
	selected   = event.getValue( "selected", "" );
	homepageId = prc.homepage.id ?: "";
	pageIcon   = translateResource( "page-types.#args.page_type#:iconclass", "fa-file-o" );

	allowableChildPageTypes = getAllowableChildPageTypes( args.page_type );

</cfscript>

<cfoutput>
	<cfsavecontent variable="options">
		<div class="node-options">
			<cfif not args.trashed>
				<a data-context-key="p" href="#event.buildLink( page=args.id )#" title="#translateResource( "cms:sitetree.preview.page.link" )#" target="_blank"><i class="fa fa-external-link"></i></a>

				<cfif allowableChildPageTypes eq "*" or ListLen( allowableChildPageTypes ) gt 1>
					<a data-context-key="a" href="#event.buildAdminLink( linkTo="sitetree.pageTypeDialog", queryString="parentPage=#args.id#" )#" data-toggle="bootbox-modal" data-buttons="cancel" data-modal-class="page-type-picker" title="#HtmlEditFormat( translateResource( uri="cms:sitetree.add.child.page.link", data=[ args.label ] ) )#"><span><!--- hack to bypass some brutal css ---></span><i class="fa fa-plus"></i></a>
				<cfelseif allowableChildPageTypes neq "none">
					<a data-context-key="a" href="#event.buildAdminLink( linkTo='sitetree.addPage', querystring='parent_page=#args.id#&page_type=#allowableChildPageTypes#' )#" title="#HtmlEditFormat( translateResource( uri="cms:sitetree.add.child.page.link", data=[ args.label ] ) )#"><span><!--- hack to bypass some brutal css ---></span><i class="fa fa-plus"></i></a>
				</cfif>

				<a data-context-key="e" href="#event.buildAdminLink( linkTo="sitetree.editPage", queryString="id=#args.id#")#" title="#translateResource( "cms:sitetree.edit.child.page.link" )#"><i class="fa fa-pencil"></i></a>
				<cfif args.id neq homepageId>
					<a data-context-key="d" href="#event.buildAdminLink( linkTo="sitetree.trashPageAction", queryString="id=#args.id#")#" class="confirmation-prompt" title="#translateResource( uri="cms:sitetree.trash.child.page.link", data=[ safeTitle ] )#"><i class="fa fa-trash-o"></i></a>
				</cfif>
				<cfif args.hasChildren>
					<a data-context-key="o" href="#event.buildAdminLink( linkTo="sitetree.reorderChildren", queryString="id=#args.id#")#" title="#translateResource( uri="cms:sitetree.reorder.children.link", data=[ safeTitle ] )#"><i class="fa fa-sort-amount-asc"></i></a>
				</cfif>

				<a data-context-key="h" href="#event.buildAdminLink( linkTo="sitetree.pageHistory", queryString="id=#args.id#")#" title="#translateResource( "cms:sitetree.page.history.link" )#"><i class="fa fa-history"></i></a>
			<cfelse>
				<a data-context-key="r" href="#event.buildAdminLink( linkTo="sitetree.restorePage", queryString="id=#args.id#" )#" title="#translateResource( uri="cms:sitetree.restore.page.link", data=[ safeTitle ] )#"><i class="fa fa-magic"></i></a>
				<a data-context-key="d" href="#event.buildAdminLink( linkTo="sitetree.deletePageAction", queryString="id=#args.id#")#" class="confirmation-prompt" title="#translateResource( uri="cms:sitetree.delete.page.link", data=[ safeTitle ] )#"><i class="fa fa-trash-o"></i></a>
			</cfif>
		</div>

		<div class="node-data">
			<p class="pagetitle">#renderField( object="page", property="label", data="#args.label#", context="admin" )#</p>
			<cfif args.trashed>
				<p class="slug">#na#</p>
				<p class="fullslug">#na#</p>
				<p class="active">#na#</p>
			<cfelse>
				<p class="slug">#args.slug#</p>
				<p class="fullslug">#args.full_slug#</p>
				<p class="active">#renderField( object="page", property="active", data="#args.active#", context="admin" )#</p>
			</cfif>
			<p class="created">#renderField( object="page", property="datecreated", data="#args.datecreated#", context="admin" )#</p>
			<p class="modified">#renderField( object="page", property="datemodified", data="#args.datemodified#", context="admin" )#</p>
			<p class="id">#args.id#</p>
		</div>
	</cfsavecontent>

	<cfif args.hasChildren>
		<div class="tree-folder">
			<div class="tree-node tree-folder-header<cfif selected eq args.id> selected-node</cfif>" data-context-container="#args.id#">
				<span class="fa-stack">
					<i class="fa fa-folder fa-stack-2x"></i>
					<cfif pageIcon neq "fa-file-o">
						<i class="fa #pageIcon# fa-inverse fa-stack-1x"></i>
					</cfif>
				</span>

				<div class="tree-folder-name node-name #args.active ? 'active' : 'inactive light-grey'#">
					#args.label#
					#options#
				</div>
			</div>
			<div class="tree-folder-content">
				<cfloop array="#args.children#" index="child">
					#renderView( view="/admin/sitetree/_node", args=child )#
				</cfloop>
			</div>
		</div>
	<cfelse>
		<div class="tree-node tree-item<cfif selected eq args.id> selected-node</cfif>" data-context-container="#args.id#">
			<div class="tree-item-name node-name #args.active ? 'active' : 'inactive light-grey'#">
				<span class="fa-stack">
					<i class="fa #pageIcon# fa-2x"></i>
				</span>
				#args.label#
				#options#
			</div>
		</div>
	</cfif>
</cfoutput>