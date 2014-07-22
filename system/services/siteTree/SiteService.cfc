/**
 * The site service provides methods for interacting with the core "Site" system
 */
component output=false displayname="Site service" autodoc=true {

// CONSTRUCTOR
	/**
	 * @siteDao.inject           presidecms:object:site
	 * @sessionStorage.inject    coldbox:plugin:sessionStorage
	 * @permissionService.inject permissionService
	 *
	 */
	public any function init( required any siteDao, required any sessionStorage, required any permissionService ) output=false {
		_setSiteDao( arguments.siteDao );
		_setSessionStorage( arguments.sessionStorage );
		_setPermissionService( arguments.permissionService );

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
	 * Returns the site record that matches the incoming domain and URL path.
	 *
	 * @domain.hint The domain name used in the incoming request, e.g. testsite.com
	 * @path.hint   The URL path of the incoming request, e.g. /path/to/somepage.html
	 */
	public struct function matchSite( required string domain, required string path ) output=false autodoc=true {
		var possibleMatches = _getSiteDao().selectData(
			  filter       = "( domain = '*' or domain = :domain )"
			, filterParams = { domain = arguments.domain }
			, orderBy      = "Length( domain ) desc, Length( path ) desc"
		);

		for( var match in possibleMatches ){
			if ( arguments.path.startsWith( match.path ) ) {
				return match;
			}
		}

		return {};
	}

	/**
	 * Returns the id of the currently active site for the administrator. If no site selected, chooses the first site
	 * that the logged in user has rights to
	 */
	public string function getActiveAdminSite() output=false autodoc=true{
		var sessionStorage    = _getSessionStorage();
		var permissionService = _getPermissionService();

		if ( sessionStorage.exists( "_activeSite" ) ) {
			var activeSite = sessionStorage.getVar( "_activeSite" );
			if ( Len( Trim( activeSite ) ) && permissionService.hasPermission( permissionKey="sites.navigate", context="site", contextKey=activeSite ) ) {
				return activeSite;
			}
		}

		var sites = _getSiteDao().selectData( orderBy = "Length( domain ), Length( path )" );
		for( var site in sites ) {
			if ( permissionService.hasPermission( permissionKey="sites.navigate", context="site", contextKey=site.id ) ) {
				setActiveAdminSite( site.id );

				return site.id;
			}
		}

		return "";
	}

	/**
	 * Sets the current active admin site id
	 */
	public void function setActiveAdminSite( required string siteId ) output=false autodoc=true {
		_getSessionStorage().setVar( "_activeSite", arguments.siteId );
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
}