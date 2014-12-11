component implements="iRouteHandler" output=false singleton=true {

// constructor
	/**
	 * @adminPath.inject         coldbox:setting:preside_admin_path
	 * @sysConfigService.inject  SystemConfigurationService
	 * @eventName.inject         coldbox:setting:eventName
	 * @defaultEvent.inject      coldbox:setting:adminDefaultEvent
	 * @controller.inject        coldbox
	 */
	public any function init( required string adminPath, required string eventName, required string defaultEvent, required any sysConfigService, required any controller ) output=false {
		_setAdminPath( arguments.adminPath );
		_setEventName( arguments.eventName );
		_setDefaultEvent( arguments.defaultEvent );
		_setSysConfigService( arguments.sysConfigService );
		_setController( arguments.controller );

		return this;
	}

// route handler methods
	public boolean function match( required string path, required any event ) output=false {
		return ReFindNoCase( "^/#_getAdminPath()#/", arguments.path );
	}

	public void function translate( required string path, required any event ) output=false {
		var translated = ReReplace( arguments.path, "^/#_getAdminPath()#/", "admin/" );

		translated = ListChangeDelims( translated, ".", "/" );
		if ( translated == "admin" ) {
			translated = ListAppend( translated, _getDefaultEvent(), "." );
		}

		if ( !_getController().handlerExists( translated ) ) {
			translated = ListAppend( translated, "index", "." );
		}

		event.setValue( _getEventName(), translated );
	}

	public boolean function reverseMatch( required struct buildArgs, required any event ) output=false {
		return Len( Trim( buildArgs.linkTo ?: "" ) ) and ListFirst( buildArgs.linkTo, "." ) eq "admin";
	}

	public string function build( required struct buildArgs, required any event ) output=false {
		var link = "/#_getAdminPath()#/#ListChangeDelims( ListRest( buildArgs.linkTo, "." ), "/", "." )#/";

		if ( Len( Trim( buildArgs.queryString ?: "" ) ) ) {
			link &= "?" & buildArgs.queryString;
		}

		return event.getSiteUrl() & link;
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

	private any function _getSysConfigService() output=false {
		return _sysConfigService;
	}
	private void function _setSysConfigService( required any sysConfigService ) output=false {
		_sysConfigService = arguments.sysConfigService;
	}

	private any function _getController() output=false {
		return _controller;
	}
	private void function _setController( required any controller ) output=false {
		_controller = arguments.controller;
	}

	private string function _getDefaultEvent() output=false {
		return _defaultEvent;
	}
	private void function _setDefaultEvent( required string defaultEvent ) output=false {
		_defaultEvent = arguments.defaultEvent;
	}
}