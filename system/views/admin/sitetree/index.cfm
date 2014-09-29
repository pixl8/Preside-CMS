<cfscript>
	site = event.getSite();

	prc.pageIcon  = "sitemap";
	prc.pageTitle = site.name ?: translateResource( "cms:sitetree" );

	activeTree       = event.getValue( name="activeTree", defaultValue=ArrayNew(1), private=true );
	treeTrash        = event.getValue( name="treeTrash" , defaultValue=ArrayNew(1), private=true );
	noneSelectedText = translateResource( "cms:sitetree.context.pane.noneselected" );
</cfscript>

<cfoutput>
	<table class="table table-striped table-hover tree-table">
		<thead>
			<tr>
				<th>Page title</th>
				<th>Page type</th>
				<th>Actions</th>
				<th>Active</th>
				<th>Permissioning</th>
				<th>URL</th>
			</tr>
		</thead>
		<tbody data-nav-list-child-selector="tr" data-nav-list="1">
			<cfloop array="#activeTree#" index="node">
				#renderView( view="/admin/sitetree/_node", args=node )#
			</cfloop>
		</tbody>
	</table>
</cfoutput>