/**
 * @singleton
 * @presideService
 *
 */
component {

// CONSTRUCTOR
	public any function init() {
		return this;
	}

// PUBLIC API METHODS
	public void function setVar(
		  required string  name
		, required any     value
		,          string  expires  = 0
		,          boolean secure   = false
		,          string  path     = ""
		,          string  domain   = ""
		,          string  httpOnly = true
	) {
		var serialized = SerializeJSON( arguments.value );
		var encrypted  = _encryptIt( serialized );
		var args       = {
			  secure   = arguments.secure
			, httpOnly = arguments.httpOnly
		}

		if ( Len( Trim( arguments.expires ) ) && arguments.expires != 0 ) {
			args.expires = arguments.expires;
		}

		if ( Len( arguments.path ) ) {
			if ( !Len( arguments.domain ) ) {
				throw( type="CookieStorage.MissingDomainArgument", message="If you specify path, you must also specify domain." );
			}

			args.path = arguments.path;
		}

		if ( Len( arguments.domain ) ) {
			args.domain = arguments.domain;
		}

		cookie name=UCase( arguments.name ) value=encrypted attributeCollection=args;
	}

	public any function getVar( required string name, any default ) {
		if ( exists( arguments.name ) ) {
			var cookieValue = _decryptIt( cookie[ UCase( arguments.name ) ] );

			if ( IsJson( cookieValue ) ) {
				cookieValue = DeserializeJSON( cookieValue );
			}

			return cookieValue;
		}

		if ( StructKeyExists( arguments, "default" ) ) {
			return arguments.default;
		}

		throw( type="CookieStorage.InvalidKey", message="The key you requested: #arguments.name# does not exist" );
	}

	public boolean function deleteVar( required string name, string domain="" ) {
		if ( exists( arguments.name ) ) {
			var args = { expires = "NOW" }

			if ( Len( arguments.domain ) ) {
				args.domain = arguments.domain;
			}

			cookie name=UCase( arguments.name ) value="" attributeCollection=args;
			cookie.delete( arguments.name );

			return true;

		}

		return false;
	}

	public boolean function exists( required string name ) {
		return StructKeyExists( cookie, UCase( arguments.name ) );
	}

// PRIVATE HELPERS
	private string function _setupEncryptionKey() {
		var key = $getPresideSetting( "system", "cookie_encryption_key" );

		if ( !Len( Trim( key ) ) ) {
			var legacyCookieKeyFile = "/app/config/.cookieEncryptionKey";

			if ( FileExists( legacyCookieKeyFile ) ) {
				try {
					key = FileRead( legacyCookieKeyFile );
				} catch( any e ) {}
			}

			if ( !Len( Trim( key ) ) ) {
				key = GenerateSecretKey( "AES" );
			}

			$getSystemConfigurationService().saveSetting( "system", "cookie_encryption_key", key );

			if ( FileExists( legacyCookieKeyFile ) ) {
				FileDelete( legacyCookieKeyFile );
			}
		}

		_setEncryptionKey( key );

		return key;
	}

	private string function _encryptIt( required string encValue ) {
		return Encrypt( arguments.encValue, _getEncryptionKey(), "AES", "HEX" );
	}

	private string function _decryptIt( required string decValue ) {
		try {
			return Decrypt( arguments.decValue, _getEncryptionKey(), "AES", "HEX" );
		} catch( any e ) {
			return "";
		}
	}

// GETTERS AND SETTERS
	private string function _getEncryptionKey() {
		if ( !Len( Trim( variables._encryptionKey ?: "" ) ) ) {
			return _setupEncryptionKey();
		}

		return _encryptionKey;
	}
	private void function _setEncryptionKey( required string encryptionKey ) {
		_encryptionKey = arguments.encryptionKey;
	}
}