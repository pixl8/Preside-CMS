/**
 * The site service provides methods for interacting with the core "Site" system
 */
component output=false singleton=true displayname="Site service" autodoc=true {

// CONSTRUCTOR
	/**
	 * @siteDao.inject               presidecms:object:site
	 * @siteAliasDomainDao.inject    presidecms:object:site_alias_domain
	 * @siteRedirectDomainDao.inject presidecms:object:site_redirect_domain
	 * @sessionStorage.inject        coldbox:plugin:sessionStorage
	 * @permissionService.inject     permissionService
	 * @coldbox.inject               coldbox
	 *
	 */
	public any function init( required any siteDao, required any siteAliasDomainDao, required any siteRedirectDomainDao, required any sessionStorage, required any permissionService, required any coldbox ) output=false {
		_setSiteDao( arguments.siteDao );
		_setSiteRedirectDomainDao( arguments.siteRedirectDomainDao );
		_setSiteAliasDomainDao( arguments.siteAliasDomainDao );
		_setSessionStorage( arguments.sessionStorage );
		_setPermissionService( arguments.permissionService );
		_setColdbox( arguments.coldbox );

		ensureDefaultSiteExists();

		return this;
	}

// PUBLIC API

	/**
	 * Returns a query of all the registered sites
	 */
	public query function listSites() output=false autodoc=true {
		return _getSiteDao().selectData( orderBy = "name" );
	}

	/**
	 * Returns a single site matched by id
	 *
	 * @id.hint ID of the site to get
	 */
	public struct function getSite( required string id ) output=false autodoc=true {
		var site = _getSiteDao().selectData( id=arguments.id );

		for( var s in site ){
			return s;
		}

		return {};
	}

	/**
	 * Returns the site record that matches the incoming domain and URL path.
	 *
	 * @domain.hint The domain name used in the incoming request, e.g. testsite.com
	 * @path.hint   The URL path of the incoming request, e.g. /path/to/somepage.html
	 */
	public struct function matchSite( required string domain, required string path ) output=false autodoc=true {
		var siteDao   = _getSiteDao();
		var dbAdapter = siteDao.getDbAdapter();
		var possibleMatches = siteDao.selectData(
			  filter       = "( domain = '*' or domain = :domain )"
			, filterParams = { domain = arguments.domain }
			, orderBy      = "#dbAdapter.getLengthFunctionSql( 'domain' )# desc, #dbAdapter.getLengthFunctionSql( 'path' )# desc"
		);

		for( var match in possibleMatches ){
			if ( arguments.path.startsWith( match.path ) ) {
				return match;
			}
		}

		var aliasMatch = _getSiteAliasDomainDao().selectData(
			  selectFields = [ "site" ]
			, filter       = { domain = arguments.domain }
		);

		if ( aliasMatch.recordCount ) {
			var site = getSite( aliasMatch.site );

			site.domain = arguments.domain

			return site;
		}

		return {};
	}

	/**
	 * Returns the id of the currently active site for the administrator. If no site selected, chooses the first site
	 * that the logged in user has rights to
	 *
	 * @autodoc
	 * @domain.hint domain that the site should match
	 */
	public struct function getActiveAdminSite( required string domain ) {
		var sessionStorage    = _getSessionStorage();
		var permissionService = _getPermissionService();

		if ( sessionStorage.exists( "_activeSite" ) ) {
			var activeSite = sessionStorage.getVar( "_activeSite" );
			if ( IsStruct( activeSite ) && Len( Trim( activeSite.id ?: "" ) ) && permissionService.hasPermission( permissionKey="sites.navigate", context="site", contextKeys=[ activeSite.id ] ) ) {
				return activeSite;
			}
		}

		var siteDao   = _getSiteDao();
		var dbAdapter = siteDao.getDbAdapter();
		var sites     = siteDao.selectData(
			  filter       = "( domain = '*' or domain = :domain )"
			, filterParams = { domain = arguments.domain }
			, orderBy      = "#dbAdapter.getLengthFunctionSql( 'domain' )# desc, #dbAdapter.getLengthFunctionSql( 'path' )#"
		);

		for( var site in sites ) {
			if ( permissionService.hasPermission( permissionKey="sites.navigate", context="site", contextKeys=[ site.id ] ) ) {
				_getSessionStorage().setVar( "_activeSite", site );

				return site;
			}
		}

		return {};
	}

	/**
	 * Sets the current active admin site id
	 */
	public void function setActiveAdminSite( required string siteId ) output=false autodoc=true {
		var site = _getSiteDao().selectData( id=arguments.siteId );

		for( var s in site ) { // little query to struct hack
			if ( _getPermissionService().hasPermission( permissionKey="sites.navigate", context="site", contextKeys=[ s.id ] ) ) {
				_getSessionStorage().setVar( "_activeSite", s );
			}
		}
	}

	/**
	 * Ensures that at least one site is registered with the system, called internally
	 * before checking valid routes
	 */
	public void function ensureDefaultSiteExists() output=false autodoc=true {
		transaction {
			if ( !_getSiteDao().dataExists( useCache=false ) ) {
				_getSiteDao().insertData( useVersioning = false, data = {
					  protocol      = "http"
					, domain        = cgi.server_name ?: "127.0.0.1"
					, path          = "/"
					, name          = "Default site"
				} );
			}
		}
	}

	/**
	 * Retrieves the current active site id. This is based either on the URL, for front-end requests, or the currently
	 * selected site when in the administrator
	 */
	public string function getActiveSiteId() output=false autodoc=true {
		var site = _getColdbox().getRequestContext().getSite();

		return site.id ?: "";
	}

	/**
	 * Retrieves the current active site template. This is based either on the URL, for front-end requests, or the currently
	 * selected site when in the administrator
	 */
	public string function getActiveSiteTemplate() output=false autodoc=true {
		var site = _getColdbox().getRequestContext().getSite();

		return site.template ?: "";
	}

	/**
	 * Sync alias domains with the site record
	 */
	public boolean function syncSiteAliasDomains( required string siteId, required string domains ) output=false autodoc=true {
		var aliasDomainsDao = _getSiteAliasDomainDao();
		var aliasDomains    = ListToArray( arguments.domains, Chr(10) & Chr(13) & "," );

		aliasDomainsDao.deleteData( filter={ site = arguments.siteId } );
		for( var domain in aliasDomains ){
			try {
				aliasDomainsDao.insertData( { site=arguments.siteId, domain=domain } );
			} catch( any e ) {}
		}


		return true;
	}

	/**
	 * Sync redirect domains with the site record
	 */
	public boolean function syncSiteRedirectDomains( required string siteId, required string domains ) output=false autodoc=true {
		var redirectDomainsDao = _getSiteRedirectDomainDao();
		var redirectDomains    = ListToArray( arguments.domains, Chr(10) & Chr(13) & "," );

		redirectDomainsDao.deleteData( filter={ site = arguments.siteId } );
		for( var domain in redirectDomains ){
			try {
				redirectDomainsDao.insertData( { site=arguments.siteId, domain=domain } );
			} catch( any e ) {}
		}


		return true;
	}

	/**
	 * Returns a site record that has a redirect domain matching the given domain
	 */
	public query function getRedirectSiteForDomain( required string domain ) output=false {
		return _getSiteRedirectDomainDao().selectData(
			  selectFields = [ "site.id", "site.protocol", "site.domain" ]
			, filter       = { domain = arguments.domain }
		);
	}

// GETTERS AND SETTERS
	private any function _getSiteDao() output=false {
		return _siteDao;
	}
	private void function _setSiteDao( required any siteDao ) output=false {
		_siteDao = arguments.siteDao;
	}

	private any function _getSessionStorage() output=false {
		return _sessionStorage;
	}
	private void function _setSessionStorage( required any sessionStorage ) output=false {
		_sessionStorage = arguments.sessionStorage;
	}

	private any function _getPermissionService() output=false {
		return _permissionService;
	}
	private void function _setPermissionService( required any permissionService ) output=false {
		_permissionService = arguments.permissionService;
	}

	private any function _getColdbox() output=false {
		return _coldbox;
	}
	private void function _setColdbox( required any coldbox ) output=false {
		_coldbox = arguments.coldbox;
	}

	private any function _getSiteAliasDomainDao() output=false {
		return _siteAliasDomainDao;
	}
	private void function _setSiteAliasDomainDao( required any siteAliasDomainDao ) output=false {
		_siteAliasDomainDao = arguments.siteAliasDomainDao;
	}

	private any function _getSiteRedirectDomainDao() output=false {
		return _siteRedirectDomainDao;
	}
	private void function _setSiteRedirectDomainDao( required any siteRedirectDomainDao ) output=false {
		_siteRedirectDomainDao = arguments.siteRedirectDomainDao;
	}
}