<cfscript>
	activeFolder = Trim( rc.folder  ?: "" );
	rootFolder   = prc.rootFolderId ?: 0;
	if ( not Len( activeFolder ) ) {
		activeFolder = rootFolder;
	}

	permissionContext   = prc.permissionContext ?: [];
</cfscript>

<cfoutput>
	<form action="#event.buildAdminLink( linkTo='assetManager.multiRecordAction' )#" method="post" id="multi-action-form" class="asset-manager-listing-form">
		<input type="hidden" name="multiAction" value="">
		<table id="asset-listing-table" class="table table-hover table-striped asset-listing-table">
			<thead>
				<tr>
					<th class="center" data-width="50px">
						<label>
							<input type="checkbox" class="ace" />
							<span class="lbl"></span>
						</label>
					</th>
					<th data-field="title">#translateResource( "preside-objects.asset:title.singular" )#</th>
					<th data-width="240px" data-field="datemodified">#translateResource( "preside-objects.asset:field.datemodified.title" )#</th>
					<th data-width="240px" data-field="datecreated">#translateResource( "preside-objects.asset:field.datecreated.title" )#</th>
					<th data-width="100px">#translateResource( "cms:assetmanager.browser.table.actions.header" )#</th>
				</tr>
			</thead>
			<tbody data-nav-list="1" data-nav-list-child-selector="> tr">
			</tbody>
		</table>

		#renderView( view="/admin/assetmanager/_listingTableMultiActions" )#
	</form>
</cfoutput>