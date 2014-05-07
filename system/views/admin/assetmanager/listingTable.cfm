<cfscript>
	activeFolder = Trim( rc.folder  ?: "" );
	rootFolder   = prc.rootFolderId ?: 0;
	if ( not Len( activeFolder ) ) {
		activeFolder = rootFolder;
	}

	folders = renderPresideObjectView(
		  object  = "asset_folder"
		, view    = "browserListing"
		, filter  = { parent_folder = activeFolder }
		, orderBy = "label asc"
	);
	assets = renderPresideObjectView(
		  object  = "asset"
		, view    = "browserListing"
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
					<a class="btn btn-success btn-xs" data-global-key="a" href="#event.buildAdminLink( linkTo='assetManager.addFolder', queryString='folder=#( rc.folder ?: "" )#' )#">
						<i class="fa fa-plus"></i>
						#translateResource( "cms:assetManager.add.folder.button" )#
					</a>
				</th>
			</tr>
		</thead>
		<tbody data-nav-list="1" data-nav-list-child-selector="> tr">
			<cfif activeFolder neq rootFolder>
				#renderPresideObjectView( object="asset_folder", view="browserListingUpOneLevel", id=activeFolder )#
			</cfif>
			#folders#
			#assets#
		</tbody>
	</table>
</cfoutput>