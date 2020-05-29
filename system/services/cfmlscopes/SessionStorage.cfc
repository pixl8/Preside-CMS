/**
 * @presideService true
 * @singleton      true
 */
component extends="preside.system.modules.cbstorages.models.SessionStorage" output=false {

	property name="sqlRunner" inject="sqlRunner";

	public any function init() {
		return super.init();
	}

// CUSTOM FUNCTIONS FOR PRESIDE SESSION MANAGEMENT
	public any function restore() {
		var sessionId = cookie.psid ?: "";
		if ( Len( Trim( sessionId ) ) ) {
			var record = _getSessionRecord( sessionId );

			if ( record.recordCount ) {
				if ( _expired( record.expiry ) ) {
					_deleteSessionRecord( sessionId );
				} else {
					try {
						request._presideSession = DeserializeJson( record.value );
					} catch( any e ) {
						request._presideSession = {};
					}
					request._presideSession.sessionId = sessionId;
				}
			}
		}
	}

	public any function persist() {
		var storage              = getStorage();
		var ignoreKeys           = [ "sessionid" ];
		var keysToBeEmptyStructs = [ "cbStorage", "cbox_flash_scope" ];
		var sessionIsUsed        = false;

		for( var key in storage ) {
			if ( ignoreKeys.findNoCase( key ) ) {
				continue;
			}
			if ( keysToBeEmptyStructs.findNoCase( key ) && IsStruct( storage[ key ] ) && storage[ key ].isEmpty() ) {
				continue;
			}

			sessionIsUsed = true;
			break;
		}

		if ( sessionIsUsed ) {
			var updated = false;
			var sessionId = storage.sessionId ?: "";
			var expiry = expiry=_getUnixTimeStamp() + _getSessionTimeoutInSeconds();

			StructDelete( storage, "sessionId" );
			var value = SerializeJson( storage );

			if ( Len( Trim( sessionId ) ) ) {
				updated = _updateSessionRecord( sessionId, expiry, value );
			}

			if ( !updated ) {
				sessionId = _createSessionRecord( expiry, value );

				cookie name="psid" value=LCase( sessionId );
			}
		}
	}

	public void function rotate() {
		if ( _usePresideSessionManagement() ) {
			var currentSessionId = getVar( "sessionId" );
			if ( Len( currentSessionId ) ) {
				setVar( "sessionId", CreateUUId() );
				_deleteSessionRecord( currentSessionId );
			}
		} else {
			var appSettings = getApplicationSettings();

			if ( ( appSettings.sessionType ?: "cfml" ) != "j2ee" ) {
				SessionRotate();
			}
		}
	}

// STANDARD SESSION STORAGE FUNCTIONS
	public any function getVar( name, default ) output=false {
		if ( _usePresideSessionManagement() ) {
			var storage = getStorage();
			return storage[ arguments.name ] ?: ( arguments.default ?: "" );
		} else if ( _areSessionsEnabled() ) {
			return super.getVar( argumentCollection=arguments );
		}

		return arguments.default ?: "";
	}

	public any function setVar( name, value ) output=false {
		if ( _usePresideSessionManagement() ) {
			var storage = getStorage();
			storage[ arguments.name ] = arguments.value;
		} else if ( _areSessionsEnabled() ) {
			return super.setVar( argumentCollection=arguments );
		}
		return;
	}

	public any function deleteVar( name ) output=false {
		if ( _usePresideSessionManagement() ) {
			var storage = getStorage();

			return StructDelete( storage, arguments.name, true );
		} else if ( _areSessionsEnabled() ) {
			return super.deleteVar( argumentCollection=arguments );
		}
		return false;
	}

	public any function exists( name ) output=false {
		if ( _usePresideSessionManagement() ) {
			var storage = getStorage();

			return StructKeyExists( storage, arguments.name );
		} else if ( _areSessionsEnabled() ) {
			return super.exists( argumentCollection=arguments );
		}

		return false;
	}

	public any function clearAll() output=false {
		if ( _usePresideSessionManagement() ) {
			removeStorage();
		} else if ( _areSessionsEnabled() ) {
			return super.clearAll( argumentCollection=arguments );
		}
		return;
	}

	public any function getStorage() output=false {
		if ( _usePresideSessionManagement() ) {
			return request._presideSession ?: _createStorage();
		} else if ( _areSessionsEnabled() ) {
			return super.getStorage( argumentCollection=arguments );
		}
		return {};
	}

	public any function removeStorage() output=false {
		if ( _usePresideSessionManagement() ) {
			StructDelete( request, "_presideSession" );
		} else if ( _areSessionsEnabled() ) {
			return super.removeStorage( argumentCollection=arguments );
		}
		return;
	}

// PRIVATE HELPERS
	private boolean function _areSessionsEnabled() output=false {
		var appSettings = getApplicationSettings();

		return IsBoolean( appSettings.sessionManagement ?: "" ) && appSettings.sessionManagement;
	}

	private boolean function _usePresideSessionManagement() output=false {
		var appSettings = getApplicationSettings();

		return IsBoolean( appSettings.presideSessionManagement ?: "" ) && appSettings.presideSessionManagement;
	}

	private struct function _createStorage() {
		request._presideSession = request._presideSession ?: {};

		return request._presideSession;
	}

	private boolean function _expired( expiryTimeout ) {
		return _getUnixTimeStamp() > arguments.expiryTimeout;
	}

	private numeric function _getSessionTimeoutInSeconds() {
		var appSettings   = getApplicationSettings();
		var timeout       = appSettings.sessionTimeout ?: CreateTimeSpan( 0, 0, 20, 0 );
		var secondsInADay = 86400;

		return Round( Val( timeout ) * secondsInADay );
	}

	private numeric function _getUnixTimeStamp() {
		var epochInMs = CreateObject( "java", "java.time.Instant" ).now().toEpochMilli();

		return Ceiling( epochInMs / 1000  );
	}

	private query function _getSessionRecord( required string sessionId ) {
		return sqlRunner.runSql(
			  sql = "select session_storage.expiry, session_storage.value from psys_session_storage session_storage where id = :id"
			, dsn = _getSessionStorageDsn()
			, params = [ { type="cf_sql_varchar", value=arguments.sessionId, name="id" } ]
		);
	}

	private query function _deleteSessionRecord( required string sessionId ) {
		return sqlRunner.runSql(
			  sql = "delete from psys_session_storage where id = :id"
			, dsn = _getSessionStorageDsn()
			, params = [ { type="cf_sql_varchar", value=arguments.sessionId, name="id" } ]
		);
	}

	private string function _getSessionStorageDsn() {
		if ( !StructKeyExists( variables, "_sessionStorageDsn" ) ) {
			variables._sessionStorageDsn = $getPresideObject( "session_storage" ).getDsn();
		}
		return variables._sessionStorageDsn;
	}

	private boolean function _updateSessionRecord( required string sessionId, required numeric expiry, required string value ) {
		var result = sqlRunner.runSql(
			  sql        = "update psys_session_storage set expiry = :expiry, value = :value where id = :id"
			, dsn        = _getSessionStorageDsn()
			, returnType = "info"
			, params     = [
				  { type="cf_sql_varchar" , value=arguments.sessionId, name="id"     }
				, { type="cf_sql_int"     , value=arguments.expiry   , name="expiry" }
				, { type="cf_sql_clob"    , value=arguments.value    , name="value"  }
			  ]
		);

		return Val( result.recordCount ?: 0 ) > 0;
	}

	private string function _createSessionRecord( required numeric expiry, required string value ) {
		var id = CreateUUId();

		sqlRunner.runSql(
			  sql        = "insert into psys_session_storage ( id, datecreated, expiry, value ) values ( :id, :datecreated, :expiry, :value )"
			, dsn        = _getSessionStorageDsn()
			, returnType = "info"
			, params     = [
				  { type="cf_sql_varchar"  , value=id              , name="id"          }
				, { type="cf_sql_timestamp", value=Now()           , name="datecreated" }
				, { type="cf_sql_int"      , value=arguments.expiry, name="expiry"      }
				, { type="cf_sql_clob"     , value=arguments.value , name="value"       }
			  ]
		);

		return id;
	}


}