 component extends="coldbox.system.ioc.config.Binder" {

	public void function configure() {
		_registerAopListener();
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
	}

	private void function _mapCommonSystemServices() {
		mapDirectory( packagePath="preside.system.services", exclude="FileSystemStorageProvider|logger", influence=function( mapping, objectPath ) {
			_injectPresideSuperClass( argumentCollection=arguments );
		} );
	}

	private void function _mapSiteServices() {
		var appMapping     = getColdbox().getSetting( name="appMapping"    , defaultValue="/app" );
		var appMappingPath = getColdbox().getSetting( name="appMappingPath", defaultValue="app"  );

		if ( DirectoryExists( "#appMapping#/services" ) ) {
			mapDirectory( packagePath="#appMappingPath#.services", influence=function( mapping, objectPath ) {
				_injectPresideSuperClass( argumentCollection=arguments );
			} );
		}
	}

	private void function _mapExtensionServices() {
		var extensions  = getColdbox().getSetting( name="activeExtensions", defaultValue=[] );
		for( var i=extensions.len(); i > 0; i-- ){
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
	}

	private void function _loadExtensionConfigurations() {
		var extensions     = getColdbox().getSetting( name="activeExtensions", defaultValue=[] );
		var appMappingPath = getColdbox().getSetting( name="appMappingPath"  , defaultValue="app" );

		for( var i=extensions.len(); i > 0; i-- ){
			var wireboxConfigPath = ListAppend( extensions[i].directory, "config/Wirebox.cfc", "/" );
			if ( FileExists( wireboxConfigPath ) ) {
				CreateObject( "#appMappingPath#.extensions.#ListLast( extensions[i].directory, '\/' )#.config.Wirebox" ).configure( binder=this );
			}
		}
	}

	private void function _registerAopListener() {
		wirebox.listeners = [
			{ class="coldbox.system.aop.Mixer",properties={} }
		];
	}

	private void function _injectPresideSuperClass( required any mapping, required string objectPath ) {
		if ( _wantsPresideInjection( getComponentMetaData( arguments.objectPath ) ) ) {
			arguments.mapping.virtualInheritance( "presideSuperClass" );
		}
	}

	private boolean function _wantsPresideInjection( required struct meta ) {
		if ( arguments.meta.keyExists( "presideService" ) ) {
			return true;
		}

		if ( arguments.meta.keyExists( "extends" ) && arguments.meta.extends.count() ) {
			return _wantsPresideInjection( arguments.meta.extends );
		}

		return false;
	}
}