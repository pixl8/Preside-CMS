component implements="iRouteHandler" output=false singleton=true {

// constructor
	/**
	 * @eventName.inject       coldbox:setting:eventName
	 * @sitetreeService.inject SitetreeService
	 */
	public any function init( required string eventName, required any sitetreeService ) output=false {
		_setEventName( arguments.eventName );
		_setSiteTreeService( arguments.siteTreeService );

		return this;
	}

// route handler methods
	public boolean function match( required string path, required any event ) output=false {
		return arguments.path eq "/" or arguments.path eq "/index.cfm" or ReFindNoCase( "\.html$", arguments.path );
	}

	public void function translate( required string path, required any event ) output=false {
		var slug        = "";
		var id          = "";
		var subaction   = "";
		var rc          = event.getCollection();
		var prc         = event.getCollection( private=true );

		if ( arguments.path eq "/index.cfm" or arguments.path eq "/" ) {
			slug      = "/";
		} else {
			slug      = ReReplaceNoCase( arguments.path, "^(.*?)(_(.*?))?(\.(.*?))?\.html", "\1/" );
			subaction = ReReplaceNoCase( arguments.path, "^(.*?)(_(.*?))?(\.(.*?))?\.html", "\3" );
			id        = ReReplaceNoCase( arguments.path, "^(.*?)(_(.*?))?(\.(.*?))?\.html", "\5" );
		}

		if ( Len( Trim( id ) ) ) {
			rc.id = id;
		}

		prc.slug = slug;
		if ( Len( Trim( subaction ) ) ) {
			prc.subaction = subaction;
		}

		event.setValue( _getEventName(), "core.SiteTreePageRequestHandler" );
	}

	public boolean function reverseMatch( required struct buildArgs ) output=false {
		return Len( Trim( buildArgs.page ?: "" ) );
	}

	public string function build( required struct buildArgs ) output=false {
 		var treeSvc  = _getSiteTreeService();
		var homepage = treeSvc.getSiteHomepage();
		var page     = treeSvc.getPage( id = buildArgs.page, selectFields=[ "id", "_hierarchy_slug as slug" ] );
		var link     = "";

		if ( page.recordCount ) {
			if ( page.id eq homepage.id ) {
				return "/";
			}

			link = ReReplace( page.slug, "/$", "" );

			if ( Len( Trim( buildArgs.subaction ?: "" ) ) ) {
				link &= "_" & buildArgs.subaction;
			}
			if ( Len( Trim( buildArgs.id ?: "" ) ) ) {
				link &= "." & buildArgs.id;
			}

			link &= ".html";
		}

		return link;
	}

// private getters and setters
	private string function _getEventName() output=false {
		return _eventName;
	}
	private void function _setEventName( required string eventName ) output=false {
		_eventName = arguments.eventName;
	}

	private any function _getSiteTreeService() output=false {
		return _siteTreeService;
	}
	private void function _setSiteTreeService( required any siteTreeService ) output=false {
		_siteTreeService = arguments.siteTreeService;
	}
}