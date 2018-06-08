component {

	property name="presideObjectService" inject="presideObjectService";

	private string function adminView( event, rc, prc, args={} ){
		var objectName    = args.objectName   ?: "";
		var propertyName  = args.propertyName ?: "";
		var recordId      = args.recordId     ?: "";
		var enum          = presideObjectService.getObjectPropertyAttribute( objectName=objectName, propertyName=propertyName, attributeName="enum" );
		var values        = listToArray( args.data );
		var rendered      = [];

		if ( !enum.len() ) {
			return args.data;
		}

		for( var value in values ) {
			rendered.append( translateResource( uri="enum.#enum#:#value#.label", defaultValue=value ) );
		}

		return rendered.toList( ", " );
	}

	private string function adminDatatable( event, rc, prc, args={} ){
		return adminView( argumentCollection=arguments );
	}

}