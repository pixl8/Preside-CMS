component {

	/**
	 * @presideObjectService.inject       provider:presideObjectService
	 * @systemConfigurationService.inject provider:systemConfigurationService
	 * @adminLoginService.inject          provider:loginService
	 * @websiteLoginService.inject        provider:websiteLoginService
	 * @emailService.inject               provider:emailService
	 * @errorLogService.inject            provider:errorLogService
	 * @featureService.inject             provider:featureService
	 * @notificationService.inject        provider:notificationService
	 *
	 */
	public any function init(
		   required any presideObjectService
		,  required any systemConfigurationService
		,  required any adminLoginService
		,  required any websiteLoginService
		,  required any emailService
		,  required any errorLogService
		,  required any featureService
		,  required any notificationService
	) {
		$presideObjectService       = arguments.presideObjectService;
		$systemConfigurationService = arguments.systemConfigurationService;
		$adminLoginService          = arguments.adminLoginService;
		$websiteLoginService        = arguments.websiteLoginService;
		$emailService               = arguments.emailService;
		$errorLogService            = arguments.errorLogService;
		$featureService             = arguments.featureService;
		$notificationService        = arguments.notificationService;

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

// EMAIL SERVICE
	public any function $getEmailService() {
		return $emailService;
	}

	public any function $sendEmail() {
		return $getEmailService().send( argumentCollection=arguments );
	}

// ERROR LOGGING
	public any function $getErrorLogService() {
		return $errorLogService;
	}

	public any function $raiseError() {
		return $getErrorLogService().raiseError( argumentCollection=arguments );
	}

// PRESIDE FEATURES
	public any function $getFeatureService() {
		return $featureService;
	}

	public any function $isFeatureEnabled() {
		return $getFeatureService().isFeatureEnabled( argumentCollection=arguments );
	}

// NOTIFICATIONS
	public any function $getNotificationService() {
		return $notificationService;
	}

	public any function $createNotification() {
		return $getNotificationService().createNotification( argumentCollection=arguments );
	}
}