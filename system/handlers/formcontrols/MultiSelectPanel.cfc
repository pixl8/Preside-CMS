/**
 * @feature presideForms
 */
component {
	property name="presideObjectService" inject="PresideObjectService";
	property name="dataExportService"    inject="DataExportService";

	public string function index( event, rc, prc, args={} ) {
		args.labels    = args.labels ?: [];
		args.values    = args.values ?: [];
		var savedValue = event.getValue( name=args.name, defaultValue=args.defaultValue ?: "" );
		var objectName = args.object ?: "";

		if ( !isEmptyString( objectName ) ) {
			if ( isTrue( args.useObjProperties ?: "" ) ) {
				args.labels = [];
				args.values = dataExportService.getAllowExportObjectProperties( objectName=objectName );

				if ( !isEmptyString( savedValue ) ) {
					var savedValueArray = listToArray( savedValue );
					var parentOnlyArray = [];

					for ( var value in savedValueArray ) {
						var parentKey = ListFirst( value, "." );
						if ( !ArrayContains( parentOnlyArray, parentKey ) ) {
							ArrayAppend( parentOnlyArray, parentKey );
						}
					}

					var valuesArrLength = arrayLen( args.values );

					args.values.each( function( item, index ) {
						if ( isTrue( arrayFind( parentOnlyArray, item ) ) ) {
							var savedArrIndex = arrayFind( parentOnlyArray, item );
							    savedArrIndex = ( savedArrIndex > valuesArrLength ) ? valuesArrLength : savedArrIndex;

							args.values.swap( savedArrIndex, index );
						}
					});
				}

				var baseI18nUri = presideObjectService.getResourceBundleUriRoot( objectName=objectName );
				for( var prop in args.values ) {
					var propId = IsSimpleValue( prop ) ? prop : StructKeyList( prop );

					ArrayAppend( args.labels, translateResource(
						  uri          = baseI18nUri & "field.#propId#.title"
						, defaultValue = translateResource( uri="cms:preside-objects.default.field.#propId#.title", defaultValue=propId )
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