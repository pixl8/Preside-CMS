/**
 * This service exists to provide APIs that make providing support for multilingual
 * translations of standard preside objects possible in a transparent way. You are
 * unlikely to need to deal with this API directly.
 *
 * @displayName Multilingual Preside Object Service
 */
component autodoc=true {

// CONSTRUCTOR
	public any function init() {
		return this;
	}

// PUBLIC METHODS
	public boolean function isObjectMultilingual( required struct object ) {
		var multiLingualFlag = arguments.object.multilingual ?: "";

		return IsBoolean( multiLingualFlag ) && multiLingualFlag;
	}

	public array function listMultilingualObjectProperties( required struct object ) {
		var multilingualProperties = [];
		var objectProperties       = arguments.object.properties ?: {};

		for( var propertyName in objectProperties ) {
			var property = objectProperties[ propertyName ];
			if ( IsBoolean( property.multilingual ?: "" ) && property.multilingual ) {
				multilingualProperties.append( propertyName );
			}
		}

		return multiLingualProperties;
	}



}