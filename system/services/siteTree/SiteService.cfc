/**
 * The site service provides methods for interacting with the core "Site" system
 */
component output=false displayname="Site service" autodoc=true {

// CONSTRUCTOR
	/**
	 * @siteDao.inject presidecms:object:site
	 */
	public any function init( required any siteDao ) output=false {
		_setSiteDao( arguments.siteDao );
	}

// PUBLIC API
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


// GETTERS AND SETTERS
	private any function _getSiteDao() output=false {
		return _siteDao;
	}
	private void function _setSiteDao( required any siteDao ) output=false {
		_siteDao = arguments.siteDao;
	}

}