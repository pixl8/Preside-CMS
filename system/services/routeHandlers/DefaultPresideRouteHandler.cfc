component implements="iRouteHandler" output=false singleton=true {

// constructor
	/**
	 * @eventName.inject       coldbox:setting:eventName
	 * @sitetreeService.inject SitetreeService
	 * @siteService.inject     siteService
	 */
	public any function init( required string eventName, required any sitetreeService, required any siteService ) output=false {
		_setEventName( arguments.eventName );
		_setSiteTreeService( arguments.siteTreeService );
		_setSiteService( arguments.siteService );

		return this;
	}

// route handler methods
	public boolean function match( required string path, required any event ) output=false {
		if ( Len( Trim( event.getValue( "event", "" ) ) ) ) {
			return false;
		}

		if ( arguments.path eq "/" or arguments.path eq "/index.cfm" ) {
			return true;
		}

		if ( ReFindNoCase( "\.html$", arguments.path ) ) {
			return true;
		}

		var incomingPathNoSlashes = ReReplace( arguments.path, "^/?(.*?)/?$", "\1" );
		for ( var site in _getSiteService().listSites() ) {
			var sitePathNoSlashes = ReReplace( site.path, "^/?(.*?)/?$", "\1" );
			if ( sitePathNoSlashes == incomingPathNoSlashes ) {
				return true;
			}
		}

		return false;
	}

	public void function translate( required string path, required any event ) output=false {
		var slug          = "";
		var id            = "";
		var subaction     = "";
		var params        = "";
		var rc            = event.getCollection();
		var prc           = event.getCollection( private=true );
		var site          = event.getSite();
		var pathMinusSite = arguments.path;

		if ( Len( site.path ?: "" ) > 1 ) {
			pathMinusSite = Right( pathMinusSite, Len( pathMinusSite ) - Len( site.path ) );
			if ( Left( pathMinusSite, 1 ) != "/" ) {
				pathMinusSite = "/" & pathMinusSite;
			}
		}

		if ( pathMinusSite eq "/index.cfm" or pathMinusSite eq "/" ) {
			slug      = "/";
		} else {
			slug      = ReReplaceNoCase( pathMinusSite, "^(.*?)(_(.*?))?(\.(.*?))?\.html", "\1/" );
			subaction = ReReplaceNoCase( pathMinusSite, "^(.*?)(_(.*?))?(\.(.*?))?\.html", "\3" );
			id        = ReReplaceNoCase( pathMinusSite, "^(.*?)(_(.*?))?(\.(.*?))?\.html", "\5" );
		}

		if ( Find( "!", slug ) ) {
			params = ListToArray( ListRest( slug, "!" ), "/" );
			slug   = ListFirst( slug, "!" );

			var key="";
			for( var i=1; i <= params.len(); i++ ){
				if ( i mod 2 ) {
					key = params[i];
				} else {
					rc[ key ] = UrlDecode( params[i] );
				}
			}
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
		var page     = treeSvc.getPage( id = buildArgs.page, selectFields=[ "page.id", "page._hierarchy_slug as slug", "site.protocol", "site.domain", "site.path" ] );
		var link     = "";
		var root     = "#page.protocol#://#page.domain#";

		if ( ( cgi.server_port ?: 80 ) != 80 ) {
			root &= ":" & cgi.server_port;
		}
		root &= ReReplace( page.path, '/$', '' );


		if ( page.recordCount ) {
			if ( page.id eq homepage.id ) {
				return root & "/";
			}

			link &= ReReplace( page.slug, "/$", "" );

			if ( Len( Trim( buildArgs.subaction ?: "" ) ) ) {
				link &= "_" & buildArgs.subaction;
			}
			if ( Len( Trim( buildArgs.id ?: "" ) ) ) {
				link &= "." & buildArgs.id;
			}

			if ( StructKeyExists( buildArgs, "params" ) && IsStruct( buildArgs.params ) && StructCount( buildArgs.params ) ) {
				var delim = "/!";
				for( var key in buildArgs.params ){
					if ( IsSimpleValue( buildArgs.params[ key ] ) ) {
						link &= delim & UrlEncodedFormat( key ) & "/" & UrlEncodedFormat( buildArgs.params[ key ] );
						delim = "/";
					}
				}
			}

			link &= ".html";

			if ( Len( Trim( buildArgs.queryString ?: "" ) ) ) {
				link &= "?" & buildArgs.queryString;
			}
		}

		return root & link;
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

	private any function _getSiteService() output=false {
		return _siteService;
	}
	private void function _setSiteService( required any siteService ) output=false {
		_siteService = arguments.siteService;
	}
}