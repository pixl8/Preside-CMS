/**
 * This service is not a singleton and tries to rely on
 * as little external code knowledge as possible so as to
 * run before the application has been started up. It provides
 * methods for handling maintenance mode display and settings
 *
 */
component output=false {

// constructor
	public any function init( string configPath=ExpandPath( "/app/config/.maintenance" ) ) output=false {
		_setConfigPath( arguments.configPath );
	}

// public api
	public boolean function setMaintenanceMode( required string maintenanceHtml, required array allowedIps, required string bypassPassword ) output=false {
		var settings = {
			  html           = arguments.maintenanceHtml
			, allowedIps     = arguments.allowedIps
			, bypassPassword = arguments.bypassPassword
		};

		_setApplicationVariable( settings );
		_writeMaintenanceModeToFile( settings );

		return true;
	}

	public boolean function clearMaintenanceMode() output=false {
		var filePath = _getConfigPath();

		if ( FileExists( filePath ) ) {
			FileDelete( filePath );
		}
		_setApplicationVariable({});

		return true;
	}

	public struct function getMaintenanceModeSettings() output=false {
		var settings = _getApplicationVariable();

		if ( IsNull( settings ) ) {
			settings = _readMaintenanceModeFromFile();
			_setApplicationVariable( settings );
		}

		return settings;
	}

	public boolean function isMaintenanceModeActive() output=false {
		return getMaintenanceModeSettings().count();
	}

	public boolean function canRequestBypassMaintenanceMode() output=false {
		var settings       = getMaintenanceModeSettings();
		var safeIps        = settings.allowedIps ?: [];
		var bypassPassword = settings.bypassPassword;
		var clientIp       = cgi.remote_addr;

		if ( IsArray( safeIps ) && safeIps.find( clientIp ) ) {
			return true;
		}

		if ( Len( Trim( bypassPassword  ) ) ) {
			var scopes = [ session, cookie, form, url ];
			var key    = "maintenanceModeByPass";

			for( var scope in scopes ){
				if ( scope.keyExists( key ) && scope[ key ] == bypassPassword ) {
					session[ key ] = bypassPassword;
					return true;
				}
			}
		}

		return false;
	}

	public void function showMaintenancePageIfActive() output=false {
		if ( isMaintenanceModeActive() && !canRequestBypassMaintenanceMode() ) {
			var settings = getMaintenanceModeSettings();
			header statuscode=503;
			content reset="true" type="text/html";
			WriteOutput( settings.html );
			abort;
		}
	}

// private helpers
	private struct function _readMaintenanceModeFromFile() output=false {
		var filePath = _getConfigPath();
		try {
			var modeSettings = DeSerializeJson( FileRead( filePath ) );
			return IsStruct( modeSettings ) ? modeSettings : {};
		} catch( any e ) {
			return {};
		}
	}
	private void function _writeMaintenanceModeToFile( required struct maintenanceModeSettings ) ouptut=false {
		var filePath = _getConfigPath();

		FileWrite( filePath, SerializeJson( arguments.maintenanceModeSettings ) );
	}

	private any function _getApplicationVariable() output=false {
		return application.presideMaintenanceMode ?: NullValue();
	}
	private void function _setApplicationVariable( required struct maintenanceModeSettings ) {
		application.presideMaintenanceMode = arguments.maintenanceModeSettings;
	}

// getters and setters
	private string function _getConfigPath() output=false {
		return _configPath;
	}
	private void function _setConfigPath( required string configPath ) output=false {
		_configPath = arguments.configPath;
	}
}