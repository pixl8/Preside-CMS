component implements="iRouteHandler" singleton=true {

// constructor
	/**
	 * @eventName.inject        coldbox:setting:eventName
	 * @sitetreeService.inject  SitetreeService
	 * @siteService.inject      siteService
	 * @pageTypesService.inject pageTypesService
	 */
	public any function init( required string eventName, required any sitetreeService, required any siteService, required any pageTypesService ) output=false {
		_setEventName( arguments.eventName );
		_setSiteTreeService( arguments.siteTreeService );
		_setSiteService( arguments.siteService );
		_setPageTypesService( arguments.pageTypesService );

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

		if ( arguments.path eq "/index.cfm" or arguments.path eq "/" ) {
			slug      = "/";
		} else {
			slug      = ReReplaceNoCase( arguments.path, "^(.*?)(_(.*?))?(\.(.*?))?\.html", "\1/" );
			subaction = ReReplaceNoCase( arguments.path, "^(.*?)(_(.*?))?(\.(.*?))?\.html", "\3" );
			id        = ReReplaceNoCase( arguments.path, "^(.*?)(_(.*?))?(\.(.*?))?\.html", "\5" );
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

	public boolean function reverseMatch( required struct buildArgs, required any event ) output=false {
		return Len( Trim( buildArgs.page ?: "" ) );
	}

	public string function build( required struct buildArgs, required any event ) output=false {
		var site     = arguments.buildArgs.site ?: "";
		var page     = _getPageByIdOrPageType( page=arguments.buildArgs.page, site=site );
		var link     = "";
		var root     = event.getSiteUrl( page.site );

		if ( page.recordCount ) {
			var homepageId = _getHomepageId( site );

			if ( page.id == homepageId ) {
				return ReReplace( root, "([^/])$", "\1/" ); // ensures trailing slash
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

	private query function _getPageByIdOrPageType( required string page, string site="" ) output=false {
		var ptService       = _getPageTypesService();
		var siteTreeService = _getSiteTreeService();
		var getPageArgs     = {
			  selectFields = [ "page.id", "page._hierarchy_slug as slug", "page.site" ]
			, version      = 0
			, getLatest    = false
			, allowDrafts  = true
			, site         = arguments.site
		};

		if ( ptService.pageTypeExists( arguments.page ) && ptService.isSystemPageType( arguments.page ) ) {
			getPageArgs.systemPage = arguments.page;
		} else {
			getPageArgs.id = arguments.page;
		}

		if ( siteTreeService.arePageSlugsMultilingual() ) {
			getPageArgs.selectFields = [ "page.id", "page.slug", "page.site" ];
			var page = Duplicate( siteTreeService.getPage( argumentCollection=getPageArgs ) );

			if ( page.recordCount ) {
				var ancestors = siteTreeService.getAncestors( id=page.id, selectFields=[ "slug" ], site=arguments.site );

				if ( ancestors.recordCount ) {
					var newSlug = "/" & ValueList( ancestors.slug, "/" ) & "/" & page.slug & "/";
					newSlug = newSlug.reReplace( "/+", "/", "all" );
					page.slug[ 1 ] = newSlug;
				}
			}

			return page;
		}

		return siteTreeService.getPage( argumentCollection=getPageArgs );
	}

	private string function _getHomepageId( required string site ) {
		request[ "_siteHomepageId#site#" ] = request[ "_siteHomepageId#site#" ] ?: _getSiteTreeService().getSiteHomepage( site=site, selectFields=[ "id" ] ).id;

		return request[ "_siteHomepageId#site#" ]
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

	private any function _getPageTypesService() output=false {
		return _pageTypesService;
	}
	private void function _setPageTypesService( required any pageTypesService ) output=false {
		_pageTypesService = arguments.pageTypesService;
	}
}