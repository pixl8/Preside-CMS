/**
 * Simple Wrapper for configured file types
 *
 * @singleton      true
 * @presideService true
 * @autodoc        true
 */
component displayName="AssetManager Service" {


	property name="configuredTypesByGroup" inject="coldbox:setting:assetManager.types";

	public any function init() {
		return this;
	}

	public void function postInit() {
		_setupConfiguredFileTypesAndGroups( configuredTypesByGroup );
	}

// PUBLIC API METHODS
	public array function listTypesForGroup( required string groupName ) {
		var groups = _getGroups();

		return groups[ arguments.groupName ] ?: [];
	}

	public array function expandTypeList( required array types, boolean prefixExtensionsWithPeriod=false ) {
		var expanded = [];
		var types    = getTypes();

		for( var typeName in arguments.types ){
			if ( StructKeyExists( types, typeName ) ) {
				expanded.append( typeName );
			} else {
				for( var typeName in listTypesForGroup( typeName ) ){
					expanded.append( typeName );
				}
			}
		}

		if ( arguments.prefixExtensionsWithPeriod ) {
			for( var i=1; i <= expanded.len(); i++ ){
				expanded[i] = "." & expanded[i];
			}
		}

		return expanded;
	}

	public struct function getAssetType( string filename="", string name=ListLast( arguments.fileName, "." ), boolean throwOnMissing=false ) {
		var types = getTypes();

		if ( StructKeyExists( types, arguments.name ) ) {
			return types[ arguments.name ];
		}

		if ( not arguments.throwOnMissing ) {
			return {};
		}

		throw(
			  type    = "assetManager.fileTypeNotFound"
			, message = "The file type, [#arguments.name#], could not be found"
		);
	}

	public struct function getTypes() {
		return variables._types ?: {};
	}

// PRIVATE HELPERS
	private void function _setupConfiguredFileTypesAndGroups( typesByGroup ) {
		var types  = {};
		var groups = {};

		for( var groupName in typesByGroup ){
			if ( IsStruct( typesByGroup[ groupName ] ) ) {
				groups[ groupName ] = StructKeyArray( typesByGroup[ groupName ] );
				for( var typeName in typesByGroup[ groupName ] ) {
					var type = typesByGroup[ groupName ][ typeName ];
					types[ typeName ] = {
						  typeName          = typeName
						, groupName         = groupName
						, extension         = type.extension ?: typeName
						, mimetype          = type.mimetype  ?: ""
						, serveAsAttachment = IsBoolean( type.serveAsAttachment ?: "" ) && type.serveAsAttachment
						, trackDownloads    = IsBoolean( type.trackDownloads    ?: "" ) && type.trackDownloads
					};
				}
			}
		}

		_setGroups( groups );
		_setTypes( types );
	}

// GETTERS AND SETTERS
	private any function _getGroups() {
		return _groups;
	}
	private void function _setGroups( required any groups ) {
		_groups = arguments.groups;
	}

	private void function _setTypes( required struct types ) {
		_types = arguments.types;
	}

}
