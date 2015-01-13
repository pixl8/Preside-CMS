<cfscript>
	site = event.getSite();

	prc.pageIcon  = "trash";
	prc.pageTitle = translateResource( uri="cms:sitetree.trash", data=[ site.name ?: "" ] );
	prc.pageSubTitle = translateResource( uri="cms:sitetree.trash.subtitle" );

	treeTrash     = prc.treeTrash ?: [];
</cfscript>

<cfoutput>
	<cfif treeTrash.len()>
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

		<div class="form-actions row">
			<div class="col-md-offset-2">
				<a href="#event.buildAdminLink( linkTo='sitetree' )#" class="pull-right">
					<i class="fa fa-fw fa-reply fa-lg"></i>
					#translateResource( "cms:sitetree.trash.backtotreelink.title" )#
				</a>
			</div>
		</div>
	<cfelse>
		<p>
			<em>#translateResource( "cms:sitetree.no.trash.nodes.message" )#</em><br />
			<a href="#event.buildAdminLink( linkTo='sitetree' )#">
				<i class="fa fa-fw fa-reply fa-lg"></i>
				#translateResource( "cms:sitetree.trash.backtotreelink.title" )#
			</a>
		</p>
	</cfif>
</cfoutput>