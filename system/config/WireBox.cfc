 component extends="coldbox.system.ioc.config.Binder" output=false {

	public void function configure() output=false {
		_setupCustomDslProviders();
		_mapCommonDirectories();
		_mapSpecificInstancesOfServices();
	}

// PRIVATE UTILITY
	private void function _setupCustomDslProviders() output=false {
		mapDSL( "presidecms", "preside.system.coldboxModifications.PresideWireboxDsl" );
	}

	private void function _mapCommonDirectories() output=false {
		mapDirectory( packagePath="preside.system.api", exclude="FileSystemStorageProvider|logger" );
		mapDirectory( "preside.system.routeHandlers" );
	}

	private void function _mapSpecificInstancesOfServices() output=false {
		var settings = getColdbox().getSettingStructure();

		map( "baseService" ).to( "preside.system.base.Service" ).noAutoWire();

		map( "defaultLogger" ).asSingleton().to( "preside.system.api.logger.CfLogLogger" ).noAutowire()
			.initArg( name="defaultLog", value=settings.default_log_name  ?: "preside" )
			.initArg( name="logLevel"  , value=settings.default_log_level ?: "information" );

		map( "assetStorageProvider" ).asSingleton().to( "preside.system.api.fileStorage.FileSystemStorageProvider" ).parent( "baseService" ).noAutoWire()
			.initArg( name="rootDirectory" , value=settings.uploads_directory & "/assets" )
			.initArg( name="trashDirectory", value=settings.uploads_directory & "/.trash" )
			.initArg( name="rootUrl"       , value="" );

		map( "tempStorageProvider" ).asSingleton().to( "preside.system.api.fileStorage.FileSystemStorageProvider" ).parent( "baseService" ).noAutoWire()
			.initArg( name="rootDirectory" , value=settings.tmp_uploads_directory & "/.tmp" )
			.initArg( name="trashDirectory", value=settings.tmp_uploads_directory & "/.trash" )
			.initArg( name="rootUrl"       , value="" );
	}
}