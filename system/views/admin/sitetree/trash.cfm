<cfscript>
	site = event.getSite();

	prc.pageIcon  = "sitemap";
	prc.pageTitle = translateResource( uri="cms:sitetree.trash", data=[ site.name ?: "" ] );

	treeTrash     = event.getValue( name="treeTrash" , defaultValue=ArrayNew(1), private=true );
</cfscript>

<cfoutput>
	<table class="table table-striped table-hover tree-table">
		<thead>
			<tr>
				<th>#translateResource( 'cms:sitetree.table.title.header'    )#</th>
			</tr>
		</thead>
		<tbody data-nav-list-child-selector="tr" data-nav-list="1">
			<cfloop array="#treeTrash#" index="node">
				#renderView( view="/admin/sitetree/_trashNode", args=node )#
			</cfloop>
		</tbody>
	</table>
</cfoutput>