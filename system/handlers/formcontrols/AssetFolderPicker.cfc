component output=false {

	property name="assetManagerService" inject="assetManagerService";

	public string function index( event, rc, prc, viewletArgs={} ) output=false {
		var value = event.getValue(
			  name         = viewletArgs.name ?: ""
			, defaultValue = viewletArgs.defaultValue ?: ""
		);

		if ( not IsSimpleValue( value ) ) {
			value = "";
		}

		if ( Len( Trim ( value ) ) ) {
			viewletArgs.selectedFolder = assetManagerService.getFolder( id = value );
		}

		viewletArgs.folders = assetManagerService.getAllFoldersForSelectList();
		viewletArgs.rootFolderId = assetManagerService.getRootFolderId();

		return renderView( view="formcontrols/assetFolderPicker/index", args=viewletArgs );
	}
}