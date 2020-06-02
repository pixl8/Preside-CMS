component extends="coldbox.system.web.flash.SessionFlash" {


	public function saveFlash() {
		if ( _sessionsEnabled() ) {
			return super.saveFlash( argumentCollection=arguments );
		}
		return this;
	}
	public function flashExists() {
		if ( _sessionsEnabled() ) {
			return super.flashExists( argumentCollection=arguments );
		}
		return false;
	}
	public function getFlash() {
		if ( _sessionsEnabled() ) {
			return super.getFlash( argumentCollection=arguments );
		}
		return {};
	}
	public function removeFlash() {
		if ( _sessionsEnabled() ) {
			return super.removeFlash( argumentCollection=arguments );
		}

		return this;
	}

// PRIVATE HELPER
	private boolean function _sessionsEnabled() {
		var am = getApplicationMetadata();
		var sm = am.sessionManagement ?: "";

		return IsBoolean( sm ) && sm;
	}

}