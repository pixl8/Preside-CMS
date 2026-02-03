/**
 * @feature presideForms
 */
component {
	property name="enumService" inject="enumService";

	public string function index( event, rc, prc, args={} ) {
		var enum = args.enum ?: "";

		args.items = enumService.listItems( enum );
		if ( !ArrayLen( args.items ) ) {
			return "";
		}

		var hasToggleFields = false;
		var toggleFields    = _getToggleFields( fields=( args.toggleFields ?: "" ), separator=( args.toggleSeparator ?: "|" ) );

		if ( !isEmpty( toggleFields ) ) {
			for ( var i=1; i<=ArrayLen( args.items ); i++ ) {
				var id = args.items[ i ].id ?: "";

				if ( !isEmptyString( toggleFields[ id ] ?: "" ) ) {
					args.items[ i ].toggleFields = toggleFields[ id ];

					hasToggleFields = true;
				}
			}
		}

		args.class = Trim( args.class ?: "" );

		if ( hasToggleFields ) {
			args.class &= ( isEmptyString( args.toggleClass ?: "" ) ? " togglable-enum-radio-list" : args.toggleClass );
		}

		event.include( "/js/admin/specific/enumRadioList/" );

		return renderView( view="formcontrols/enumRadioList/index", args=args );
	}

	public struct function _getToggleFields( required any fields, string separator="|" ) {
		var fields = {};

		if ( IsSimpleValue( arguments.fields ) ) {
			arguments.fields = ListToArray( arguments.fields, arguments.separator );
		}

		for ( var toggleField in arguments.fields ) {
			if ( Find( ":", toggleField ) ) {
				StructAppend( fields, { "#ListFirst( toggleField, ":")#"=ListRest( toggleField, ":" ) } )
			}
		}

		return fields;
	}

}