component {

	/**
	 * @presideObjectService.inject       provider:presideObjectService
	 * @systemConfigurationService.inject provider:systemConfigurationService
	 *
	 */
	public any function init( required any presideObjectService, required any systemConfigurationService ) {
		$presideObjectService       = arguments.presideObjectService;
		$systemConfigurationService = arguments.systemConfigurationService;

		return this;
	}

	public any function $getPresideObjectService() {
		return $presideObjectService;
	}

	public any function $getPresideObject() {
		return $presideObjectService.getObject( argumentCollection=arguments );
	}

	public any function $getSystemConfigurationService() {
		return $systemConfigurationService;
	}

	public any function $getPresideSetting() {
		return $getSystemConfigurationService().getSetting( argumentCollection=arguments );
	}

	public any function $getPresideCategorySettings() {
		return $getSystemConfigurationService().getCategorySettings( argumentCollection=arguments );
	}


}