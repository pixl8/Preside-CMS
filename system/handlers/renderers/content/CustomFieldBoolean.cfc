/**
 * @feature admin and customFields
 */
component {

	property name="presideObjectService"    inject="presideObjectService";
	property name="customFieldTypesService" inject="customFieldTypesService";
	property name="customFieldBadgeService" inject="customFieldBadgeService";

	public string function default( event, rc, prc, args={} ) {
		var data   = args.data ?: "";
		var config = _getDisplayConfig( argumentCollection=arguments );

		if ( ( config.booleanDisplay ?: "" ) == "customBadge" ) {
			return _badgeLabel( data, config );
		}

		return _wording( data, config.booleanDisplay ?: "checkCross" );
	}

	public string function admin( event, rc, prc, args={} ) {
		var data   = args.data ?: "";
		var config = _getDisplayConfig( argumentCollection=arguments );
		var mode   = config.booleanDisplay ?: "checkCross";

		if ( mode == "customBadge" ) {
			return customFieldBadgeService.renderBadge(
				  label  = _badgeLabel( data, config )
				, colour = _badgeColour( data, config )
			);
		}

		if ( mode == "checkCross" ) {
			return _icon( data );
		}

		return EncodeForHTML( _wording( data, mode ) );
	}

	public string function adminView( event, rc, prc, args={} ) {
		return admin( argumentCollection=arguments );
	}

	private string function _wording( required any data, required string mode ) {
		if ( !IsBoolean( arguments.data ) ) {
			return translateResource( uri="cms:boolean.not.set" );
		}

		if ( arguments.mode == "trueFalse" ) {
			return translateResource( uri="customFields:boolean.#( arguments.data ? 'true' : 'false' )#" );
		}

		return translateResource( uri="cms:boolean.#( arguments.data ? 'yes' : 'no' )#" );
	}

	private string function _icon( required any data ) {
		if ( !IsBoolean( arguments.data ) ) {
			return '<i class="fa fa-question grey" title="#EncodeForHTMLAttribute( translateResource( "cms:boolean.not.set" ) )#"></i>';
		}

		var icon = arguments.data ? "check-circle green" : "times-circle red";

		return '<i class="fa fa-#icon#" title="#EncodeForHTMLAttribute( _wording( arguments.data, "yesNo" ) )#"></i>';
	}

	private string function _badgeLabel( required any data, required struct config ) {
		return arguments.config[ _badgeKey( arguments.data ) & "Label" ] ?: "";
	}

	private string function _badgeColour( required any data, required struct config ) {
		return arguments.config[ _badgeKey( arguments.data ) & "Colour" ] ?: "";
	}

	private string function _badgeKey( required any data ) {
		if ( !IsBoolean( arguments.data ) ) {
			return "unset";
		}

		return arguments.data ? "true" : "false";
	}

	private struct function _getDisplayConfig( event, rc, prc, args={} ) {
		var objectName   = args.objectName   ?: "";
		var propertyName = args.propertyName ?: "";

		if ( !Len( objectName ) || !Len( propertyName ) ) {
			return customFieldTypesService.getDisplayConfig( dataType="boolean" );
		}

		return customFieldTypesService.getDisplayConfig(
			  dataType   = "boolean"
			, typeConfig = presideObjectService.getObjectPropertyAttribute(
				  objectName    = objectName
				, propertyName  = propertyName
				, attributeName = "customFieldDisplayConfig"
			  )
		);
	}

}
