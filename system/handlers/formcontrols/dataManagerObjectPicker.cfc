component {
	property name="dataManagerService" inject="dataManagerService";

	public string function index( event, rc, prc, args={} ) {
		var groupedObjects = dataManagerService.getGroupedObjects();

		if ( !groupedObjects.len() ) {
			return "";
		}

		args.values = [ "" ]; // show the default values as empty
		args.labels = [ "" ]; // show the default labels as empty

		for( var group in groupedObjects ){
			for( var object in group.objects ){
				args.values.append( object.id );
				args.labels.append( object.title );
			}
		}

		return renderView( view="formcontrols/select/index", args=args );
	}
}