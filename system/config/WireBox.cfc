 component extends="coldbox.system.ioc.config.Binder" {

	public void function configure() {
		_setupCustomDslProviders();
		_mapCommonSystemServices();
		_mapSpecificSystemServices();
		_mapExtensionServices();
		_mapSiteServices();
		_loadExtensionConfigurations();
	}

// PRIVATE UTILITY
	private void function _setupCustomDslProviders() {
		mapDSL( "presidecms", "preside.system.coldboxModifications.PresideWireboxDsl" );
		mapDSL( "delayedInjector", "preside.system.coldboxModifications.DelayedInjectorDsl" );
		mapDSL( "coldbox", "preside.system.coldboxModifications.LegacyDslBuilder" );
	}

	private void function _mapCommonSystemServices() {
		mapDirectory( packagePath="preside.system.services", exclude="FileSystemStorageProvider|logger", influence=function( mapping, objectPath ) {
			_injectPresideSuperClass( argumentCollection=arguments );
		} );
	}

	private void function _mapSiteServices() {
		var appMapping     = getColdbox().getSetting( name="appMapping"    , defaultValue="app" ).reReplace( "^/", "" );
		var appMappingPath = getColdbox().getSetting( name="appMappingPath", defaultValue="app"  );

		if ( DirectoryExists( "/#appMapping#/services" ) ) {
			mapDirectory( packagePath="#appMappingPath#.services", influence=function( mapping, objectPath ) {
				_injectPresideSuperClass( argumentCollection=arguments );
			} );
		}
	}

	private void function _mapExtensionServices() {
		var extensions  = getColdbox().getSetting( name="activeExtensions", defaultValue=[] );
		for( var i=1; i<=extensions.len(); i++ ){
			var servicesDir = ListAppend( extensions[i].directory, "services", "/" )
			if ( DirectoryExists( servicesDir ) ) {
				mapDirectory( packagePath=servicesDir, influence=function( mapping, objectPath ) {
					_injectPresideSuperClass( argumentCollection=arguments );
				}  );
			}
		}
	}

	private void function _mapSpecificSystemServices() {
		var settings = getColdbox().getSettingStructure();

		map( "baseService" ).to( "preside.system.base.Service" ).noAutoWire();

		map( "defaultLogger" ).asSingleton().to( "preside.system.services.logger.CfLogLogger" ).noAutowire()
			.initArg( name="defaultLog", value=settings.default_log_name  ?: "preside" )
			.initArg( name="logLevel"  , value=settings.default_log_level ?: "information" );

		map( "assetStorageProvider" ).asSingleton().to( "preside.system.services.fileStorage.FileSystemStorageProvider" ).parent( "baseService" ).noAutoWire()
			.initArg( name="rootDirectory"   , value=settings.assetmanager.storage.public    )
			.initArg( name="privateDirectory", value=settings.assetmanager.storage.private   )
			.initArg( name="trashDirectory"  , value=settings.assetmanager.storage.trash     )
			.initArg( name="rootUrl"         , value=settings.assetmanager.storage.publicUrl );

		map( "formBuilderStorageProvider" ).asSingleton().to( "preside.system.services.fileStorage.FileSystemStorageProvider" ).parent( "baseService" ).noAutoWire()
			.initArg( name="rootDirectory"   , value=settings.uploads_directory & "/formbuilder" )
			.initArg( name="privateDirectory", value=settings.uploads_directory & "/formbuilder" )
			.initArg( name="trashDirectory"  , value=settings.uploads_directory & "/.trash" )
			.initArg( name="rootUrl"         , value="" );

		map( "spreadsheetLib" ).asSingleton().to( "spreadsheetlib.Spreadsheet" );
		map( "presideRenderer" ).asSingleton().to( "preside.system.coldboxModifications.services.Renderer" );

		var emailQueueConcurrency = Val( settings.email.queueConcurrency ?: 1 );
		for( var i=1; i <= emailQueueConcurrency; i++ ) {
			map( "PresideEmailQueueHeartBeat#i#" )
			    .asSingleton()
			    .to( "preside.system.services.concurrency.PresideEmailQueueHeartBeat" )
			    .initArg( name="instanceNumber", value=i )
			    .virtualInheritance( "presideSuperClass" );
		}

		var assetQueueConcurrency = Val( settings.assetmanager.queue.concurrency ?: 1 );
		for( var i=1; i <= assetQueueConcurrency; i++ ) {
			map( "AssetQueueHeartbeat#i#" )
			    .asSingleton()
			    .to( "preside.system.services.concurrency.AssetQueueHeartbeat" )
			    .initArg( name="instanceNumber", value=i )
			    .virtualInheritance( "presideSuperClass" );
		}

		var healthcheckServices = settings.healthCheckServices ?: {};
		var msInADay            = 86400000;
		for( var serviceId in healthcheckServices ) {
			var intervalInMs = Val( healthcheckServices[ serviceId ].interval ?: CreateTimeSpan( 0, 0, 0, 30 ) ) * msInADay;

			map( "healthcheckHeartBeat#serviceId#" )
			    .asSingleton()
			    .to( "preside.system.services.concurrency.HealthcheckHeartBeat" )
			    .initArg( name="serviceId", value=serviceId )
			    .initArg( name="intervalInMs", value=intervalInMs )
			    .virtualInheritance( "presideSuperClass" );
		}
	}

	private void function _loadExtensionConfigurations() {
		var extensions     = getColdbox().getSetting( name="activeExtensions", defaultValue=[] );
		var appMappingPath = getColdbox().getSetting( name="appMappingPath"  , defaultValue="app" );

		for( var i=1; i<=extensions.len(); i++ ){
			var wireboxConfigPath = ListAppend( extensions[i].directory, "config/Wirebox.cfc", "/" );
			if ( FileExists( wireboxConfigPath ) ) {
				CreateObject( "#appMappingPath#.extensions.#ListLast( extensions[i].directory, '\/' )#.config.Wirebox" ).configure( binder=this );
			}
		}
	}

	private void function _injectPresideSuperClass( required any mapping, required string objectPath ) {
		if ( _wantsPresideInjection( getComponentMetaData( arguments.objectPath ) ) ) {
			arguments.mapping.virtualInheritance( "presideSuperClass" );
		}
	}

	private boolean function _wantsPresideInjection( required struct meta ) {
		if ( StructKeyExists( arguments.meta, "presideService" ) ) {
			return true;
		}

		if ( StructKeyExists( arguments.meta, "extends" ) && arguments.meta.extends.count() ) {
			return _wantsPresideInjection( arguments.meta.extends );
		}

		return false;
	}
}