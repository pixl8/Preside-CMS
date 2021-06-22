/**
 * @singleton
 *
 */
component {

	property name="i18n" inject="i18n";

	variables._applicationCacheBuster = LCase( CreateUUId() );

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
		return ReFindNoCase( "^/preside/system/assets/_dynamic/rulesEngineFilterExpressions/(.*?)/(.*?)/(.*?)/", arguments.path );
	}

	public void function translate( required string path, required any event ) {
		var pattern = "^/preside/system/assets/_dynamic/rulesEngineFilterExpressions/(.*?)/(.*?)/(.*?)/";
		var locale = ReReplaceNoCase( arguments.path, pattern, "\1" );
		var filterObject = ReReplaceNoCase( arguments.path, pattern, "\2" );

		i18n.setFwLocale( locale );
		event.setValue( "filterObject", filterObject, true );
		event.setValue( _getEventName(), "admin.rulesEngine.downloadFilterExpressions" );
	}

	public boolean function reverseMatch( required struct buildArgs, required any event ) {
		return Len( Trim( buildArgs.filterExpressionsObject ?: "" ) );
	}

	public string function build( required struct buildArgs, required any event ) {
		var object = buildArgs.filterExpressionsObject ?: "";
		var path   = "/#i18n.getFwLocale()#/#object#/#variables._applicationCacheBuster#/";

		if ( Len( Trim( buildArgs.excludeTags ?: "" ) ) ) {
			path &= "?excludeTags=#Trim( buildArgs.excludeTags )#";
		}

		return event.getSiteUrl( includeLanguageSlug=false, includePath=false ) & "/preside/system/assets/_dynamic/rulesEngineFilterExpressions" & path;
	}

// private getters and setters
	private string function _getEventName() {
		return _eventName;
	}
	private void function _setEventName( required string eventName ) {
		_eventName = arguments.eventName;
	}
}