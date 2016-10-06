component output="false" displayname=""  {
	property name="rootFolderStorageProvider" inject="rootFolderStorageProvider";

	public string function index( event, rc, prc, args={} ) output=false {
		var fileBinary  = "";
		if( rootFolderStorageProvider.objectExists( path = "#args.path#" ) ){
			fileBinary = rootFolderStorageProvider.getObject( path = "#args.path#" );
		}else{
			fileBinary = ''
		}
		var fileContent = toString(fileBinary);
		args.defaultValue = fileContent

		return renderView( view="formcontrols/textarea/index", args=args );
	}
}