<cfscript>
	activeFolder = Trim( rc.folder  ?: "" );
	allowedTypes = prc.allowedTypes ?: [];

	rootFolder   = prc.rootFolderId ?: 0;
	if ( not Len( activeFolder ) ) {
		activeFolder = rootFolder;
	}

	folders = renderPresideObjectView(
		  object  = "asset_folder"
		, view    = "preside-objects/asset_folder/pickerBrowserListing"
		, filter  = { parent_folder = activeFolder }
		, orderBy = "label asc"
	);


	assetFilter = { asset_folder = activeFolder };
	if ( allowedTypes.len() ){
		assetFilter.asset_type = allowedTypes;
	}
	assets = renderPresideObjectView(
		  object  = "asset"
		, view    = "preside-objects/asset/pickerBrowserListing"
		, filter  = assetFilter
		, orderBy = "label asc"
	);

	multiple = IsBoolean( rc.multiple ?: "" ) && rc.multiple;
</cfscript>

<cfoutput>
	#renderView( 'admin/layout/breadcrumbs' )#
	<table id="asset-listing-table" class="table table-striped table-bordered table-hover asset-listing-table" data-multiple="#multiple#">
		<thead>
			<tr>
				<th>&nbsp;</th>
				<th>#translateResource( "cms:assetManager.browser.name.column" )#</th>
			</tr>
		</thead>
		<tbody data-nav-list="1" data-nav-list-child-selector="> tr">
			<cfif activeFolder neq rootFolder>
				#renderPresideObjectView( object="asset_folder", view="preside-objects/asset_folder/pickerBrowserListingUpOneLevel", id=activeFolder )#
			</cfif>
			#folders#
			#assets#
		</tbody>
	</table>
</cfoutput>