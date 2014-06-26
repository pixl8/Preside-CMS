component output=false {

	property name="assetManagerService" inject="assetManagerService";

	public string function index( event, rc, prc, args={} ) output=false {
		var value = event.getValue(
			  name         = args.name ?: ""
			, defaultValue = args.defaultValue ?: ""
		);

		if ( not IsSimpleValue( value ) ) {
			value = "";
		}

		if ( Len( Trim ( value ) ) ) {
			args.selectedFolder = assetManagerService.getFolder( id = value );
		}

		args.folders = assetManagerService.getAllFoldersForSelectList();
		args.rootFolderId = assetManagerService.getRootFolderId();

		return renderView( view="formcontrols/assetFolderPicker/index", args=args );
	}
}