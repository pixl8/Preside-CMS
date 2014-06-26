component implements="iRouteHandler" output=false singleton=true {

// constructor
	/**
	 * @adminPath.inject         coldbox:setting:preside_admin_path
	 * @sysConfigService.inject  SystemConfigurationService
	 * @eventName.inject         coldbox:setting:eventName
	 * @adminDefaultEvent.inject coldbox:setting:adminDefaultEvent
	 */
	public any function init( required string adminPath, required string eventName, required string adminDefaultEvent, required any sysConfigService ) output=false {
		_setAdminPath( arguments.adminPath );
		_setEventName( arguments.eventName );
		_setAdminDefaultEvent( arguments.adminDefaultEvent );
		_setSysConfigService( arguments.sysConfigService );

		return this;
	}

// route handler methods
	public boolean function match( required string path, required any event ) output=false {
		return ReFindNoCase( "^/#_getAdminPath()#/", arguments.path );
	}

	public void function translate( required string path, required any event ) output=false {
		var translated = ReReplace( arguments.path, "^/#_getAdminPath()#/", "admin/" );

		translated = ListChangeDelims( translated, ".", "/" );

		if ( ListLen( translated, "." ) lt 2 ) {
			translated = translated & "." & _getAdminDefaultEvent();
		}

		event.setValue( _getEventName(), translated );
	}

	public boolean function reverseMatch( required struct buildArgs ) output=false {
		return Len( Trim( buildArgs.linkTo ?: "" ) ) and ListFirst( buildArgs.linkTo, "." ) eq "admin";
	}

	public string function build( required struct buildArgs ) output=false {
		var link = "/#_getAdminPath()#/#ListChangeDelims( ListRest( buildArgs.linkTo, "." ), "/", "." )#/";

		if ( Len( Trim( buildArgs.queryString ?: "" ) ) ) {
			link &= "?" & buildArgs.queryString;
		}

		return link;
	}

// private getters and setters
	private string function _getAdminPath() output=false {
		var fromSysConfig = _getSysConfigService().getSetting( "general", "admin_url" );

		return Len( Trim( fromSysConfig ) ) ? fromSysConfig : _adminPath;
	}
	private void function _setAdminPath( required string adminPath ) output=false {
		_adminPath = arguments.adminPath;
	}

	private string function _getEventName() output=false {
		return _eventName;
	}
	private void function _setEventName( required string eventName ) output=false {
		_eventName = arguments.eventName;
	}

	private string function _getAdminDefaultEvent() output=false {
		return _adminDefaultEvent;
	}
	private void function _setAdminDefaultEvent( required string adminDefaultEvent ) output=false {
		_adminDefaultEvent = arguments.adminDefaultEvent;
	}

	private any function _getSysConfigService() output=false {
		return _sysConfigService;
	}
	private void function _setSysConfigService( required any sysConfigService ) output=false {
		_sysConfigService = arguments.sysConfigService;
	}
}