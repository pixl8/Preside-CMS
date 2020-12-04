component {
	property name="presideObjectService" inject="PresideObjectService";

	public string function index( event, rc, prc, args={} ) {
		args.labels    = args.labels ?: [];
		args.values    = args.values ?: [];
		var savedValue = event.getValue( name=args.name, defaultValue=args.defaultValue ?: "" );
		var objectName = args.object ?: "";

		if ( !isEmptyString( objectName ) ) {
			if ( isTrue( args.useObjProperties ?: "" ) ) {
				args.labels = [];
				args.values = [];
				var props   = presideObjectService.getObjectProperties( objectName );

				for ( var prop in props ) {
					if ( !( props[ prop ].relationship ?: "" ).reFindNoCase( "to\-many$" ) && !IsTrue( props[ prop ].excludeDataExport ?: "" ) ) {
						args.values.append( prop );
					}
				}

				if ( !isEmptyString( savedValue ) ) {
					var savedValueArray = listToArray( savedValue );

					args.values.each( function( item, index ) {
						if ( isTrue( arrayFind( savedValueArray, item ) ) ) {
							args.values.swap( arrayFind( savedValueArray, item ), index );
						}
					});
				}

				var baseI18nUri = presideObjectService.getResourceBundleUriRoot( objectName=objectName );
				for( var prop in args.values ) {
					args.labels.append( translateResource(
						  uri          = baseI18nUri & "field.#prop#.title"
						, defaultValue = translateResource( uri="cms:preside-objects.default.field.#prop#.title", defaultValue=prop )
					) );
				}

				args.selectSize = ( arrayLen( args.values ) lt 10 ) ? arrayLen( args.values ) : 10;
			} else {
				var fParams = {};
				var orderBy = [];

				orderBy.append( args.objOrderBy ?: "" );

				if ( !isEmptyString( savedValue ) ) {
					orderBy.prepend( "FIELD( id, :ids )" );
					fParams.ids = { value=savedValue, type="varchar", list=true };
				}

				var objRecords = presideObjectService.selectData(
					  objectName   = objectName
					, selectFields = listToArray( args.objSelectFields ?: "id,label" )
					, savedFilters = listToArray( args.objSavedFilters ?: "" )
					, filterParams = fParams
					, orderBy      = arrayToList( orderBy )
				);

				if ( objRecords.recordcount ) {
					args.values = valueArray( objRecords, args.objIdField    ?: "id" );
					args.labels = valueArray( objRecords, args.objLabelField ?: presideObjectService.getLabelField( objectName ) );

					args.selectSize = ( objRecords.recordcount lt 10 ) ? objRecords.recordcount : 10;
				}
			}
		}

		return renderView( view="/formcontrols/multiSelectPanel/index", args=args )
	}
}