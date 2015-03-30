/**
 * This service is used by the admin interface
 * for all APIs to do with managing maintenance
 * mode.
 *
 * @singleton true
 */
component {

// constructor
	/**
	 * @maintenanceModeService.inject     maintenanceModeService
	 * @systemConfigurationService.inject systemConfigurationService
	 */
	public any function init( required any maintenanceModeService, required any systemConfigurationService ) {
		_setMaintenanceModeService( arguments.maintenanceModeService );
		_setSystemConfigurationService( arguments.systemConfigurationService );
	}

// public api
	public struct function getSettings() {
		return _getSystemConfigurationService().getCategorySettings( "maintenanceMode" );
	}

	public void function saveSettings( required struct settings ) {
		var configService = _getSystemConfigurationService();

		for( var settingName in settings ) {
			configService.saveSetting(
				  category = "maintenanceMode"
				, setting  = settingName
				, value    = settings[ settingName ]
			)
		}
	}

// private helpers

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
}