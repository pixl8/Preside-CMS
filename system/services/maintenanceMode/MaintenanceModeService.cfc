/**
 * This service is not a singleton and tries to rely on
 * as little external code knowledge as possible so as to
 * run before the application has been started up. It provides
 * methods for handling maintenance mode display and settings
 *
 */
component {

// constructor
	public any function init( string configPath=ExpandPath( "/app/config/.maintenance" ) ) {
		_setConfigPath( arguments.configPath );
	}

// public api
	public boolean function setMaintenanceMode(
		  required string  maintenanceHtml
		, required array   allowedIps
		, required string  bypassPassword
		, required boolean tasksEnabled
	) {
		var settings = {
			  html           = arguments.maintenanceHtml
			, allowedIps     = arguments.allowedIps
			, bypassPassword = arguments.bypassPassword
			, tasksEnabled   = arguments.tasksEnabled
			, bypassUuid     = createUUID()
		};

		_setApplicationVariable( settings );
		_writeMaintenanceModeToFile( settings );

		return true;
	}

	public boolean function clearMaintenanceMode() {
		var filePath = _getConfigPath();

		if ( FileExists( filePath ) ) {
			FileDelete( filePath );
		}
		_setApplicationVariable({});

		return true;
	}

	public struct function getMaintenanceModeSettings() {
		var settings = _getApplicationVariable();

		if ( IsNull( local.settings ) ) {
			settings = _readMaintenanceModeFromFile();
			_setApplicationVariable( settings );
		}

		return settings;
	}

	public boolean function isMaintenanceModeActive() {
		return getMaintenanceModeSettings().count();
	}

	public boolean function canRequestBypassMaintenanceMode() {
		if ( !_areSessionsEnabled() ) {
			return false;
		}

		var settings       = getMaintenanceModeSettings();
		var safeIps        = settings.allowedIps ?: [];
		var bypassPassword = settings.bypassPassword;
		var bypassUuid     = settings.bypassUuid ?: "";
		var clientIp       = cgi.remote_addr;

		if ( IsArray( safeIps ) && safeIps.find( clientIp ) ) {
			return true;
		}

		if ( bypassUuid.len() && bypassUuid == ( url.heartbeatBypass ?: "" ) ) {
			return true;
		}

		if ( Len( Trim( bypassPassword  ) ) ) {
			var scopes = [ session, cookie, form, url ];

			for( var scope in scopes ){
				if ( StructKeyExists( scope, bypassPassword ) ) {
					session[ bypassPassword ] = true;
					return true;
				}
			}
		}

		return false;
	}

	public void function showMaintenancePageIfActive() {
		if ( isMaintenanceModeActive() && !canRequestBypassMaintenanceMode() ) {
			var settings = getMaintenanceModeSettings();
			header statuscode=503;
			content reset="true" type="text/html";
			WriteOutput( settings.html );
			abort;
		}
	}

// private helpers
	private struct function _readMaintenanceModeFromFile() {
		var filePath = _getConfigPath();
		try {
			var modeSettings = DeSerializeJson( FileRead( filePath ) );
			return IsStruct( modeSettings ) ? modeSettings : {};
		} catch( any e ) {
			return {};
		}
	}
	private void function _writeMaintenanceModeToFile( required struct maintenanceModeSettings ) {
		var filePath = _getConfigPath();

		FileWrite( filePath, SerializeJson( arguments.maintenanceModeSettings ) );
	}

	private any function _getApplicationVariable() {
		return application.presideMaintenanceMode ?: NullValue();
	}
	private void function _setApplicationVariable( required struct maintenanceModeSettings ) {
		application.presideMaintenanceMode = arguments.maintenanceModeSettings;
	}

	private boolean function _areSessionsEnabled() {
		var appSettings = getApplicationSettings( true );

		return IsBoolean( appSettings.sessionManagement ?: "" ) && appSettings.sessionManagement;
	}

// getters and setters
	private string function _getConfigPath() {
		return _configPath;
	}
	private void function _setConfigPath( required string configPath ) {
		_configPath = arguments.configPath;
	}
}