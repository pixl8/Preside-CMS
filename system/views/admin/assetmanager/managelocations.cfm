<cfoutput>
	<div class="top-right-button-group">
		#renderViewlet( "admin.assetmanager.storageProviderPicker" )#
	</div>

	#renderView( view="/admin/datamanager/_objectDataTable", args={
		  objectName      = "asset_storage_location"
		, useMultiActions = false
		, gridFields      = [ "name", "storageProvider", "datemodified" ]
		, datasourceUrl   = event.buildAdminLink( "assetManager.getStorageLocationsForAjaxDataTables" )
	} )#
</cfoutput>