 component extends="coldbox.system.ioc.config.Binder" output=false {

	public void function configure() output=false {
		scopeRegistration( false );

		_registerAopListener();
		_setupCustomDslProviders();
		_mapCommonSystemServices();
		_mapSpecificSystemServices();
		_mapExtensionServices();
		_mapSiteServices();
		_loadExtensionConfigurations();
	}

// PRIVATE UTILITY
	private void function _setupCustomDslProviders() output=false {
		mapDSL( "presidecms", "preside.system.coldboxModifications.PresideWireboxDsl" );
	}

	private void function _mapCommonSystemServices() output=false {
		mapDirectory( packagePath="preside.system.services", exclude="FileSystemStorageProvider|logger" );
	}

	private void function _mapSiteServices() output=false {
		if ( DirectoryExists( "/app/services" ) ) {
			mapDirectory( packagePath="app.services" );
		}
	}

	private void function _mapExtensionServices() output=false {
		var extensions  = getColdbox().getSetting( name="activeExtensions", defaultValue=[] );
		for( var i=extensions.len(); i > 0; i-- ){
			var servicesDir = ListAppend( extensions[i].directory, "services", "/" )
			if ( DirectoryExists( servicesDir ) ) {
				mapDirectory( packagePath=servicesDir );
			}
		}
	}

	private void function _mapSpecificSystemServices() output=false {
		var settings = getColdbox().getSettingStructure();

		map( "baseService" ).to( "preside.system.base.Service" ).noAutoWire();

		map( "defaultLogger" ).asSingleton().to( "preside.system.services.logger.CfLogLogger" ).noAutowire()
			.initArg( name="defaultLog", value=settings.default_log_name  ?: "preside" )
			.initArg( name="logLevel"  , value=settings.default_log_level ?: "information" );

		map( "assetStorageProvider" ).asSingleton().to( "preside.system.services.fileStorage.FileSystemStorageProvider" ).parent( "baseService" ).noAutoWire()
			.initArg( name="rootDirectory" , value=settings.uploads_directory & "/assets" )
			.initArg( name="trashDirectory", value=settings.uploads_directory & "/.trash" )
			.initArg( name="rootUrl"       , value="" );

		map( "tempStorageProvider" ).asSingleton().to( "preside.system.services.fileStorage.FileSystemStorageProvider" ).parent( "baseService" ).noAutoWire()
			.initArg( name="rootDirectory" , value=settings.tmp_uploads_directory & "/.tmp" )
			.initArg( name="trashDirectory", value=settings.tmp_uploads_directory & "/.trash" )
			.initArg( name="rootUrl"       , value="" );
	}

	private void function _loadExtensionConfigurations() output=false {
		var extensions  = getColdbox().getSetting( name="activeExtensions", defaultValue=[] );
		for( var i=extensions.len(); i > 0; i-- ){
			var wireboxConfigPath = ListAppend( extensions[i].directory, "config/Wirebox.cfc", "/" );
			if ( FileExists( wireboxConfigPath ) ) {
				CreateObject( "app.extensions.#ListLast( extensions[i].directory, '\/' )#.config.Wirebox" ).configure( binder=this );
			}
		}
	}

	private void function _registerAopListener() output=false {
		wirebox.listeners = [
			{ class="coldbox.system.aop.Mixer",properties={} }
		];
	}
}