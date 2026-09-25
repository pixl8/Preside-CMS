/**
 * Resolves experimental Labs features: code mode, system default, then per-user override.
 *
 * @presideService true
 * @singleton      true
 * @feature        admin
 */
component {

	/**
	 * @labsConfig.inject coldbox:setting:labs
	 */
	public any function init( required struct labsConfig ) {
		_setLabsConfig( arguments.labsConfig );

		return this;
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

// PRIVATE HELPERS
	private boolean function _resolveEnabled( required string experimentId ) {
		var experiments = _getExperiments();
		var spec        = "";
		var mode        = "";
		var userPref    = "";
		var sysDefault  = "";

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

		sysDefault = $getPresideSetting( category="labs", setting=arguments.experimentId, default="" );
		if ( Len( Trim( sysDefault ) ) ) {
			return _settingIsOn( sysDefault );
		}

		return mode == "labsDefaultOn";
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

	private boolean function _settingIsOn( required string value ) {
		return CompareNoCase( arguments.value, "on" ) == 0 || $helpers.isTrue( arguments.value );
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

}
