/**
 * @feature presideForms and dataExport
 */
component {
	property name="dataExportService"    inject="dataExportService";
	property name="presideObjectService" inject="presideObjectService";

	public string function index( event, rc, prc, args={} ) {
		var objectName = args.exportObject ?: ( prc.record.object_name ?: ( rc.object ?: "" ) );

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
			var propRelationship = props[ prop ].relationship ?: "";

			if ( propRelationship == "select-data-view" ) {
				continue;
			}

			if ( !propRelationship.reFindNoCase( "to\-many$" ) && !IsTrue( props[ prop ].excludeDataExport ?: "" ) ) {
				args.values.append( prop );
			}
		}

		for( var prop in args.values ) {
			args.labels.append( translatePropertyName( objectName, prop ) );
		}

		return renderView( view="formcontrols/select/index", args=args );
	}
}