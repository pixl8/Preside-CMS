<cfscript>
	activeFolder = Trim( rc.folder  ?: "" );
	rootFolder   = prc.rootFolderId ?: 0;
	if ( not Len( activeFolder ) ) {
		activeFolder = rootFolder;
	}

	permissionContext   = prc.permissionContext ?: [];

	folders = renderPresideObjectView(
		  object  = "asset_folder"
		, view    = "preside-objects/asset_folder/browserListing"
		, filter  = { parent_folder = activeFolder }
		, orderBy = "label asc"
	);
	assets = renderPresideObjectView(
		  object  = "asset"
		, view    = "preside-objects/asset/browserListing"
		, filter  = { asset_folder = activeFolder }
		, orderBy = "label asc"
	);
</cfscript>

<cfoutput>
	<table id="asset-listing-table" class="table table-striped table-bordered table-hover asset-listing-table">
		<thead>
			<tr>
				<th>&nbsp;</th>
				<th>#translateResource( "cms:assetManager.browser.name.column" )#</th>
				<th>
					<cfif hasPermission( permissionKey="assetmanager.folders.add", context="assetmanagerfolder", contextKeys=permissionContext )>
						<a class="btn btn-success btn-xs" data-global-key="a" href="#event.buildAdminLink( linkTo='assetManager.addFolder', queryString='folder=#( rc.folder ?: "" )#' )#">
							<i class="fa fa-plus"></i>
							#translateResource( "cms:assetManager.add.folder.button" )#
						</a>
					</cfif>
				</th>
			</tr>
		</thead>
		<tbody data-nav-list="1" data-nav-list-child-selector="> tr">
			<cfif activeFolder neq rootFolder>
				#renderPresideObjectView( object="asset_folder", view="preside-objects/asset_folder/browserListingUpOneLevel", id=activeFolder )#
			</cfif>
			#folders#
			#assets#
		</tbody>
	</table>
</cfoutput>