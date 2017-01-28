/**
 * @singleton
 *
 */
component implements="iRouteHandler" output=false {

// constructor
	/**
	 * @adminPath.inject           coldbox:setting:preside_admin_path
	 * @eventName.inject           coldbox:setting:eventName
	 * @sysConfigService.inject    delayedInjector:systemConfigurationService
	 * @applicationsService.inject delayedInjector:applicationsService
	 * @controller.inject          coldbox
	 */
	public any function init( required string adminPath, required string eventName, required any applicationsService, required any sysConfigService, required any controller ) {
		_setAdminPath( arguments.adminPath );
		_setEventName( arguments.eventName );
		_setApplicationsService( arguments.applicationsService );
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
			translated = _getDefaultEvent();
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

		return event.getSiteUrl( includePath=false, includeLanguageSlug=false ) & link;
	}

// private helpers
	private string function _getDefaultEvent() {
		return _getApplicationsService().getDefaultEvent();
	}

// private getters and setters
	private string function _getAdminPath() {
		var fromSysConfig = _getSysConfigService().getSetting( "general", "admin_url" );

		return Len( Trim( fromSysConfig ) ) ? fromSysConfig : _adminPath;
	}
	private void function _setAdminPath( required string adminPath ) {
		_adminPath = arguments.adminPath;
	}

	private string function _getEventName() {
		return _eventName;
	}
	private void function _setEventName( required string eventName ) {
		_eventName = arguments.eventName;
	}

	private any function _getSysConfigService() {
		return _sysConfigService;
	}
	private void function _setSysConfigService( required any sysConfigService ) {
		_sysConfigService = arguments.sysConfigService;
	}

	private any function _getController() {
		return _controller;
	}
	private void function _setController( required any controller ) {
		_controller = arguments.controller;
	}

	private any function _getApplicationsService() {
		return _applicationsService;
	}
	private void function _setApplicationsService( required any applicationsService ) {
		_applicationsService = arguments.applicationsService;
	}
}