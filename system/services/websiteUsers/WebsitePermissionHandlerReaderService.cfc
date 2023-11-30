/**
 * @singleton      true
 * @presideService true
 */
component {

	public any function init() {
		return this;
	}

	public struct function getPermissionHandlerFromDirectories( required array directories ) {
		var permissionHandlers = {};

		for( var dir in arguments.directories ) {
			permissionHandlers.append( getPermissionHandlerFromDirectory( dir ) );
		}

		return permissionHandlers;
	}

	public struct function getPermissionHandlerFromDirectory( required string directory ) {
		var dottedDirPath   = arguments.directory.reReplace( "[\\/]", ".", "all" ).reReplace( "^\.", "" ).reReplace( "\.$", "" );
		var expandedDirPath = ExpandPath( arguments.directory );
		var handlerCfcs     = DirectoryList( expandedDirPath, true, "path", "*.cfc" );
		var permissionHandlers     = {};

		for( var handlerCfc in handlerCfcs ){
			var relativePath       = handlerCfc.replace( expandedDirPath, "" );
			var dottedRelativePath = relativePath.reReplace( "[\\/]", ".", "all" ).reReplace( "^\.", "" ).reReplace( "\.cfc$", "" );
			var dottedCfcPath         = dottedDirPath & "." & dottedRelativePath;

			permissionHandlers.append( getPermissionHandlerFromCfc(
				  componentPath = dottedCfcPath
				, rootPath      = dottedDirPath
			) );
		}

		return permissionHandlers;
	}

	public struct function getPermissionHandlerFromCfc( required string componentPath, required string rootPath ) {
		var feature = preside.system.services.helpers.ComponentMetaDataReader::getComponentAttribute( arguments.componentPath, "feature" );

		if ( len( trim( feature ) ) && !$isFeatureEnabled( feature ) ) {
			return {};
		}

		var permissions = {};
		var functions   = preside.system.services.helpers.ComponentMetaDataReader::getComponentFunctions( arguments.componentPath );
		var baseId      = arguments.componentPath.replaceNoCase( rootPath, "" ).reReplace( "^\.", "" );

		for( var functionName in functions ) {
			if ( functionName == "checkPermission" ) {
				permissions[ baseId ] = {
					  handler    = "websitePermissions.#baseId#.checkPermission"
					, keyPattern = functions[ functionName ].keyPattern ?: ".*"
				};
			}
		}

		return permissions;
	}
}