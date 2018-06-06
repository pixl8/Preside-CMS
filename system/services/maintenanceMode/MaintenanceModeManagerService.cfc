/**
 * This service is used by the admin interface
 * for all APIs to do with managing maintenance
 * mode.
 *
 * @singleton
 * @presideService
 */
component {

// constructor
	/**
	 * @maintenanceModeService.inject     maintenanceModeService
	 * @systemConfigurationService.inject systemConfigurationService
	 * @taskManagerService.inject         taskManagerService
	 * @maintenanceModeViewlet.inject     coldbox:setting:maintenanceModeViewlet
	 * @coldbox.inject                    coldbox
	 */
	public any function init(
		  required any maintenanceModeService
		, required any systemConfigurationService
		, required any taskManagerService
		, required any coldbox
		, required string maintenanceModeViewlet
	) {
		_setMaintenanceModeService( arguments.maintenanceModeService );
		_setSystemConfigurationService( arguments.systemConfigurationService );
		_setTaskManagerService( arguments.taskManagerService );
		_setMaintenanceModeViewlet( arguments.maintenanceModeViewlet );
		_setColdbox( arguments.coldbox );
	}

// public api
	public struct function getSettings() {
		return _getSystemConfigurationService().getCategorySettings( "maintenanceMode" );
	}

	public void function saveSettings( required struct settings ) {
		var configService = _getSystemConfigurationService();
		var active        = IsBoolean( arguments.settings.active ?: "" ) && arguments.settings.active;

		for( var settingName in settings ) {
			configService.saveSetting(
				  category = "maintenanceMode"
				, setting  = settingName
				, value    = settings[ settingName ]
			);
		}

		active ? _activateMaintenanceMode( arguments.settings ) : _deactivateMaintenanceMode();
	}

// private helpers
	private void function _activateMaintenanceMode( required struct settings ) {
		var taskSettings = _getSystemConfigurationService().getCategorySettings( "taskmanager" );
		var tasksEnabled = IsBoolean( taskSettings.scheduledtasks_enabled ?: "" ) && taskSettings.scheduledtasks_enabled;
		if ( tasksEnabled ) {
			_setScheduledTaskStatus( false );
		}

		_getMaintenanceModeService().setMaintenanceMode(
			  maintenanceHtml = _generateMaintenanceModePage( arguments.settings )
			, bypassPassword  = arguments.settings.bypass_password ?: ""
			, allowedIps      = ListToArray( arguments.settings.ip_whitelist ?: "", Chr(10) & Chr(13) & "," )
			, tasksEnabled    = tasksEnabled
		);

		$audit(
			  action = "activate_maintenance_mode"
			, type   = "maintenancemode"
		);
	}

	private void function _deactivateMaintenanceMode() {
		var mmSettings = _getMaintenanceModeService().getMaintenanceModeSettings();
		_getMaintenanceModeService().clearMaintenanceMode();

		if ( isBoolean( mmSettings.tasksEnabled ?: "" ) && mmSettings.tasksEnabled ) {
			_setScheduledTaskStatus( true );
		}

		$audit(
			  action = "deactivate_maintenance_mode"
			, type   = "maintenancemode"
		);
	}

	private void function _setScheduledTaskStatus( required boolean tasksEnabled ) {
		_getSystemConfigurationService().saveSetting(
			  category = "taskmanager"
			, setting  = "scheduledtasks_enabled"
			, value    = arguments.tasksEnabled
		);
		_getTaskManagerService().registerMasterScheduledTask();
	}

	private string function _generateMaintenanceModePage( required struct settings ) {
		return _getColdbox().renderViewlet(
			  event = _getMaintenanceModeViewlet()
			, args  = arguments.settings
		);
	}

// getters and setters
	private any function _getMaintenanceModeService() {
		return _maintenanceModeService;
	}
	private void function _setMaintenanceModeService( required any maintenanceModeService ) {
		_maintenanceModeService = arguments.maintenanceModeService;
	}

	private any function _getSystemConfigurationService() {
		return _systemConfigurationService;
	}
	private void function _setSystemConfigurationService( required any systemConfigurationService ) {
		_systemConfigurationService = arguments.systemConfigurationService;
	}

	private any function _getTaskManagerService() {
		return _taskManagerService;
	}
	private void function _setTaskManagerService( required any taskManagerService ) {
		_taskManagerService = arguments.taskManagerService;
	}

	private any function _getColdbox() output=false {
		return _coldbox;
	}
	private void function _setColdbox( required any coldbox ) output=false {
		_coldbox = arguments.coldbox;
	}

	private string function _getMaintenanceModeViewlet() output=false {
		return _maintenanceModeViewlet;
	}
	private void function _setMaintenanceModeViewlet( required string maintenanceModeViewlet ) output=false {
		_maintenanceModeViewlet = arguments.maintenanceModeViewlet;
	}
}