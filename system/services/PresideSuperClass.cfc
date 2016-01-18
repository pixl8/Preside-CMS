/**
 * This class is used to provide common PresideCMS functionality to your service layer.
 * See [[presidesuperclass]] for a full guide on how to make use of this class.
 *
 * @autodoc true
 *
 */
component displayName="Preside Super Class" {

	/**
	 * @presideObjectService.inject       delayedInjector:presideObjectService
	 * @systemConfigurationService.inject delayedInjector:systemConfigurationService
	 * @adminLoginService.inject          delayedInjector:loginService
	 * @adminPermissionService.inject     delayedInjector:permissionService
	 * @websiteLoginService.inject        delayedInjector:websiteLoginService
	 * @websitePermissionService.inject   delayedInjector:websitePermissionService
	 * @emailService.inject               delayedInjector:emailService
	 * @errorLogService.inject            delayedInjector:errorLogService
	 * @featureService.inject             delayedInjector:featureService
	 * @notificationService.inject        delayedInjector:notificationService
	 * @coldbox.inject                    delayedInjector:coldbox
	 *
	 */
	public any function init(
		   required any presideObjectService
		,  required any systemConfigurationService
		,  required any adminLoginService
		,  required any adminPermissionService
		,  required any websiteLoginService
		,  required any websitePermissionService
		,  required any emailService
		,  required any errorLogService
		,  required any featureService
		,  required any notificationService
		,  required any coldbox
	) {
		$presideObjectService       = arguments.presideObjectService;
		$systemConfigurationService = arguments.systemConfigurationService;
		$adminLoginService          = arguments.adminLoginService;
		$adminPermissionService     = arguments.adminPermissionService;
		$websiteLoginService        = arguments.websiteLoginService;
		$websitePermissionService   = arguments.websitePermissionService;
		$emailService               = arguments.emailService;
		$errorLogService            = arguments.errorLogService;
		$featureService             = arguments.featureService;
		$notificationService        = arguments.notificationService;
		$coldbox                    = arguments.coldbox;

		return this;
	}

// PRESIDE OBJECTS
	/**
	 * Returns an instance of the [[api-presideobjectservice]]. For example:
     * \n
     * ## Example
     * \n
	 * ```luceescript
	 * $getPresideObjectService().dbSync();
	 * ```
	 *
	 * @autodoc true
	 *
	 */
	public any function $getPresideObjectService() {
		return $presideObjectService;
	}

	/**
	 * Proxy to the [[presideobjectservice-getobject]] method on the [[api-presideobjectservice]].
	 * \n
	 * ## Example
	 * \n
	 * ```luceescript
	 * $getPresideObject( "my_object" ).deleteData( id=arguments.id );
	 * ```
	 *
	 * @autodoc true
	 *
	 */
	public any function $getPresideObject() {
		return $presideObjectService.getObject( argumentCollection=arguments );
	}

// SYSTEM CONFIG SERVICE
	/**
	 * Returns an instance of the [[api-systemconfigurationservice]]. See [[editablesystemsettings]] for a full guide.
	 * \n
	 * ## Example
     * \n
	 * ```luceescript
	 * $getSystemConfigurationService().saveSetting(
	 * \t      catetory = "my-settings"
	 * \t    , setting  = "my-setting"
	 * \t    , value    = arguments.settingValue
	 * );
	 * ```
	 *
	 * @autodoc true
	 *
	 */
	public any function $getSystemConfigurationService() {
		return $systemConfigurationService;
	}

	/**
	 * Proxy to the [[systemconfigurationservice-getsetting]] method of [[api-systemconfigurationservice]]. See [[editablesystemsettings]] for a full guide.
	 * \n
	 * ## Example
	 * \n
	 * ```luceescript
	 * var mailServer = $getPresideSetting( category="email", setting="server" );
	 * ```
	 *
	 * @autodoc true
	 *
	 */
	public any function $getPresideSetting() {
		return $getSystemConfigurationService().getSetting( argumentCollection=arguments );
	}

	/**
	 * Proxy to the [[systemconfigurationservice-getCategorySettings]] method of [[api-systemconfigurationservice]]. See [[editablesystemsettings]] for a full guide.
	 * \n
	 * ## Example
	 * \n
	 * ```luceescript
	 * var mailSettings = $getPresideCategorySettings( category="email" );
	 * ```
	 *
	 * @autodoc true
	 *
	 */
	public any function $getPresideCategorySettings() {
		return $getSystemConfigurationService().getCategorySettings( argumentCollection=arguments );
	}

// LOGGED IN USERS
	/**
	 * Returns the [[api-loginservice]]. This can be used to check logged in user details, etc.
	 * See [[cmspermissioning]] for a full guide.
	 * \n
	 * ## Example
	 * \n
	 * ```luceescript
	 * if ( $getAdminLoginService().isSystemUser() ) {
	 * \t    // ...
	 * }
	 * ```
	 * @autodoc true
	 *
	 */
	public any function $getAdminLoginService() {
		return $adminLoginService;
	}

	/**
	 * Returns the [[api-websiteloginservice]]. This can be used to check logged in user details, etc.
	 * * See [[websiteusersandpermissioning]] for a full guide.
	 * \n
	 * ## Example
	 * \n
	 * ```luceescript
	 * if ( $getWebsiteLoginService().isImpersonated() ) {
	 * \t    // ...
	 * }
	 * ```
	 *
	 * @autodoc true
	 *
	 */
	public any function $getWebsiteLoginService() {
		return $websiteLoginService;
	}

	/**
	 * Returns the [[api-permissionservice]]. This can be used to check CMS admin permissions, etc.
	 * See [[cmspermissioning]] for a full guide.
	 * \n
	 * ## Example
	 * \n
	 * ```luceescript
	 * var adminSystemUserRoles = $getAdminPermissionService().listRoles();
	 * ```
	 *
	 * @autodoc true
	 *
	 */
	public any function $getAdminPermissionService() {
		return $adminPermissionService;
	}

	/**
	 * Returns the [[api-websitepermissionservice]]. This can be used to check website user permissions, etc.
	 * See [[websiteusersandpermissioning]] for a full guide.
	 * \n
	 * ## Example
	 * \n
	 * ```luceescript
	 * var userBenefits = $getWebsitePermissionService().listUserBenefits(
	 * \t    userId = $getWebsiteLoggedInUserId()
	 * );
	 * ```
	 *
	 * @autodoc true
	 *
	 */
	public any function $getWebsitePermissionService() {
		return $websitePermissionService;
	}

	/**
	 * Proxy to the [[loginservice-isLoggedIn]] method of [[api-loginservice]].
	 * See [[cmspermissioning]] for a full guide.
	 * \n
	 * ## Example
	 * \n
	 * ```luceescript
	 * if ( $isAdminUserLoggedIn() ) {
	 * \t    // ...
	 * }
	 * ```
	 *
	 * @autodoc true
	 *
	 */
	public any function $isAdminUserLoggedIn() {
		return $getAdminLoginService().isLoggedIn( argumentCollection=arguments );
	}

	/**
	 * Proxy to the [[loginservice-getadminloggedinuserdetails]] method of [[api-loginservice]].
	 * See [[cmspermissioning]] for a full guide.
	 * \n
	 * ## Example
	 * \n
	 * ```luceescript
	 * var userDetails = $getAdminLoggedInUserDetails();
	 * ```
	 *
	 * @autodoc true
	 *
	 */
	public any function $getAdminLoggedInUserDetails() {
		return $getAdminLoginService().getLoggedInUserDetails( argumentCollection=arguments );
	}

	/**
	 * Proxy to the [[loginservice-getadminloggedinuserid]] method of [[api-loginservice]].
	 * See [[cmspermissioning]] for a full guide.
	 * \n
	 * ## Example
	 * \n
	 * ```luceescript
	 * var userId = $getAdminLoggedInUserId();
	 * ```
	 *
	 * @autodoc true
	 *
	 */
	public any function $getAdminLoggedInUserId() {
		return $getAdminLoginService().getLoggedInUserId( argumentCollection=arguments );
	}

	/**
	 * Proxy to the [[permissionservice-hasadminpermission]] method of [[api-permissionservice]].
	 * See [[cmspermissioning]] for a full guide.
	 * \n
	 * ## Example
	 * \n
	 * ```luceescript
	 * if ( $hasAdminPermission( "eventssystem.manage" ) ) {
	 * \t    // ...
	 * }
	 * ```
	 *
	 * @autodoc true
	 *
	 */
	public any function $hasAdminPermission() {
		return $getAdminPermissionService().hasPermission( argumentCollection=arguments );
	}

	/**
	 * Proxy to the [[websiteloginservice-isloggedin]] method of [[api-websiteloginservice]].
	 * See [[websiteusersandpermissioning]] for a full guide.
	 * \n
	 * ## Example
	 * \n
	 * ```luceescript
	 * if ( $isWebsiteUserLoggedIn() ) {
	 * \t    // ...
	 * }
	 * ```
	 *
	 * @autodoc true
	 *
	 */
	public any function $isWebsiteUserLoggedIn() {
		return $getWebsiteLoginService().isLoggedIn( argumentCollection=arguments );
	}

	/**
	 * Proxy to the [[websiteloginservice-isimpersonated]] method of [[api-websiteloginservice]].
	 * See [[websiteusersandpermissioning]] for a full guide.
	 * \n
	 * ## Example
	 * \n
	 * ```luceescript
	 * if ( $isWebsiteUserLoggedIn() && !$isWebsiteUserImpersonated() ) {
	 * \t    // do some sensitive action that requires the actual user to be logged in
	 * }
	 * ```
	 *
	 * @autodoc true
	 *
	 */
	public any function $isWebsiteUserImpersonated() {
		return $getWebsiteLoginService().isImpersonated( argumentCollection=arguments );
	}

	/**
	 * Proxy to the [[websiteloginservice-getloggedinuserdetails]] method of [[api-websiteloginservice]].
	 * See [[websiteusersandpermissioning]] for a full guide.
	 * \n
	 * ## Example
	 * \n
	 * ```luceescript
	 * var userDetails = $getWebsiteLoggedInUserDetails();
	 * ```
	 *
	 * @autodoc true
	 *
	 */
	public any function $getWebsiteLoggedInUserDetails() {
		return $getWebsiteLoginService().getLoggedInUserDetails( argumentCollection=arguments );
	}

	/**
	 * Proxy to the [[websiteloginservice-getloggedinuserid]] method of [[api-websiteloginservice]].
	 * See [[websiteusersandpermissioning]] for a full guide.
	 * \n
	 * ## Example
	 * \n
	 * ```luceescript
	 * var userId = $getWebsiteLoggedInUserId();
	 * ```
	 *
	 * @autodoc true
	 *
	 */
	public any function $getWebsiteLoggedInUserId() {
		return $getWebsiteLoginService().getLoggedInUserId( argumentCollection=arguments );
	}

	/**
	 * Proxy to the [[websiteloginservice-haspermission]] method of [[api-websitepermissionservice]].
	 * See [[websiteusersandpermissioning]] for a full guide.
	 * \n
	 * ## Example
	 * \n
	 * ```luceescript
	 * if ( $hasWebsitePermission( "review.submit" ) ) {
	 *     // ...
	 * }
	 * ```
	 *
	 * @autodoc true
	 *
	 */
	public any function $hasWebsitePermission() {
		return $getWebsitePermissionService().hasPermission( argumentCollection=arguments );
	}

// EMAIL SERVICE
	/**
	 * Returns an instance of the [[api-emailservice]]. This service can be used for
	 * sending templated emails. See [[emailtemplating]] for a full guide.
	 * \n
	 * ## Example
	 * \n
	 * ```luceescript
	 * var emailTemplates = $getEmailService().listTemplates();
	 * ```
	 *
	 * @autodoc true
	 *
	 */
	public any function $getEmailService() {
		return $emailService;
	}

	/**
	 * Proxy to the [[emailservice-send]] method of the [[api-emailservice]].
	 *  See [[emailtemplating]] for a full guide.
	 * \n
	 * ## Example
	 * \n
	 * ```luceescript
	 * $sendEmail(
	 * \t      template = "eventBookingConfirmation"
	 * \t    , args     =  { bookingId = arguments.bookingId }
	 * );
	 * ```
	 * @autodoc true
	 *
	 */
	public any function $sendEmail() {
		return $getEmailService().send( argumentCollection=arguments );
	}

// ERROR LOGGING
	/**
	 * Returns an instance of the [[api-errorlogservice]]. This service
	 * can be used to raise and query system errors.
	 * \n
	 * ## Example
	 * \n
	 * ```luceescript
	 * $getErrorLogService().deleteAllErrors();
	 * ```
	 *
	 * @autodoc true
	 *
	 */
	public any function $getErrorLogService() {
		return $errorLogService;
	}

	/**
	 * Proxy to the [[errorlogservice-raiseerror]] method of the [[api-errorlogservice]].
	 * Raises an error with the system.
	 * \n
	 * ## Example
	 * \n
	 * ```luceescript
	 * try {
	 * \t    result = input / 0;
	 * } catch( any e ) {
	 * \t    $raiseError( e );
	 * }
	 * ```
	 *
	 * @autodoc true
	 *
	 */
	public any function $raiseError() {
		return $getErrorLogService().raiseError( argumentCollection=arguments );
	}

// PRESIDE FEATURES
	/**
	 * Returns an instance of the [[api-featureservice]]. This service can be used for checking
	 * whether or not a feature is enabled.
	 *
	 * @autodoc true
	 *
	 */
	public any function $getFeatureService() {
		return $featureService;
	}

	/**
	 * Proxy to the [[featureservice-isfeatureenabled]] method of the [[api-featureservice]].
	 * \n
	 * ## Example
	 * \n
	 * ```luceescript
	 * if ( $isFeatureEnabled( "websiteUsers" ) ) {
	 * \t    // ...
	 * }
	 * ```
	 *
	 * @autodoc true
	 *
	 */
	public any function $isFeatureEnabled() {
		return $getFeatureService().isFeatureEnabled( argumentCollection=arguments );
	}

// NOTIFICATIONS
	/**
	 * Returns an instance of the [[api-notificationservice]]. See [[notifications]] for a full guide.
	 * \n
	 * ## Example
	 * \n
	 * ```luceescript
	 * var unreadNotifications = $getNotificationService().getUnreadNotificationCount(
	 * \t    userId = $getAdminLoggedInUserId()
	 * );
	 * ```
	 *
	 * @autodoc true
	 *
	 */
	public any function $getNotificationService() {
		return $notificationService;
	}

	/**
	 * Proxy to the [[notificationservice-createnotification]] method of the [[api-notificationservice]].
	 * See [[notifications]] for a full guide.
	 * \n
	 * ## Example
	 * \n
	 * ```luceescript
	 * $createNotification(
	 * \t      topic = "eventbooked"
	 * \t    , type  = "info"
	 * \t    , data  = { bookingId = arguments.bookingId }
	 * );
	 * ```
	 *
	 * @autodoc true
	 *
	 */
	public any function $createNotification() {
		return $getNotificationService().createNotification( argumentCollection=arguments );
	}

	/**
	 * Returns the coldbox controller	 *
	 *
	 * @autodoc
	 */
	public any function $getColdbox() {
		return $coldbox;
	}

	/**
	 * Proxy to the i18n Coldbox plugin's `translateResource()` method.
	 * \n
	 * ## Example
	 * \n
	 * ```luceescript
	 * translated = $translateResource( uri="cms:ok.btn" );
	 * ```
	 *
	 * @autodoc
	 */
	public any function $translateResource() {
		return $getColdbox().getPlugin( "i18n" ).translateResource( argumentCollection=arguments );
	}

	/**
	 * Proxy to the core PresideCMS 'renderViewlet' method.
	 * \n
	 * ## Example
	 * \n
	 * ```luceescript
	 * var rendered = $renderViewlet( event="my.viewlet", args=someData );
	 *
	 * ```
	 *
	 * @autodoc
	 *
	 */
	public any function $renderViewlet() {
		return $getColdbox().renderViewlet( argumentCollection=arguments );
	}
}