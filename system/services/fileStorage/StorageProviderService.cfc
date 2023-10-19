/**
 * @singleton
 * @presideService
 *
 */
component {

// CONSTRUCTOR
	/**
	 * @configuredProviders.inject coldbox:setting:storageproviders
	 *
	 */
	public any function init( required any configuredProviders ) {
		_setConfiguredProviders( arguments.configuredProviders );

		return this;
	}

// PUBLIC API METHODS
	public array function listProviders() {
		return _getConfiguredProviders().keyArray();
	}

	public any function getProvider( required string id, struct configuration={}, boolean skipConstructor=false ) {
		var providers = _getConfiguredProviders();

		if ( StructKeyExists( providers, arguments.id ) ) {
			return _createObject(
				  cfcPath         = providers[ arguments.id ].class
				, constructorArgs = arguments.configuration
				, skipConstructor = arguments.skipConstructor
			);
		}

		throw( type="presidecms.storage.provider.not.found", message="The storage provider, [#arguments.id#], is not registered with the Storage Provider Service" );
	}

	public any function validateProvider(
		  required string id
		, required struct configuration
		, required any validationResult
	) {
		var provider = getProvider( id=arguments.id, configuration=arguments.configuration, skipConstructor=true );

		return provider.validate( validationResult=arguments.validationResult, configuration=arguments.configuration );
	}

	public boolean function providerSupportsFileSystem( required any storageProvider ) {
		if ( !StructKeyExists( arguments.storageProvider, "__supportsFileSystem" ) ) {
			var meta = getComponentMetadata( arguments.storageProvider );

			if ( $helpers.isTrue( meta.fileSystemSupport ?: "" ) ) {
				arguments.storageProvider.__supportsFileSystem = true;
			} else if ( IsInstanceOf( arguments.storageProvider, "StorageProviderFileSystemSupport" ) ) {
				arguments.storageProvider.__supportsFileSystem = true;
			} else {
				arguments.storageProvider.__supportsFileSystem = false;
			}
		}

		return arguments.storageProvider.__supportsFileSystem;
	}

// PRIVATE HELPERS
	private any function _createObject( required string cfcPath, required struct constructorArgs, required boolean skipConstructor ) {
		var instance = CreateObject( "component", arguments.cfcPath );

		return arguments.skipConstructor ? instance : instance.init( argumentCollection=constructorArgs )
	}

// GETTERS AND SETTERS
	private any function _getConfiguredProviders() {
		return _configuredProviders;
	}
	private void function _setConfiguredProviders( required any configuredProviders ) {
		_configuredProviders = arguments.configuredProviders;
	}

}