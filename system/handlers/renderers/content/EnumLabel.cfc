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
			var iconClass = translateResource( uri="enum.#enum#:#value#.iconClass", defaultValue="" );
			var icon = iconClass.len() ? '<i class="fa fa-fw #iconClass#"></i>&nbsp; ' : "";
			var label = translateResource( uri="enum.#enum#:#value#.label", defaultValue=value );

			rendered.append( icon & label );
		}

		return rendered.toList( ", " );
	}

	private string function adminDatatable( event, rc, prc, args={} ){
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
			var iconClass = translateResource( uri="enum.#enum#:#value#.iconClass", defaultValue="" );
			var icon = iconClass.len() ? '<i class="fa fa-fw #iconClass#"></i> ' : "";
			var label = translateResource( uri="enum.#enum#:#value#.label", defaultValue=value );

			rendered.append( icon & label );
		}

		return rendered.toList( ", " );
	}

}