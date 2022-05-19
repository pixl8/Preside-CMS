component {
	property name="presideObjectService" inject="PresideObjectService";
	property name="loginService"         inject="LoginService";
	property name="permissionService"    inject="PermissionService";

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
						var hasPermission     = true;
						var requiredRoleCheck = StructKeyExists( props[ prop ], "limitToAdminRoles" )
						                     && ( args.context ?: "" ) == "admin"
						                     && !loginService.isSystemUser();

						if ( requiredRoleCheck ) {
							hasPermission = permissionService.userHasAssignedRoles(
								  userId = loginService.getLoggedInUserId()
								, roles  = ListToArray( props[ prop ].limitToAdminRoles )
							);
						}

						if ( hasPermission ) {
							ArrayAppend( args.values, prop );
						}
					}
				}

				if ( !isEmptyString( savedValue ) ) {
					var savedValueArray = listToArray( savedValue );
					var valuesArrLength = arrayLen( args.values );

					args.values.each( function( item, index ) {
						if ( isTrue( arrayFind( savedValueArray, item ) ) ) {
							var savedArrIndex = arrayFind( savedValueArray, item );
							    savedArrIndex = ( savedArrIndex > valuesArrLength ) ? valuesArrLength : savedArrIndex;

							args.values.swap( savedArrIndex, index );
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