/**
 * @feature admin and customFields
 */
component {

	property name="presideObjectService"    inject="presideObjectService";
	property name="customFieldTypesService" inject="customFieldTypesService";

	variables.GENERIC_CURRENCY_SIGN = Chr( 164 );

	public string function default( event, rc, prc, args={} ) {
		var data = args.data ?: "";

		if ( !IsNumeric( data ) ) {
			return data;
		}

		var config   = _getDisplayConfig( argumentCollection=arguments );
		var value    = Val( data );
		var rendered = "";

		switch( config.numberDisplay ?: "standard" ) {
			case "currency":
				rendered = _currency( value, config );
			break;
			case "percentage":
				rendered = _formatNumber( value, config, _defaultDecimalPlaces( argumentCollection=arguments ) ) & "%";
			break;
			case "compact":
				rendered = _compact( value, config );
			break;
			default:
				rendered = _formatNumber( value, config, _defaultDecimalPlaces( argumentCollection=arguments ) );
		}

		return ( config.prefix ?: "" ) & rendered & ( config.suffix ?: "" );
	}

	public string function admin( event, rc, prc, args={} ) {
		return EncodeForHTML( default( argumentCollection=arguments ) );
	}

	public string function adminView( event, rc, prc, args={} ) {
		return admin( argumentCollection=arguments );
	}

	private string function _currency( required numeric value, required struct config ) {
		var rendered = LSCurrencyFormat( arguments.value, "local" );

		if ( !Find( GENERIC_CURRENCY_SIGN, rendered ) ) {
			return rendered;
		}

		rendered = LSCurrencyFormat( arguments.value, "local", translateResource( uri="customFields:number.currency.locale" ) );

		if ( !Find( GENERIC_CURRENCY_SIGN, rendered ) ) {
			return rendered;
		}

		return _formatNumber( arguments.value, arguments.config, 2 );
	}

	private string function _compact( required numeric value, required struct config ) {
		var magnitude = Abs( arguments.value );
		var units     = [
			  { divisor=1000000000, key="billion"  }
			, { divisor=1000000   , key="million"  }
			, { divisor=1000      , key="thousand" }
		];

		for( var unit in units ) {
			if ( magnitude >= unit.divisor ) {
				return _formatNumber( arguments.value / unit.divisor, arguments.config, 1 )
				     & translateResource( uri="customFields:number.compact.#unit.key#" );
			}
		}

		return _formatNumber( arguments.value, arguments.config, 0 );
	}

	private string function _formatNumber( required numeric value, required struct config, required numeric defaultPlaces ) {
		var places = Len( arguments.config.decimalPlaces ?: "" ) ? Val( arguments.config.decimalPlaces ) : arguments.defaultPlaces;
		var mask   = ( arguments.config.useGrouping ?: true ) ? "0," : "0";

		if ( places > 0 ) {
			mask &= "." & RepeatString( "0", places );
		}

		return LSNumberFormat( arguments.value, mask );
	}

	private numeric function _defaultDecimalPlaces( event, rc, prc, args={} ) {
		return _getDataType( argumentCollection=arguments ) == "float" ? 2 : 0;
	}

	private string function _getDataType( event, rc, prc, args={} ) {
		var dataType = _getPropertyAttribute( argumentCollection=arguments, attributeName="customFieldDataType" );

		return Len( dataType ) ? dataType : "integer";
	}

	private struct function _getDisplayConfig( event, rc, prc, args={} ) {
		return customFieldTypesService.getDisplayConfig(
			  dataType   = "integer"
			, typeConfig = _getPropertyAttribute( argumentCollection=arguments, attributeName="customFieldDisplayConfig" )
		);
	}

	private string function _getPropertyAttribute( event, rc, prc, args={}, required string attributeName ) {
		var objectName   = args.objectName   ?: "";
		var propertyName = args.propertyName ?: "";

		if ( !Len( objectName ) || !Len( propertyName ) ) {
			return "";
		}

		return presideObjectService.getObjectPropertyAttribute(
			  objectName    = objectName
			, propertyName  = propertyName
			, attributeName = arguments.attributeName
		);
	}

}
