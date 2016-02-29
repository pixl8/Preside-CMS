/**
 * @singleton
 * @presideservice
 *
 */
component {

// CONSTRUCTOR
	public any function init() {
		_setValidationEndpoint( "https://www.google.com/recaptcha/api/siteverify" );
		return this;
	}

// PUBLIC API METHODS
	public boolean function validate( required string response, string remoteAddress=cgi.remote_address ) {
		var resp      = "";
		var secretKey = $getPresideSetting( "recaptcha", "secret_key" );

		http url=_getValidationEndpoint() method="POST" timeout="10" result="resp" {
			httpparam type="formfield" name="secret"   value=secretKey;
			httpparam type="formfield" name="response" value=arguments.response;
			httpparam type="formfield" name="remoteip" value=arguments.remoteAddress;
		}

		if ( IsJson( resp.fileContent ) ) {
			var resp = DeserializeJson( resp.fileContent );

			return IsBoolean( resp.success ?: "" ) && resp.success;
		}

		return false;
	}

// PRIVATE HELPERS

// GETTERS AND SETTERS
	private string function _getValidationEndpoint() {
		return _validationEndpoint;
	}
	private void function _setValidationEndpoint( required string validationEndpoint ) {
		_validationEndpoint = arguments.validationEndpoint;
	}

}