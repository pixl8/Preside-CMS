component {

	/**
	 * @presideObjectService.inject       provider:presideObjectService
	 * @systemConfigurationService.inject provider:systemConfigurationService
	 * @adminLoginService.inject          provider:loginService
	 * @websiteLoginService.inject        provider:websiteLoginService
	 *
	 */
	public any function init(
		   required any presideObjectService
		,  required any systemConfigurationService
		,  required any adminLoginService
		,  required any websiteLoginService
	) {
		$presideObjectService       = arguments.presideObjectService;
		$systemConfigurationService = arguments.systemConfigurationService;
		$adminLoginService          = arguments.adminLoginService;
		$websiteLoginService        = arguments.websiteLoginService;

		return this;
	}

// PRESIDE OBJECTS
	public any function $getPresideObjectService() {
		return $presideObjectService;
	}

	public any function $getPresideObject() {
		return $presideObjectService.getObject( argumentCollection=arguments );
	}

// SYSTEM CONFIG SERVICE
	public any function $getSystemConfigurationService() {
		return $systemConfigurationService;
	}

	public any function $getPresideSetting() {
		return $getSystemConfigurationService().getSetting( argumentCollection=arguments );
	}

	public any function $getPresideCategorySettings() {
		return $getSystemConfigurationService().getCategorySettings( argumentCollection=arguments );
	}

// LOGGED IN USERS
	public any function $getAdminLoginService() {
		return $adminLoginService;
	}

	public any function $getWebsiteLoginService() {
		return $websiteLoginService;
	}

	public any function $isAdminUserLoggedIn() {
		return $getAdminLoginService().isLoggedIn( argumentCollection=arguments );
	}

	public any function $getAdminLoggedInUserDetails() {
		return $getAdminLoginService().getLoggedInUserDetails( argumentCollection=arguments );
	}

	public any function $getAdminLoggedInUserId() {
		return $getAdminLoginService().getLoggedInUserId( argumentCollection=arguments );
	}

	public any function $isWebsiteUserLoggedIn() {
		return $getWebsiteLoginService().isLoggedIn( argumentCollection=arguments );
	}

	public any function $isWebsiteUserImpersonated() {
		return $getWebsiteLoginService().isImpersonated( argumentCollection=arguments );
	}

	public any function $getWebsiteLoggedInUserDetails() {
		return $getWebsiteLoginService().getLoggedInUserDetails( argumentCollection=arguments );
	}

	public any function $getWebsiteLoggedInUserId() {
		return $getWebsiteLoginService().getLoggedInUserId( argumentCollection=arguments );
	}

	public any function $getWebsiteLoggedInUserId() {
		return $getWebsiteLoginService().getLoggedInUserId( argumentCollection=arguments );
	}


}