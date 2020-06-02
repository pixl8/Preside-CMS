/**
 * This class is used to provide common Preside functionality to your service layer.
 * See [[presidesuperclass]] for a full guide on how to make use of this class.
 *
 * @autodoc
 *
 */
component displayName="Preside Super Class" {

	/**
	 * @presideObjectService.inject       delayedInjector:presideObjectService
	 * @systemConfigurationService.inject delayedInjector:systemConfigurationService
	 * @adminLoginService.inject          delayedInjector:loginService
	 * @adminPermissionService.inject     delayedInjector:permissionService
	 * @websiteLoginService.inject        delayedInjector:websiteLoginService
	 * @websiteUserActionService.inject   delayedInjector:websiteUserActionService
	 * @websitePermissionService.inject   delayedInjector:websitePermissionService
	 * @emailService.inject               delayedInjector:emailService
	 * @errorLogService.inject            delayedInjector:errorLogService
	 * @featureService.inject             delayedInjector:featureService
	 * @notificationService.inject        delayedInjector:notificationService
	 * @auditService.inject               delayedInjector:auditService
	 * @contentRendererService.inject     delayedInjector:contentRendererService
	 * @taskmanagerService.inject         delayedInjector:taskmanagerService
	 * @validationEngine.inject           delayedInjector:validationEngine
	 * @adHocTaskManagerService.inject    delayedInjector:adHocTaskManagerService
	 * @threadUtil.inject                 delayedInjector:threadUtil
	 * @coldbox.inject                    delayedInjector:coldbox
	 * @i18n.inject                       delayedInjector:i18n
	 * @htmlHelper.inject                 delayedInjector:HTMLHelper@coldbox
	 * @healthcheckService.inject         delayedInjector:healthcheckService
	 * @presideHelperClass.inject         presideHelperClass
	 *
	 */
	public any function init(
		  required any presideObjectService
		, required any systemConfigurationService
		, required any adminLoginService
		, required any adminPermissionService
		, required any websiteLoginService
		, required any websiteUserActionService
		, required any websitePermissionService
		, required any emailService
		, required any errorLogService
		, required any featureService
		, required any notificationService
		, required any auditService
		, required any contentRendererService
		, required any taskmanagerService
		, required any validationEngine
		, required any adHocTaskManagerService
		, required any threadUtil
		, required any coldbox
		, required any i18n
		, required any htmlHelper
		, required any healthcheckService
		, required any presideHelperClass
	) {
		$presideObjectService       = arguments.presideObjectService;
		$systemConfigurationService = arguments.systemConfigurationService;
		$adminLoginService          = arguments.adminLoginService;
		$adminPermissionService     = arguments.adminPermissionService;
		$websiteLoginService        = arguments.websiteLoginService;
		$websiteUserActionService   = arguments.websiteUserActionService;
		$websitePermissionService   = arguments.websitePermissionService;
		$emailService               = arguments.emailService;
		$errorLogService            = arguments.errorLogService;
		$featureService             = arguments.featureService;
		$notificationService        = arguments.notificationService;
		$auditService               = arguments.auditService;
		$contentRendererService     = arguments.contentRendererService;
		$taskmanagerService         = arguments.taskmanagerService;
		$validationEngine           = arguments.validationEngine;
		$adHocTaskManagerService    = arguments.adHocTaskManagerService;
		$threadUtil                 = arguments.threadUtil;
		$coldbox                    = arguments.coldbox;
		$i18n                       = arguments.i18n;
		$htmlHelper                 = arguments.htmlHelper;
		$healthcheckService         = arguments.healthcheckService;

		this.$helpers = arguments.presideHelperClass;

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
	 * @autodoc
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
	 * @autodoc
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
	 * @autodoc
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
	 * @autodoc
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
	 * @autodoc
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
	 * @autodoc
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
	 * @autodoc
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
	 * @autodoc
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
	 * @autodoc
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
	 * @autodoc
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
	 * @autodoc
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
	 * @autodoc
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
	 * @autodoc
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
	 * @autodoc
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
	 * @autodoc
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
	 * @autodoc
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
	 * @autodoc
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
	 * @autodoc
	 *
	 */
	public any function $hasWebsitePermission() {
		return $getWebsitePermissionService().hasPermission( argumentCollection=arguments );
	}

	/**
	 * Proxy to the [[websiteuseractionservice-recordaction]] method of [[api-websiteuseractionservice]].
	 * \n
	 * ## Example
	 * \n
	 * ```luceescript
	 * $recordWebsiteUserAction();
	 * ```
	 *
	 * @autodoc
	 */
	public any function $recordWebsiteUserAction( string userId=$getWebsiteLoggedInUserId() ) {
		return $websiteUserActionService.recordAction( argumentCollection=arguments );
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
	 * @autodoc
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
	 * @autodoc
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
	 * @autodoc
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
	 * @autodoc
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
	 * @autodoc
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
	 * @autodoc
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
	 * @autodoc
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
	 * @autodoc
	 *
	 */
	public any function $createNotification() {
		return $getNotificationService().createNotification( argumentCollection=arguments );
	}

	/**
	 * Returns the audit log service
	 *
	 * @autodoc
	 */
	public any function $getAuditService() {
		return $auditService;
	}

	/**
	 * Proxy to auditService.log() method. Creates an audit log entry.
	 * \n
	 * ## Example
	 * \n
	 * ```luceescript
	 * $audit(
	 *       detail   = {}
	 *     , source   = "login"
	 *     , action   = "login_success"
	 *     , type     = "user"
	 * );
	 * ```
	 *
	 * @autodoc
	 */
	public any function $audit(
		string userId = $getAdminLoggedInUserId()
	) {
		return $getAuditService().log( argumentCollection=arguments );
	}

	/**
	 * Returns the content renderer service
	 *
	 * @autodoc
	 */
	public any function $getContentRendererService() {
		return $contentRendererService;
	}

	/**
	 * Proxy to contentRendererService.render() method
	 *
	 * @autodoc
	 *
	 */
	public any function $renderContent() {
		return $getContentRendererService().render( argumentCollection=arguments );
	}

	/**
	 * Proxy to contentRendererService.renderLabel() method
	 *
	 * @autodoc
	 *
	 */
	public any function $renderLabel() {
		return $getContentRendererService().renderLabel( argumentCollection=arguments );
	}

	/**
	 * Proxy to contentRendererService.renderField() method
	 *
	 * @autodoc
	 *
	 */
	public any function $renderField() {
		return $getContentRendererService().renderField( argumentCollection=arguments );
	}

	/*
	 * Returns an instance of the [[api-taskmanagerService]]. See [[taskmanager]] for a full guide.
	 *
	 * @autodoc
	 *
	 */
	public any function $getTaskmanagerService() {
		return $taskmanagerService;
	}

	/**
	 * Proxy to the [[taskmanagerservice-runtask]] method of the [[api-taskmanagerservice]].
	 * See [[taskmanager]] for a full guide.
	 * $runTask( "resizeImages" );
	 * ```
	 *
	 * @autodoc
	 *
	 */
	public any function $runTask() {
		return $getTaskmanagerService().runTask( argumentCollection=arguments );
	}

	/**
	 * Returns an instance of the preside validation engine (see [[validation-framework]] for more details)
	 *
	 * @autodoc
	 */
	public any function $getValidationEngine() {
		return $validationEngine;
	}

	/**
	 * Returns a new validation result (see [[validation-framework]] for more details)
	 *
	 * @autodoc
	 */
	public any function $newValidationResult() {
		return $getValidationEngine().newValidationResult();
	}

	/**
	 * Returns the coldbox controller
	 *
	 * @autodoc
	 */
	public any function $getColdbox() {
		return $coldbox;
	}

	/**
	 * Returns the current request context object
	 *
	 * @autodoc
	 */
	public any function $getRequestContext() {
		return $getColdbox().getRequestService().getContext();
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
		return $i18n.translateResource( argumentCollection=arguments );
	}

	/**
	 * Proxy to the i18n `translateObjectName()` method.
	 * \n
	 * ## Example
	 * \n
	 * ```luceescript
	 * translated = $translateObjectName( objectName="my_object", plural=false );
	 * ```
	 *
	 * @autodoc
	 */
	public any function $translateObjectName() {
		return $i18n.translateObjectName( argumentCollection=arguments );
	}

	/**
	 * Proxy to the i18n `translatePropertyName()` method.
	 * \n
	 * ## Example
	 * \n
	 * ```luceescript
	 * translated = $translatePropertyName( objectName="my_object", propertyName="my_property" );
	 * ```
	 *
	 * @autodoc
	 */
	public any function $translatePropertyName() {
		return $i18n.translatePropertyName( argumentCollection=arguments );
	}


	/**
	 * Proxy to i18n service's getFWCountryCode() and getFWLanguageCode()
	 * methods to provide the locale of the current request
	 * \n
	 * ## Example
	 * \n
	 * ```luceescript
	 * currentLocale = $getI18nLocale()
	 * ```
	 */
	public string function $getI18nLocale() {
		if ( len( $i18n.getFWCountryCode() ) ) {
			return $i18n.getFWLanguageCode() & "_" & $i18n.getFWCountryCode();
		}
		return $i18n.getFWLanguageCode();
	}

	/**
	 * Proxy to the core Preside 'renderViewlet' method.
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

	/**
	 * Proxy to the core coldbox 'runEvent' method.
	 * \n
	 * ## Example
	 * \n
	 * ```luceescript
	 * var result = $runEvent( event="my.viewlet", eventArguments={ args=someData }, private=true, prePostExempt=true );
	 *
	 * ```
	 *
	 * @autodoc
	 *
	 */
	public any function $runEvent() {
		return $getColdbox().runEvent( argumentCollection=arguments );
	}

	/**
	 * Proxy to Coldbox's InterceptorService.processState() method.
	 * \n
	 * ## Example
	 * \n
	 * ```luceescript
	 * $announceInterception( "onFormBuilderFormSubmission", formSubmissionData );
	 * ```
	 *
	 * @autodoc
	 */
	public any function $announceInterception(
		  required string  state
		,          struct  interceptData = {}
	) {
		return $getColdbox().getInterceptorService().processState( argumentCollection=arguments )
	}

	/**
	 * Gets the adhoc taskmanager service
	 *
	 * @autodoc
	 */
	public any function $getAdhocTaskManagerService() {
		return $adHocTaskManagerService;
	}

	/**
	 * Proxy to the [[adhoctaskmanagerservice-createtask]] method of the [[api-adhoctaskmanagerservice]]
	 * service.
	 * \n
	 * ## Example
	 * \n
	 * ```luceescript
	 * var taskId = $createTask(
	 * \t  event  = "generate.invoice"
	 * \t, args   = { salesref=salesref }
	 * \t, runNow = true
	 * );
	 * ```
	 *
	 * @autodoc
	 */
	public any function $createTask() {
		return $getAdhocTaskManagerService().createTask( argumentCollection=arguments );
	}

	/**
	 * Proxy to the slugify method of Coldbox's HTMLHelper
	 * \n
	 * ## Example
	 * \n
	 * ```luceescript
	 * var slug = $slugify( "My Site: About Us" );
	 * // Will return "my-site-about-us"
	 * ```
	 *
	 * @autodoc           true
	 * @str.hint          The String to 'slugify'
	 * @maxLength.hint    Max length of the resultant string. Will be trimmed to this length if longer.
	 * @allow.hint        A regex safe list of additional characters to allow
	 * @preserveCase.hint Whether or not to allow mixed case. If false, default, the slug will be all lowercase.
	 */
	public string function $slugify( required str, numeric maxLength=0, allow="", preserveCase=false ) {
		var slug = Trim( arguments.str );

		if ( !preserveCase ) {
			slug = LCase( slug );
		}
		slug = ReplaceList( slug, '#chr(228)#,#chr(252)#,#chr(246)#,#chr(223)#', 'ae,ue,oe,ss' );
		slug = ReReplace( slug, "[^a-zA-Z0-9-\s#arguments.allow#]", "", "all" );
		slug = Trim( ReReplace( slug, "[\s-]+", " ", "all" ) );
		slug = ReReplace( slug, "\s", "-", "all" );

		if ( arguments.maxlength ) {
			slug = left( slug, arguments.maxlength );
		}

		return slug;
	}

	/**
	 * Returns the [[api-threadutil|threadUtil] service.
	 *
	 * @autodoc true
	 *
	 */
	public any function $getThreadUtil() {
		return $threadUtil;
	}

	/**
	 * Checks to see whether or not the current thread
	 * has been interrupted. Useful for long loops to gracefully
	 * shutdown when asked. Proxy to [[threadutil-isinterrupted]].
	 *
	 * @autodoc
	 */
	public boolean function $isInterrupted() {
		return $getThreadUtil().isInterrupted( argumentCollection=arguments );
	}

	/**
	 * Logs to the Lucee system output console (either direct to console, or to
	 * catalina.out if Tomcat, etc). This method wraps SystemOutput() and adds
	 * a PRESIDE prefix + timestamp to every log.
	 * \n
	 * Example:
	 * \n
	 * ```
	 * $systemOutput( "Lions and tigers and bears. Oh my!" );
	 * ```
	 *
	 * @autodoc true
	 * @message The message to send to the console/log
	 */
	public void function $systemOutput( required string message, string appId=$getApplicationId() ) {
		SystemOutput( "Preside System Output (#arguments.appId#) [#DateTimeFormat( Now(), 'yyyy-mm-dd HH:nn:ss' )#]: #message#" & Chr( 13 ) & Chr( 10 ) );
	}

	/**
	 * Returns the ID of the current Application.
	 *
	 * @autodoc true
	 */
	public string function $getApplicationId() {
		var appSettings = getApplicationMetadata();
		return appSettings.PRESIDE_APPLICATION_ID ?: ( appSettings.name ?: "" );
	}


	/**
	 * Returns the [[api-healthcheckservice]] service
	 *
	 * @autodoc true
	 *
	 */
	public void function $getHealthcheckService() {
		return $healthcheckService;
	}

	/**
	 * Returns whether or not the given healthcheck
	 * service is up (proxies to [[healthcheckservice-isup]])
	 *
	 * @autodoc   true
	 * @serviceid ID of the service to check
	 */
	public any function $isUp( required string serviceId ) {
		return $healthcheckService.isUp( argumentCollection=arguments );
	}

	/**
	 * Returns whether or not the given healthcheck
	 * service is down (proxies to [[healthcheckservice-isup]] and
	 * reverses the result)
	 *
	 * @autodoc   true
	 * @serviceid ID of the service to check
	 */
	public any function $isDown( required string serviceId ) {
		return !$healthcheckService.isUp( argumentCollection=arguments );
	}


}