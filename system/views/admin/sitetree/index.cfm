<cfscript>
	site = event.getSite();

	prc.pageIcon  = "sitemap";
	prc.pageTitle = site.name ?: translateResource( "cms:sitetree" );

	activeTree = event.getValue( name="activeTree", defaultValue=ArrayNew(1), private=true );
</cfscript>

<cfoutput>
	<table class="table table-striped table-hover tree-table">
		<thead>
			<tr>
				<th>#translateResource( 'cms:sitetree.table.title.header'    )#</th>
				<th>#translateResource( 'cms:sitetree.table.pagetype.header' )#</th>
				<th>#translateResource( 'cms:sitetree.table.active.header'   )#</th>
				<th>#translateResource( 'cms:sitetree.table.access.header'   )#</th>
				<th>#translateResource( 'cms:sitetree.table.url.header'      )#</th>
			</tr>
		</thead>
		<tbody data-nav-list-child-selector="tr" data-nav-list="1">
			<cfloop array="#activeTree#" index="node">
				#renderView( view="/admin/sitetree/_node", args=node )#
			</cfloop>
		</tbody>
	</table>
</cfoutput>