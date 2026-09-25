/**
 * @feature presideForms
 */
component {
	property name="dataManagerService"   inject="dataManagerService";
	property name="presideObjectService" inject="presideObjectService";

	public string function index( event, rc, prc, args={} ) {
		var groupedObjects = dataManagerService.getGroupedObjects();
		var extraObjects   = getSetting( name="extraObjectsDataManagerPicker", defaultValue=[] );

		args.values = [ "" ]; // show the default values as empty
		args.labels = [ "" ]; // show the default labels as empty

		for( var group in groupedObjects ){
			for( var object in group.objects ){
				args.values.append( object.id );
				args.labels.append( object.title );
			}
		}

		for ( var objectName in extraObjects ) {
			if ( presideObjectService.objectExists( objectName ) && !args.values.findNoCase( objectName ) && hasCmsPermission(
				  permissionKey = "datamanager.navigate"
				, context       = "datamanager"
				, contextKeys   = [ objectName ]
			) ) {
				args.values.append( objectName );
				args.labels.append( translateResource( uri="preside-objects.#objectName#:title" ) );
			}
		}

		if ( args.values.len() == 1 ) {
			return "";
		}

		return renderView( view="formcontrols/select/index", args=args );
	}
}