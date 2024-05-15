/**
 * Provides logic for dealing with configured applications
 * for the Preside admin system.
 *
 * @autodoc        true
 * @singleton      true
 * @presideservice true
 * @feature        admin
 *
 */
component {

// CONSTRUCTOR
	/**
	 * @configuredApplications.inject coldbox:setting:adminApplications
	 *
	 */
	public any function init( required array configuredApplications ) {
		_setupConfiguredApplications( arguments.configuredApplications );

		return this;
	}

// PUBLIC API METHODS
	/**
	 * Returns an array of application ids that are active in the
	 * system.
	 *
	 * @autodoc
	 * @limitByCurrentUser.hint Whether or not to limit the list of application to those applications that the logged in user has access to
	 */
	public array function listApplications( boolean limitByCurrentUser=false ) {
		var allApplications    = _getConfiguredApplications();
		var activeApplications = [];

		for( var applicationId in allApplications ) {
			var app            = allApplications[ applicationId ];
			var featureEnabled = $isFeatureEnabled( app.feature );
			var userHasAccess  = !limitByCurrentUser || !$isAdminUserLoggedIn() || !Len( Trim( app.accessPermission ) ) || $hasAdminPermission( app.accessPermission );

			if ( featureEnabled && userHasAccess ) {
				activeApplications.append( applicationId );
			}
		}

		return activeApplications;
	}

	/**
	 * Returns the ID of the default application for the current user
	 *
	 * @autodoc
	 */
	public string function getDefaultApplication() {
		var apps = listApplications( limitByCurrentUser=true );

		return apps[ 1 ] ?: "";
	}

	/**
	 * Returns the configured (or calculated by convention), default
	 * event for an application. This is the event to represent
	 * the homepage of the application.
	 *
	 * @autodoc
	 * @applicationId.hint The ID of the application whose default event you wish to get. If not supplied, the default application will be used.
	 *
	 */
	public string function getDefaultEvent( string applicationId=getDefaultApplication() ) {
		var apps = _getConfiguredApplications();

		return apps[ arguments.applicationId ].defaultEvent ?: "";
	}

	public string function getDefaultUrl( string applicationId=getDefaultApplication(), string siteId="" ) {
		var defaultUrl = getAdminHomepageUrl( argumentCollection = arguments );

		if ( !$helpers.isEmptyString( defaultUrl ) ) {
			return defaultUrl;
		}

		return $getRequestContext().buildLink( linkTo=getDefaultEvent( applicationId ) );
	}

	public string function getAdminHomepageUrl( string siteId="") {
		var userId       = $getAdminLoggedInUserId();
		var siteHomepage = $getPresideObject( "security_user_site" ).selectData(
			  filter = {
			  	  user = userId
			  }
			, filterParams = {
				site = arguments.siteId
			}
			, selectFields = [ "homepage_url" , "site" ]
			, orderby = " case when site=:site then 0 else 1 end, datemodified desc "
		);

		if ( siteHomepage.recordCount && siteHomepage.site!=arguments.siteId ) {
			return reReplaceNoCase( siteHomepage.homepage_url ?: "", "_sid=[^&]+&?", "" );
		}

		return siteHomepage.homepage_url ?: "";
	}

	public void function setAdminHomepageUrl( required string siteId, required string homepageUrl ) {
		var userId  = $getAdminLoggedInUserId();
		var updated = $getPresideObject( "security_user_site" ).updateData(
			  filter = {
				  user = userId
				, site = arguments.siteId
			  }
			, data = {
				homepage_url = arguments.homepageUrl
			}
		);

		if ( updated==0 ) {
			$getPresideObject( "security_user_site" ).insertData(
				data = {
					  user         = userId
					, site         = arguments.siteId
					, homepage_url = arguments.homepageUrl
				}
			);
		}
	}

	/**
	 * Returns the configured (or calculated by convention)
	 * layout for the given application.
	 *
	 * @autodoc
	 * @applicationId.hint The ID of the application whose layout you wish to get. If not supplied, the default application will be used.
	 */
	public string function getLayout( string applicationId=getDefaultApplication() ) {
		var apps = _getConfiguredApplications();

		return apps[ arguments.applicationId ].layout ?: "";
	}

	/**
	 * Returns the active application based on the current coldbox event
	 *
	 * @autodoc
	 * @event.hint The current coldbox event
	 *
	 */
	public string function getActiveApplication( required string event ) {
		var configuredApplications = _getConfiguredApplications();
		var matches = [];

		for( var applicationId in configuredApplications ) {
			var app = configuredApplications[ applicationId ];

			if ( arguments.event.reFindNoCase( app.activeEventPattern ) ) {
				matches.append( { id=applicationId, patternAccuracy=app.activeEventPattern.len() } );
			}
		}

		matches.sort( function( a, b ){
			return a.patternAccuracy < b.patternAccuracy ? 1 : -1;
		} );

		if ( ArrayLen( matches ) ) {
			return matches[ 1 ].id;
		} else {
			$getRequestContext().adminAccessDenied();
		}
	}

// PRIVATE HELPERS
	private void function _setupConfiguredApplications( required array configuredApplications ) {
		var applications = StructNew( "linked" );

		for( var app in configuredApplications ) {
			var applicationId = Trim( IsSimpleValue( app ) ? app : ( app.id ?: "" ) );

			if ( applicationId.len() ) {
				applications[ applicationId ] = {
					  feature            = app.feature            ?: applicationId
					, accessPermission   = app.accessPermission   ?: "#applicationId#.access"
					, defaultEvent       = app.defaultEvent       ?: "admin.#applicationId#.index"
					, activeEventPattern = app.activeEventPattern ?: "^admin\.#applicationId#.*"
					, layout             = app.layout             ?: applicationId
				};
			}
		}

		_setConfiguredApplications( applications );
	}

// GETTERS AND SETTERS
	private struct function _getConfiguredApplications() {
		return _configuredApplications;
	}
	private void function _setConfiguredApplications( required struct configuredApplications ) {
		_configuredApplications = arguments.configuredApplications;
	}

}