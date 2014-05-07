component output=false hint="I am just a bean wrapper to structure to represent a preside object property" {

// CONSTRUCTOR
	public any function init(){
		var key = "";

		_setAttributes( arguments );
		for( key in arguments ){
			this[ key ] = arguments[ key ];
		}

		return this;
	}

// PUBLIC API METHODS
	public boolean function attributeExists( required string name ){
		var attrs = _getAttributes();

		return StructKeyExists( attrs, arguments.name );
	}

	public any function getAttribute( required string name, string defaultValue="" ) output=false {
		var attrs = _getAttributes();

		if ( attributeExists( arguments.name ) ) {
			return attrs[ arguments.name ];
		}

		return arguments.defaultValue;
	}

	public void function setAttribute( required string name, required any value ) output=false {
		var attrs = _getAttributes();

		this[ arguments.name ] = arguments.value;
		attrs[ arguments.name ] = arguments.value;
	}

	public struct function getMemento(){
		return _getAttributes();
	}

// PRIVATE HELPERS
	private boolean function _isTrue( required any value ) output=false {
		return value eq "yes" or ( IsBoolean( arguments.value ) and arguments.value );
	}

// GETTERS AND SETTERS
	private struct function _getAttributes() output=false {
		return _attributes;
	}
	private void function _setAttributes( required struct attributes ) output=false {
		var attr = "";
		var booleanAttributes = "required";

		variables._attributes = {};
		for( attr in arguments.attributes ){

			if ( ListFindNoCase( booleanAttributes, attr ) ) {
				_attributes[ attr ] = _isTrue( arguments.attributes[ attr ] );
			} else {
				_attributes[ attr ] = arguments.attributes[ attr ];
			}
		}
	}
}