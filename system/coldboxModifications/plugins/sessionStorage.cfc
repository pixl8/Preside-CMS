component extends="coldbox.system.plugins.SessionStorage" output=false {

	private boolean function areSessionsEnabled() output=false {
		var appSettings = getApplicationSettings();

		return IsBoolean( appSettings.sessionManagement ?: "" ) && appSettings.sessionManagement;
	}

	public any function getVar() output=false {
		if ( areSessionsEnabled() ) {
			return super.getVar( argumentCollection=arguments );
		}
		return;
	}

	public any function setVar() output=false {
		if ( areSessionsEnabled() ) {
			SessionRotate();
			return super.setVar( argumentCollection=arguments );
		}
		return;
	}

	public any function deleteVar() output=false {
		if ( areSessionsEnabled() ) {
			return super.deleteVar( argumentCollection=arguments );
		}
		return false;
	}

	public any function exists() output=false {
		if ( areSessionsEnabled() ) {
			return super.exists( argumentCollection=arguments );
		}
		return false;
	}

	public any function clearAll() output=false {
		if ( areSessionsEnabled() ) {
			return super.clearAll( argumentCollection=arguments );
		}
		return;
	}

	public any function getStorage() output=false {
		if ( areSessionsEnabled() ) {
			return super.getStorage( argumentCollection=arguments );
		}
		return {};
	}

	public any function removeStorage() output=false {
		if ( areSessionsEnabled() ) {
			return super.removeStorage( argumentCollection=arguments );
		}
		return;
	}

}