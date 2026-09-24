/**
 * @feature admin and customFields
 */
component {

	property name="presideObjectService"    inject="presideObjectService";
	property name="customFieldTypesService" inject="customFieldTypesService";

	public string function default( event, rc, prc, args={} ) {
		var data = args.data ?: "";

		if ( !LSIsDate( data ) ) {
			return data;
		}

		if ( _isRelative( argumentCollection=arguments ) ) {
			return renderContent( renderer="datetime", data=data, context="relative" );
		}

		return _formatAbsolute( argumentCollection=arguments );
	}

	public string function admin( event, rc, prc, args={} ) {
		var data = args.data ?: "";

		if ( !LSIsDate( data ) ) {
			return data;
		}

		if ( _isRelative( argumentCollection=arguments ) ) {
			return '<abbr title="#EncodeForHTMLAttribute( _formatAbsolute( argumentCollection=arguments ) )#">#EncodeForHTML( renderContent( renderer="datetime", data=data, context="relative" ) )#</abbr>';
		}

		return _formatAbsolute( argumentCollection=arguments );
	}

	public string function adminView( event, rc, prc, args={} ) {
		return admin( argumentCollection=arguments );
	}

	public string function dataexport( event, rc, prc, args={} ) {
		var data = args.data ?: "";

		if ( !LSIsDate( data ) ) {
			return data;
		}

		return _formatAbsolute( argumentCollection=arguments );
	}

	private boolean function _isRelative( event, rc, prc, args={} ) {
		return ( _getDisplayConfig( argumentCollection=arguments ).dateDisplay ?: "" ) == "relative";
	}

	private string function _formatAbsolute( event, rc, prc, args={} ) {
		var parsed   = LSParseDateTime( args.data ?: "" );
		var rendered = LSDateFormat( parsed, _dateMask( argumentCollection=arguments ) );

		if ( _getDataType( argumentCollection=arguments ) == "datetime" ) {
			rendered &= " " & LSTimeFormat( parsed, _timeMask( argumentCollection=arguments ) );
		}

		return rendered;
	}

	private string function _dateMask( event, rc, prc, args={} ) {
		switch( _getDisplayConfig( argumentCollection=arguments ).dateDisplay ?: "systemDefault" ) {
			case "short":
				return translateResource( uri="customFields:dateFormat.short" );
			case "medium":
				return translateResource( uri="customFields:dateFormat.medium" );
			case "long":
				return translateResource( uri="customFields:dateFormat.long" );
		}

		var adminUser  = _getAdminUserDetails( argumentCollection=arguments );
		var userFormat = adminUser.user_admin_date_format ?: "";

		return Len( userFormat ) ? userFormat : translateResource( uri="cms:dateFormat" );
	}

	private string function _timeMask( event, rc, prc, args={} ) {
		var adminUser  = _getAdminUserDetails( argumentCollection=arguments );
		var userFormat = adminUser.user_time_format ?: "";

		if ( Len( userFormat ) ) {
			return userFormat == "24h" ? "HH:mm:ss" : "hh:mm:ss tt";
		}

		return translateResource( uri="cms:timeFormat" );
	}

	private struct function _getAdminUserDetails( event, rc, prc, args={} ) {
		if ( !IsObject( arguments.event ?: "" ) ) {
			return {};
		}

		var details = arguments.event.getAdminUserDetails();

		return IsStruct( details ) ? details : {};
	}

	private string function _getDataType( event, rc, prc, args={} ) {
		var dataType = _getPropertyAttribute( argumentCollection=arguments, attributeName="customFieldDataType" );

		return Len( dataType ) ? dataType : "date";
	}

	private struct function _getDisplayConfig( event, rc, prc, args={} ) {
		return customFieldTypesService.getDisplayConfig(
			  dataType   = "date"
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
