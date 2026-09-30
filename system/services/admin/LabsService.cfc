/**
 * Resolves experimental Labs features: code mode, system default, then per-user override.
 *
 * @presideService true
 * @singleton      true
 * @feature        admin
 */
component {

	/**
	 * @labsConfig.inject  coldbox:setting:labs
	 * @enumService.inject delayedInjector:enumService
	 */
	public any function init( required struct labsConfig, required any enumService ) {
		_setLabsConfig( arguments.labsConfig );
		_setEnumService( arguments.enumService );

		return this;
	}

	public void function registerExperimentsEnum() {
		_getEnumService().registerEnum(
			  enum         = "labsExperiment"
			, keys         = listConfigurableExperiments()
			, translations = {
				  label       = "cms:editProfile.labs.experiment.{key}.title"
				, description = "cms:editProfile.labs.experiment.{key}.description"
			  }
		);
	}

	public boolean function isEnabled( required string experimentId ) {
		var cache       = request._presideLabsEnabled ?: {};
		var cacheExists = StructKeyExists( request, "_presideLabsEnabled" );

		if ( cacheExists && StructKeyExists( cache, arguments.experimentId ) ) {
			return cache[ arguments.experimentId ];
		}

		if ( !cacheExists ) {
			cache = {};
			request._presideLabsEnabled = cache;
		}

		cache[ arguments.experimentId ] = _resolveEnabled( arguments.experimentId );

		return cache[ arguments.experimentId ];
	}

	public array function listConfigurableExperiments() {
		var experiments  = _getExperiments();
		var result       = [];
		var experimentId = "";
		var spec         = "";
		var mode         = "";

		for( experimentId in experiments ) {
			spec = experiments[ experimentId ];
			if ( IsStruct( spec ) ) {
				mode = _normalizeMode( spec.mode ?: "labsDefaultOff" );
			} else {
				mode = "labsDefaultOff";
			}
			if ( mode != "alwaysOn" ) {
				ArrayAppend( result, experimentId );
			}
		}

		ArraySort( result, "textnocase" );

		return result;
	}

	public boolean function hasConfigurableExperiments() {
		return ArrayLen( listConfigurableExperiments() ) > 0;
	}

	public string function getUserPreference( required string experimentId ) {
		var userId = $getAdminLoggedInUserId();
		var record = "";

		if ( !Len( Trim( userId ) ) ) {
			return "default";
		}

		record = $getPresideObject( "admin_lab_preference" ).selectData(
			  filter       = { security_user=userId, experiment=arguments.experimentId }
			, selectFields = [ "value" ]
		);

		if ( !record.recordCount ) {
			return "default";
		}

		return _normalizePreference( record.value );
	}

	public void function saveUserPreference( required string experimentId, required string value ) {
		var userId     = $getAdminLoggedInUserId();
		var preference = _normalizePreference( arguments.value );
		var dao        = "";
		var existing   = "";

		if ( !Len( Trim( userId ) ) || !StructKeyExists( _getExperiments(), arguments.experimentId ) ) {
			return;
		}

		dao      = $getPresideObject( "admin_lab_preference" );
		existing = dao.selectData(
			  filter       = { security_user=userId, experiment=arguments.experimentId }
			, selectFields = [ "id" ]
		);

		if ( existing.recordCount ) {
			dao.updateData( id=existing.id, data={ value=preference } );
		} else {
			dao.insertData( {
				  security_user = userId
				, experiment    = arguments.experimentId
				, value         = preference
			} );
		}

		_clearRequestCache( arguments.experimentId );
	}

	public array function listSignpostExperiments() {
		var userId        = $getAdminLoggedInUserId();
		var preferences   = {};
		var experimentIds = [];
		var result        = [];
		var experimentId  = "";
		var preference    = "";

		if ( !Len( Trim( userId ) ) ) {
			return result;
		}

		preferences   = _getUserPreferences();
		experimentIds = listConfigurableExperiments();

		for( experimentId in experimentIds ) {
			preference = preferences[ experimentId ] ?: { value="default", signpost_dismissed=false };

			if ( preference.value == "off" || preference.signpost_dismissed || isEnabled( experimentId ) ) {
				continue;
			}

			ArrayAppend( result, {
				  id    = experimentId
				, title = $translateResource(
					  uri          = "cms:editProfile.labs.experiment.#experimentId#.title"
					, defaultValue = experimentId
				)
			} );
		}

		return result;
	}

	public void function dismissSignpost( required array experimentIds ) {
		var userId       = $getAdminLoggedInUserId();
		var configurable = [];
		var dao          = "";
		var experimentId = "";
		var existing     = "";

		if ( !Len( Trim( userId ) ) ) {
			return;
		}

		configurable = listConfigurableExperiments();
		dao          = $getPresideObject( "admin_lab_preference" );

		for( experimentId in arguments.experimentIds ) {
			if ( !ArrayFindNoCase( configurable, experimentId ) ) {
				continue;
			}

			existing = dao.selectData(
				  filter       = { security_user=userId, experiment=experimentId }
				, selectFields = [ "id" ]
			);

			if ( existing.recordCount ) {
				dao.updateData( id=existing.id, data={ signpost_dismissed=true } );
			} else {
				dao.insertData( {
					  security_user      = userId
					, experiment         = experimentId
					, value              = "default"
					, signpost_dismissed = true
				} );
			}
		}
	}

// PRIVATE HELPERS
	private boolean function _resolveEnabled( required string experimentId ) {
		var experiments = _getExperiments();
		var spec        = "";
		var mode        = "";
		var userPref    = "";

		if ( !StructKeyExists( experiments, arguments.experimentId ) ) {
			return false;
		}

		spec = experiments[ arguments.experimentId ];
		if ( IsStruct( spec ) ) {
			mode = _normalizeMode( spec.mode ?: "labsDefaultOff" );
		} else {
			mode = "labsDefaultOff";
		}

		if ( mode == "alwaysOn" ) {
			return true;
		}

		userPref = getUserPreference( arguments.experimentId );
		if ( userPref == "on" ) {
			return true;
		}
		if ( userPref == "off" ) {
			return false;
		}

		return _isEnabledSystemWide( arguments.experimentId );
	}

	private boolean function _isEnabledSystemWide( required string experimentId ) {
		var enabledExperiments = $getPresideSetting( category="labs", setting="enabled_experiments", default="" );

		return ListFindNoCase( enabledExperiments, arguments.experimentId ) > 0;
	}

	private string function _normalizeMode( required string mode ) {
		if ( ArrayFindNoCase( [ "alwaysOn", "labsDefaultOff", "labsDefaultOn" ], arguments.mode ) ) {
			return arguments.mode;
		}

		return "labsDefaultOff";
	}

	private string function _normalizePreference( required string value ) {
		if ( ArrayFindNoCase( [ "default", "on", "off" ], arguments.value ) ) {
			return LCase( arguments.value );
		}

		return "default";
	}

	private struct function _getUserPreferences() {
		var userId = $getAdminLoggedInUserId();
		var prefs  = {};
		var rows   = "";
		var i      = 0;

		if ( !Len( Trim( userId ) ) ) {
			return prefs;
		}

		rows = $getPresideObject( "admin_lab_preference" ).selectData(
			  filter       = { security_user=userId }
			, selectFields = [ "experiment", "value", "signpost_dismissed" ]
		);

		for( i=1; i<=rows.recordCount; i++ ) {
			prefs[ rows.experiment[ i ] ] = {
				  value              = _normalizePreference( rows.value[ i ] )
				, signpost_dismissed = $helpers.isTrue( rows.signpost_dismissed[ i ] ?: "" )
			};
		}

		return prefs;
	}

	private void function _clearRequestCache( required string experimentId ) {
		if ( StructKeyExists( request, "_presideLabsEnabled" ) ) {
			StructDelete( request._presideLabsEnabled, arguments.experimentId );
		}
	}

	private struct function _getExperiments() {
		var config = _getLabsConfig();

		return config.experiments ?: {};
	}

	private struct function _getLabsConfig() {
		return _labsConfig;
	}
	private void function _setLabsConfig( required struct labsConfig ) {
		_labsConfig = arguments.labsConfig;
	}

	private any function _getEnumService() {
		return _enumService;
	}
	private void function _setEnumService( required any enumService ) {
		_enumService = arguments.enumService;
	}

}
