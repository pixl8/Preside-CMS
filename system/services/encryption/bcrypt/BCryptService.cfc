component output=false singleton=true {

// CONSTRUCTOR
	public any function init() output=false {
		_setJBCrypt(
			jBCrypt = CreateObject( 'java', 'org.mindrot.jbcrypt.BCrypt', ExpandPath( "/preside/system/services/encryption/bcrypt/lib/jbcrypt-0.3m.jar" ) )
		);

		return this;
	}

// PUBLIC API METHODS
	public string function hashPw( required string pw, numeric workFactor=10 ) output=false {
		var jBCrypt = _getJBCrypt();
		var salt    = jBCrypt.genSalt( javaCast("int", workFactor ) );

		return jBCrypt.hashpw( pw, salt );
	}

	public boolean function checkPw( required string plainText, required string hashed ) output=false {
		if ( not Len( Trim( arguments.hashed ) ) ) {
			return false;
		}

		try {
			return _getJBCrypt().checkpw( plainText, hashed );
		} catch ( any e ) {
			if ( e.message contains 'salt' or e.detail contains 'salt' ) {
				return false;
			}

			rethrow;
		}
	}

// GETTERS AND SETTERS
	private any function _getJBCrypt() output=false {
		return _jBCrypt;
	}
	private void function _setJBCrypt( required any jBCrypt ) output=false {
		_jBCrypt = arguments.jBCrypt;
	}
}