/**
 * Registers database-defined custom objects as virtual preside objects.
 *
 * @singleton      true
 * @presideService true
 * @autodoc        true
 * @feature        customObjects
 */
component {

	property name="presideObjectService"         inject="delayedInjector:presideObjectService";
	property name="customFieldsValueTableService" inject="delayedInjector:customFieldsValueTableService";
	property name="customFieldsService"          inject="delayedInjector:customFieldsService";
	property name="customFieldsPropertyInjector" inject="delayedInjector:customFieldsPropertyInjector";
	property name="resourceBundleService"        inject="delayedInjector:resourceBundleService";
	property name="formsService"                 inject="delayedInjector:formsService";
	property name="adminDataViewsService"        inject="delayedInjector:adminDataViewsService";
	property name="loginService"                 inject="delayedInjector:loginService";
	property name="permissionService"            inject="delayedInjector:permissionService";

	variables.sharedValueObjectName = "_cfv_custom_object_record";
	variables.sharedValueTableName  = "_cfv_custom_object_record";
	variables.readOperations        = "navigate,read";

	public any function init() {
		return this;
	}

	public string function getObjectName( required string key ) {
		return "cobj_" & LCase( Trim( arguments.key ) );
	}

	public string function getSharedValueObjectName() {
		return variables.sharedValueObjectName;
	}

	public void function addVirtualObjects( required struct objects ) {
		if ( !StructKeyExists( arguments.objects, "custom_object_record" ) ) {
			return;
		}

		_capturePrototype( arguments.objects.custom_object_record.meta ?: {} );
		_registerSharedValueObject( arguments.objects );

		try {
			var definitions = presideObjectService.selectData(
				  objectName = "custom_object"
				, filter     = { active=true }
				, returntype = "array"
			);
		} catch ( any e ) {
			return;
		}

		for( var definition in definitions ) {
			try {
				_registerIntoStruct( arguments.objects, definition );
			} catch ( any e ) {}
		}
	}

	public void function ensureRuntimeObjects() {
		var definitions = [];

		try {
			definitions = presideObjectService.selectData(
				  objectName = "custom_object"
				, returntype = "array"
			);
		} catch ( any e ) {
			return;
		}

		for( var definition in definitions ) {
			try {
				_registerOrUnregister( definition );
			} catch ( any e ) {}
		}

		registerI18n( definitions );
	}

	public void function refreshDefinition( required string id ) {
		var definition = getDefinition( arguments.id );

		if ( StructIsEmpty( definition ) ) {
			return;
		}

		var previousGroupId = "";
		var objectName      = getObjectName( definition.key ?: "" );

		_registerOrUnregister( definition );
		registerI18nForDefinition( definition );
		_clearObjectCaches( objectName );

		if ( _isTrue( definition.active ?: "" ) && presideObjectService.objectExists( objectName ) ) {
			try {
				customFieldsPropertyInjector.refreshObject( objectName );
			} catch ( any e ) {}
		}
	}

	public void function removeDefinition( required struct definition ) {
		var objectName = getObjectName( arguments.definition.key ?: "" );
		var groupId    = resolveGroupId( arguments.definition.category ?: "" );
		var fields     = [];

		try {
			fields = presideObjectService.selectData(
				  objectName = "custom_field"
				, filter     = { target_object=objectName }
				, returntype = "array"
			);
		} catch ( any e ) {
			fields = [];
		}

		for( var field in fields ) {
			try {
				customFieldsService.deleteFieldData( field );
			} catch ( any e ) {}

			if ( Len( Trim( field.id ?: "" ) ) ) {
				presideObjectService.deleteData( objectName="custom_field", id=field.id );
			}
		}

		if ( Len( Trim( arguments.definition.id ?: "" ) ) && presideObjectService.objectExists( "custom_object_record" ) ) {
			presideObjectService.deleteData(
				  objectName = "custom_object_record"
				, filter     = { custom_object=arguments.definition.id }
			);
		}

		if ( presideObjectService.objectExists( objectName ) ) {
			presideObjectService.unregisterRuntimeObject( objectName );
		}

		resourceBundleService.clearDynamicResources( "preside-objects.#objectName#" );
		_clearUnusedCustomGroup( groupId );
		_clearObjectCaches( objectName );
	}

	public struct function getDefinition( required string id ) {
		if ( !Len( Trim( arguments.id ) ) ) {
			return {};
		}

		var row = presideObjectService.selectData(
			  objectName = "custom_object"
			, id         = arguments.id
			, returntype = "struct"
		);

		return IsStruct( row ) ? row : {};
	}

	public struct function buildVirtualObjectMeta( required struct definition, struct prototype={} ) {
		var source     = StructIsEmpty( arguments.prototype ) ? _getPrototypeMeta() : arguments.prototype;
		var meta       = Duplicate( source );
		var objectName = getObjectName( arguments.definition.key ?: "" );
		var hasLabel   = !StructKeyExists( arguments.definition, "has_label_field" ) || _isTrue( arguments.definition.has_label_field );

		meta.name                  = objectName;
		meta.tableName             = source.tableName ?: "psys_custom_object_record";
		meta.dbsync                = false;
		meta.customObject          = arguments.definition.id ?: "";
		meta.customObjectKey       = LCase( Trim( arguments.definition.key ?: "" ) );
		meta.customFieldsEnabled   = true;
		meta.datamanagerEnabled    = true;
		meta.datamanagerGroup      = resolveGroupId( arguments.definition.category ?: "" );
		meta.versioned             = false;
		meta.useDrafts             = false;
		meta.feature               = "customObjects";
		meta.datamanagerGridFields = hasLabel ? "label,datecreated,datemodified" : "datecreated,datemodified";

		meta.properties  = Duplicate( source.properties ?: {} );
		meta.propertyNames = Duplicate( source.propertyNames ?: [] );

		if ( StructKeyExists( meta.properties, "custom_object" ) ) {
			meta.properties.custom_object.control            = "none";
			meta.properties.custom_object.adminRenderer      = "none";
			meta.properties.custom_object.excludeDataExport  = true;
			meta.properties.custom_object.autofilter         = false;
		}

		if ( hasLabel ) {
			meta.noLabel    = false;
			meta.labelfield = "label";
			if ( StructKeyExists( meta.properties, "label" ) ) {
				meta.properties.label.required = true;
			}
		} else {
			StructDelete( meta.properties, "label" );
			meta.propertyNames = _without( meta.propertyNames, "label" );
			meta.dbFieldList   = ArrayToList( _without( ListToArray( meta.dbFieldList ?: "" ), "label" ) );
			meta.noLabel       = true;
			meta.labelfield    = "";
		}

		var labelField = resolveLabelField( arguments.definition );
		if ( Len( labelField ) ) {
			meta.labelfield = labelField;
			meta.noLabel    = false;
		}

		return meta;
	}

	public string function resolveLabelField( required struct definition ) {
		var hasLabel = !StructKeyExists( arguments.definition, "has_label_field" ) || _isTrue( arguments.definition.has_label_field );
		var chosen   = Trim( arguments.definition.label_field ?: "" );

		if ( !Len( chosen ) || CompareNoCase( chosen, "label" ) == 0 ) {
			return hasLabel ? "label" : "";
		}

		return chosen;
	}

	public string function getLabelFieldValidationError( required string objectName, required string labelField, boolean hasLabelField=true ) {
		var chosen = Trim( arguments.labelField );

		if ( !Len( chosen ) ) {
			return "";
		}
		if ( !Len( arguments.objectName ) || !IsObject( customFieldsService ) ) {
			return "preside-objects.custom_object:field.label_field.validation.unknown";
		}

		for ( var field in customFieldsService.listFields( objectName=arguments.objectName, includeInactive=true ) ) {
			if ( Compare( field.key ?: "", chosen ) == 0 ) {
				return "";
			}
		}

		return "preside-objects.custom_object:field.label_field.validation.unknown";
	}

	public string function resolveGroupId( required string category ) {
		var categoryLabel = Trim( arguments.category );

		if ( !Len( categoryLabel ) ) {
			return "cobj_uncategorised";
		}

		var builtInGroupId = _matchingBuiltInGroupId( categoryLabel );
		if ( Len( builtInGroupId ) ) {
			return builtInGroupId;
		}

		return "cobj_" & slugifyCategory( categoryLabel );
	}

	public string function slugifyCategory( required string category ) {
		var slug = LCase( Trim( arguments.category ) );

		slug = ReReplace( slug, "[^a-z0-9]+", "_", "all" );
		slug = ReReplace( slug, "^_+|_+$", "", "all" );

		if ( !Len( slug ) ) {
			slug = "uncategorised";
		}

		return Left( slug, 60 );
	}

	public array function listCategorySuggestions() {
		var suggestions = {};

		if ( IsObject( presideObjectService ) ) {
			for( var objectName in presideObjectService.listObjects() ) {
				if ( Len( presideObjectService.getObjectAttribute( objectName, "customObject", "" ) ) ) {
					continue;
				}

				var groupId = presideObjectService.getObjectAttribute( objectName, "datamanagerGroup", "" );
				if ( !Len( groupId ) ) {
					continue;
				}

				var title = resourceBundleService.getResource( uri="preside-objects.groups.#groupId#:title" );
				if ( Len( title ) ) {
					suggestions[ title ] = true;
				}
			}

			try {
				var rows = presideObjectService.selectData(
					  objectName   = "custom_object"
					, selectFields = [ "category" ]
					, returntype   = "array"
				);
				for( var row in rows ) {
					if ( Len( Trim( row.category ?: "" ) ) ) {
						suggestions[ Trim( row.category ) ] = true;
					}
				}
			} catch ( any e ) {}
		}

		var labels = StructKeyArray( suggestions );
		ArraySort( labels, "textnocase" );

		return labels;
	}

	public boolean function userCan(
		  required string objectName
		, required string operation
		,          string userId = ""
	) {
		if ( !IsObject( loginService ) || !IsObject( presideObjectService ) ) {
			return false;
		}

		var user = Len( Trim( arguments.userId ) ) ? Trim( arguments.userId ) : loginService.getLoggedInUserId();
		if ( !Len( user ) ) {
			return false;
		}

		var currentUser = loginService.getLoggedInUserId();
		if ( ( !Len( Trim( arguments.userId ) ) || arguments.userId == currentUser ) && loginService.isSystemUser() ) {
			return true;
		}

		var definitionId = presideObjectService.getObjectAttribute( arguments.objectName, "customObject", "" );
		if ( !Len( definitionId ) ) {
			return false;
		}

		var manageGroups = _groupIdsFor( definitionId, "custom_object_manage_group" );
		var readGroups   = _groupIdsFor( definitionId, "custom_object_read_group" );
		var userGroups   = permissionService.listUserGroups( user );
		var canManage    = _intersects( userGroups, manageGroups );
		var canRead      = canManage || _intersects( userGroups, readGroups );

		if ( ListFindNoCase( variables.readOperations, arguments.operation ) ) {
			return canRead;
		}

		return canManage;
	}

	public boolean function deletionConfirmationMatches( required struct definition, required string typedName ) {
		var expected = Len( Trim( arguments.definition.label ?: "" ) ) ? arguments.definition.label : ( arguments.definition.key ?: "" );

		return Compare( Trim( arguments.typedName ), expected ) == 0;
	}

	public numeric function countRecords( required string definitionId ) {
		if ( !Len( Trim( arguments.definitionId ) ) || !presideObjectService.objectExists( "custom_object_record" ) ) {
			return 0;
		}

		return presideObjectService.selectData(
			  objectName      = "custom_object_record"
			, filter          = { custom_object=arguments.definitionId }
			, recordCountOnly = true
		);
	}

	public numeric function countFields( required string objectName ) {
		if ( !Len( Trim( arguments.objectName ) ) || !presideObjectService.objectExists( "custom_field" ) ) {
			return 0;
		}

		return presideObjectService.selectData(
			  objectName      = "custom_field"
			, filter          = { target_object=arguments.objectName }
			, recordCountOnly = true
		);
	}

	public string function getKeyValidationError( required string key, string ignoreObjectName="" ) {
		var objectKey = LCase( Trim( arguments.key ) );

		if ( !Len( objectKey ) || !ReFind( "^[a-z][a-z0-9_]{0,39}$", objectKey ) ) {
			return "customObjects:validation.key.format";
		}

		var objectName = getObjectName( objectKey );
		if ( presideObjectService.objectExists( objectName ) && Compare( objectName, arguments.ignoreObjectName ) != 0 ) {
			var existingId = presideObjectService.getObjectAttribute( objectName, "customObject", "" );
			if ( !Len( existingId ) || Compare( objectName, arguments.ignoreObjectName ) != 0 ) {
				return "customObjects:validation.key.collision";
			}
		}

		var matches = presideObjectService.selectData(
			  objectName = "custom_object"
			, filter     = { key=objectKey }
			, returntype = "array"
		);
		for( var match in matches ) {
			if ( getObjectName( match.key ?: "" ) != arguments.ignoreObjectName ) {
				return "customObjects:validation.key.duplicate";
			}
		}

		return "";
	}

	public void function registerI18n( array definitions ) {
		var rows = arguments.definitions ?: [];

		if ( !ArrayLen( rows ) ) {
			try {
				rows = presideObjectService.selectData(
					  objectName = "custom_object"
					, returntype = "array"
				);
			} catch ( any e ) {
				return;
			}
		}

		for( var definition in rows ) {
			registerI18nForDefinition( definition );
		}
	}

	public void function registerI18nForDefinition( required struct definition ) {
		var objectName = getObjectName( arguments.definition.key ?: "" );
		var iconClass  = _fontAwesomeClass( arguments.definition.icon_class ?: "" );

		resourceBundleService.registerDynamicResources( "preside-objects.#objectName#", {
			  "title"          = arguments.definition.label ?: objectName
			, "title.singular" = arguments.definition.label_singular ?: ( arguments.definition.label ?: objectName )
			, "description"    = arguments.definition.description ?: ""
			, "iconClass"      = iconClass
			, "field.label.title" = "Label"
		} );

		var groupId = resolveGroupId( arguments.definition.category ?: "" );
		if ( Left( groupId, 5 ) == "cobj_" ) {
			resourceBundleService.registerDynamicResources( "preside-objects.groups.#groupId#", {
				  title       = Len( Trim( arguments.definition.category ?: "" ) ) ? arguments.definition.category : groupId
				, description = ""
				, iconclass   = "fa-folder-o"
			} );
		}
	}

	public string function getCustomObjectId( required string objectName ) {
		if ( !isCustomObject( arguments.objectName ) ) {
			return "";
		}

		return presideObjectService.getObjectAttribute( arguments.objectName, "customObject", "" );
	}

	public boolean function isCustomObject( required string objectName ) {
		if ( !Len( arguments.objectName ) || !IsObject( presideObjectService ) || !presideObjectService.objectExists( arguments.objectName ) ) {
			return false;
		}

		return Len( presideObjectService.getObjectAttribute( arguments.objectName, "customObject", "" ) ) > 0;
	}

	public boolean function prepareRecordScope( required struct interceptData ) {
		var objectName = arguments.interceptData.objectName ?: "";

		if ( !isCustomObject( objectName ) ) {
			return false;
		}

		var definitionId = presideObjectService.getObjectAttribute( objectName, "customObject", "" );

		arguments.interceptData.extraFilters = arguments.interceptData.extraFilters ?: [];
		ArrayAppend( arguments.interceptData.extraFilters, { filter={ "#objectName#.custom_object"=definitionId } } );

		if ( IsStruct( arguments.interceptData.data ?: "" ) ) {
			arguments.interceptData.data.custom_object = definitionId;
		}

		return true;
	}

	public boolean function allowsOperation( required struct interceptData, required string operation ) {
		if ( _isTrue( arguments.interceptData.bypassCustomObjectPermissions ?: "" ) ) {
			return true;
		}

		return userCan(
			  objectName = arguments.interceptData.objectName ?: ""
			, operation  = arguments.operation
		);
	}


	private void function _registerOrUnregister( required struct definition ) {
		var objectName = getObjectName( arguments.definition.key ?: "" );

		if ( !Len( Trim( arguments.definition.key ?: "" ) ) ) {
			return;
		}

		if ( _isTrue( arguments.definition.active ?: "" ) ) {
			presideObjectService.registerRuntimeObject( objectName, {
				  meta     = buildVirtualObjectMeta( arguments.definition )
				, instance = _newObjectInstance()
			} );
		} else if ( presideObjectService.objectExists( objectName ) ) {
			presideObjectService.unregisterRuntimeObject( objectName );
		}
	}

	private void function _registerIntoStruct( required struct objects, required struct definition ) {
		var objectName = getObjectName( arguments.definition.key ?: "" );

		if ( !Len( Trim( arguments.definition.key ?: "" ) ) ) {
			return;
		}

		arguments.objects[ objectName ] = {
			  meta     = buildVirtualObjectMeta( arguments.definition )
			, instance = _newObjectInstance()
		};
	}

	private void function _registerSharedValueObject( required struct objects ) {
		if ( StructKeyExists( arguments.objects, variables.sharedValueObjectName ) ) {
			return;
		}

		var hostMeta = arguments.objects.custom_object_record.meta ?: _getPrototypeMeta();
		var meta     = customFieldsValueTableService.createValueObjectMeta( "custom_object_record", hostMeta );

		meta.tableName = variables.sharedValueTableName;
		meta.dbsync    = true;

		arguments.objects[ variables.sharedValueObjectName ] = {
			  meta     = meta
			, instance = "auto_created"
		};
	}

	private void function _capturePrototype( required struct meta ) {
		if ( StructIsEmpty( arguments.meta ) ) {
			return;
		}

		variables.prototypeMeta = Duplicate( arguments.meta );
	}

	private struct function _getPrototypeMeta() {
		if ( IsStruct( variables.prototypeMeta ?: "" ) && !StructIsEmpty( variables.prototypeMeta ) ) {
			return variables.prototypeMeta;
		}

		return {};
	}

	private any function _newObjectInstance() {
		return CreateObject( "component", "preside.system.base.SystemPresideObject" );
	}

	private array function _groupIdsFor( required string definitionId, required string pivotObject ) {
		var rows = presideObjectService.selectData(
			  objectName   = arguments.pivotObject
			, filter       = { custom_object=arguments.definitionId }
			, selectFields = [ "security_group" ]
			, returntype   = "array"
		);
		var ids = [];

		for( var row in rows ) {
			if ( Len( Trim( row.security_group ?: "" ) ) ) {
				ArrayAppend( ids, row.security_group );
			}
		}

		return ids;
	}

	private boolean function _intersects( required array left, required array right ) {
		for( var item in arguments.left ) {
			if ( ArrayFindNoCase( arguments.right, item ) ) {
				return true;
			}
		}

		return false;
	}

	private string function _fontAwesomeClass( required string iconClass ) {
		var icon = Trim( arguments.iconClass );

		if ( !Len( icon ) ) {
			return "fa-database";
		}

		if ( ReFindNoCase( "^fa-", icon ) ) {
			return icon;
		}

		return "fa-" & icon;
	}

	private string function _matchingBuiltInGroupId( required string category ) {
		var seen = {};

		for( var objectName in presideObjectService.listObjects() ) {
			if ( Len( presideObjectService.getObjectAttribute( objectName, "customObject", "" ) ) ) {
				continue;
			}

			var groupId = presideObjectService.getObjectAttribute( objectName, "datamanagerGroup", "" );
			if ( !Len( groupId ) || StructKeyExists( seen, groupId ) ) {
				continue;
			}

			seen[ groupId ] = true;
			var title = resourceBundleService.getResource( uri="preside-objects.groups.#groupId#:title" );
			if ( Len( title ) && !CompareNoCase( title, arguments.category ) ) {
				return groupId;
			}
		}

		return "";
	}

	private boolean function _isTrue( required any value ) {
		return IsBoolean( arguments.value ) && arguments.value;
	}

	private array function _without( required array values, required string unwanted ) {
		var kept = [];

		for( var value in arguments.values ) {
			if ( CompareNoCase( Trim( value ), arguments.unwanted ) ) {
				ArrayAppend( kept, Trim( value ) );
			}
		}

		return kept;
	}

	private void function _clearObjectCaches( required string objectName ) {
		try {
			formsService.clearDynamicFormsForObject( arguments.objectName );
		} catch ( any e ) {}

		try {
			adminDataViewsService.clearCache();
		} catch ( any e ) {}
	}

	private void function _clearUnusedCustomGroup( required string groupId ) {
		if ( Left( arguments.groupId, 5 ) != "cobj_" ) {
			return;
		}

		try {
			var rows = presideObjectService.selectData(
				  objectName = "custom_object"
				, returntype = "array"
			);
		} catch ( any e ) {
			return;
		}

		for( var row in rows ) {
			if ( resolveGroupId( row.category ?: "" ) == arguments.groupId ) {
				return;
			}
		}

		resourceBundleService.clearDynamicResources( "preside-objects.groups.#arguments.groupId#" );
	}

}
