component output=false {

	public void function configure() output=false {
		settings = {};

		settings.appMapping    = request._presideMappings.appMapping    ?: "/app";
		settings.assetsMapping = request._presideMappings.assetsMapping ?: "/assets";
		settings.logsMapping   = request._presideMappings.logsMapping   ?: "/logs";

		settings.appMappingPath    = Replace( ReReplace( settings.appMapping   , "^/", "" ), "/", ".", "all" );
		settings.assetsMappingPath = Replace( ReReplace( settings.assetsMapping, "^/", "" ), "/", ".", "all" );
		settings.logsMappingPath   = Replace( ReReplace( settings.logsMapping  , "^/", "" ), "/", ".", "all" );

		settings.activeExtensions = _loadExtensions();

		coldbox = {
			  appName                   = "OpenPreside Website"
			, handlersIndexAutoReload   = false
			, debugMode                 = false
			, defaultEvent              = "general.index"
			, customErrorTemplate       = ""
			, reinitPassword            = "true"
			, handlerCaching            = true
			, eventCaching              = true
			, requestContextDecorator   = "preside.system.coldboxModifications.RequestContextDecorator"
			, UDFLibraryFile            = _getUdfFiles()
			, pluginsExternalLocation   = "preside.system.plugins"
			, viewsExternalLocation     = "/preside/system/views"
			, layoutsExternalLocation   = "/preside/system/layouts"
			, modulesExternalLocation   = ["/preside/system/modules"]
			, handlersExternalLocation  = "preside.system.handlers"
			, applicationStartHandler   = "General.applicationStart"
			, requestStartHandler       = "General.requestStart"
			, missingTemplateHandler    = "General.notFound"
			, onInvalidEvent            = "General.notFound"
			, coldboxExtensionsLocation = "preside.system.coldboxModifications"
		};

		i18n = {
			  defaultLocale      = "en"
			, localeStorage      = "cookie"
			, unknownTranslation = "**NOT FOUND**"
		};

		interceptors = [
			{ class="preside.system.interceptors.ApplicationReloadInterceptor"        , properties={} },
			{ class="preside.system.interceptors.CsrfProtectionInterceptor"           , properties={} },
			{ class="preside.system.interceptors.PageTypesPresideObjectInterceptor"   , properties={} },
			{ class="preside.system.interceptors.SiteTenancyPresideObjectInterceptor" , properties={} },
			{ class="preside.system.interceptors.MultiLingualPresideObjectInterceptor", properties={} },
			{ class="preside.system.interceptors.ValidationProviderSetupInterceptor"  , properties={} },
			{ class="preside.system.interceptors.SES"                                 , properties = { configFile = "/preside/system/config/Routes.cfm" } },
			{ class="preside.system.interceptors.RedirectsInterceptor"                , properties={} }
		];
		interceptorSettings = {
			  throwOnInvalidStates     = false
			, customInterceptionPoints = []
		};

		interceptorSettings.customInterceptionPoints.append( "prePresideReload"               );
		interceptorSettings.customInterceptionPoints.append( "postPresideReload"              );
		interceptorSettings.customInterceptionPoints.append( "onBuildLink"                    );
		interceptorSettings.customInterceptionPoints.append( "onCreateSelectDataCacheKey"     );
		interceptorSettings.customInterceptionPoints.append( "postDbSyncObjects"              );
		interceptorSettings.customInterceptionPoints.append( "postDeleteObjectData"           );
		interceptorSettings.customInterceptionPoints.append( "postInsertObjectData"           );
		interceptorSettings.customInterceptionPoints.append( "postLoadPresideObject"          );
		interceptorSettings.customInterceptionPoints.append( "postLoadPresideObjects"         );
		interceptorSettings.customInterceptionPoints.append( "postPrepareObjectFilter"        );
		interceptorSettings.customInterceptionPoints.append( "postReadPresideObject"          );
		interceptorSettings.customInterceptionPoints.append( "postReadPresideObjects"         );
		interceptorSettings.customInterceptionPoints.append( "postRenderSiteTreePage"         );
		interceptorSettings.customInterceptionPoints.append( "postSelectObjectData"           );
		interceptorSettings.customInterceptionPoints.append( "postUpdateObjectData"           );
		interceptorSettings.customInterceptionPoints.append( "postParseSelectFields"          );
		interceptorSettings.customInterceptionPoints.append( "postPrepareTableJoins"          );
		interceptorSettings.customInterceptionPoints.append( "preDbSyncObjects"               );
		interceptorSettings.customInterceptionPoints.append( "preDeleteObjectData"            );
		interceptorSettings.customInterceptionPoints.append( "preInsertObjectData"            );
		interceptorSettings.customInterceptionPoints.append( "preLoadPresideObject"           );
		interceptorSettings.customInterceptionPoints.append( "preLoadPresideObjects"          );
		interceptorSettings.customInterceptionPoints.append( "prePrepareObjectFilter"         );
		interceptorSettings.customInterceptionPoints.append( "preReadPresideObject"           );
		interceptorSettings.customInterceptionPoints.append( "preRenderSiteTreePage"          );
		interceptorSettings.customInterceptionPoints.append( "preSelectObjectData"            );
		interceptorSettings.customInterceptionPoints.append( "preUpdateObjectData"            );
		interceptorSettings.customInterceptionPoints.append( "preParseSelectFields"           );
		interceptorSettings.customInterceptionPoints.append( "onApplicationStart"             );
		interceptorSettings.customInterceptionPoints.append( "onCreateNotification"           );
		interceptorSettings.customInterceptionPoints.append( "preCreateNotification"          );
		interceptorSettings.customInterceptionPoints.append( "postCreateNotification"         );
		interceptorSettings.customInterceptionPoints.append( "preCreateNotificationConsumer"  );
		interceptorSettings.customInterceptionPoints.append( "postCreateNotificationConsumer" );
		interceptorSettings.customInterceptionPoints.append( "preAttemptLogin"                );
		interceptorSettings.customInterceptionPoints.append( "onLoginSuccess"                 );
		interceptorSettings.customInterceptionPoints.append( "onLoginFailure"                 );
		interceptorSettings.customInterceptionPoints.append( "preDownloadFile"                );
		interceptorSettings.customInterceptionPoints.append( "onDownloadFile"                 );
		interceptorSettings.customInterceptionPoints.append( "onReturnFile304"                );
		interceptorSettings.customInterceptionPoints.append( "preDownloadAsset"               );
		interceptorSettings.customInterceptionPoints.append( "onDownloadAsset"                );

		cacheBox = {
			configFile = _discoverCacheboxConfigurator()
		};

		wirebox = {
			  singletonReload = false
			, binder          = _discoverWireboxBinder()
		};

		logbox = {
			appenders = {
				defaultLogAppender = {
					  class      = 'coldbox.system.logging.appenders.AsyncRollingFileAppender'
					, properties = { filePath=settings.logsMapping, filename="coldbox.log" }
				}
			},
			root = { appenders='defaultLogAppender', levelMin='FATAL', levelMax='WARN' }
		};

		settings.eventName                   = "event";
		settings.formControls                = {};
		settings.widgets                     = {};
		settings.templates                   = [];
		settings.adminDefaultEvent           = "sitetree";
		settings.preside_admin_path          = "admin";
		settings.presideHelpAndSupportLink   = "http://www.pixl8.co.uk";
		settings.dsn                         = "preside";
		settings.presideObjectsTablePrefix   = "pobj_";
		settings.system_users                = "sysadmin";
		settings.updateRepositoryUrl         = "http://downloads.presidecms.com.s3.amazonaws.com";
		settings.notFoundLayout              = "Main";
		settings.notFoundViewlet             = "errors.notFound";
		settings.accessDeniedLayout          = "Main";
		settings.accessDeniedViewlet         = "errors.accessDenied";
		settings.serverErrorLayout           = "Main";
		settings.serverErrorViewlet          = "errors.serverError";
		settings.maintenanceModeViewlet      = "errors.maintenanceMode";
		settings.cookieEncryptionKey         = _getCookieEncryptionKey();
		settings.injectedConfig              = Duplicate( application.injectedConfig ?: {} );
		settings.notificationTopics          = [];
		settings.autoSyncDb                  = IsBoolean( settings.injectedConfig.autoSyncDb ?: ""  ) && settings.injectedConfig.autoSyncDb;
		settings.autoRestoreDeprecatedFields = true;
		settings.devConsoleToggleKeyCode     = 96;

		settings.adminSideBarItems = [
			  "sitetree"
			, "assetmanager"
			, "datamanager"
			, "websiteUserManager"
		];

		settings.adminConfigurationMenuItems = [
			  "usermanager"
			, "passwordPolicyManager"
			, "systemConfiguration"
			, "updateManager"
			, "urlRedirects"
			, "errorLogs"
			, "maintenanceMode"
		];

		settings.assetManager = {
			  maxFileSize       = "5"
			, types             = _getConfiguredFileTypes()
			, derivatives       = _getConfiguredAssetDerivatives()
			, folders           = {}
		};
		settings.assetManager.allowedExtensions = _typesToExtensions( settings.assetManager.types );

		settings.adminPermissions = {
			  sitetree               = [ "navigate", "read", "add", "edit", "trash", "viewtrash", "emptytrash", "restore", "delete", "manageContextPerms", "viewversions", "sort", "translate" ]
			, sites                  = [ "navigate", "manage", "translate" ]
			, datamanager            = [ "navigate", "read", "add", "edit", "delete", "manageContextPerms", "viewversions", "translate" ]
			, usermanager            = [ "navigate", "read", "add", "edit", "delete" ]
			, groupmanager           = [ "navigate", "read", "add", "edit", "delete" ]
			, passwordPolicyManager  = [ "manage" ]
			, websiteBenefitsManager = [ "navigate", "read", "add", "edit", "delete", "prioritize" ]
			, websiteUserManager     = [ "navigate", "read", "add", "edit", "delete", "prioritize", "impersonate" ]
			, devtools               = [ "console" ]
			, systemConfiguration    = [ "manage" ]
			, notifications          = [ "configure" ]
			, maintenanceMode        = [ "configure" ]
			, urlRedirects           = [ "navigate", "addRule", "editRule", "deleteRule" ]
			, presideobject          = {
				  security_user  = [ "read", "add", "edit", "delete", "viewversions" ]
				, security_group = [ "read", "add", "edit", "delete", "viewversions" ]
				, page           = [ "read", "add", "edit", "delete", "viewversions" ]
				, site           = [ "read", "add", "edit", "delete", "viewversions" ]
				, asset          = [ "read", "add", "edit", "delete", "viewversions" ]
				, asset_folder   = [ "read", "add", "edit", "delete", "viewversions" ]
				, link           = [ "read", "add", "edit", "delete", "viewversions" ]
			}
			, assetmanager           = {
				  general = [ "navigate" ]
				, folders = [ "add", "edit", "delete", "manageContextPerms" ]
				, assets  = [ "upload", "edit", "delete", "download", "pick" ]
			 }
		};

		settings.adminRoles = StructNew( "linked" );

		settings.adminRoles.sysadmin      = [ "usermanager.*", "groupmanager.*", "systemConfiguration.*", "presideobject.security_user.*", "presideobject.security_group.*", "websiteBenefitsManager.*", "websiteUserManager.*", "sites.*", "presideobject.links.*", "notifications.*", "passwordPolicyManager.*", "urlRedirects.*"  ];
		settings.adminRoles.contentadmin  = [ "sites.*", "presideobject.site.*", "presideobject.link.*", "sitetree.*", "presideobject.page.*", "datamanager.*", "assetmanager.*", "presideobject.asset.*", "presideobject.asset_folder.*" ];
		settings.adminRoles.contenteditor = [ "presideobject.link.*", "sites.navigate", "sitetree.*", "presideobject.page.*", "datamanager.*", "assetmanager.*", "presideobject.asset.*", "presideobject.asset_folder.*", "!*.delete", "!*.manageContextPerms", "!assetmanager.folders.add" ];

		settings.websitePermissions = {
			  pages  = [ "access" ]
			, assets = [ "access" ]
		};

		// uploads directory - each site really should override this setting and provide an external location
		settings.uploads_directory     = ExpandPath( "/uploads" );
		settings.tmp_uploads_directory = ExpandPath( "/uploads" );

		settings.ckeditor = {
			  defaults    = {
				  stylesheets = [ "/css/admin/specific/richeditor/" ]
				, width       = "auto"
				, minHeight   = 0
				, maxHeight   = 300
				, configFile  = "/ckeditorExtensions/config.js"
			  }
			, toolbars    = _getCkEditorToolbarConfig()
		};

		settings.static = {
			  rootUrl        = ""
			, siteAssetsPath = "/assets"
			, siteAssetsUrl  = "/assets"
		};

		settings.features = {
			  sitetree              = { enabled=true , siteTemplates=[ "*" ] }
			, sites                 = { enabled=true , siteTemplates=[ "*" ] }
			, assetManager          = { enabled=true , siteTemplates=[ "*" ] }
			, websiteUsers          = { enabled=true , siteTemplates=[ "*" ] }
			, datamanager           = { enabled=true , siteTemplates=[ "*" ] }
			, systemConfiguration   = { enabled=true , siteTemplates=[ "*" ] }
			, updateManager         = { enabled=true , siteTemplates=[ "*" ] }
			, cmsUserManager        = { enabled=true , siteTemplates=[ "*" ] }
			, errorLogs             = { enabled=true , siteTemplates=[ "*" ] }
			, passwordPolicyManager = { enabled=true , siteTemplates=[ "*" ] }
			, multilingual          = { enabled=false, siteTemplates=[ "*" ] }
			, "devtools.reload"     = { enabled=true , siteTemplates=[ "*" ] }
			, "devtools.cache"      = { enabled=true , siteTemplates=[ "*" ] }
			, "devtools.new"        = { enabled=false, siteTemplates=[ "*" ] }
			, "devtools.extension"  = { enabled=false, siteTemplates=[ "*" ] }
		};

		settings.filters = {
			livePages = { filter = "page.trashed = 0 and page.active = 1 and ( page.embargo_date is null or now() > page.embargo_date ) and ( page.expiry_date is null or now() < page.expiry_date )" }
		};

		settings.validationProviders = [ "presideObjectValidators", "passwordPolicyValidator" ];

		settings.antiSamy = {
			  enabled                 = true
			, policy                  = "myspace"
			, bypassForAdministrators = true
		};

		_loadConfigurationFromExtensions();

		environments = {
			local = "^local\.,\.local$,^localhost(:[0-9]+)?$,^127.0.0.1(:[0-9]+)?$"
		}

	}

// ENVIRONMENT SPECIFIC
	public void function local() output=false {
		settings.showErrors = true;
		settings.autoSyncDb = true;

		settings.features[ "devtools.new"       ].enabled=true;
		settings.features[ "devtools.extension" ].enabled=true;
	}

// PRIVATE UTILITY
	private array function _getUdfFiles() output=false {
		var udfs     = DirectoryList( "/preside/system/helpers", true, false, "*.cfm" );
		var siteUdfs = ArrayNew(1);
		var udf      = "";
		var i        = 0;

		for( i=1; i lte ArrayLen( udfs ); i++ ) {
			udfs[i] = _getMappedPathFromFull( udfs[i], "/preside/system/helpers/" );
		}

		if ( DirectoryExists( "#settings.appMapping#/helpers" ) ) {
			siteUdfs = DirectoryList( "#settings.appMapping#/helpers", true, false, "*.cfm" );

			for( udf in siteUdfs ){
				ArrayAppend( udfs, _getMappedPathFromFull( udf, "#settings.appMapping#/helpers" ) );
			}
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

		return udfs;
	}

	private string function _getMappedPathFromFull( required string fullPath, required string mapping ) output=false {
		var expandedMapping       = ExpandPath( arguments.mapping );
		var pathRelativeToMapping = Replace( arguments.fullPath, expandedMapping, "" );

		return arguments.mapping & Replace( pathRelativeToMapping, "\", "/", "all" );
	}

	private string function _discoverWireboxBinder() output=false {
		if ( FileExists( "#settings.appMapping#/config/WireBox.cfc" ) ) {
			return "#settings.appMappingPath#.config.WireBox";
		}

		return 'preside.system.config.WireBox';
	}

	private string function _discoverCacheboxConfigurator() output=false {
		if ( FileExists( "#settings.appMapping#/config/Cachebox.cfc" ) ) {
			return "#settings.appMappingPath#.config.Cachebox";
		}

		return "preside.system.config.Cachebox";
	}

	private array function _loadExtensions() output=false {
		return new preside.system.services.devtools.ExtensionManagerService(
			  appMapping          = settings.appMapping
			, extensionsDirectory = "#settings.appMapping#/extensions"
		).listExtensions( activeOnly=true );
	}

	private struct function _getConfiguredFileTypes() output=false{
		var types = {};

		types.image = {
			  jpg  = { serveAsAttachment=false, mimeType="image/jpeg" }
			, jpeg = { serveAsAttachment=false, mimeType="image/jpeg" }
			, gif  = { serveAsAttachment=false, mimeType="image/gif"  }
			, png  = { serveAsAttachment=false, mimeType="image/png"  }
		};

		types.video = {
			  swf = { serveAsAttachment=true, mimeType="application/x-shockwave-flash" }
			, flv = { serveAsAttachment=true, mimeType="video/x-flv" }
		};

		types.document = {
			  pdf  = { serveAsAttachment=true, mimeType="application/pdf"    }
			, csv  = { serveAsAttachment=true, mimeType="application/csv"    }
			, doc  = { serveAsAttachment=true, mimeType="application/msword" }
			, dot  = { serveAsAttachment=true, mimeType="application/msword" }
			, docx = { serveAsAttachment=true, mimeType="application/vnd.openxmlformats-officedocument.wordprocessingml.document" }
			, dotx = { serveAsAttachment=true, mimeType="application/vnd.openxmlformats-officedocument.wordprocessingml.template" }
			, docm = { serveAsAttachment=true, mimeType="application/vnd.ms-word.document.macroEnabled.12" }
			, dotm = { serveAsAttachment=true, mimeType="application/vnd.ms-word.template.macroEnabled.12" }
			, xls  = { serveAsAttachment=true, mimeType="application/vnd.ms-excel" }
			, xlt  = { serveAsAttachment=true, mimeType="application/vnd.ms-excel" }
			, xla  = { serveAsAttachment=true, mimeType="application/vnd.ms-excel" }
			, xlsx = { serveAsAttachment=true, mimeType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet" }
			, xltx = { serveAsAttachment=true, mimeType="application/vnd.openxmlformats-officedocument.spreadsheetml.template" }
			, xlsm = { serveAsAttachment=true, mimeType="application/vnd.ms-excel.sheet.macroEnabled.12" }
			, xltm = { serveAsAttachment=true, mimeType="application/vnd.ms-excel.template.macroEnabled.12" }
			, xlam = { serveAsAttachment=true, mimeType="application/vnd.ms-excel.addin.macroEnabled.12" }
			, xlsb = { serveAsAttachment=true, mimeType="application/vnd.ms-excel.sheet.binary.macroEnabled.12" }
			, ppt  = { serveAsAttachment=true, mimeType="application/vnd.ms-powerpoint" }
			, pot  = { serveAsAttachment=true, mimeType="application/vnd.ms-powerpoint" }
			, pps  = { serveAsAttachment=true, mimeType="application/vnd.ms-powerpoint" }
			, ppa  = { serveAsAttachment=true, mimeType="application/vnd.ms-powerpoint" }
			, pptx = { serveAsAttachment=true, mimeType="application/vnd.openxmlformats-officedocument.presentationml.presentation" }
			, potx = { serveAsAttachment=true, mimeType="application/vnd.openxmlformats-officedocument.presentationml.template" }
			, ppsx = { serveAsAttachment=true, mimeType="application/vnd.openxmlformats-officedocument.presentationml.slideshow" }
			, ppam = { serveAsAttachment=true, mimeType="application/vnd.ms-powerpoint.addin.macroEnabled.12" }
			, pptm = { serveAsAttachment=true, mimeType="application/vnd.ms-powerpoint.presentation.macroEnabled.12" }
			, potm = { serveAsAttachment=true, mimeType="application/vnd.ms-powerpoint.template.macroEnabled.12" }
			, ppsm = { serveAsAttachment=true, mimeType="application/vnd.ms-powerpoint.slideshow.macroEnabled.12" }
		}

		// TODO, more types to be defined here!

		return types;
	}

	private string function _typesToExtensions( required struct types ) output=false {
		var extensions = [];
		for( var cat in arguments.types ) {
			for( var ext in arguments.types[ cat ] ) {
				extensions.append( "." & ext );
			}
		}

		return extensions.toList();
	}

	private struct function _getConfiguredAssetDerivatives() output=false {
		var derivatives  = {};

		derivatives.adminthumbnail = {
			  permissions = "inherit"
			, transformations = [
				  { method="pdfPreview" , args={ page=1                }, inputfiletype="pdf", outputfiletype="jpg" }
				, { method="shrinkToFit", args={ width=200, height=200 } }
			  ]
		};

		derivatives.icon = {
			  permissions = "inherit"
			, transformations = [ { method="shrinkToFit", args={ width=32, height=32 } } ]
		};

		derivatives.pickericon = {
			  permissions = "inherit"
			, transformations = [ { method="shrinkToFit", args={ width=48, height=32 } } ]
		};

		return derivatives;
	}

	private struct function _getCkEditorToolbarConfig() output=false {
		return {
			full     =  'Maximize,-,Source,-,Preview'
					 & '|Cut,Copy,Paste,PasteText,PasteFromWord,-,Undo,Redo'
					 & '|Find,Replace,-,SelectAll,-,Scayt'
					 & '|Widgets,ImagePicker,AttachmentPicker,Table,HorizontalRule,SpecialChar,Iframe'
					 & '|PresideLink,PresideUnlink,PresideAnchor'
					 & '|Bold,Italic,Underline,Strike,Subscript,Superscript,RemoveFormat'
					 & '|NumberedList,BulletedList,-,Outdent,Indent,-,Blockquote,CreateDiv,-,JustifyLeft,JustifyCenter,JustifyRight,JustifyBlock,-,BidiLtr,BidiRtl,Language'
					 & '|Styles,Format',

			noInserts = 'Maximize,-,Source,-,Preview'
					 & '|Cut,Copy,Paste,PasteText,PasteFromWord,-,Undo,Redo'
					 & '|Find,Replace,-,SelectAll,-,Scayt'
					 & '|PresideLink,PresideUnlink,PresideAnchor'
					 & '|Bold,Italic,Underline,Strike,Subscript,Superscript,RemoveFormat'
					 & '|NumberedList,BulletedList,-,Outdent,Indent,-,Blockquote,CreateDiv,-,JustifyLeft,JustifyCenter,JustifyRight,JustifyBlock,-,BidiLtr,BidiRtl,Language'
					 & '|Styles,Format',

			bolditaliconly = 'Bold,Italic'
		};

	}

	private string function _getCookieEncryptionKey() output=false {
		var cookieKeyFile = "#settings.appMapping#/config/.cookieEncryptionKey";
		if ( FileExists( cookieKeyFile ) ) {
			try {
				return FileRead( cookieKeyFile );
			} catch( any e ) {}
		}

		var key = GenerateSecretKey( "AES" );
		FileWrite( cookieKeyFile, key );

		return key;
	}

	private void function _loadConfigurationFromExtensions() output=false {
		for( var ext in settings.activeExtensions ){
			if ( FileExists( ext.directory & "/config/Config.cfc" ) ) {
				var cfcPath = ReReplace( ListChangeDelims( ext.directory & "/config/Config", ".", "/" ), "^\.", "" );

				CreateObject( cfcPath ).configure( config=variables );
			}
		}
	}
}