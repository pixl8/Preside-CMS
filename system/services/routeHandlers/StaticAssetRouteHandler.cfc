/**
 * @singleton
 *
 */
component {

// constructor
	/**
	 * @eventName.inject coldbox:setting:eventName
	 */
	public any function init( required string eventName ) {
		_setEventName( arguments.eventName );

		return this;
	}

// route handler methods
	public boolean function match( required string path, required any event ) {
		return ReFindNoCase( "^/preside/(system|extension)/assets/(.*?)/", arguments.path ) && !ReFind( "\.\.", arguments.path );
	}

	public void function translate( required string path, required any event ) {
		event.setValue( "staticAssetPath", arguments.path );
		event.setValue( _getEventName(), "admin.StaticAssetDownload.download" );
	}

	public boolean function reverseMatch( required struct buildArgs, required any event ) {
		return Len( Trim( buildArgs.systemStaticAsset ?: "" ) );
	}

	public string function build( required struct buildArgs, required any event ) {
		var path = buildArgs.systemStaticAsset ?: "";

		if ( !ReFind( "^/", path ) ) {
			path = "/" & path;
		}

		return event.getSiteUrl( includeLanguageSlug=false ) & "/preside/system/assets" & path;
	}

// private getters and setters
	private string function _getEventName() {
		return _eventName;
	}
	private void function _setEventName( required string eventName ) {
		_eventName = arguments.eventName;
	}
}