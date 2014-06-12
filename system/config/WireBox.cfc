 component extends="coldbox.system.ioc.config.Binder" output=false {

	public void function configure() output=false {

		var settings = getColdbox().getSettingStructure();

	// base objects (todo, make mixin style concerns rather than real inheritance)
		map( "baseService" ).asSingleton().to( "preside.system.base.Service" ).noAutoWire()
			.initArg( name="presideObjectService", ref="PresideObjectService" )
			.initArg( name="logger"              , ref="defaultLogger" );

	// utilities
		map( "defaultLogger" ).asSingleton().to( "preside.system.api.logger.CfLogLogger" ).noAutowire()
			.initArg( name="defaultLog", value=settings.default_log_name  ?: "preside" )
			.initArg( name="logLevel"  , value=settings.default_log_level ?: "information" );

		map( "sessionService" ).asSingleton().to( "preside.system.api.cfmlScopes.SessionService" ).noAutowire();

		map( "bCryptService" ).asSingleton().to( "preside.system.api.encryption.bcrypt.BCryptService" ).noAutowire();
		map( "resourceBundleService" ).asSingleton().to( "preside.system.api.i18n.ResourceBundleService" ).noAutowire()
			.initArg( name="bundleDirectories", value=_getApplicationDirectories( "/i18n/" ) );

	// database abstractions
		map( "sqlLogger" ).asSingleton().to( "preside.system.api.logger.CfLogLogger" ).noAutowire()
			.initArg( name="defaultLog", value=settings.sql_log_name  ?: "preside_sql" )
			.initArg( name="logLevel"  , value=settings.sql_log_level ?: "information" );

		map( "sqlRunner" ).asSingleton().to( "preside.system.api.database.sqlRunner" ).noAutowire()
			.initArg( name="logger", ref="sqlLogger" );

		map( "dbInfoService" ).asSingleton().to( "preside.system.api.database.Info" ).noAutowire();

		map( "dbAdapterFactory" ).asSingleton().to( "preside.system.api.database.adapters.AdapterFactory" ).noAutowire()
			.initArg( name="dbInfoService", ref="dbInfoService" )
			.initArg( name="cache"        , dsl="cachebox:SystemCache" );

	// preside objects setup
		map( "sqlLogger" ).asSingleton().to( "preside.system.api.logger.CfLogLogger" ).noAutowire()
			.initArg( name="defaultLog", value=settings.sql_log_name  ?: "preside_sql" )
			.initArg( name="logLevel"  , value=settings.sql_log_level ?: "information" );

		map( "objectReaderService" ).asSingleton().to( "preside.system.api.presideObjects.Reader" ).noAutoWire()
			.initArg( name="dsn"        , value=settings.dsn ?: "preside" )
			.initArg( name="tablePrefix", value=settings.preside_objects_table_prefix ?: "pobj_" );

		map( "schemaVersioningService" ).asSingleton().to( "preside.system.api.presideObjects.sqlSchemaVersioning" ).noAutoWire()
			.initArg( name="adapterFactory", ref="dbAdapterFactory" )
			.initArg( name="sqlRunner"     , ref="sqlRunner"        )
			.initArg( name="dbInfoService" , ref="dbInfoService"    );

		map( "schemaSyncService" ).asSingleton().to( "preside.system.api.presideObjects.sqlSchemaSynchronizer" ).noAutoWire()
			.initArg( name="adapterFactory"         , ref="dbAdapterFactory"        )
			.initArg( name="sqlRunner"              , ref="sqlRunner"               )
			.initArg( name="dbInfoService"          , ref="dbInfoService"           )
			.initArg( name="schemaVersioningService", ref="schemaVersioningService" );

		map( "relationshipGuidanceService" ).asSingleton().to( "preside.system.api.presideObjects.relationshipGuidance" ).noAutoWire()
			.initArg( name="objectReader", ref="objectReaderService" );

		map( "presideObjectDecorator" ).asSingleton().to( "preside.system.api.presideObjects.presideObjectDecorator" ).noAutoWire()

		map( "PresideObjectService" ).asSingleton().to( "preside.system.api.presideObjects.PresideObjectService" ).noAutoWire()
			.initArg( name="objectDirectories"     , value=_getApplicationDirectories( "/preside-objects/" ) )
			.initArg( name="objectReader"          , ref="objectReaderService"           )
			.initArg( name="sqlSchemaSynchronizer" , ref="schemaSyncService"             )
			.initArg( name="adapterFactory"        , ref="dbAdapterFactory"              )
			.initArg( name="sqlRunner"             , ref="sqlRunner"                     )
			.initArg( name="relationshipGuidance"  , ref="relationshipGuidanceService"   )
			.initArg( name="presideObjectDecorator", ref="presideObjectDecorator"        )
			.initArg( name="objectCache"           , dsl="cachebox:SystemCache" )
			.initArg( name="defaultQueryCache"     , dsl="cachebox:DefaultQueryCache"    );

		map( "presideObjectViewService" ).asSingleton().to( "preside.system.api.presideObjects.PresideObjectViewService" ).noAutoWire()
			.initArg( name="presideObjectService"  , ref="PresideObjectService" )
			.initArg( name="presideContentRenderer", ref="contentRenderer" )
			.initArg( name="coldboxRenderer"       , dsl="coldbox:plugin:renderer" )
			.initArg( name="viewDirectories"       , value=_getApplicationDirectories( "/views/" ) );

	// route handlers
		map( "adminRouteHandler" ).asSingleton().to( "preside.system.routeHandlers.AdminRouteHandler" ).noAutowire()
			.initArg( name="adminPath"        , value=settings.preside_admin_path ?: "pcms_admin" )
			.initArg( name="eventName"        , value=settings.eventName          ?: "event" )
			.initArg( name="adminDefaultEvent", value=settings.adminDefaultEvent  ?: "sitetree" );

		map( "assetRouteHandler" ).asSingleton().to( "preside.system.routeHandlers.AssetRouteHandler" ).noAutowire()
			.initArg( name="eventName", value=settings.eventName ?: "event" );

		map( "staticAssetRouteHandler" ).asSingleton().to( "preside.system.routeHandlers.StaticAssetRouteHandler" ).noAutowire()
			.initArg( name="eventName", value=settings.eventName ?: "event" );

		map( "defaultPresideRouteHandler" ).asSingleton().to( "preside.system.routeHandlers.DefaultPresideRouteHandler" ).noAutowire()
			.initArg( name="eventName"      , value=settings.eventName ?: "event" )
			.initArg( name="sitetreeService", ref="siteTreeService" );

	// admin related services
		map( "adminLoginService" ).asSingleton().to( "preside.system.api.admin.LoginService" ).parent( "baseService" ).noAutoWire()
			.initArg( name="sessionService", ref="sessionService"                      )
			.initArg( name="bCryptService" , ref="bCryptService"                       )
			.initArg( name="systemUserList", value=settings.system_users ?: "sysadmin" );

		map( "auditService" ).asSingleton().to ( "preside.system.api.admin.AuditService" ).parent( "baseService" ).noAutoWire();

		map( "dataManagerService" ).asSingleton().to( "preside.system.api.admin.DataManagerService" ).parent( "baseService" ).noAutoWire()
			.initArg( name="contentRenderer"  , ref="contentRenderer" )
			.initArg( name="permissionService", ref="permissionService" )
			.initArg( name="i18nPlugin"       , dsl="coldbox:plugin:i18n" );

		map( "assetStorageProvider" ).asSingleton().to( "preside.system.api.fileStorage.FileSystemStorageProvider" ).parent( "baseService" ).noAutoWire()
			.initArg( name="rootDirectory" , value=settings.uploads_directory & "/assets" )
			.initArg( name="trashDirectory", value=settings.uploads_directory & "/.trash" )
			.initArg( name="rootUrl"       , value="" );

		map( "tempStorageProvider" ).asSingleton().to( "preside.system.api.fileStorage.FileSystemStorageProvider" ).parent( "baseService" ).noAutoWire()
			.initArg( name="rootDirectory" , value=settings.tmp_uploads_directory & "/.tmp" )
			.initArg( name="trashDirectory", value=settings.tmp_uploads_directory & "/.trash" )
			.initArg( name="rootUrl"       , value="" );

		map( "imageManipulationService" ).asSingleton().to( "preside.system.api.assetManager.ImageManipulationService" ).parent( "baseService" ).noAutoWire();
		map( "assetTransformer" ).asSingleton().to( "preside.system.api.assetManager.AssetTransformer" ).parent( "baseService" ).noAutoWire()
			.initArg( name="imageManipulationService", ref="imageManipulationService" );

		map( "assetManagerService" ).asSingleton().to( "preside.system.api.assetManager.AssetManagerService" ).parent( "baseService" ).noAutoWire()
			.initArg( name="storageProvider"         , ref="assetStorageProvider" )
			.initArg( name="temporaryStorageProvider", ref="tempStorageProvider" )
			.initArg( name="assetTransformer"        , ref="assetTransformer" )
			.initArg( name="configuredDerivatives"   , value=settings.assetManager.derivatives ?: {} )
			.initArg( name="configuredTypesByGroup"  , value=settings.assetManager.types ?: {} )

		map( "assetRendererService" ).asSingleton().to( "preside.system.api.assetManager.assetRendererService" ).parent( "baseService" ).noAutoWire()
			.initArg( name="assetManagerService", ref="assetManagerService" )
			.initArg( name="coldbox", value=getColdbox() );

		map( "ckeditorToolbarHelper" ).asSingleton().to( "preside.system.api.admin.CkEditorToolbarHelper" ).noAutowire()
			.initArg( name="configuredToolbars", value=settings.ckeditor.toolbars ?: {} );

	// globally used services
		map( "validationEngine" ).asSingleton().to( "preside.system.api.validation.ValidationEngine" ).parent( "baseService" ).noAutoWire();

		map( "presideObjectValidators" ).asSingleton().to( "preside.system.api.validation.PresideObjectValidators" ).parent( "baseService" ).noAutoWire();

		map( "presideFieldRuleGenerator" ).asSingleton().to( "preside.system.api.validation.PresideFieldRuleGenerator" ).parent( "baseService" ).noAutoWire()
			.initArg( name="resourceBundleService", ref="resourceBundleService" );

		map( "siteTreeService" ).asSingleton().to( "preside.system.api.siteTree.SiteTreeService" ).parent( "baseService" ).noAutoWire()
			.initArg( name="loginService"    , ref="adminLoginService" )
			.initArg( name="pageTypesService", ref="pageTypesService" );

		map( "formsService" ).asSingleton().to( "preside.system.api.forms.FormsService" ).parent( "baseService" ).noAutoWire()
			.initArg( name="validationEngine"         , ref   = "validationEngine"                      )
			.initArg( name="presideFieldRuleGenerator", ref   = "presideFieldRuleGenerator"             )
			.initArg( name="i18n"                     , dsl   = "coldbox:plugin:i18n"                   )
			.initArg( name="defaultContextName"       , dsl   = "coldbox:fwSetting:EventAction"         )
			.initArg( name="configuredControls"       , dsl   = "coldbox:setting:formControls"          )
			.initArg( name="coldbox"                  , value = getColdbox()                            )
			.initArg( name="formDirectories"          , value = _getApplicationDirectories( "/forms/" ) );

		map( "widgetsService" ).asSingleton().to( "preside.system.api.widgets.WidgetsService" ).parent( "baseService" ).noAutoWire()
			.initArg( name="configuredWidgets", dsl   = "coldbox:setting:widgets" )
			.initArg( name="formsService"           , ref   = "formsService"               )
			.initArg( name="autoDiscoverDirectories", value = _getApplicationDirectories() )
			.initArg( name="coldbox"                , value = getColdbox()                 );

		map( "contentRenderer" ).asSingleton().to( "preside.system.api.rendering.ContentRendererService" ).parent( "baseService" ).noAutoWire()
			.initArg( name="coldbox"             , value=getColdbox() )
			.initArg( name="cache"               , dsl="cachebox:systemCache" )
			.initArg( name="assetRendererService", ref="assetRendererService" )
			.initArg( name="widgetsService"      , ref="widgetsService" );

		map( "pageTypesService" ).asSingleton().to( "preside.system.api.pageTypes.PageTypesService" ).parent( "baseService" ).noAutoWire()
			.initArg( name="autoDiscoverDirectories", value = _getApplicationDirectories()  );


		map( "draftService" ).asSingleton().to( "preside.system.api.drafts.DraftService" ).parent( "baseService" ).noAutoWire();

		map( "FrontendEditingService" ).asSingleton().to( "preside.system.api.frontendEditing.FrontendEditingService" ).parent( "baseService" ).noAutoWire()
			.initArg( name="draftService", ref="draftService" );

		map( "csrfProtectionService" ).asSingleton().to( "preside.system.api.security.CsrfProtectionService" ).noAutoWire()
			.initArg( name="sessionService"      , ref="sessionService"                      )
			.initArg( name="tokenExpiryInSeconds", value=settings.csrf_token_timeout ?: 1200 )
			.initArg( name="maxTokens"           , value=settings.csrf_max_tokens    ?: 100  );

		map( "permissionService" ).asSingleton().to( "preside.system.api.security.PermissionService" ).parent( "baseService" ).noAutoWire()
			.initArg( name="loginService"     , ref  ="adminLoginService"         )
			.initArg( name="permissionsConfig", value=settings.permissions ?: {}  )
			.initArg( name="rolesConfig"      , value=settings.roles       ?: {}  )
			.initArg( name="cacheProvider"    , dsl  ="cachebox:PermissionsCache" );

	// DEVELOPER TOOLS
		map( "scaffoldingService" ).asSingleton().to( "preside.system.api.devtools.ScaffoldingService" ).parent( "baseService" ).noAutoWire()
			.initArg( name="widgetsService"  , ref="widgetsService" )
			.initArg( name="pageTypesService", ref="pageTypesService" );

		map( "applicationReloadService" ).asSingleton().to( "preside.system.api.devtools.ApplicationReloadService" ).parent( "baseService" ).noAutoWire()
			.initArg( name="coldbox"              , value = getColdbox()                           )
			.initArg( name="resourceBundleService", ref   = "resourceBundleService"                )
			.initArg( name="StickerForPreside"    , dsl   = "coldbox:myPlugin:StickerForPreside"   )
			.initArg( name="widgetsService"       , ref   = "widgetsService"                       )
			.initArg( name="pageTypesService"     , ref   = "pageTypesService"                     )
			.initArg( name="formsService"         , ref   = "formsService"                         );

		map( "extensionManagerService" ).asSingleton().to( "preside.system.api.devtools.ExtensionManagerService" ).noAutoWire()
			.initArg( name="extensionsDirectory"     , value="/app/extensions" );

	}

	private array function _getApplicationDirectories( string subDir="" ) output=false {
		if ( !ReFind( "^/", subDir ) ) {
			subDir = "/" & subDir;
		}

		var directories = [ "/preside/system#subDir#" ];
		var extensions  = getColdbox().getSetting( name="activeExtensions", defaultValue=[] );

		for( var i=extensions.len(); i > 0; i-- ){
			ArrayAppend( directories, extensions[i].directory & subDir );
		}

		ArrayAppend( directories, "/app#subDir#" );

		return directories;
	}
}