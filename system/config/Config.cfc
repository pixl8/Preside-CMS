component {

// MAIN CONFIGURE() ENTRYPOINT
	public void function configure() {
		variables.settings = {};

		__setupEnvironmentVariables();
		__setupMappings();
		__setupExtensions();
		__setupEnvironments();
		__setupColdbox();
		__setupI18n();
		__setupInterceptors();
		__setupCachebox();
		__setupWirebox();
		__setupLogbox();
		__setupDatasource();
		__setupGlobalDataFilters();
		__setupAdminBehaviour();
		__setupAdminNavigation();
		__setupAdminRolesAndPermissions();
		__setupWebsiteUsers();
		__setupErrorPages();
		__setupUrlHandling();
		__setupAssetManager();
		__setupDataManagerDefaults();
		__setupEmailCenter();
		__setupRicheditor();
		__setupFormSettings();
		__setupWidgetsAndSiteTemplates();
		__setupFeatures();
		__setupDevConsole();
		__setupEnums();
		__setupFormValidationProviders();
		__setupStaticAssetConfiguration();
		__setupRequestSecurity();
		__setupRestFramework();
		__setupMultilingualDefaults();
		__setupFormBuilder();
		__setupRulesEngine();
		__setupTenancy();
		__setupDataExport();
		__setupFullPageCaching();
		__setupHeartbeatsAndServices();
		__setupNotifications();
		__setupIgnoreFile();
		__loadConfigurationFromExtensions();
	}

// ENVIRONMENT SPECIFIC
	public void function local() {
		settings.showErrors = true;
		settings.autoSyncDb = true;

		settings.features[ "devtools.new"       ].enabled = true;
		settings.features[ "devtools.extension" ].enabled = true;

		settings.ignoreFile.read  = false;
		settings.ignoreFile.write = true;

		settings.environmentBannerConfig = { icon="fa-code", cssClass="alert-info" };
	}

// SPECIFIC AREAS
	private void function __setupEnvironmentVariables() {
		settings.env = settings.injectedConfig = Duplicate( application.env ?: {} );
	}

	private void function __setupMappings() {
		settings.appMapping    = application.appMapping    = ( request._presideMappings.appMapping ?: "app" ).reReplace( "^/", "" );
		settings.assetsMapping = application.assetsMapping = request._presideMappings.assetsMapping ?: "/assets";
		settings.logsMapping   = application.logsMapping   = request._presideMappings.logsMapping   ?: "/logs";

		settings.appMappingPath    = application.appMappingPath    = Replace( settings.appMapping, "/", ".", "all" );
		settings.assetsMappingPath = application.assetsMappingPath = Replace( ReReplace( settings.assetsMapping, "^/", "" ), "/", ".", "all" );
		settings.logsMappingPath   = application.logsMappingPath   = Replace( ReReplace( settings.logsMapping  , "^/", "" ), "/", ".", "all" );
	}

	private void function __setupExtensions() {
		settings.legacyExtensionsNowInCore = [
			  "preside-ext-taskmanager"
			, "preside-ext-formbuilder"
			, "preside-ext-redirects"
			, "preside-ext-individual-filter"
			, "preside-ext-vips"
			, "preside-ext-db-perf-enhancements"
			, "preside-ext-email-log-performance"
		];

		settings.activeExtensions = application.activeExtensions = new preside.system.services.devtools.ExtensionManagerService(
			  appMapping       = settings.appMapping
			, ignoreExtensions = settings.legacyExtensionsNowInCore
		).listExtensions();
	}

	private void function __setupEnvironments() {
		variables.environments = {
			local = "^local\.,\.local(:[0-9]+)?$,^localhost(:[0-9]+)?$,^127.0.0.1(:[0-9]+)?$"
		};

		settings.environmentMessage      = "";
		settings.environmentBannerConfig = { icon="fa-desktop", cssClass="alert-danger", display=false };
	}

	private void function __setupColdbox() {
		var applicationSettings = getApplicationSettings();

		settings.disableMajorReloads = IsBoolean( settings.env.DISABLE_MAJOR_RELOADS ?: ""  ) && settings.env.DISABLE_MAJOR_RELOADS;

		variables.coldbox = {
			  appName                   = "Preside Website"
			, handlersIndexAutoReload   = false
			, debugMode                 = false
			, defaultEvent              = "general.index"
			, reinitPassword            = ( applicationSettings.COLDBOX_RELOAD_PASSWORD ?: "true" )
			, handlerCaching            = true
			, eventCaching              = true
			, requestContextDecorator   = "preside.system.coldboxModifications.RequestContextDecorator"
			, applicationHelper         = _getUdfFiles()
			, pluginsExternalLocation   = "preside.system.plugins"
			, viewsExternalLocation     = "/preside/system/views"
			, layoutsExternalLocation   = "/preside/system/layouts"
			, modulesExternalLocation   = [ "/app/extensions_app", "/app/extensions", "/preside/system/modules" ]
			, handlersExternalLocation  = "preside.system.handlers"
			, applicationStartHandler   = "General.applicationStart"
			, applicationEndHandler     = "General.applicationEnd"
			, requestStartHandler       = "General.requestStart"
			, requestEndHandler         = "General.requestEnd"
			, missingTemplateHandler    = "General.notFound"
			, onInvalidEvent            = "General.notFound"
			, coldboxExtensionsLocation = "preside.system.coldboxModifications"
			, customErrorTemplate       = "/preside/system/coldboxModifications/includes/errorReport.cfm"
		};

		settings.coldboxVersion = _calculateColdboxVersion();
		settings.eventName      = "event";
	}

	private void function __setupI18n() {
		variables.i18n = {
			  defaultLocale      = "en"
			, localeStorage      = "cookie"
			, unknownTranslation = "**NOT FOUND**"
		};

		settings.adminLanguages = [];
	}

	private void function __setupInterceptors() {
		variables.interceptors = [
			{ class="preside.system.interceptors.ApplicationReloadInterceptor"        , properties={} },
			{ class="preside.system.interceptors.CsrfProtectionInterceptor"           , properties={} },
			{ class="preside.system.interceptors.PageTypesPresideObjectInterceptor"   , properties={} },
			{ class="preside.system.interceptors.TenancyPresideObjectInterceptor"     , properties={} },
			{ class="preside.system.interceptors.MultiLingualPresideObjectInterceptor", properties={} },
			{ class="preside.system.interceptors.AdminLayoutInterceptor"              , properties={} },
			{ class="preside.system.interceptors.WebsiteUserImpersonationInterceptor" , properties={} },
			{ class="preside.system.interceptors.ScheduledExportDownloadInterceptor"  , properties={} },
			{ class="preside.system.interceptors.FormBuilderInterceptor"              , properties={} },
		];

		variables.interceptorSettings = {
			  throwOnInvalidStates     = false
			, customInterceptionPoints = []
		};

		interceptorSettings.customInterceptionPoints.append( "prePresideReload"                      );
		interceptorSettings.customInterceptionPoints.append( "postPresideReload"                     );
		interceptorSettings.customInterceptionPoints.append( "onBuildLink"                           );
		interceptorSettings.customInterceptionPoints.append( "onCreateSelectDataCacheKey"            );
		interceptorSettings.customInterceptionPoints.append( "postDbSyncObjects"                     );
		interceptorSettings.customInterceptionPoints.append( "postDeleteObjectData"                  );
		interceptorSettings.customInterceptionPoints.append( "postInsertObjectData"                  );
		interceptorSettings.customInterceptionPoints.append( "postLoadPresideObject"                 );
		interceptorSettings.customInterceptionPoints.append( "postLoadPresideObjects"                );
		interceptorSettings.customInterceptionPoints.append( "postPrepareObjectFilter"               );
		interceptorSettings.customInterceptionPoints.append( "postReadPresideObject"                 );
		interceptorSettings.customInterceptionPoints.append( "postReadPresideObjects"                );
		interceptorSettings.customInterceptionPoints.append( "postRenderSiteTreePage"                );
		interceptorSettings.customInterceptionPoints.append( "postAddSiteTreePage"                   );
		interceptorSettings.customInterceptionPoints.append( "postEditSiteTreePage"                  );
		interceptorSettings.customInterceptionPoints.append( "postSelectObjectData"                  );
		interceptorSettings.customInterceptionPoints.append( "postUpdateObjectData"                  );
		interceptorSettings.customInterceptionPoints.append( "postParseSelectFields"                 );
		interceptorSettings.customInterceptionPoints.append( "postPrepareTableJoins"                 );
		interceptorSettings.customInterceptionPoints.append( "postPrepareVersionSelect"              );
		interceptorSettings.customInterceptionPoints.append( "preDbSyncObjects"                      );
		interceptorSettings.customInterceptionPoints.append( "preDeleteObjectData"                   );
		interceptorSettings.customInterceptionPoints.append( "preInsertObjectData"                   );
		interceptorSettings.customInterceptionPoints.append( "preLoadPresideObject"                  );
		interceptorSettings.customInterceptionPoints.append( "preLoadPresideObjects"                 );
		interceptorSettings.customInterceptionPoints.append( "prePrepareObjectFilter"                );
		interceptorSettings.customInterceptionPoints.append( "preReadPresideObject"                  );
		interceptorSettings.customInterceptionPoints.append( "preRenderSiteTreePage"                 );
		interceptorSettings.customInterceptionPoints.append( "postInitializePresideSiteteePage"      );
		interceptorSettings.customInterceptionPoints.append( "postInitializeDummyPresideSiteTreePage");
		interceptorSettings.customInterceptionPoints.append( "preSelectObjectData"                   );
		interceptorSettings.customInterceptionPoints.append( "preUpdateObjectData"                   );
		interceptorSettings.customInterceptionPoints.append( "preParseSelectFields"                  );
		interceptorSettings.customInterceptionPoints.append( "onApplicationStart"                    );
		interceptorSettings.customInterceptionPoints.append( "onApplicationEnd"                      );
		interceptorSettings.customInterceptionPoints.append( "onCreateNotification"                  );
		interceptorSettings.customInterceptionPoints.append( "preCreateNotification"                 );
		interceptorSettings.customInterceptionPoints.append( "postCreateNotification"                );
		interceptorSettings.customInterceptionPoints.append( "preCreateNotificationConsumer"         );
		interceptorSettings.customInterceptionPoints.append( "postCreateNotificationConsumer"        );
		interceptorSettings.customInterceptionPoints.append( "preAttemptLogin"                       );
		interceptorSettings.customInterceptionPoints.append( "onLoginSuccess"                        );
		interceptorSettings.customInterceptionPoints.append( "onLoginFailure"                        );
		interceptorSettings.customInterceptionPoints.append( "onLogout"                              );
		interceptorSettings.customInterceptionPoints.append( "onAdminLoginSuccess"                   );
		interceptorSettings.customInterceptionPoints.append( "onAdminLoginFailure"                   );
		interceptorSettings.customInterceptionPoints.append( "preDownloadFile"                       );
		interceptorSettings.customInterceptionPoints.append( "onDownloadFile"                        );
		interceptorSettings.customInterceptionPoints.append( "onReturnFile304"                       );
		interceptorSettings.customInterceptionPoints.append( "preDownloadAsset"                      );
		interceptorSettings.customInterceptionPoints.append( "onDownloadAsset"                       );
		interceptorSettings.customInterceptionPoints.append( "postReadRestResourceDirectories"       );
		interceptorSettings.customInterceptionPoints.append( "onRestRequest"                         );
		interceptorSettings.customInterceptionPoints.append( "onRestError"                           );
		interceptorSettings.customInterceptionPoints.append( "onMissingRestResource"                 );
		interceptorSettings.customInterceptionPoints.append( "onUnsupportedRestMethod"               );
		interceptorSettings.customInterceptionPoints.append( "preInvokeRestResource"                 );
		interceptorSettings.customInterceptionPoints.append( "postInvokeRestResource"                );
		interceptorSettings.customInterceptionPoints.append( "onRestRequestParameterValidationError" );
		interceptorSettings.customInterceptionPoints.append( "preFormBuilderFormSubmission"          );
		interceptorSettings.customInterceptionPoints.append( "postFormBuilderFormSubmission"         );
		interceptorSettings.customInterceptionPoints.append( "preSaveFormbuilderQuestionResponse"    );
		interceptorSettings.customInterceptionPoints.append( "onReloadConfigCategories"              );
		interceptorSettings.customInterceptionPoints.append( "preSaveSystemConfig"                   );
		interceptorSettings.customInterceptionPoints.append( "postSaveSystemConfig"                  );
		interceptorSettings.customInterceptionPoints.append( "preSetUserSession"                     );
		interceptorSettings.customInterceptionPoints.append( "prePresideRequestCapture"              );
		interceptorSettings.customInterceptionPoints.append( "postPresideRequestCapture"             );
		interceptorSettings.customInterceptionPoints.append( "onPresideDetectIncomingSite"           );
		interceptorSettings.customInterceptionPoints.append( "onPresideDetectLanguage"               );
		interceptorSettings.customInterceptionPoints.append( "onPresideUrlRedirects"                 );
		interceptorSettings.customInterceptionPoints.append( "onPresideRedirectDomains"              );
		interceptorSettings.customInterceptionPoints.append( "preRoutePresideSESRequest"             );
		interceptorSettings.customInterceptionPoints.append( "postRoutePresideSESRequest"            );
		interceptorSettings.customInterceptionPoints.append( "onGetEmailContextPayload"              );
		interceptorSettings.customInterceptionPoints.append( "onAccessDenied"                        );
		interceptorSettings.customInterceptionPoints.append( "onNotFound"                            );
		interceptorSettings.customInterceptionPoints.append( "onReturnAsset304"                      );
		interceptorSettings.customInterceptionPoints.append( "onPrepareEmailSendArguments"           );
		interceptorSettings.customInterceptionPoints.append( "onPrepareEmailTemplateRecipientFilters");
		interceptorSettings.customInterceptionPoints.append( "preRenderEmailTemplateSettingsForm"    );
		interceptorSettings.customInterceptionPoints.append( "preRenderEmailTemplateNotices"         );
		interceptorSettings.customInterceptionPoints.append( "preRenderEmailTemplateActions"         );
		interceptorSettings.customInterceptionPoints.append( "preSendEmail"                          );
		interceptorSettings.customInterceptionPoints.append( "postSendEmail"                         );
		interceptorSettings.customInterceptionPoints.append( "preDataExportPrepareData"              );
		interceptorSettings.customInterceptionPoints.append( "postDataExportPrepareData"             );
		interceptorSettings.customInterceptionPoints.append( "preClearRelatedCaches"                 );
		interceptorSettings.customInterceptionPoints.append( "postClearRelatedCaches"                );
		interceptorSettings.customInterceptionPoints.append( "onClearSettingsCache"                  );
		interceptorSettings.customInterceptionPoints.append( "onClearCaches"                         );
		interceptorSettings.customInterceptionPoints.append( "onClearPageCaches"                     );
		interceptorSettings.customInterceptionPoints.append( "onInvalidateRenderedAssetCache"        );
		interceptorSettings.customInterceptionPoints.append( "preRenderForm"                         );
		interceptorSettings.customInterceptionPoints.append( "postRenderForm"                        );
		interceptorSettings.customInterceptionPoints.append( "prePrepareEmailMessage"                );
		interceptorSettings.customInterceptionPoints.append( "postPrepareEmailMessage"               );
		interceptorSettings.customInterceptionPoints.append( "preRenderEmailLayout"                  );
		interceptorSettings.customInterceptionPoints.append( "postRenderEmailLayout"                 );
		interceptorSettings.customInterceptionPoints.append( "prePrepareEmailParameters"             );
		interceptorSettings.customInterceptionPoints.append( "postPrepareEmailParameters"            );
		interceptorSettings.customInterceptionPoints.append( "prePrepareEmailPreviewParameters"      );
		interceptorSettings.customInterceptionPoints.append( "postPrepareEmailPreviewParameters"     );
		interceptorSettings.customInterceptionPoints.append( "preRenderContent"                      );
		interceptorSettings.customInterceptionPoints.append( "postRenderContent"                     );
		interceptorSettings.customInterceptionPoints.append( "onGenerateEmailUnsubscribeLink"        );
		interceptorSettings.customInterceptionPoints.append( "onEmailSend"                           );
		interceptorSettings.customInterceptionPoints.append( "onEmailFail"                           );
		interceptorSettings.customInterceptionPoints.append( "onEmailOpen"                           );
		interceptorSettings.customInterceptionPoints.append( "onEmailMarkAsSpam"                     );
		interceptorSettings.customInterceptionPoints.append( "onEmailUnsubscribe"                    );
		interceptorSettings.customInterceptionPoints.append( "onEmailDeliver"                        );
		interceptorSettings.customInterceptionPoints.append( "onEmailClick"                          );
		interceptorSettings.customInterceptionPoints.append( "onEmailResend"                         );
		interceptorSettings.customInterceptionPoints.append( "onDetectEmailEventBot"                 );
		interceptorSettings.customInterceptionPoints.append( "postExtraTopRightButtonsForObject"     );
		interceptorSettings.customInterceptionPoints.append( "postGetExtraQsForBuildAjaxListingLink" );
		interceptorSettings.customInterceptionPoints.append( "postExtraRecordActionsForGridListing"  );
		interceptorSettings.customInterceptionPoints.append( "onGetListingBatchActions"              );
		interceptorSettings.customInterceptionPoints.append( "postGetExtraListingMultiActions"       );
		interceptorSettings.customInterceptionPoints.append( "postGetExtraAddRecordActionButtons"    );
		interceptorSettings.customInterceptionPoints.append( "postExtraTopRightButtonsForAddRecord"  );
		interceptorSettings.customInterceptionPoints.append( "postExtraTopRightButtonsForViewRecord" );
		interceptorSettings.customInterceptionPoints.append( "postGetExtraEditRecordActionButtons"   );
		interceptorSettings.customInterceptionPoints.append( "postExtraTopRightButtonsForEditRecord" );
		interceptorSettings.customInterceptionPoints.append( "postGetExtraCloneRecordActionButtons"  );
		interceptorSettings.customInterceptionPoints.append( "postExtraTopRightButtons"              );
		interceptorSettings.customInterceptionPoints.append( "preValidateForm"		                 );
		interceptorSettings.customInterceptionPoints.append( "preRenderLabelSelectData"		         );
		interceptorSettings.customInterceptionPoints.append( "preObjectPickerSelectData"	         );
		interceptorSettings.customInterceptionPoints.append( "preGetObjectRecordsForAjaxSelectControlSelect" );
		interceptorSettings.customInterceptionPoints.append( "preRulesForField"                      );
		interceptorSettings.customInterceptionPoints.append( "postRulesForField"                     );
		interceptorSettings.customInterceptionPoints.append( "preRenderDataManagerObjectInfoCard"    );
		interceptorSettings.customInterceptionPoints.append( "preRenderDataManagerObjectTabs"        );
		interceptorSettings.customInterceptionPoints.append( "postPrepareDevToolsVersions"           );
		interceptorSettings.customInterceptionPoints.append( "postRenderDelayedViewlets"             );
		interceptorSettings.customInterceptionPoints.append( "preRunCustomization"                   );
		interceptorSettings.customInterceptionPoints.append( "postRunCustomization"                  );
		interceptorSettings.customInterceptionPoints.append( "onEmailTemplateGetAdditionalQueryStringForBuildAjaxListingLink" );
		interceptorSettings.customInterceptionPoints.append( "onEmailTemplatePreFetchRecordsForGridListing" );
	}

	private void function __setupCachebox() {
		variables.cacheBox = { configFile=_discoverCacheboxConfigurator() };
	}

	private void function __setupWirebox() {
		variables.wirebox = {
			  singletonReload = false
			, binder          = _discoverWireboxBinder()
		};
	}

	private void function __setupLogbox() {
		variables.logbox = {
			appenders = {
				defaultLogAppender = {
					  class      = 'coldbox.system.logging.appenders.RollingFileAppender'
					, properties = { filePath=settings.logsMapping, filename="coldbox.log", async=true }
				},
				taskManagerRequestAppender = {
					  class      = 'preside.system.services.logger.TaskManagerLogAppender'
					, properties = { logName="TASKMANAGER" }
				},
				adhocTaskManagerAppender = {
					  class      = 'preside.system.services.logger.AdhocTaskManagerLogAppender'
					, properties = { logName="ADHOCTASKMANAGER" }
				}
			},
			root = { appenders='defaultLogAppender', levelMin='FATAL', levelMax='WARN' },
			categories = {
				taskManager      = { appenders='taskManagerRequestAppender', levelMin='FATAL', levelMax='INFO' },
				adhocTaskManager = { appenders='adhocTaskmanagerAppender'  , levelMin='FATAL', levelMax='INFO' }
			}
		};
	}

	private void function __setupAdminBehaviour() {
		settings.adminDefaultEvent           = "sitetree";
		settings.adminNotificationsSticky    = true;
		settings.adminNotificationsPosition  = "bottom-right";
		settings.preside_admin_path          = "admin";
		settings.presideHelpAndSupportLink   = "http://www.pixl8.co.uk";
		settings.system_users                = "sysadmin";
		settings.updateRepositoryUrl         = "http://downloads.presidecms.com.s3.amazonaws.com"; // deprecated
		settings.notificationTopics          = [];
		settings.notificationCountLimit      = 100;
		settings.showNonLiveContentByDefault = true;
		settings.adminLoginProviders         = [ "preside" ];
	}

	private void function __setupAdminNavigation() {
		settings.adminApplications = [ {
			  id                 = "cms"
			, feature            = "cms"
			, defaultEvent       = "admin.sitetree"
			, accessPermission   = "cms.access"
			, activeEventPattern = "admin\..*"
			, layout             = "admin"
		} ];

		settings.adminSideBarItems = [
			  "sitetree"
			, "assetmanager"
			, "datamanager"
			, "websiteUserManager"
			, "formbuilder"
			, "emailcenter"
		];

		settings.adminConfigurationMenuItems = [
			  "usermanager"
			, "usergroupmanager"
			, "notification"
			, "passwordPolicyManager"
			, "systemConfiguration"
			, "rulesEngine"
			, "links"
			, "urlRedirects"
			, "errorLogs"
			, "auditTrail"
			, "maintenanceMode"
			, "taskmanager"
			, "savedexport"
			, "apiManager"
			, "systemInformation"
		];

		settings.adminMenuItems = {};
		settings.adminMenuItems.sitetree = {
			  feature       = "sitetree"
			, permissionKey = "sitetree.navigate"
			, activeChecks  = { handlerPatterns="^admin\.sitetree\.*" }
			, buildLinkArgs = { linkTo="sitetree" }
			, gotoKey       = "s"
			, icon          = "fa-sitemap"
			, title         = "cms:sitetree"
		};
		settings.adminMenuItems.assetManager = {
			  feature       = "assetManager"
			, permissionKey = "assetmanager.general.navigate"
			, activeChecks  = { handlerPatterns="^admin\.assetmanager\.*" }
			, buildLinkArgs = { linkTo="assetmanager" }
			, gotoKey       = "a"
			, icon          = "fa-picture-o"
			, title         = "cms:assetManager"
		};
		settings.adminMenuItems.datamanager = {
			  feature       = "datamanager"
			, permissionKey = "datamanager.navigate"
			, buildLinkArgs = { linkTo="datamanager" }
			, gotoKey       = "d"
			, icon          = "fa-database"
			, title         = "cms:datamanager"
		};
		settings.adminMenuItems.emailCenter = {
			  feature      = "emailcenter"
			, activeChecks = { handlerPatterns="^admin\.emailcenter\." }
			, icon         = "fa-envelope"
			, title        = "cms:emailCenter.menu.title"
			, subMenuItems = [
			      "emailCenterCustomTemplates"
			    , "emailCenterSystemTemplates"
			    , "-"
			    , "emailCenterLayouts"
			    , "emailCenterBlueprints"
			    , "-"
			    , "emailCenterSettings"
			    , "emailCenterLogs"
			    , "emailCenterQueue"
			  ]
		};
		settings.adminMenuItems.emailCenterCustomTemplates = {
			  feature       = "customEmailTemplates"
			, permissionKey = "emailcenter.customTemplates.navigate"
			, activeChecks  = { handlerPatterns="^admin\.emailcenter\.customTemplates" }
			, buildLinkArgs = { linkTo="emailcenter.customTemplates" }
			, title         = "cms:emailcenter.customTemplates.menu.title"
			, icon          = "fa-envelope"
		};
		settings.adminMenuItems.emailCenterSystemTemplates = {
			  feature       = "emailcenter"
			, permissionKey = "emailcenter.systemTemplates.navigate"
			, activeChecks  = { handlerPatterns="^admin\.emailcenter\.systemtemplates" }
			, buildLinkArgs = { linkTo="emailcenter.systemtemplates" }
			, title         = "cms:emailcenter.systemtemplates.menu.title"
			, icon          = "fa-envelope"
		};
		settings.adminMenuItems.emailCenterLayouts = {
			  feature       = "emailcenter"
			, permissionKey = "emailcenter.layouts.navigate"
			, activeChecks  = { handlerPatterns="^admin\.emailcenter\.layouts" }
			, buildLinkArgs = { linkTo="emailcenter.layouts" }
			, title         = "cms:emailcenter.layouts.menu.title"
			, icon          = "fa-trello"
		};
		settings.adminMenuItems.emailCenterBlueprints = {
			  feature       = "customEmailTemplates"
			, permissionKey = "emailcenter.blueprints.navigate"
			, activeChecks  = { handlerPatterns="^admin\.emailcenter\.blueprints" }
			, buildLinkArgs = { linkTo="emailcenter.blueprints" }
			, title         = "cms:emailcenter.blueprints.menu.title"
			, icon          = "fa-map"
		};
		settings.adminMenuItems.emailCenterSettings = {
			  feature       = "emailcenter"
			, permissionKey = "emailcenter.settings.navigate"
			, activeChecks  = { handlerPatterns="^admin\.emailcenter\.settings" }
			, buildLinkArgs = { linkTo="emailcenter.settings" }
			, title         = "cms:emailcenter.settings.menu.title"
			, icon          = "fa-cogs"
		};
		settings.adminMenuItems.emailCenterLogs = {
			  feature       = "emailcenter"
			, permissionKey = "emailcenter.logs.view"
			, activeChecks  = { handlerPatterns="^admin\.emailcenter\.logs" }
			, buildLinkArgs = { linkTo="emailcenter.logs" }
			, title         = "cms:emailcenter.logs.menu.title"
			, icon          = "fa-file-alt"
		};
		settings.adminMenuItems.emailCenterQueue = {
			  feature       = "customEmailTemplates"
			, permissionKey = "emailcenter.queue.view"
			, activeChecks  = { handlerPatterns="^admin\.emailcenter\.queue" }
			, buildLinkArgs = { linkTo="emailcenter.queue" }
			, title         = "cms:emailcenter.queue.menu.title"
			, icon          = "fa-layer-group"
		};

		settings.adminMenuItems.formbuilder = {
			  feature       = "formbuilder"
			, icon          = "fa-check-square-o"
			, title         = "formbuilder:admin.menu.title"
			, subMenuItems = [ "formbuilderQuestions", "formbuilderForms" ]
		};

		settings.adminMenuItems.formbuilderQuestions = {
			  feature       = "formbuilder2"
			, permissionKey = "formquestions.navigate"
			, activeChecks  = { datamanagerObject="formbuilder_question" }
			, buildLinkArgs = { objectName="formbuilder_question" }
			, title         = "formbuilder:questions.menu.title"
			, icon          = "fa-question"
		};
		settings.adminMenuItems.formbuilderForms = {
			  feature       = "formbuilder"
			, permissionKey = "formbuilder.navigate"
			, activeChecks  = { handlerPatterns="^admin\.formbuilder\." }
			, buildLinkArgs = { linkTo="formbuilder" }
			, title         = "formbuilder:forms.menu.title"
			, icon          = "fa-check-square-o"
			, gotoKey       = "f"
		}

		settings.adminMenuItems.websiteuserManager = {
			  feature      = "websiteUsers"
			, icon         = "fa-group"
			, title        = "cms:websiteUserManager"
			, subMenuItems = [ "websiteUsers", "websiteBenefits" ]
		};

		settings.adminMenuItems.websiteUsers = {
			  feature       = "websiteUsers"
			, permissionKey = "websiteUserManager.navigate"
			, activeChecks  = { handlerPatterns="^admin\.websiteUserManager\." }
			, buildLinkArgs = { linkTo="websiteUserManager" }
			, title         =  "cms:websiteUserManager.users"
			, icon          =  "fa-group"
		};
		settings.adminMenuItems.websiteBenefits = {
			  feature       = "websiteBenefits"
			, permissionKey = "websiteBenefitsManager.navigate"
			, activeChecks  = { handlerPatterns="^admin\.websiteBenefitsManager\." }
			, buildLinkArgs = { linkTo="websiteBenefitsManager" }
			, title         =  "cms:websiteUserManager.benefits"
			, icon          =  "fa-group"
		};

		settings.adminMenuItems.apiManager = {
			  feature       = "apiManager"
			, permissionKey = "apiManager.navigate"
			, buildLinkArgs = { linkTo="apiManager" }
			, activeChecks  = { handlerPatterns="^admin\.apiManager\." }
			, icon          = "fa-code"
			, title         = "cms:apiManager"
		};
		settings.adminMenuItems.auditTrail = {
			  feature       = "auditTrail"
			, permissionKey = "auditTrail.navigate"
			, buildLinkArgs = { linkTo="auditTrail" }
			, activeChecks  = { handlerPatterns="^admin\.auditTrail\." }
			, icon          = "fa-history"
			, title         = "cms:auditTrail"
		};
		settings.adminMenuItems.errorLogs = {
			  feature       = "errorLogs"
			, permissionKey = "errorLogs.navigate"
			, buildLinkArgs = { linkTo="errorLogs" }
			, activeChecks  = { handlerPatterns="^admin\.errorLogs\." }
			, icon          = "fa-exclamation-circle"
			, title         = "cms:errorLogs"
		};
		settings.adminMenuItems.links = {
			  buildLinkArgs = { objectName="link" }
			, activeChecks  = { datamanagerObject="link" }
			, icon          = "fa-link"
			, title         = "cms:links.navigation.link"
			, permissionKey = "presideobject.link.read"
			, feature       = "cms"
		};
		settings.adminMenuItems.maintenanceMode = {
			  permissionKey = "maintenanceMode.configure"
			, buildLinkArgs = { linkTo="maintenanceMode" }
			, activeChecks  = { handlerPatterns="^admin\.maintenanceMode\." }
			, feature       = "maintenanceMode"
			, icon          = "fa-medkit"
			, title         = "cms:maintenanceMode"
		};
		settings.adminMenuItems.notification = {
			  permissionKey = "notifications.configure"
			, buildLinkArgs = { linkTo="notifications.configure" }
			, activeChecks  = { handlerPatterns="^admin\.notifications\.configure" }
			, icon          = "fa-bell"
			, title         = "cms:notifications.system.menu.title"
		};
		settings.adminMenuItems.passwordPolicyManager = {
			  feature       = "passwordPolicyManager"
			, permissionKey = "passwordpolicymanager.manage"
			, buildLinkArgs = { linkTo="passwordpolicymanager" }
			, activeChecks  = { handlerPatterns="^admin\.passwordpolicymanager\." }
			, icon          = "fa-key"
			, title         = "cms:passwordpolicymanager.configmenu.title"
		};
		settings.adminMenuItems.rulesEngine = {
			  feature       = "rulesEngine"
			, permissionKey = "rulesEngine.navigate"
			, buildLinkArgs = { objectName="rules_engine_condition" }
			, activeChecks  = { datamanagerObject="rules_engine_condition" }
			, icon          = "fa-map-signs"
			, title         = "cms:rulesEngine.navigation.link"
		};
		settings.adminMenuItems.savedexport = {
			  feature       = "dataexport"
			, permissionKey = "savedExport.navigate"
			, buildLinkArgs = { objectName="saved_export" }
			, activeChecks  = { datamanagerObject="saved_export" }
			, icon          = "fa-download"
			, title         = "cms:savedexport"
		};
		settings.adminMenuItems.systemConfiguration = {
			  feature       = "systemConfiguration"
			, permissionKey = "systemConfiguration.manage"
			, buildLinkArgs = { linkTo="sysconfig" }
			, activeChecks  = { handlerPatterns="^admin\.sysconfig\." }
			, icon          = "fa-cogs"
			, title         = "cms:sysconfig.menu.title"
		};
		settings.adminMenuItems.systemInformation = {
			  feature       = "systemInformation"
			, permissionKey = "systemInformation.navigate"
			, buildLinkArgs = { linkTo="systemInformation" }
			, activeChecks  = { handlerPatterns="^admin\.systemInformation\." }
			, icon          = "fa-info-circle"
			, title         = "cms:systemInformation.menu.title"
		};
		settings.adminMenuItems.taskmanager = {
			  permissionKey = "taskmanager.navigate"
			, buildLinkArgs = { linkTo="taskmanager" }
			, activeChecks  = { handlerPatterns="^admin\.taskmanager\." }
			, icon          = "fa-clock-o"
			, title         = "cms:taskmanager"
		};
		settings.adminMenuItems.urlRedirects = {
			  feature       = "urlRedirects"
			, permissionKey = "urlRedirects.navigate"
			, buildLinkArgs = { linkTo="urlRedirects" }
			, activeChecks  = { handlerPatterns="^admin\.urlRedirects\." }
			, icon          = "fa-code-fork"
			, title         = "cms:urlRedirects.navigation.link"
		};
		settings.adminMenuItems.usermanager = {
			  feature       = "cmsUserManager"
			, permissionKey = "usermanager.navigate"
			, buildLinkArgs = { linkTo="usermanager.users" }
			, activeChecks  = { handlerPatterns="^admin\.usermanager\.users" }
			, icon          = "fa-user"
			, title         = "cms:usermanager.users"
		};
		settings.adminMenuItems.usergroupmanager = {
			  feature       = "cmsUserManager"
			, permissionKey = "groupmanager.navigate"
			, buildLinkArgs = { linkTo="usermanager.groups" }
			, activeChecks  = { handlerPatterns="^admin\.usermanager\.groups" }
			, icon          = "fa-group"
			, title         = "cms:usermanager.groups"
		};
	}

	private void function __setupAdminRolesAndPermissions() {
		settings.adminPermissions = {
			  cms                    = [ "access" ]
			, sitetree               = [ "navigate", "read", "add", "edit", "activate", "publish", "savedraft", "trash", "viewtrash", "emptytrash", "restore", "delete", "manageContextPerms", "viewversions", "sort", "translate", "clearcaches", "clone" ]
			, sites                  = [ "navigate", "manage", "translate" ]
			, datamanager            = [ "navigate", "read", "add", "edit","batchedit", "delete", "batchdelete", "manageContextPerms", "viewversions", "translate", "publish", "savedraft", "clone", "usefilters", "managefilters" ]
			, usermanager            = [ "navigate", "read", "add", "edit", "delete" ]
			, groupmanager           = [ "navigate", "read", "add", "edit", "delete" ]
			, passwordPolicyManager  = [ "manage" ]
			, websiteBenefitsManager = [ "navigate", "read", "add", "edit", "delete", "prioritize" ]
			, websiteUserManager     = [ "navigate", "read", "add", "edit", "delete", "prioritize", "impersonate" ]
			, devtools               = [ "console" ]
			, systemConfiguration    = [ "manage" ]
			, notifications          = [ "configure" ]
			, maintenanceMode        = [ "configure" ]
			, systemInformation      = [ "navigate" ]
			, urlRedirects           = [ "navigate", "read", "addRule", "editRule", "deleteRule" ]
			, formbuilder            = [ "navigate", "addform", "editform", "deleteForm" ,"lockForm", "activateForm", "deleteSubmissions", "editformactions" ]
			, formquestions          = [ "navigate", "read", "add", "edit", "delete", "batchdelete", "batchedit", "clone", "managefilters", "usefilters" ]
			, taskmanager            = [ "navigate", "run", "toggleactive", "viewlogs", "configure" ]
			, adhocTaskManager       = [ "navigate", "viewtask", "canceltask" ]
			, savedExport            = [ "navigate", "read", "add", "edit", "delete" ]
			, auditTrail             = [ "navigate" ]
			, rulesEngine            = [ "navigate", "read", "edit", "add", "delete", "clone", "unlock", "usefilters", "managefilters" ]
			, apiManager             = [ "navigate", "read", "add", "edit", "delete" ]
			, errorlogs              = [ "navigate" ]
			, emailCenter            = {
				  layouts          = [ "navigate", "configure" ]
				, customTemplates  = [ "navigate", "view", "add", "edit", "delete", "publish", "savedraft", "configureLayout", "editSendOptions", "send", "read", "cancelsend" ]
				, systemTemplates  = [ "navigate", "savedraft", "publish", "configurelayout" ]
				, serviceProviders = [ "manage" ]
				, settings         = [ "navigate", "manage", "resend" ]
				, blueprints       = [ "navigate", "add", "edit", "delete", "read", "configureLayout" ]
				, logs             = [ "view" ]
				, queue            = [ "view", "clear" ]
			  }
			, presideobject          = {
				  security_user  = [ "navigate", "read", "add", "edit", "delete", "viewversions" ]
				, security_group = [ "navigate", "read", "add", "edit", "delete", "viewversions" ]
				, system_alert   = [ "navigate", "read", "add", "edit", "delete", "viewversions" ]
				, page           = [ "navigate", "read", "add", "edit", "delete", "viewversions" ]
				, site           = [ "navigate", "read", "add", "edit", "delete", "viewversions" ]
				, asset          = [ "navigate", "read", "add", "edit", "delete", "viewversions" ]
				, asset_folder   = [ "navigate", "read", "add", "edit", "delete", "viewversions" ]
				, link           = [ "navigate", "read", "add", "edit", "delete", "viewversions" ]
			}
			, assetmanager           = {
				  general          = [ "navigate" ]
				, folders          = [ "add", "edit", "delete", "manageContextPerms" ]
				, assets           = [ "upload", "edit", "delete", "download", "pick", "translate" ]
				, storagelocations = [ "manage" ]
			 }
		};

		settings.adminRoles = StructNew( "linked" );

		settings.adminRoles.sysadmin           = [ "cms.access", "usermanager.*", "groupmanager.*", "systemConfiguration.*", "presideobject.system_alert.*", "presideobject.security_user.*", "presideobject.security_group.*", "websiteBenefitsManager.*", "websiteUserManager.*", "sites.*", "presideobject.links.*", "notifications.*", "passwordPolicyManager.*", "urlRedirects.*", "systemInformation.*", "taskmanager.navigate", "taskmanager.viewlogs", "auditTrail.*", "rulesEngine.*", "emailCenter.*", "!emailCenter.queue.*", "savedExport.*", "formbuilder.*", "formquestions.*" ];
		settings.adminRoles.contentadmin       = [ "cms.access", "sites.*", "presideobject.site.*", "presideobject.link.*", "sitetree.*", "presideobject.page.*", "datamanager.*", "assetmanager.*", "presideobject.asset.*", "presideobject.asset_folder.*", "formbuilder.*", "formquestions.*", "!formbuilder.lockForm", "!formbuilder.activateForm", "!formbuilder.deleteForm", "rulesEngine.read", "emailCenter.*", "!emailCenter.queue.*" ];
		settings.adminRoles.contenteditor      = [ "cms.access", "presideobject.link.*", "sites.navigate", "sitetree.*", "presideobject.page.*", "datamanager.*", "assetmanager.*", "presideobject.asset.*", "presideobject.asset_folder.*", "!*.delete", "!*.manageContextPerms", "!assetmanager.folders.add", "rulesEngine.read" ];
		settings.adminRoles.formbuildermanager = [ "cms.access", "formbuilder.*", "formquestions.*" ];
		settings.adminRoles.emailcentremanager = [ "cms.access", "emailCenter.*", "!emailCenter.queue.*" ];
		settings.adminRoles.rulesenginemanager = [ "cms.access", "rulesEngine.*" ];
		settings.adminRoles.savedExportManager = [ "cms.access", "savedExport.*" ];
		settings.adminRoles.savedExportAccess  = [ "cms.access", "savedExport.navigate", "savedExport.read" ];
	}

	private void function __setupWebsiteUsers() {
		settings.websitePermissions = {
			  pages  = [ "access" ]
			, assets = [ "access" ]
		};

		settings.websiteUsers = {
			actions = {
				  login       = [ "login", "autologin", "logout", "failedLogin", "sendPasswordResetInstructions", "changepassword" ]
				, request     = [ "pagevisit" ]
				, formbuilder = [ "submitform" ]
				, asset       = [ "download" ]
			}
		};
	}

	private void function __setupDatasource() {
		settings.dsn                         = "preside";
		settings.presideObjectsTablePrefix   = "pobj_";
		settings.syncDb                      = IsBoolean( settings.env.syncDb ?: ""  ) ? settings.env.syncDb : true;
		settings.autoSyncDb                  = IsBoolean( settings.env.autoSyncDb ?: ""  ) && settings.env.autoSyncDb;
		settings.throwOnLongTableName        = false;
		settings.autoRestoreDeprecatedFields = true;
		settings.useQueryCacheDefault        = true;
		settings.mssql = { useVarcharMaxForText = false }
		settings.datasourceConnection = {
			  retries      = Val( settings.env.DATASOURCE_CONNECTION_RETRIES     ?: 0   )
			, retryPause   = Val( settings.env.DATASOURCE_CONNECTION_RETRY_PAUSE ?: 100 )
			, failureRegex = settings.env.DATASOURCE_CONNECTION_FAILURE_REGEX ?: "Communications link failure"
		};

		settings.queryTimeout = {
			  default                 = Val( settings.env.QUERY_TIMEOUT ?: 0 )
			, backgroundThreadDefault = Val( settings.env.BACKGROUND_QUERY_TIMEOUT ?: ( settings.env.QUERY_TIMEOUT ?: 0 ) )
			, datamanagerRowCount     = Val( settings.env.DATAMANAGER_ROWCOUNT_QUERY_TIMEOUT ?: ( settings.env.QUERY_TIMEOUT ?: 3 ) )
		};
	}

	private void function __setupGlobalDataFilters() {
		settings.filters = {
			livePages = function(){
				var nowish = DateTimeFormat( Now(), "yyyy-mm-dd HH:nn:00" );
				var sql    = "page.trashed = '0' and page.active = '1' and ( page.embargo_date is null or :now >= page.embargo_date ) and ( page.expiry_date is null or :now <= page.expiry_date )";
				var params = { "now" = { type="cf_sql_timestamp", value=nowish } };

				return { filter=sql, filterParams=params };
			}
			, nonDeletedSites = { filter="site.deleted is null or site.deleted = :site.deleted", filterParams={ "site.deleted"=false } }
			, activeFormbuilderForms = { filter = { "formbuilder_form.active" = true } }
			, webUserEmailTemplates = {
				  filter       = "email_template.recipient_type = :email_template.recipient_type or ( email_template.recipient_type is null and email_blueprint.recipient_type = :email_template.recipient_type )"
				, filterParams = { "email_template.recipient_type" = "websiteUser" }
			  }
		};
	}

	private void function __setupErrorPages() {
		settings.notFoundLayout         = "Main";
		settings.notFoundViewlet        = "errors.notFound";
		settings.accessDeniedLayout     = "Main";
		settings.accessDeniedViewlet    = "errors.accessDenied";
		settings.serverErrorLayout      = "Main";
		settings.serverErrorViewlet     = "errors.serverError";
		settings.maintenanceModeViewlet = "errors.maintenanceMode";
	}

	private void function __setupUrlHandling() {
		// URL handling and domains generally an editorial concern.
		// these settings useful for Preside applications that are fixed
		// admin applications with the 'site' feature disabled
		settings.forceSsl       = IsBoolean( settings.env.forceSsl ?: "" ) && settings.env.forceSsl;
		settings.allowedDomains = ListToArray( LCase( settings.env.allowedDomains  ?: "" ) );
		settings.defaultSiteProtocol = settings.defaultSiteProtocol ?: ( settings.env.DEFAULT_SITE_PROTOCOL ?: _getCurrentProtocol() );
	}

	private void function __setupAssetManager() {
		settings.uploads_directory = ExpandPath( "/uploads" );
		settings.storageProviders = { filesystem = { class="preside.system.services.fileStorage.fileSystemStorageProvider" } };
		settings.assetManager = {
			  maxFileSize = "5"
			, derivativeLimits = { maxHeight=0, maxWidth=0, maxResolution=0, tooBigPlaceholder="/preside/system/assets/images/placeholders/largeimage.jpg" }
			, types       = _getConfiguredFileTypes()
			, derivatives = _getConfiguredAssetDerivatives()
			, datatable   = { paginationOptions=[ 5, 10, 25, 50, 100 ], defaultPageLength=10 }
			, queue       = { concurrency=1, batchSize=100, downloadWaitSeconds=5 }
			, folders     = {}
			, vips        = {
				  binDir  = settings.env.VIPS_BINDIR ?: "/usr/bin"
				, timeout = Val( settings.env.VIPS_TIMEOUT ?: 60 )
			  }
			, storage     = {
				  public    = ( settings.env[ "assetmanager.storage.public"    ] ?: settings.uploads_directory & "/assets" )
				, private   = ( settings.env[ "assetmanager.storage.private"   ] ?: settings.uploads_directory & "/assets" ) // same as public by default for backward compatibility
				, trash     = ( settings.env[ "assetmanager.storage.trash"     ] ?: settings.uploads_directory & "/.trash" )
				, publicUrl = ( settings.env[ "assetmanager.storage.publicUrl" ] ?: "" )
			  }
			, cacheExpiry = {
				  public  = Val( settings.env.ASSET_CACHE_EXPIRY_PUBLIC  ?: 31536000 ) // one year
				, private = Val( settings.env.ASSET_CACHE_EXPIRY_PRIVATE ?: 86400    ) // one day
			  }
		};
		settings.assetManager.allowedExtensions = _typesToExtensions( settings.assetManager.types );
		settings.assetManager.types.document.append( { tiff = { serveAsAttachment = true, mimeType="image/tiff" } } );
	}

	private void function __setupDataManagerDefaults() {
		settings.dataManager = {};
		settings.dataManager.defaults = {};
		settings.dataManager.defaults.typeToConfirmDelete      = false;
		settings.dataManager.defaults.typeToConfirmBatchDelete = true;
		settings.dataManager.defaults.datatable = {}
		settings.dataManager.defaults.datatable.paginationOptions = [ 5, 10, 25, 50, 100 ];
		settings.dataManager.defaults.datatable.defaultPageLength = 10;
	}

	private void function __setupEmailCenter() {
		settings.email = _getEmailSettings(); // seems silly, but need to keep this for backward compat
		settings.email.smtp = {};
		settings.email.smtp.async = IsBoolean( settings.env.SMTP_ASYNC ?: "" ) ? settings.env.SMTP_ASYNC : true;
		settings.email.botDetection = {
			  userAgents              = [ "(bot\b|crawler\b|spider\b|80legs|ia_archiver|voyager|curl|wget|wget|python|yahoo! slurp|mediapartners-google)", "Microsoft Outlook", "ms-office", "googleimageproxy", "thunderbird", "healthcheck", "zabbix", "kube-probe" ]
			, tooManyClicksCount      = 10
			, tooManyClicksSeconds    = 10
			, honeyPotTimezoneSeconds = 10
		};
	}

	private void function __setupRicheditor() {
		settings.ckeditor = {};

		settings.ckeditor.defaults = {
			  stylesheets           = [ "/css/admin/specific/richeditor/" ]
			, width                 = "auto"
			, minHeight             = 0
			, maxHeight             = 300
			, autoParagraph         = false
			, configFile            = "/ckeditorExtensions/config.js?v=$RELEASE_VERSION"
			, defaultConfigs        = {
				  pasteFromWordPromptCleanup      = true
				, codeSnippet_theme               = "atelier-dune.dark"
				, skin                            = "bootstrapck"
				, format_tags                     = 'p;h1;h2;h3;h4;h5;h6;pre;div'
				, autoGrow_onStartup              = true
				, emailProtection                 = 'encode'
				, removePlugins                   = 'iframe,wsc,scayt'
				, disallowedContent               = 'font; *[align,contenteditable]; *{line-height,margin*}'
				, scayt_sLang                     = "en_GB"
				, pasteFromWordDisallow           = [
					  "span"  // Strip all span elements
					, "*(*)"  // Strip all classes
					, "*{*}"  // Strip all inline-styles
				]
				, extraAllowedContent   = "img dl dt dd"
				, stylesSet = []
				, stylesheetParser_validSelectors = "^(h[1-6]|p|span|pre|li|ul|ol|dl|dt|dd|small|i|b|em|strong|table)\.\w+"
			}
		};
		settings.ckeditor.linkPicker = _getRicheditorLinkPickerConfig();
		settings.ckeditor.toolbars   = _getCkEditorToolbarConfig();
	}

	private void function __setupFormSettings() {
		settings.formControls            = {};
		settings.autoTrimFormSubmissions = { admin=false, frontend=false };

		settings.formControls.iconPicker.icons = [ "500px", "accessible-icon", "accusoft", "acquisitions-incorporated", "ad", "address-book", "address-card", "adjust", "adn", "adobe", "adversal", "affiliatetheme", "air-freshener", "airbnb", "algolia", "align-center", "align-justify", "align-left", "align-right", "alipay", "allergies", "amazon", "amazon-pay", "ambulance", "american-sign-language-interpreting", "amilia", "anchor", "android", "angellist", "angle-double-down", "angle-double-left", "angle-double-right", "angle-double-up", "angle-down", "angle-left", "angle-right", "angle-up", "angry", "angrycreative", "angular", "ankh", "app-store", "app-store-ios", "apper", "apple", "apple-alt", "apple-pay", "archive", "archway", "arrow-alt-circle-down", "arrow-alt-circle-left", "arrow-alt-circle-right", "arrow-alt-circle-up", "arrow-circle-down", "arrow-circle-left", "arrow-circle-right", "arrow-circle-up", "arrow-down", "arrow-left", "arrow-right", "arrow-up", "arrows-alt", "arrows-alt-h", "arrows-alt-v", "artstation", "assistive-listening-systems", "asterisk", "asymmetrik", "at", "atlas", "atlassian", "atom", "audible", "audio-description", "autoprefixer", "avianex", "aviato", "award", "aws", "baby", "baby-carriage", "backspace", "backward", "bacon", "balance-scale", "balance-scale-left", "balance-scale-right", "ban", "band-aid", "bandcamp", "barcode", "bars", "baseball-ball", "basketball-ball", "bath", "battery-empty", "battery-full", "battery-half", "battery-quarter", "battery-three-quarters", "battle-net", "bed", "beer", "behance", "behance-square", "bell", "bell-slash", "bezier-curve", "bible", "bicycle", "biking", "bimobject", "binoculars", "biohazard", "birthday-cake", "bitbucket", "bitcoin", "bity", "black-tie", "blackberry", "blender", "blender-phone", "blind", "blog", "blogger", "blogger-b", "bluetooth", "bluetooth-b", "bold", "bolt", "bomb", "bone", "bong", "book", "book-dead", "book-medical", "book-open", "book-reader", "bookmark", "bootstrap", "border-all", "border-none", "border-style", "bowling-ball", "box", "box-open", "boxes", "braille", "brain", "bread-slice", "briefcase", "briefcase-medical", "broadcast-tower", "broom", "brush", "btc", "buffer", "bug", "building", "bullhorn", "bullseye", "burn", "buromobelexperte", "bus", "bus-alt", "business-time", "buysellads", "calculator", "calendar", "calendar-alt", "calendar-check", "calendar-day", "calendar-minus", "calendar-plus", "calendar-times", "calendar-week", "camera", "camera-retro", "campground", "canadian-maple-leaf", "candy-cane", "cannabis", "capsules", "car", "car-alt", "car-battery", "car-crash", "car-side", "caret-down", "caret-left", "caret-right", "caret-square-down", "caret-square-left", "caret-square-right", "caret-square-up", "caret-up", "carrot", "cart-arrow-down", "cart-plus", "cash-register", "cat", "cc-amazon-pay", "cc-amex", "cc-apple-pay", "cc-diners-club", "cc-discover", "cc-jcb", "cc-mastercard", "cc-paypal", "cc-stripe", "cc-visa", "centercode", "centos", "certificate", "chair", "chalkboard", "chalkboard-teacher", "charging-station", "chart-area", "chart-bar", "chart-line", "chart-pie", "check", "check-circle", "check-double", "check-square", "cheese", "chess", "chess-bishop", "chess-board", "chess-king", "chess-knight", "chess-pawn", "chess-queen", "chess-rook", "chevron-circle-down", "chevron-circle-left", "chevron-circle-right", "chevron-circle-up", "chevron-down", "chevron-left", "chevron-right", "chevron-up", "child", "chrome", "chromecast", "church", "circle", "circle-notch", "city", "clinic-medical", "clipboard", "clipboard-check", "clipboard-list", "clock", "clone", "closed-captioning", "cloud", "cloud-download-alt", "cloud-meatball", "cloud-moon", "cloud-moon-rain", "cloud-rain", "cloud-showers-heavy", "cloud-sun", "cloud-sun-rain", "cloud-upload-alt", "cloudscale", "cloudsmith", "cloudversify", "cocktail", "code", "code-branch", "codepen", "codiepie", "coffee", "cog", "cogs", "coins", "columns", "comment", "comment-alt", "comment-dollar", "comment-dots", "comment-medical", "comment-slash", "comments", "comments-dollar", "compact-disc", "compass", "compress", "compress-arrows-alt", "concierge-bell", "confluence", "connectdevelop", "contao", "cookie", "cookie-bite", "copy", "copyright", "cotton-bureau", "couch", "cpanel", "creative-commons", "creative-commons-by", "creative-commons-nc", "creative-commons-nc-eu", "creative-commons-nc-jp", "creative-commons-nd", "creative-commons-pd", "creative-commons-pd-alt", "creative-commons-remix", "creative-commons-sa", "creative-commons-sampling", "creative-commons-sampling-plus", "creative-commons-share", "creative-commons-zero", "credit-card", "critical-role", "crop", "crop-alt", "cross", "crosshairs", "crow", "crown", "crutch", "css3", "css3-alt", "cube", "cubes", "cut", "cuttlefish", "d-and-d", "d-and-d-beyond", "dashcube", "database", "deaf", "delicious", "democrat", "deploydog", "deskpro", "desktop", "dev", "deviantart", "dharmachakra", "dhl", "diagnoses", "diaspora", "dice", "dice-d20", "dice-d6", "dice-five", "dice-four", "dice-one", "dice-six", "dice-three", "dice-two", "digg", "digital-ocean", "digital-tachograph", "directions", "discord", "discourse", "divide", "dizzy", "dna", "dochub", "docker", "dog", "dollar-sign", "dolly", "dolly-flatbed", "donate", "door-closed", "door-open", "dot-circle", "dove", "download", "draft2digital", "drafting-compass", "dragon", "draw-polygon", "dribbble", "dribbble-square", "dropbox", "drum", "drum-steelpan", "drumstick-bite", "drupal", "dumbbell", "dumpster", "dumpster-fire", "dungeon", "dyalog", "earlybirds", "ebay", "edge", "edit", "egg", "eject", "elementor", "ellipsis-h", "ellipsis-v", "ello", "ember", "empire", "envelope", "envelope-open", "envelope-open-text", "envelope-square", "envira", "equals", "eraser", "erlang", "ethereum", "ethernet", "etsy", "euro-sign", "evernote", "exchange-alt", "exclamation", "exclamation-circle", "exclamation-triangle", "expand", "expand-arrows-alt", "expeditedssl", "external-link-alt", "external-link-square-alt", "eye", "eye-dropper", "eye-slash", "facebook", "facebook-f", "facebook-messenger", "facebook-square", "fan", "fantasy-flight-games", "fast-backward", "fast-forward", "fax", "feather", "feather-alt", "fedex", "fedora", "female", "fighter-jet", "figma", "file", "file-alt", "file-archive", "file-audio", "file-code", "file-contract", "file-csv", "file-download", "file-excel", "file-export", "file-image", "file-import", "file-invoice", "file-invoice-dollar", "file-medical", "file-medical-alt", "file-pdf", "file-powerpoint", "file-prescription", "file-signature", "file-upload", "file-video", "file-word", "fill", "fill-drip", "film", "filter", "fingerprint", "fire", "fire-alt", "fire-extinguisher", "firefox", "first-aid", "first-order", "first-order-alt", "firstdraft", "fish", "fist-raised", "flag", "flag-checkered", "flag-usa", "flask", "flickr", "flipboard", "flushed", "fly", "folder", "folder-minus", "folder-open", "folder-plus", "font", "font-awesome", "font-awesome-alt", "font-awesome-flag", "font-awesome-logo-full", "fonticons", "fonticons-fi", "football-ball", "fort-awesome", "fort-awesome-alt", "forumbee", "forward", "foursquare", "free-code-camp", "freebsd", "frog", "frown", "frown-open", "fulcrum", "funnel-dollar", "futbol", "galactic-republic", "galactic-senate", "gamepad", "gas-pump", "gavel", "gem", "genderless", "get-pocket", "gg", "gg-circle", "ghost", "gift", "gifts", "git", "git-alt", "git-square", "github", "github-alt", "github-square", "gitkraken", "gitlab", "gitter", "glass-cheers", "glass-martini", "glass-martini-alt", "glass-whiskey", "glasses", "glide", "glide-g", "globe", "globe-africa", "globe-americas", "globe-asia", "globe-europe", "gofore", "golf-ball", "goodreads", "goodreads-g", "google", "google-drive", "google-play", "google-plus", "google-plus-g", "google-plus-square", "google-wallet", "gopuram", "graduation-cap", "gratipay", "grav", "greater-than", "greater-than-equal", "grimace", "grin", "grin-alt", "grin-beam", "grin-beam-sweat", "grin-hearts", "grin-squint", "grin-squint-tears", "grin-stars", "grin-tears", "grin-tongue", "grin-tongue-squint", "grin-tongue-wink", "grin-wink", "grip-horizontal", "grip-lines", "grip-lines-vertical", "grip-vertical", "gripfire", "grunt", "guitar", "gulp", "h-square", "hacker-news", "hacker-news-square", "hackerrank", "hamburger", "hammer", "hamsa", "hand-holding", "hand-holding-heart", "hand-holding-usd", "hand-lizard", "hand-middle-finger", "hand-paper", "hand-peace", "hand-point-down", "hand-point-left", "hand-point-right", "hand-point-up", "hand-pointer", "hand-rock", "hand-scissors", "hand-spock", "hands", "hands-helping", "handshake", "hanukiah", "hard-hat", "hashtag", "hat-wizard", "haykal", "hdd", "heading", "headphones", "headphones-alt", "headset", "heart", "heart-broken", "heartbeat", "helicopter", "highlighter", "hiking", "hippo", "hips", "hire-a-helper", "history", "hockey-puck", "holly-berry", "home", "hooli", "hornbill", "horse", "horse-head", "hospital", "hospital-alt", "hospital-symbol", "hot-tub", "hotdog", "hotel", "hotjar", "hourglass", "hourglass-end", "hourglass-half", "hourglass-start", "house-damage", "houzz", "hryvnia", "html5", "hubspot", "i-cursor", "ice-cream", "icicles", "icons", "id-badge", "id-card", "id-card-alt", "igloo", "image", "images", "imdb", "inbox", "indent", "industry", "infinity", "info", "info-circle", "instagram", "intercom", "internet-explorer", "invision", "ioxhost", "italic", "itch-io", "itunes", "itunes-note", "java", "jedi", "jedi-order", "jenkins", "jira", "joget", "joint", "joomla", "journal-whills", "js", "js-square", "jsfiddle", "kaaba", "kaggle", "key", "keybase", "keyboard", "keycdn", "khanda", "kickstarter", "kickstarter-k", "kiss", "kiss-beam", "kiss-wink-heart", "kiwi-bird", "korvue", "landmark", "language", "laptop", "laptop-code", "laptop-medical", "laravel", "lastfm", "lastfm-square", "laugh", "laugh-beam", "laugh-squint", "laugh-wink", "layer-group", "leaf", "leanpub", "lemon", "less", "less-than", "less-than-equal", "level-down-alt", "level-up-alt", "life-ring", "lightbulb", "line", "link", "linkedin", "linkedin-in", "linode", "linux", "lira-sign", "list", "list-alt", "list-ol", "list-ul", "location-arrow", "lock", "lock-open", "long-arrow-alt-down", "long-arrow-alt-left", "long-arrow-alt-right", "long-arrow-alt-up", "low-vision", "luggage-cart", "lyft", "magento", "magic", "magnet", "mail-bulk", "mailchimp", "male", "mandalorian", "map", "map-marked", "map-marked-alt", "map-marker", "map-marker-alt", "map-pin", "map-signs", "markdown", "marker", "mars", "mars-double", "mars-stroke", "mars-stroke-h", "mars-stroke-v", "mask", "mastodon", "maxcdn", "medal", "medapps", "medium", "medium-m", "medkit", "medrt", "meetup", "megaport", "meh", "meh-blank", "meh-rolling-eyes", "memory", "mendeley", "menorah", "mercury", "meteor", "microchip", "microphone", "microphone-alt", "microphone-alt-slash", "microphone-slash", "microscope", "microsoft", "minus", "minus-circle", "minus-square", "mitten", "mix", "mixcloud", "mizuni", "mobile", "mobile-alt", "modx", "monero", "money-bill", "money-bill-alt", "money-bill-wave", "money-bill-wave-alt", "money-check", "money-check-alt", "monument", "moon", "mortar-pestle", "mosque", "motorcycle", "mountain", "mouse-pointer", "mug-hot", "music", "napster", "neos", "network-wired", "neuter", "newspaper", "nimblr", "node", "node-js", "not-equal", "notes-medical", "npm", "ns8", "nutritionix", "object-group", "object-ungroup", "odnoklassniki", "odnoklassniki-square", "oil-can", "old-republic", "om", "opencart", "openid", "opera", "optin-monster", "osi", "otter", "outdent", "page4", "pagelines", "pager", "paint-brush", "paint-roller", "palette", "palfed", "pallet", "paper-plane", "paperclip", "parachute-box", "paragraph", "parking", "passport", "pastafarianism", "paste", "patreon", "pause", "pause-circle", "paw", "paypal", "peace", "pen", "pen-alt", "pen-fancy", "pen-nib", "pen-square", "pencil-alt", "pencil-ruler", "penny-arcade", "people-carry", "pepper-hot", "percent", "percentage", "periscope", "person-booth", "phabricator", "phoenix-framework", "phoenix-squadron", "phone", "phone-alt", "phone-slash", "phone-square", "phone-square-alt", "phone-volume", "photo-video", "php", "pied-piper", "pied-piper-alt", "pied-piper-hat", "pied-piper-pp", "piggy-bank", "pills", "pinterest", "pinterest-p", "pinterest-square", "pizza-slice", "place-of-worship", "plane", "plane-arrival", "plane-departure", "play", "play-circle", "playstation", "plug", "plus", "plus-circle", "plus-square", "podcast", "poll", "poll-h", "poo", "poo-storm", "poop", "portrait", "pound-sign", "power-off", "pray", "praying-hands", "prescription", "prescription-bottle", "prescription-bottle-alt", "print", "procedures", "product-hunt", "project-diagram", "pushed", "puzzle-piece", "python", "qq", "qrcode", "question", "question-circle", "quidditch", "quinscape", "quora", "quote-left", "quote-right", "quran", "r-project", "radiation", "radiation-alt", "rainbow", "random", "raspberry-pi", "ravelry", "react", "reacteurope", "readme", "rebel", "receipt", "recycle", "red-river", "reddit", "reddit-alien", "reddit-square", "redhat", "redo", "redo-alt", "registered", "remove-format", "renren", "reply", "reply-all", "replyd", "republican", "researchgate", "resolving", "restroom", "retweet", "rev", "ribbon", "ring", "road", "robot", "rocket", "rocketchat", "rockrms", "route", "rss", "rss-square", "ruble-sign", "ruler", "ruler-combined", "ruler-horizontal", "ruler-vertical", "running", "rupee-sign", "sad-cry", "sad-tear", "safari", "salesforce", "sass", "satellite", "satellite-dish", "save", "schlix", "school", "screwdriver", "scribd", "scroll", "sd-card", "search", "search-dollar", "search-location", "search-minus", "search-plus", "searchengin", "seedling", "sellcast", "sellsy", "server", "servicestack", "shapes", "share", "share-alt", "share-alt-square", "share-square", "shekel-sign", "shield-alt", "ship", "shipping-fast", "shirtsinbulk", "shoe-prints", "shopping-bag", "shopping-basket", "shopping-cart", "shopware", "shower", "shuttle-van", "sign", "sign-in-alt", "sign-language", "sign-out-alt", "signal", "signature", "sim-card", "simplybuilt", "sistrix", "sitemap", "sith", "skating", "sketch", "skiing", "skiing-nordic", "skull", "skull-crossbones", "skyatlas", "skype", "slack", "slack-hash", "slash", "sleigh", "sliders-h", "slideshare", "smile", "smile-beam", "smile-wink", "smog", "smoking", "smoking-ban", "sms", "snapchat", "snapchat-ghost", "snapchat-square", "snowboarding", "snowflake", "snowman", "snowplow", "socks", "solar-panel", "sort", "sort-alpha-down", "sort-alpha-down-alt", "sort-alpha-up", "sort-alpha-up-alt", "sort-amount-down", "sort-amount-down-alt", "sort-amount-up", "sort-amount-up-alt", "sort-down", "sort-numeric-down", "sort-numeric-down-alt", "sort-numeric-up", "sort-numeric-up-alt", "sort-up", "soundcloud", "sourcetree", "spa", "space-shuttle", "speakap", "speaker-deck", "spell-check", "spider", "spinner", "splotch", "spotify", "spray-can", "square", "square-full", "square-root-alt", "squarespace", "stack-exchange", "stack-overflow", "stackpath", "stamp", "star", "star-and-crescent", "star-half", "star-half-alt", "star-of-david", "star-of-life", "staylinked", "steam", "steam-square", "steam-symbol", "step-backward", "step-forward", "stethoscope", "sticker-mule", "sticky-note", "stop", "stop-circle", "stopwatch", "store", "store-alt", "strava", "stream", "street-view", "strikethrough", "stripe", "stripe-s", "stroopwafel", "studiovinari", "stumbleupon", "stumbleupon-circle", "subscript", "subway", "suitcase", "suitcase-rolling", "sun", "superpowers", "superscript", "supple", "surprise", "suse", "swatchbook", "swimmer", "swimming-pool", "symfony", "synagogue", "sync", "sync-alt", "syringe", "table", "table-tennis", "tablet", "tablet-alt", "tablets", "tachometer-alt", "tag", "tags", "tape", "tasks", "taxi", "teamspeak", "teeth", "teeth-open", "telegram", "telegram-plane", "temperature-high", "temperature-low", "tencent-weibo", "tenge", "terminal", "text-height", "text-width", "th", "th-large", "th-list", "the-red-yeti", "theater-masks", "themeco", "themeisle", "thermometer", "thermometer-empty", "thermometer-full", "thermometer-half", "thermometer-quarter", "thermometer-three-quarters", "think-peaks", "thumbs-down", "thumbs-up", "thumbtack", "ticket-alt", "times", "times-circle", "tint", "tint-slash", "tired", "toggle-off", "toggle-on", "toilet", "toilet-paper", "toolbox", "tools", "tooth", "torah", "torii-gate", "tractor", "trade-federation", "trademark", "traffic-light", "train", "tram", "transgender", "transgender-alt", "trash", "trash-alt", "trash-restore", "trash-restore-alt", "tree", "trello", "tripadvisor", "trophy", "truck", "truck-loading", "truck-monster", "truck-moving", "truck-pickup", "tshirt", "tty", "tumblr", "tumblr-square", "tv", "twitch", "twitter", "twitter-square", "typo3", "uber", "ubuntu", "uikit", "umbrella", "umbrella-beach", "underline", "undo", "undo-alt", "uniregistry", "universal-access", "university", "unlink", "unlock", "unlock-alt", "untappd", "upload", "ups", "usb", "user", "user-alt", "user-alt-slash", "user-astronaut", "user-check", "user-circle", "user-clock", "user-cog", "user-edit", "user-friends", "user-graduate", "user-injured", "user-lock", "user-md", "user-minus", "user-ninja", "user-nurse", "user-plus", "user-secret", "user-shield", "user-slash", "user-tag", "user-tie", "user-times", "users", "users-cog", "usps", "ussunnah", "utensil-spoon", "utensils", "vaadin", "vector-square", "venus", "venus-double", "venus-mars", "viacoin", "viadeo", "viadeo-square", "vial", "vials", "viber", "video", "video-slash", "vihara", "vimeo", "vimeo-square", "vimeo-v", "vine", "vk", "vnv", "voicemail", "volleyball-ball", "volume-down", "volume-mute", "volume-off", "volume-up", "vote-yea", "vr-cardboard", "vuejs", "walking", "wallet", "warehouse", "water", "wave-square", "waze", "weebly", "weibo", "weight", "weight-hanging", "weixin", "whatsapp", "whatsapp-square", "wheelchair", "whmcs", "wifi", "wikipedia-w", "wind", "window-close", "window-maximize", "window-minimize", "window-restore", "windows", "wine-bottle", "wine-glass", "wine-glass-alt", "wix", "wizards-of-the-coast", "wolf-pack-battalion", "won-sign", "wordpress", "wordpress-simple", "wpbeginner", "wpexplorer", "wpforms", "wpressr", "wrench", "x-ray", "xbox", "xing", "xing-square", "y-combinator", "yahoo", "yammer", "yandex", "yandex-international", "yarn", "yelp", "yen-sign", "yin-yang", "yoast", "youtube", "youtube-square", "zhihu" ];
	}

	private void function __setupWidgetsAndSiteTemplates() {
		settings.widgets   = {};
		settings.templates = [];
	}

	private void function __setupFeatures() {
		settings.features = {
			  admin                           = { enabled=true , siteTemplates=[ "*" ], widgets=[] }
			, cms                             = { enabled=true , siteTemplates=[ "*" ], widgets=[] }
			, presideForms                    = { enabled=true , siteTemplates=[ "*" ], widgets=[] }
			, sitetree                        = { enabled=true , siteTemplates=[ "*" ], widgets=[]                      , dependsOn=[ "cms"   ] }
			, sites                           = { enabled=true , siteTemplates=[ "*" ], widgets=[]                      , dependsOn=[ "cms"   ] }
			, sticker                         = { enabled=true , siteTemplates=[ "*" ], widgets=[]                      , dependsOn=[ "admin" ] }
			, urlRedirects                    = { enabled=true , siteTemplates=[ "*" ], widgets=[]                      , dependsOn=[ "cms" ] }
			, taskManager                     = { enabled=true , siteTemplates=[ "*" ], widgets=[] }
			, adhocTasks                      = { enabled=true , siteTemplates=[ "*" ], widgets=[] }
			, assetManager                    = { enabled=true , siteTemplates=[ "*" ], widgets=[]                      , dependsOn=[ "admin" ] }
			, websiteUsers                    = { enabled=true , siteTemplates=[ "*" ], widgets=[]                      , dependsOn=[ "cms"   ] }
			, websiteBenefits                 = { enabled=true , siteTemplates=[ "*" ], widgets=[]                      , dependsOn=[ "websiteUsers" ] }
			, datamanager                     = { enabled=true , siteTemplates=[ "*" ], widgets=[]                      , dependsOn=[ "admin" ] }
			, batchOperationSelectAll         = { enabled=true , siteTemplates=[ "*" ], widgets=[]                      , dependsOn=[ "admin" ] }
			, useDistinctForDatatables        = { enabled=true , siteTemplates=[ "*" ], widgets=[]                      , dependsOn=[ "admin" ] }
			, systemConfiguration             = { enabled=true , siteTemplates=[ "*" ], widgets=[]                      , dependsOn=[ "admin" ] }
			, cmsUserManager                  = { enabled=true , siteTemplates=[ "*" ], widgets=[]                      , dependsOn=[ "cms"   ] }
			, errorLogs                       = { enabled=true , siteTemplates=[ "*" ], widgets=[]                      , dependsOn=[ "admin" ] }
			, redirectErrorPages              = { enabled=false, siteTemplates=[ "*" ], widgets=[]                      , dependsOn=[ "cms"   ] }
			, auditTrail                      = { enabled=true , siteTemplates=[ "*" ], widgets=[]                      , dependsOn=[ "admin" ] }
			, systemInformation               = { enabled=true , siteTemplates=[ "*" ], widgets=[]                      , dependsOn=[ "admin" ] }
			, passwordPolicyManager           = { enabled=true , siteTemplates=[ "*" ], widgets=[]                      , dependsOn=[ "admin" ] }
			, formbuilder                     = { enabled=true , siteTemplates=[ "*" ], widgets=[ "formbuilderform" ]   , dependsOn=[ "cms" ] }
			, formbuilder2                    = { enabled=false, siteTemplates=[ "*" ], widgets=[]                      , dependsOn=[ "formbuilder"   ] }
			, multilingual                    = { enabled=false, siteTemplates=[ "*" ], widgets=[]                      , dependsOn=[ "cms"   ] }
			, dataexport                      = { enabled=false, siteTemplates=[ "*" ], widgets=[]                      , dependsOn=[ "datamanager"   ] }
			, dataExporterNDJSON              = { enabled=false, siteTemplates=[ "*" ], widgets=[]                      , dependsOn=[ "dataexport"   ] }
			, twoFactorAuthentication         = { enabled=true , siteTemplates=[ "*" ], widgets=[]                      , dependsOn=[ "admin"   ] }
			, rulesEngine                     = { enabled=true , siteTemplates=[ "*" ], widgets=[ "conditionalContent" ], dependsOn=[ "datamanager" ] }
			, emailCenter                     = { enabled=true , siteTemplates=[ "*" ]                                  , dependsOn=[ "admin" ]  }
			, emailCenterResend               = { enabled=false, siteTemplates=[ "*" ]                                  , dependsOn=[ "emailCenter" ] }
			, emailStyleInliner               = { enabled=true , siteTemplates=[ "*" ]                                  , dependsOn=[ "emailCenter" ] }
			, emailLinkShortener              = { enabled=true , siteTemplates=[ "*" ]                                  , dependsOn=[ "emailCenter" ] }
			, emailOverwriteDomain            = { enabled=false, siteTemplates=[ "*" ]                                  , dependsOn=[ "emailCenter" ] }
			, emailTrackingBotDetection       = { enabled=false, siteTemplates=[ "*" ]                                  , dependsOn=[ "emailCenter" ] }
			, customEmailTemplates            = { enabled=true , siteTemplates=[ "*" ]                                  , dependsOn=[ "emailCenter" ] }
			, restFramework                   = { enabled=true , siteTemplates=[ "*" ] }
			, apiManager                      = { enabled=false, siteTemplates=[ "*" ]                                  , dependsOn=[ "admin" ] }
			, restTokenAuth                   = { enabled=false, siteTemplates=[ "*" ]                                  , dependsOn=[ "apiManager" ] }
			, adminCsrfProtection             = { enabled=true , siteTemplates=[ "*" ]                                  , dependsOn=[ "admin" ] }
			, fullPageCaching                 = { enabled=false, siteTemplates=[ "*" ]                                  , dependsOn=[ "cms" ] }
			, fullPageCachingForLoggedInUsers = { enabled=false, siteTemplates=[ "*" ]                                  , dependsOn=[ "websiteUsers" ] }
			, delayedViewlets                 = { enabled=true , siteTemplates=[ "*" ] }
			, healthchecks                    = { enabled=true , siteTemplates=[ "*" ] }
			, emailQueueHeartBeat             = { enabled=true , siteTemplates=[ "*" ]                                  , dependsOn=[ "customEmailTemplates" ] }
			, adhocTaskHeartBeat              = { enabled=true , siteTemplates=[ "*" ]                                  , dependsOn=[ "adhocTasks" ] }
			, taskmanagerHeartBeat            = { enabled=true , siteTemplates=[ "*" ]                                  , dependsOn=[ "taskManager" ] }
			, systemAlertsHeartBeat           = { enabled=true , siteTemplates=[ "*" ]                                  , dependsOn=[ "admin" ] }
			, scheduledExportHeartBeat        = { enabled=true , siteTemplates=[ "*" ]                                  , dependsOn=[ "dataexport"  ] }
			, segmentationFiltersHeartbeat    = { enabled=true , siteTemplates=[ "*" ]                                  , dependsOn=[ "rulesEngine" ] }
			, assetQueue                      = { enabled=false, siteTemplates=[ "*" ]                                  , dependsOn=[ "assetmanager" ] }
			, assetQueueHeartBeat             = { enabled=true , siteTemplates=[ "*" ]                                  , dependsOn=[ "assetQueue" ] }
			, queryCachePerObject             = { enabled=false, siteTemplates=[ "*" ] }
			, presideBasicWorkflow            = { enabled=true, siteTemplates=[ "*" ] }
			, dbLogAppender                   = { enabled=true, siteTemplates=[ "*" ] }
			, maintenanceMode                 = { enabled=true, siteTemplates=[ "*" ]                                   , dependsOn=[ "admin" ] }
			, sslInternalHttpCalls            = { enabled=_luceeGreaterThanFour(), siteTemplates=[ "*" ] }
			, sslInternalHttpCalls            = { enabled=_luceeGreaterThanFour(), siteTemplates=[ "*" ] }
			, presideSessionManagement        = { enabled=_usePresideSessionManagement(), siteTemplates=[ "*" ] }
			, "devtools.reload"               = { enabled=true , siteTemplates=[ "*" ], widgets=[]                      , dependsOn=[ "admin" ] }
			, "devtools.cache"                = { enabled=true , siteTemplates=[ "*" ], widgets=[]                      , dependsOn=[ "admin" ] }
			, "devtools.extension"            = { enabled=true , siteTemplates=[ "*" ], widgets=[]                      , dependsOn=[ "admin" ] }
			, "devtools.new"                  = { enabled=false, siteTemplates=[ "*" ], widgets=[]                      , dependsOn=[ "admin" ] }
			, passwordVisibilityToggle        = { enabled=true , siteTemplates=[ "*" ]                                  , dependsOn=[ "admin" ] }
		};
	}

	private void function __setupEnums() {
		settings.enum = {};
		settings.enum.redirectType                = [ "301", "302" ];
		settings.enum.pageAccessRestriction       = [ "inherit", "none", "full", "partial" ];
		settings.enum.pageIframeAccessRestriction = [ "inherit", "block", "sameorigin", "allow" ];
		settings.enum.internalSearchAccess        = [ "inherit", "allow", "block" ];
		settings.enum.searchAccess                = [ "inherit", "allow", "block" ];
		settings.enum.assetAccessRestriction      = [ "inherit", "none", "full" ];
		settings.enum.linkType                    = [ "email", "url", "sitetreelink", "asset", "anchor" ];
		settings.enum.linkTarget                  = [ "_blank", "_self", "_parent", "_top" ];
		settings.enum.linkProtocol                = [ "http://", "https://", "ftp://", "news://", "tel://" ];
		settings.enum.linkReferrerPolicy          = [ "no-referrer", "no-referrer-when-downgrade", "origin", "origin-when-cross-origin","same-origin","strict-origin","strict-origin-when-cross-origin","unsafe-url" ];
		settings.enum.siteProtocol                = [ "http", "https" ];
		settings.enum.emailSendingMethod          = [ "auto", "manual", "scheduled" ];
		settings.enum.emailSendingLimit           = [ "none", "once", "limited" ];
		settings.enum.emailSendQueueStatus        = [ "queued", "sending" ];
		settings.enum.timeUnit                    = [ "second", "minute", "hour", "day", "week", "month", "quarter", "year" ];
		settings.enum.segmentationFilterTimeUnit  = [ "hour", "day" ];
		settings.enum.emailSendingScheduleType    = [ "fixeddate", "repeat" ];
		settings.enum.emailActivityType           = [ "send", "deliver", "open", "click", "markasspam", "unsubscribe", "fail", "honeypotclick" ];
		settings.enum.urlStringPart               = [ "url", "domain", "path", "querystring", "protocol" ];
		settings.enum.emailAction                 = [ "sent", "received", "failed", "bounced", "opened", "markedasspam", "clicked" ];
		settings.enum.adhocTaskStatus             = [ "pending", "locked", "running", "requeued", "succeeded", "failed", "cancelled" ];
		settings.enum.assetQueueStatus            = [ "pending", "running", "failed" ];
		settings.enum.rulesfilterScopeAll         = [ "global", "individual", "group" ];
		settings.enum.rulesfilterScopeGroup       = [ "global", "group" ];
		settings.enum.rulesEngineConditionType    = [ "condition", "filter" ];
		settings.enum.dataExportExcelDataTypes    = [ "mapped", "string" ];
		settings.enum.systemAlertLevel            = [ "critical", "warning", "advisory" ];
		settings.enum.adminToolbarModes           = [ "fixed", "reveal", "none" ];
	}

	private void function __setupFormValidationProviders() {
		settings.validationProviders = [];
		settings.coreValidationProviders = [
			  "presideObjectValidators"
			, "passwordPolicyValidator"
			, "recaptchaValidator"
			, "rulesEngineConditionService"
			, "enumService"
			, "EmailCenterValidators"
		];
	}

	private void function __setupStaticAssetConfiguration() {
		settings.static = {
			  rootUrl        = ""
			, siteAssetsPath = "/assets"
			, siteAssetsUrl  = "/assets"
		};
	}

	private void function __setupRequestSecurity() {
		settings.antiSamy = {
			  enabled                 = true
			, policy                  = "preside"
			, bypassForAdministrators = true
		};

		settings.csrf = {
			  tokenExpiryInSeconds      = 1200
			, authenticatedSessionsOnly = IsBoolean( settings.env.CSRF_AUTHENTICATED_ONLY ?: "" ) && settings.env.CSRF_AUTHENTICATED_ONLY
		};
	}

	private void function __setupRestFramework() {
		settings.rest = {
			  path          = "/api"
			, corsEnabled   = false
			, apis          = {}
			, authProviders = {}
		};

		settings.rest.authProviders.token = { feature = "restTokenAuth" };
	}

	private void function __setupMultilingualDefaults() {
		settings.multilingual = {
			ignoredUrlPatterns = [ "^/api", "^/preside", "^/assets", "^/file/" ]
		};
	}

	private void function __setupFormBuilder() {
		settings.formbuilder = _setupFormBuilder(); // << Seems silly here but keeping this for backward compat

		settings.formbuilder.submissions                        = settings.formbuilder.submissions         ?: {};
		settings.formbuilder.submissions.removal                = settings.formbuilder.submissions.removal ?: {};
		settings.formbuilder.submissions.removal.minAllowedDays = 30;
	}

	private void function __setupRulesEngine(){
		settings.rulesEngine = { contexts={} };
		settings.rulesEngine.contexts.webrequest            = { subcontexts=[ "user", "page", "adminuser" ] };
		settings.rulesEngine.contexts.page                  = { feature="sitetree", object="page" };
		settings.rulesEngine.contexts.user                  = { feature="websiteUsers", object="website_user" };
		settings.rulesEngine.contexts.adminuser             = { feature="admin", object="security_user" };
		settings.rulesEngine.contexts.formBuilderSubmission = { feature="formbuilder", subcontexts=[ "webrequest" ] };
	}

	private void function __setupTenancy() {
		settings.tenancy = {};
		settings.tenancy.site = { object="site", defaultfk="site" };
	}

	private void function __setupDataExport() {
		settings.dataExport = {};
		settings.dataExport.csv = { delimiter="," };

		settings.dataExport.defaults = { excludeFields=[] };
	}

	private void function __setupFullPageCaching() {
		settings.fullPageCaching = {
			  limitCacheData = false
			, limitCacheDataKeys = {
				  rc  = []
				, prc = [ "_site", "presidePage", "__presideInlineJs", "_presideUrlPath", "currentLayout", "currentView", "slug", "viewModule" ]
			  }
		};
	}

	private void function __setupHeartbeatsAndServices() {
		settings.concurrency = _getConcurrencySettings(); // separated out still for backward compat
		settings.healthCheckServices = {};

		settings.presideservices = {
			  assetQueue          = "assetQueueService"
			, derivativeGenerator = "derivativeGeneratorService"
		};

		settings.heartbeats = {
			  defaultHostname = settings.env.DEFAULT_HEARTBEAT_HOSTNAME ?: cgi.server_name
			, assetQueue      = {}
			, cacheBoxReap    = {}
			, healthCheck     = {}
			, adhocTask       = {}
			, taskmanager     = {}
			, systemAlerts    = {}
			, emailQueue      = {}
		};

		settings.heartbeats.assetQueue.hostname   = settings.env.ASSETQUEUE_HEARTBEAT_HOSTNAME   ?: settings.heartbeats.defaultHostname;
		settings.heartbeats.adhocTask.hostname    = settings.env.ADHOCTASK_HEARTBEAT_HOSTNAME    ?: settings.heartbeats.defaultHostname;
		settings.heartbeats.taskmanager.hostname  = settings.env.TASKMANAGER_HEARTBEAT_HOSTNAME  ?: settings.heartbeats.defaultHostname;
		settings.heartbeats.systemAlerts.hostname = settings.env.SYSTEMALERTS_HEARTBEAT_HOSTNAME ?: settings.heartbeats.defaultHostname;
		settings.heartbeats.emailQueue.hostname   = settings.env.EMAILQUEUE_HEARTBEAT_HOSTNAME   ?: settings.heartbeats.defaultHostname;
		settings.heartbeats.cacheBoxReap.hostname = settings.env.CACHEBOXREAP_HEARTBEAT_HOSTNAME ?: settings.heartbeats.defaultHostname;
		settings.heartbeats.healthCheck.hostname  = settings.env.HEALTHCHECK_HEARTBEAT_HOSTNAME  ?: settings.heartbeats.defaultHostname;
		settings.heartbeats.sessionReap.hostname  = settings.env.SESSIONREAP_HEARTBEAT_HOSTNAME  ?: settings.heartbeats.defaultHostname;

		settings.heartbeats.taskmanager.poolSize  = Val( settings.env.TASKMANAGER_POOL_SIZE  ?: 0 );
		settings.heartbeats.adhocTask.poolSize    = Val( settings.env.ADHOCTASK_POOL_SIZE    ?: 0 );

		settings.heartbeats.adhocTask.staleTaskSettings = {
			  lockedMinAgeInMinutes          = 5
			, lockedMaxAgeInMinutes          = ( 7 * 24 * 60 ) // one week (i.e. ignore stale tasks over one week old to avoid restarting very old tasks with unexpected results)
			, inactiveRunningMinAgeInMinutes = 360
			, inactiveRunningMaxAgeInMinutes = ( 7 * 24 * 60 ) // one week (i.e. ignore stale tasks over one week old to avoid restarting very old tasks with unexpected results)
		};
	}

	private void function __setupNotifications() {
		ArrayAppend( settings.notificationTopics, "FormbuilderSubmissionReceived" );
	}

	private void function __setupDevConsole() {
		settings.devConsoleToggleKeyCode = 96;
	}

	private void function __setupIgnoreFile(){
		settings.ignoreFile = {
			  read  = true
			, write = false
			, path  = ExpandPath( "/.presideignore.json" )
		};
	}

	private void function __loadConfigurationFromExtensions() {
		for( var ext in settings.activeExtensions ){
			if ( FileExists( ext.directory & "/config/Config.cfc" ) ) {
				var cfcPath = ext.componentPath & ".config.Config";

				CreateObject( cfcPath ).configure( config=variables );
			}
		}
	}


// PRIVATE UTILITY

	private array function _getUdfFiles() {
		var udfs     = DirectoryList( "/preside/system/helpers", true, false, "*.cfm" );
		var siteUdfs = ArrayNew(1);
		var udf      = "";
		var i        = 0;

		for( i=1; i lte ArrayLen( udfs ); i++ ) {
			udfs[i] = _getMappedPathFromFull( udfs[i], "/preside/system/helpers/" );
		}

		for( var ext in settings.activeExtensions ){
			var helperDir = ext.directory & "/helpers";
			if ( DirectoryExists( helperDir ) ) {
				var extUdfs   = DirectoryList( helperDir, true, false, "*.cfm" );
				for( udf in extUdfs ){
					ArrayAppend( udfs, _getMappedPathFromFull( udf, helperDir ) );
				}
			}
		}

		if ( DirectoryExists( "/#settings.appMapping#/helpers" ) ) {
			siteUdfs = DirectoryList( "/#settings.appMapping#/helpers", true, false, "*.cfm" );

			for( udf in siteUdfs ){
				ArrayAppend( udfs, _getMappedPathFromFull( udf, "/#settings.appMapping#/helpers" ) );
			}
		}

		return udfs;
	}

	private string function _getMappedPathFromFull( required string fullPath, required string mapping ) {
		var expandedMapping       = ExpandPath( arguments.mapping );
		var pathRelativeToMapping = Replace( arguments.fullPath, expandedMapping, "" );

		return arguments.mapping & Replace( pathRelativeToMapping, "\", "/", "all" );
	}

	private string function _discoverWireboxBinder() {
		if ( FileExists( "/#settings.appMapping#/config/WireBox.cfc" ) ) {
			return "#settings.appMappingPath#.config.WireBox";
		}

		return 'preside.system.config.WireBox';
	}

	private string function _discoverCacheboxConfigurator() {
		if ( FileExists( "/#settings.appMapping#/config/Cachebox.cfc" ) ) {
			return "#settings.appMappingPath#.config.Cachebox";
		}

		return "preside.system.config.Cachebox";
	}

	private struct function _getConfiguredFileTypes() output=false{
		var types = {};

		types.image = {
			  jpg  = { serveAsAttachment=false, mimeType="image/jpeg" }
			, jpeg = { serveAsAttachment=false, mimeType="image/jpeg" }
			, gif  = { serveAsAttachment=false, mimeType="image/gif"  }
			, png  = { serveAsAttachment=false, mimeType="image/png"  }
			, svg  = { serveAsAttachment=false, mimeType="image/svg+xml" }
			, tiff = { serveAsAttachment=false, mimeType="image/tiff" }
			, tif  = { serveAsAttachment=false, mimeType="image/tiff" }
			, webp = { serveAsAttachment=false, mimeType="image/webp" }
		};

		types.video = {
			  swf = { serveAsAttachment=true, mimeType="application/x-shockwave-flash" }
			, flv = { serveAsAttachment=true, mimeType="video/x-flv" }
			, mp4 = { serveAsAttachment=true, mimeType="video/mp4" }
			, avi = { serveAsAttachment=true, mimeType="video/avi" }
		};

		types.document = {
			  pdf  = { serveAsAttachment=true, trackDownloads=true, mimeType="application/pdf"    }
			, csv  = { serveAsAttachment=true, trackDownloads=true, mimeType="application/csv"    }
			, doc  = { serveAsAttachment=true, trackDownloads=true, mimeType="application/msword" }
			, dot  = { serveAsAttachment=true, trackDownloads=true, mimeType="application/msword" }
			, docx = { serveAsAttachment=true, trackDownloads=true, mimeType="application/vnd.openxmlformats-officedocument.wordprocessingml.document" }
			, dotx = { serveAsAttachment=true, trackDownloads=true, mimeType="application/vnd.openxmlformats-officedocument.wordprocessingml.template" }
			, docm = { serveAsAttachment=true, trackDownloads=true, mimeType="application/vnd.ms-word.document.macroEnabled.12" }
			, dotm = { serveAsAttachment=true, trackDownloads=true, mimeType="application/vnd.ms-word.template.macroEnabled.12" }
			, xls  = { serveAsAttachment=true, trackDownloads=true, mimeType="application/vnd.ms-excel" }
			, xlt  = { serveAsAttachment=true, trackDownloads=true, mimeType="application/vnd.ms-excel" }
			, xla  = { serveAsAttachment=true, trackDownloads=true, mimeType="application/vnd.ms-excel" }
			, xlsx = { serveAsAttachment=true, trackDownloads=true, mimeType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet" }
			, xltx = { serveAsAttachment=true, trackDownloads=true, mimeType="application/vnd.openxmlformats-officedocument.spreadsheetml.template" }
			, xlsm = { serveAsAttachment=true, trackDownloads=true, mimeType="application/vnd.ms-excel.sheet.macroEnabled.12" }
			, xltm = { serveAsAttachment=true, trackDownloads=true, mimeType="application/vnd.ms-excel.template.macroEnabled.12" }
			, xlam = { serveAsAttachment=true, trackDownloads=true, mimeType="application/vnd.ms-excel.addin.macroEnabled.12" }
			, xlsb = { serveAsAttachment=true, trackDownloads=true, mimeType="application/vnd.ms-excel.sheet.binary.macroEnabled.12" }
			, ppt  = { serveAsAttachment=true, trackDownloads=true, mimeType="application/vnd.ms-powerpoint" }
			, pot  = { serveAsAttachment=true, trackDownloads=true, mimeType="application/vnd.ms-powerpoint" }
			, pps  = { serveAsAttachment=true, trackDownloads=true, mimeType="application/vnd.ms-powerpoint" }
			, ppa  = { serveAsAttachment=true, trackDownloads=true, mimeType="application/vnd.ms-powerpoint" }
			, pptx = { serveAsAttachment=true, trackDownloads=true, mimeType="application/vnd.openxmlformats-officedocument.presentationml.presentation" }
			, potx = { serveAsAttachment=true, trackDownloads=true, mimeType="application/vnd.openxmlformats-officedocument.presentationml.template" }
			, ppsx = { serveAsAttachment=true, trackDownloads=true, mimeType="application/vnd.openxmlformats-officedocument.presentationml.slideshow" }
			, ppam = { serveAsAttachment=true, trackDownloads=true, mimeType="application/vnd.ms-powerpoint.addin.macroEnabled.12" }
			, pptm = { serveAsAttachment=true, trackDownloads=true, mimeType="application/vnd.ms-powerpoint.presentation.macroEnabled.12" }
			, potm = { serveAsAttachment=true, trackDownloads=true, mimeType="application/vnd.ms-powerpoint.template.macroEnabled.12" }
			, ppsm = { serveAsAttachment=true, trackDownloads=true, mimeType="application/vnd.ms-powerpoint.slideshow.macroEnabled.12" }
		};

		// TODO, more types to be defined here!

		return types;
	}

	private string function _typesToExtensions( required struct types ) {
		var extensions = [];
		for( var cat in arguments.types ) {
			for( var ext in arguments.types[ cat ] ) {
				extensions.append( "." & ext );
			}
		}

		return extensions.toList();
	}

	private struct function _getConfiguredAssetDerivatives() {
		var derivatives  = {};

		derivatives.adminthumbnail = {
			  permissions = "inherit"
			, autoQueue = [ "image", "pdf" ]
			, transformations = [
				  { method="pdfPreview" , args={ page=1                }, inputfiletype="pdf", outputfiletype="jpg" }
				, { method="shrinkToFit", args={ width=200, height=200 } }
			  ]
		};

		derivatives.icon = {
			  permissions = "inherit"
			, autoQueue = [ "image" ]
			, transformations = [ { method="shrinkToFit", args={ width=32, height=32 } } ]
		};

		derivatives.pickericon = {
			  permissions = "inherit"
			, autoQueue = [ "image" ]
			, transformations = [ { method="shrinkToFit", args={ width=48, height=32 } } ]
		};

		derivatives.pageThumbnail = {
			  permissions = "inherit"
			, autoQueue = [ "image" ]
			, transformations = [ { method="shrinkToFit", args={ width=100, height=100 } } ]
		};

		derivatives.adminCropping = {
			  permissions = "inherit"
			, autoQueue = [ "image" ]
			, transformations = [ { method="shrinkToFit", args={ width=300, height=300 } } ]
		};

		derivatives.openGraphImage = {
			  permissions = "inherit"
			, autoQueue   = [ "image" ]
			, transformations = [ { method="shrinkToFit", args={ width=400, height=400 } } ]
		};

		return derivatives;
	}

	private struct function _getCkEditorToolbarConfig() {
		return {
			full     =  'Maximize,-,Source,-,Preview'
					 & '|Cut,Copy,-,Undo,Redo'
					 & '|Find,Replace,-,SelectAll,-,Scayt'
					 & '|Widgets,ImagePicker,AttachmentPicker,Table,HorizontalRule,SpecialChar,Iframe,CodeSnippet'
					 & '|PresideLink,PresideUnlink,PresideAnchor'
					 & '|Bold,Italic,Underline,Strike,Subscript,Superscript,RemoveFormat'
					 & '|NumberedList,BulletedList,-,Outdent,Indent,-,Blockquote,CreateDiv,-,JustifyLeft,JustifyCenter,JustifyRight,JustifyBlock,-,BidiLtr,BidiRtl,Language'
					 & '|Styles,Format',

			noInserts = 'Maximize,-,Source,-,Preview'
					 & '|Cut,Copy,-,Undo,Redo'
					 & '|Find,Replace,-,SelectAll,-,Scayt'
					 & '|PresideLink,PresideUnlink,PresideAnchor'
					 & '|Bold,Italic,Underline,Strike,Subscript,Superscript,RemoveFormat'
					 & '|NumberedList,BulletedList,-,Outdent,Indent,-,Blockquote,CreateDiv,-,JustifyLeft,JustifyCenter,JustifyRight,JustifyBlock,-,BidiLtr,BidiRtl,Language'
					 & '|Styles,Format',

			bolditaliconly = 'Bold,Italic',

			email = 'Maximize,-,Source,'
					 & '|Cut,Copy,-,Undo,Redo'
					 & '|Find,Replace,-,SelectAll,-,Scayt'
					 & '|PresideLink,PresideUnlink,-,Widgets,ImagePicker,AttachmentPicker,,SpecialChar'
					 & '|Bold,Italic,Underline,Strike,Subscript,Superscript,RemoveFormat'
					 & '|NumberedList,BulletedList,Table,HorizontalRule,-,Outdent,Indent,-,Blockquote,CreateDiv'
					 & '|JustifyLeft,JustifyCenter,JustifyRight,JustifyBlock,-,BidiLtr,BidiRtl,Language'
					 & '|Format',
		};

	}


	private struct function _setupFormBuilder() {
		var fbSettings = { itemtypes={} };

		fbSettings.itemTypes.standard = { sortorder=10, types={
			  textinput  = { isFormField=true }
			, textarea   = { isFormField=true }
			, email      = { isFormField=true }
			, number     = { isFormField=true }
			, date       = { isFormField=true }
			, time       = { isFormField=true }
			, starRating = { isFormField=true }
			, checkbox   = { isFormField=true }
			, url        = { isFormField=true }
		} };

		fbSettings.itemTypes.multipleChoice = { sortorder=20, types={
			  select       = { isFormField=true }
			, checkboxList = { isFormField=true }
			, radio        = { isFormField=true }
			, matrix       = { isFormField=true }
		} };

		fbSettings.itemTypes.upload = { sortorder=30, types={
			fileUpload = { isFormField=true, isFileUploadField=true }
		} };

		fbSettings.itemTypes.content = { sortorder=40, types={
			  spacer  = { isFormField=false }
			, content = { isFormField=false }
			, section = { isFormField=false }
		} };

		fbSettings.actions = [
			  { id="email"                                     }
			, { id="anonymousCustomerEmail"                    }
			, { id="loggedInUserEmail", feature="websiteUsers" }
		];

		fbSettings.export = { fieldNamesForHeaders=false };

		return fbSettings;
	}

	private struct function _getEmailSettings() {
		var templates        = {};
		var recipientTypes   = {};
		var serviceProviders = {};

		templates.cmsWelcome = { feature="admin", group="presideadmin", recipientType="adminUser", parameters=[
			  { id="reset_password_link", required=true }
			, { id="welcome_message", required=true }
			, "created_by"
			, "site_url"
		] };
		templates.resetCmsPassword = { feature="admin", group="presideadmin", recipientType="adminUser", saveContent=false, parameters=[
			  { id="reset_password_link", required=true }
			, "site_url"
		] };
		templates.resetCmsPasswordForTokenExpiry = { feature="admin", group="presideadmin", recipientType="adminUser", saveContent=false, parameters=[
			  { id="reset_password_link", required=true }
			, "site_url"
		] };
		templates.formbuilderSubmissionNotification = { feature="formbuilder", group="presideadmin", recipientType="anonymous", parameters=[
			  { id="admin_link"          , required=true }
			, { id="submission_preview"  , required=true }
			, { id="notification_subject", required=false }
		] };
		templates.notification = { feature="admin", group="presideadmin", recipientType="adminUser", saveContent=false, parameters=[
			  { id="admin_link"          , required=true  }
			, { id="notification_body"   , required=true  }
			, { id="notification_subject", required=false }
		] };
		templates.scheduledExport = { feature="dataExport", group="presideadmin", recipientType="adminUser", saveContent=false, parameters=[
			  { id="export_download_link", required=true  }
			, { id="export_filename"     , required=false }
			, { id="saved_export_name"   , required=false }
			, { id="number_of_records"   , required=false }
		] };
		templates.websiteWelcome = { feature="websiteUsers", group="websiteusers", recipientType="websiteUser", parameters=[
			  { id="reset_password_link", required=true }
			, "site_url"
		] };
		templates.resetWebsitePassword = { feature="websiteUsers", group="websiteusers", recipientType="websiteUser", saveContent=false, parameters=[
			  { id="reset_password_link", required=true }
			, "site_url"
		] };
		templates.resetWebsitePasswordForTokenExpiry = { feature="websiteUsers", group="websiteusers", recipientType="websiteUser", saveContent=false, parameters=[
			  { id="reset_password_link", required=true }
			, "site_url"
		] };
		templates.resetTwoFactorAuthentication = { feature="admin", group="presideadmin", recipientType="adminUser", saveContent=false, parameters=[
			  "site_url"
			, "site_admin_url"
		] };

		recipientTypes.anonymous   = {};
		recipientTypes.adminUser   = {
			  parameters             = [ "known_as", "login_id", "email_address" ]
			, filterObject           = "security_user"
			, gridFields             = [ "known_as", "email_address" ]
			, recipientIdLogProperty = "security_user_recipient"
			, feature                = "cms"
		};
		recipientTypes.websiteUser = {
			  parameters             = [ "display_name", "login_id", "email_address" ]
			, filterObject           = "website_user"
			, gridFields             = [ "display_name", "email_address" ]
			, recipientIdLogProperty = "website_user_recipient"
			, feature                = "websiteUsers"
		};

		serviceProviders.smtp = {};

		return {
			  templates            = templates
			, recipientTypes       = recipientTypes
			, serviceProviders     = serviceProviders
			, defaultContentExpiry = 30
			, queueConcurrency     = 1
		};
	}

	private struct function _getConcurrencySettings(){
		return {
			pools = {
				  scheduledTasks = { maxConcurrent=0, maxWorkQueueSize=10000 }
				, adhoc          = { maxConcurrent=0, maxWorkQueueSize=10000 }
			}
		};
	}

	private string function _calculateColdboxVersion() {
		var boxJsonPath = "/coldbox/box.json";

		if ( FileExists( boxJsonPath ) ) {
			try {
				var boxInfo = DeserializeJson( FileRead( boxJsonPath ) );

				return boxInfo.version ?: "unknown";
			} catch( any e ) {
				return "unknown";
			}
		}

		return "3.8.2";
	}

	private boolean function _luceeGreaterThanFour() {
		var luceeVersion = server.lucee.version ?: "";
		var major = Val( ListFirst( luceeVersion, "." ) );

		return major > 4;
	}

	private struct function _getRicheditorLinkPickerConfig() {
		return {
			default = {
				types=[ "sitetreelink", "url", "email", "asset", "anchor" ]
			}
			, email = {
				types=[ "sitetreelink", "url", "email", "asset", "emailvariable" ]
			}
		};
	}

	private boolean function _usePresideSessionManagement() {
		return IsBoolean( request._sessionSettings.presideSessionManagement ?: "" ) && request._sessionSettings.presideSessionManagement;
	}

	/**
	 * returns protocol based just like isSSL() in
	 * system.externals.coldbox.system.web.context.RequestContext.cfc
	 */
	private string function _getCurrentProtocol() {
		if( isBoolean( cgi.server_port_secure ) && cgi.server_port_secure ){
			return "https";
		}
		if( StructKeyExists( cgi, "https" ) && cgi.https == "on" ){
			return "https";
		}

		var headers = getHttpRequestData( false ).headers;

		if( ( headers[ "x-forwarded-proto" ] ?: "" ) == "https" ){
			return "https";
		}
		if( ( headers[ "x-scheme" ] ?: "" ) == "https" ){
			return "https";
		}

		return "http";
	}
}
