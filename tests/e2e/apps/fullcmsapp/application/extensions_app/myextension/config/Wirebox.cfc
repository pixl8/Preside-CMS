component {

	public void function configure( required any binder ) {
		var settings = binder.getColdbox().getSettingStructure();

		binder.map( "myAppExtensionStorageProvider" ).to( "preside.system.services.fileStorage.FileSystemStorageProvider" )
				.initArg( name="rootDirectory"   , value=settings.uploads_directory & "/myAppExtensionStorageProvider" )
				.initArg( name="privateDirectory", value=settings.uploads_directory & "/myAppExtensionStorageProvider" )
				.initArg( name="trashDirectory"  , value=settings.uploads_directory & "/.trash" )
				.initArg( name="rootUrl"         , value="" );
	}

}
