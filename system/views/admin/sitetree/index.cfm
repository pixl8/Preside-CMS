<cfscript>
	site = event.getSite();

	prc.pageIcon  = "sitemap";
	prc.pageTitle = site.name ?: translateResource( "cms:sitetree" );

	activeTree          = prc.activeTree ?: [];
	applicationPageTree = prc.applicationPageTree ?: [];
	trashCount          = prc.trashCount ?: 0;
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
			<cfloop array="#activeTree#" item="node" index="i">
				<cfif i eq 1>
					<cfset node.applicationPageTree = applicationPageTree />
				</cfif>
				#renderView( view="/admin/sitetree/_node", args=node )#
			</cfloop>
		</tbody>
	</table>

	<cfif hasCmsPermission( permissionKey="sitetree.viewTrash" ) >
		<div class="form-actions row">
			<div class="col-md-offset-2">
				<a href="#event.buildAdminLink( linkTo='sitetree.trash' )#" class="pull-right red">
					<i class="fa fa-fw fa-trash fa-lg"></i>
					#translateResource( uri="cms:sitetree.trash.link.title", data=[ trashCount ] )#
				</a>
			</div>
		</div>
	</cfif>
</cfoutput>