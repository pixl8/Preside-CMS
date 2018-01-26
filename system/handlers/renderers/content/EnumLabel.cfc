component {

	property name="presideObjectService" inject="presideObjectService";

	public string function adminView( event, rc, prc, args={} ){
		var objectName    = args.objectName   ?: "";
		var propertyName  = args.propertyName ?: "";
		var recordId      = args.recordId     ?: "";
		var enum          = presideObjectService.getObjectPropertyAttribute( objectName=objectName, propertyName=propertyName, attributeName="enum" );
		var values        = args.data.listToArray();
		var rendered      = [];

		if ( !enum.len() ) {
			return args.data;
		}

		for( var value in values ) {
			rendered.append( translateResource( uri="enum.#enum#:#value#.label", defaultValue=value ) );
		}

		return rendered.toList( ", " );
	}

}