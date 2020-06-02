component {
	property name="dataExportService"    inject="dataExportService";
	property name="presideObjectService" inject="presideObjectService";

	public string function index( event, rc, prc, args={} ) {
		var objectName = args.exportObject ?: "";

		if ( !objectName.len() ) {
			return "";
		}

		var propertyNames = presideObjectService.getObjectAttribute( objectName=objectName, attributeName="propertyNames" );
		var props         = presideObjectService.getObjectProperties( objectName=objectName );

		args.defaultValue = Len( args.defaultValue ?: "" ) ? args.defaultValue : dataExportService.getDefaultExportFieldsForObject( objectName ).selectFields.toList();
		args.values       = [];
		args.labels       = [];
		args.multiple     = true;
		args.sortable     = true;

		for( var prop in propertyNames ) {
			if ( !( props[ prop ].relationship ?: "" ).reFindNoCase( "to\-many$" ) ) {
				args.values.append( prop );
			}
		}

		var baseI18nUri = presideObjectService.getResourceBundleUriRoot( objectName=objectName );
		for( var prop in args.values ) {
			args.labels.append( translateResource(
				  uri          = baseI18nUri & "field.#prop#.title"
				, defaultValue = translateResource( uri="cms:preside-objects.default.field.#prop#.title", defaultValue=prop )
			) );
		}

		return renderView( view="formcontrols/select/index", args=args );
	}
}