/**
 * @feature presideForms and customFields
 */
component {

	property name="customFieldsService" inject="customFieldsService";
	property name="enumService"         inject="enumService";

	public string function index( event, rc, prc, args={} ) {
		var savedData    = args.savedData ?: {};
		var targetObject = Trim( savedData.target_object ?: ( rc.target_object ?: "" ) );
		var items        = Duplicate( enumService.listItems( args.enum ?: "customFieldKind" ) );
		var canAggregate   = Len( targetObject ) && customFieldsService.objectHasAggregateRelationships( targetObject );
		var canRelatedData = Len( targetObject ) && customFieldsService.objectHasRelatedDataRelationships( targetObject );
		var toggleFields   = _getToggleFields( fields=( args.toggleFields ?: "" ), separator=( args.toggleSeparator ?: "|" ) );
		var hasToggle      = false;

		for( var i=1; i<=ArrayLen( items ); i++ ) {
			var id = items[ i ].id ?: "";

			if ( id == "aggregate" && !canAggregate ) {
				items[ i ].disabled    = true;
				items[ i ].description = translateResource(
					  uri          = Len( targetObject ) ? "enum.customFieldKind:aggregate.disabled.description" : "enum.customFieldKind:aggregate.chooseobject.description"
					, defaultValue = "This object has no one-to-many or many-to-many collections to aggregate."
				);
			}

			if ( id == "related_data" && !canRelatedData ) {
				items[ i ].disabled    = true;
				items[ i ].description = translateResource(
					  uri          = Len( targetObject ) ? "enum.customFieldKind:related_data.disabled.description" : "enum.customFieldKind:related_data.chooseobject.description"
					, defaultValue = "This object has no many-to-one relationships to related records."
				);
			}

			if ( Len( Trim( toggleFields[ id ] ?: "" ) ) ) {
				items[ i ].toggleFields = toggleFields[ id ];
				hasToggle = true;
			}
		}

		args.items = items;
		args.class = Trim( args.class ?: "" );

		if ( hasToggle ) {
			args.class &= ( IsEmptyString( args.toggleClass ?: "" ) ? " togglable-enum-radio-list" : args.toggleClass );
		}

		event.include( "/js/admin/specific/enumRadioList/" );

		return renderView( view="formcontrols/enumRadioList/index", args=args );
	}

	private struct function _getToggleFields( required any fields, string separator="|" ) {
		var fields = {};

		if ( IsSimpleValue( arguments.fields ) ) {
			arguments.fields = ListToArray( arguments.fields, arguments.separator );
		}

		for( var toggleField in arguments.fields ) {
			if ( Find( ":", toggleField ) ) {
				StructAppend( fields, { "#ListFirst( toggleField, ":" )#"=ListRest( toggleField, ":" ) } );
			}
		}

		return fields;
	}

}
