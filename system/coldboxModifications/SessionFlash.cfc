component extends="coldbox.system.web.flash.SessionFlash" {

	public function saveFlash() {
		_getSessionStorage().setVar( variables.flashKey, getScope() );

		return this;
	}

	public function flashExists() {
		return _getSessionStorage().exists( variables.flashKey );
	}

	public function getFlash() {
		var flash = _getSessionStorage().getVar( variables.flashKey );

		if ( IsStruct( flash ) ) {
			// restore validationResult to cfc instance
			if ( StructKeyExists( flash, "validationResult" ) ) {
				if ( !isInstanceOf( flash.validationResult.content, "ValidationResult" ) && IsStruct( flash.validationResult.content ) && StructKeyExists( flash.validationResult.content, "generalMessage" ) ) {
					var message  = flash.validationResult.content.generalMessage ?: "";
					var messages = StructCopy( flash.validationResult.content.messages ?: {} );

					flash.validationResult.content = new preside.system.services.validation.ValidationResult();
					flash.validationResult.content.setGeneralMessage( message );
					flash.validationResult.content.setMessages( messages );
				}
			}

			return flash;
		}

		return {};
	}

	public function removeFlash() {
		_getSessionStorage().deleteVar( variables.flashKey );
	}

// PRIVATE HELPER
	private any function _getSessionStorage() {
		if ( !StructKeyExists( variables, "_sessionStorage" ) ) {
			variables._sessionStorage = getController().getWirebox().getInstance( "sessionStorage" );
		}

		return variables._sessionStorage;
	}

}