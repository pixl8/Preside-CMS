/**
 * @singleton
 * @implements iRouteHandler
 */
component  {

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
		var viewOnlinePattern = "^/e/v/(.*?)\.html$";
		var trackingPatterns  = "^/e/t/(o|c)/(.*?)/$";

		return ReFindNoCase( viewOnlinePattern, arguments.path ) || ReFindNoCase( trackingPatterns, arguments.path );
	}

	public void function translate( required string path, required any event ) {
		var viewOnlinePattern    = "^/e/v/(.*?)\.html$";
		var openTrackingPattern  = "^/e/t/o/(.*?)/$";
		var clickTrackingPattern = "^/e/t/c/(.*?)/$";

		if ( ReFindNoCase( viewOnlinePattern, arguments.path ) ) {
			event.setValue( "mid", ReReplaceNoCase( arguments.path, viewOnlinePattern, "\1" ) );
			event.setValue( _getEventName(), "email.viewOnline" );
		} else if ( ReFindNoCase( openTrackingPattern, arguments.path ) ) {
			event.setValue( "mid", ReReplaceNoCase( arguments.path, openTrackingPattern, "\1" ) );
			event.setValue( _getEventName(), "email.tracking.open" );
		} else if ( ReFindNoCase( clickTrackingPattern, arguments.path ) ) {
			event.setValue( "mid", ReReplaceNoCase( arguments.path, clickTrackingPattern, "\1" ) );
			event.setValue( _getEventName(), "email.tracking.click" );
		}
	}

	public boolean function reverseMatch( required struct buildArgs, required any event ) {
		var linkTo = buildArgs.linkTo ?: "";
		var acceptedEvents = [
			  "email.viewOnline"
			, "email.tracking.open"
			, "email.tracking.click"
		];

		return acceptedEvents.findNoCase( linkTo ) && StructKeyExists( buildArgs, "queryString" ) && buildArgs.queryString.findNoCase( "mid=" );
	}

	public string function build( required struct buildArgs, required any event ) {
		var params    = _queryStringToStruct( buildArgs.queryString );
		var messageId = params.mid ?: "";
		var qs        = "";
		var link      = "";

		switch( buildArgs.linkTo ) {
			case "email.viewOnline":
				link = "/e/v/#messageId#.html"
			break;
			case "email.tracking.open":
				link = "/e/t/o/#messageId#/";
			break;
			case "email.tracking.click":
				link = "/e/t/c/#messageId#/";
			break;
		}

		params.delete( "mid" );
		for( var key in params ) {
			qs = ListAppend( qs, "#key#=#params[ key ]#", "&" );
		}

		if ( Len( Trim( qs ?: "" ) ) ) {
			link &= "?" & qs;
		}

		return event.getSiteUrl() & link;
	}

// helpers
	private struct function _queryStringToStruct( required string qs ) {
		var items  = ListToArray( qs, "&" );
		var params = {};

		for( var item in items ) {
			var key = ListFirst( item, "=" );
			var value = ListRest( item, "=" );

			params[ key ] = value;
		}

		return params;
	}

// private getters and setters
	private string function _getEventName() {
		return _eventName;
	}
	private void function _setEventName( required string eventName ) {
		_eventName = arguments.eventName;
	}
}