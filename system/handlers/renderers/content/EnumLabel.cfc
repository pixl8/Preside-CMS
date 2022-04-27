component {
	property name="presideObjectService" inject="presideObjectService";

	public string function default( event, rc, prc, args={} ) {
		var objectName   = args.objectName   ?: "";
		var propertyName = args.propertyName ?: "";
		var enum         = args.enum         ?: "";
		var values       = ListToArray( args.data );
		var rendered     = [];

		if ( isEmptyString( enum ) && !isEmptyString( objectName ) && !isEmptyString( propertyName ) ) {
			enum = presideObjectService.getObjectPropertyAttribute( objectName=objectName, propertyName=propertyName, attributeName="enum" );
		}

		if ( !Len( enum ) ) {
			return args.data;
		}

		for ( var value in values ) {
			var iconClass = translateResource( uri="enum.#enum#:#value#.iconClass", defaultValue="" );
			var icon      = Len( iconClass ) ? '<i class="fa fa-fw #iconClass#"></i>&nbsp;' : "";
			var label     = translateResource( uri="enum.#enum#:#value#.label", defaultValue=value );

			ArrayAppend( rendered, icon & label );
		}

		return ArrayToList( rendered,  ", " );
	}

	private string function adminView( event, rc, prc, args={} ) {
		return default( argumentCollection=arguments );
	}

	private string function adminDatatable( event, rc, prc, args={} ){
		return default( argumentCollection=arguments );
	}
}