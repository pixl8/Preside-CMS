/**
 * Listing toolbar helpers: per-user column preferences, available
 * column pools, and auto quick-filter definitions for column heading search.
 *
 * @presideService true
 * @singleton      true
 * @feature        admin
 */
component {

	/**
	 * @dataManagerService.inject          dataManagerService
	 * @customizationService.inject        dataManagerCustomizationService
	 * @enumService.inject                 enumService
	 * @rulesEngineFilterService.inject    featureInjector:rulesEngine:rulesEngineFilterService
	 */
	public any function init(
		  required any dataManagerService
		, required any customizationService
		, required any enumService
		,          any rulesEngineFilterService
	) {
		_setDataManagerService( arguments.dataManagerService );
		_setCustomizationService( arguments.customizationService );
		_setEnumService( arguments.enumService );
		_setRulesEngineFilterService( arguments.rulesEngineFilterService ?: NullValue() );

		return this;
	}

	public array function listDefaultColumns( required string objectName ) {
		return _getDataManagerService().listGridFields( arguments.objectName );
	}

	public array function listLockedColumns( required string objectName ) {
		var locked = ListToArray( $getPresideObjectService().getObjectAttribute(
			  objectName    = arguments.objectName
			, attributeName = "datamanagerLockedGridFields"
			, defaultValue  = ""
		), ", " );

		if ( ArrayLen( locked ) ) {
			return locked;
		}

		var labelField = $getPresideObjectService().getLabelField( arguments.objectName );
		if ( Len( Trim( labelField ) ) ) {
			return [ labelField ];
		}

		return [];
	}

	/**
	 * Default pool is `@datamanagerGridFields` plus `@datamanagerHiddenGridFields`
	 * and optional `@datamanagerColumnPickerFields`. Properties may opt in or out
	 * with `datamanagerUserColumn=true|false`. Locked columns come from
	 * `@datamanagerLockedGridFields` (label field if unset). Handlers can replace
	 * the pool with `getAvailableListingColumns` / `getDefaultListingColumns`.
	 */
	public array function listAvailableColumns( required string objectName ) {
		var customized = _getCustomizationService().runCustomization(
			  objectName    = arguments.objectName
			, action        = "getAvailableListingColumns"
			, defaultResult = ""
		);

		if ( IsArray( customized ) && ArrayLen( customized ) ) {
			return _uniqueFields( customized );
		}

		var fields          = Duplicate( _getDataManagerService().listGridFields( arguments.objectName ) );
		var hiddenFields    = _getDataManagerService().listHiddenGridFields( arguments.objectName );
		var pickerFields    = ListToArray( $getPresideObjectService().getObjectAttribute(
			  objectName    = arguments.objectName
			, attributeName = "datamanagerColumnPickerFields"
			, defaultValue  = ""
		), ", " );
		var properties      = $getPresideObjectService().getObjectProperties( arguments.objectName );
		var excluded        = {};

		ArrayAppend( fields, hiddenFields, true );
		ArrayAppend( fields, pickerFields, true );
		ArrayAppend( fields, _getDataManagerService().listSearchFields( arguments.objectName ), true );

		for( var propName in properties ) {
			var prop = properties[ propName ];
			if ( IsBoolean( prop.datamanagerUserColumn ?: "" ) ) {
				if ( prop.datamanagerUserColumn ) {
					ArrayAppend( fields, propName );
				} else {
					excluded[ propName ] = true;
				}
			}
		}

		var allowed = [];
		for( var fieldName in _uniqueFields( fields ) ) {
			if ( StructKeyExists( excluded, fieldName ) || !_isListableColumn( arguments.objectName, fieldName, properties ) ) {
				continue;
			}
			ArrayAppend( allowed, fieldName );
		}

		return allowed;
	}

	public array function applyUserColumns(
		  required string objectName
		,          string listingKey    = arguments.objectName
		,          array  defaultFields = listDefaultColumns( arguments.objectName )
		,          array  available     = listAvailableColumns( arguments.objectName )
		,          array  storedFields
	) {
		var customized = _getCustomizationService().runCustomization(
			  objectName    = arguments.objectName
			, action        = "getDefaultListingColumns"
			, args          = { defaultFields=arguments.defaultFields }
			, defaultResult = ""
		);
		var defaults = ( IsArray( customized ) && ArrayLen( customized ) ) ? customized : arguments.defaultFields;
		var locked   = listLockedColumns( arguments.objectName );
		var stored   = StructKeyExists( arguments, "storedFields" ) ? arguments.storedFields : _getStoredColumns( arguments.objectName, arguments.listingKey );
		var chosen   = ArrayLen( stored ) ? stored : defaults;
		var result   = [];
		var seen     = {};

		for( var fieldName in locked ) {
			if ( ArrayFindNoCase( arguments.available, fieldName ) && !StructKeyExists( seen, LCase( fieldName ) ) ) {
				ArrayAppend( result, fieldName );
				seen[ LCase( fieldName ) ] = true;
			}
		}

		for( var fieldName in chosen ) {
			if ( !ArrayFindNoCase( arguments.available, fieldName ) || StructKeyExists( seen, LCase( fieldName ) ) ) {
				continue;
			}
			ArrayAppend( result, fieldName );
			seen[ LCase( fieldName ) ] = true;
		}

		if ( !ArrayLen( result ) ) {
			return defaults;
		}

		return result;
	}

	public boolean function saveUserColumns(
		  required string objectName
		, required array  columns
		,          string listingKey = arguments.objectName
	) {
		var userId = $getAdminLoggedInUserId();
		if ( !Len( Trim( userId ) ) ) {
			return false;
		}

		var dao      = $getPresideObject( "admin_datatable_user_preference" );
		var existing = dao.selectData(
			  filter       = { security_user=userId, object_name=arguments.objectName, listing_key=arguments.listingKey }
			, selectFields = [ "id" ]
		);

		if ( !ArrayLen( arguments.columns ) ) {
			if ( existing.recordCount ) {
				return dao.deleteData( id=existing.id ) > 0;
			}
			return true;
		}

		var available = listAvailableColumns( arguments.objectName );
		var defaults  = listDefaultColumns( arguments.objectName );
		var cleaned   = applyUserColumns(
			  objectName    = arguments.objectName
			, listingKey    = arguments.listingKey
			, defaultFields = defaults
			, available     = available
			, storedFields  = arguments.columns
		);

		if ( existing.recordCount ) {
			return dao.updateData( id=existing.id, data={ columns=ArrayToList( cleaned ) } );
		}

		return Len( dao.insertData( data={
			  security_user = userId
			, object_name   = arguments.objectName
			, listing_key   = arguments.listingKey
			, columns       = ArrayToList( cleaned )
		} ) ) > 0;
	}

	public array function listQuickFilters( required string objectName ) {
		var customized = _getCustomizationService().runCustomization(
			  objectName    = arguments.objectName
			, action        = "getListingQuickFilterFields"
			, defaultResult = ""
		);
		var properties = $getPresideObjectService().getObjectProperties( arguments.objectName );
		var fieldNames = [];
		var filters    = [];
		var excluded   = ListToArray( $getPresideObjectService().getObjectAttribute(
			  objectName    = arguments.objectName
			, attributeName = "excludeAutoExpressions"
			, defaultValue  = ""
		), ", " );

		if ( IsArray( customized ) ) {
			fieldNames = customized;
		} else {
			fieldNames = Duplicate( _getDataManagerService().listGridFields( arguments.objectName ) );
			ArrayAppend( fieldNames, _getDataManagerService().listHiddenGridFields( arguments.objectName ), true );
			ArrayAppend( fieldNames, _getDataManagerService().listSearchFields( arguments.objectName ), true );
			fieldNames = _uniqueFields( fieldNames );
		}

		for( var propName in fieldNames ) {
			if ( !StructKeyExists( properties, propName ) || ArrayFindNoCase( excluded, propName ) ) {
				continue;
			}
			if ( !IsArray( customized ) && propName == "id" ) {
				continue;
			}
			var filter = _quickFilterForProperty( arguments.objectName, properties[ propName ] );
			if ( !StructIsEmpty( filter ) ) {
				ArrayAppend( filters, filter );
			}
		}

		return filters;
	}

	public struct function getToolbarConfig(
		  required string  objectName
		,          string  listingKey        = arguments.objectName
		,          array   gridFields        = listDefaultColumns( arguments.objectName )
		,          array   hiddenGridFields  = _getDataManagerService().listHiddenGridFields( arguments.objectName )
		,          boolean allowFilter       = true
		,          boolean allowSearch       = true
		,          boolean allowManageFilter = false
		,          string  manageFilterLink  = ""
	) {
		var available = listAvailableColumns( arguments.objectName );
		var current   = applyUserColumns(
			  objectName    = arguments.objectName
			, listingKey    = arguments.listingKey
			, defaultFields = arguments.gridFields
			, available     = available
		);
		var locked    = listLockedColumns( arguments.objectName );
		var columns   = [];

		for( var fieldName in available ) {
			ArrayAppend( columns, {
				  field   = fieldName
				, label   = $translatePropertyName( arguments.objectName, fieldName, "listing" )
				, locked  = ArrayFindNoCase( locked, fieldName ) > 0
				, visible = ArrayFindNoCase( current, fieldName ) > 0
			} );
		}

		columns.sort( function( a, b ) {
			var aPos = ArrayFindNoCase( current, a.field );
			var bPos = ArrayFindNoCase( current, b.field );
			if ( aPos && bPos ) {
				return aPos - bPos;
			}
			if ( aPos ) {
				return -1;
			}
			if ( bPos ) {
				return 1;
			}
			return CompareNoCase( a.label, b.label );
		} );

		var customizedDefaults = _getCustomizationService().runCustomization(
			  objectName    = arguments.objectName
			, action        = "getDefaultListingColumns"
			, args          = { defaultFields=arguments.gridFields }
			, defaultResult = ""
		);
		var defaultColumns = ( IsArray( customizedDefaults ) && ArrayLen( customizedDefaults ) ) ? customizedDefaults : arguments.gridFields;

		return {
			  savedFilters        = _serializeSavedFilters( arguments.objectName )
			, segmentationFilters = _serializeSegmentationFilters( arguments.objectName )
			, quickFilters        = arguments.allowFilter ? listQuickFilters( arguments.objectName ) : []
			, columns             = columns
			, currentColumns      = current
			, defaultColumns      = defaultColumns
			, lockedColumns       = locked
			, listingKey          = arguments.listingKey
			, allowFilter         = arguments.allowFilter
			, allowSearch         = arguments.allowSearch
			, allowManageFilter   = arguments.allowManageFilter
			, manageFilterLink    = arguments.manageFilterLink
		};
	}

	public array function mergeExpressionArrays( array left=[], array right=[] ) {
		if ( !ArrayLen( arguments.left ) ) {
			return Duplicate( arguments.right );
		}
		if ( !ArrayLen( arguments.right ) ) {
			return Duplicate( arguments.left );
		}

		var merged = Duplicate( arguments.left );
		ArrayAppend( merged, "and" );
		ArrayAppend( merged, Duplicate( arguments.right ), true );

		return merged;
	}

// PRIVATE HELPERS
	private array function _getStoredColumns( required string objectName, required string listingKey ) {
		var userId = $getAdminLoggedInUserId();
		if ( !Len( Trim( userId ) ) ) {
			return [];
		}

		var record = $getPresideObject( "admin_datatable_user_preference" ).selectData(
			  filter       = { security_user=userId, object_name=arguments.objectName, listing_key=arguments.listingKey }
			, selectFields = [ "columns" ]
		);

		if ( !record.recordCount || !Len( Trim( record.columns ) ) ) {
			return [];
		}

		return ListToArray( record.columns );
	}

	private boolean function _isListableColumn( required string objectName, required string fieldName, required struct properties ) {
		if ( !StructKeyExists( arguments.properties, arguments.fieldName ) ) {
			return arguments.fieldName != "id";
		}

		var prop       = arguments.properties[ arguments.fieldName ];
		var renderer   = prop.renderer ?: "";
		var autofilter = prop.autofilter ?: true;
		var rel        = prop.relationship ?: "";

		if ( renderer == "none" ) {
			return false;
		}
		if ( IsBoolean( autofilter ) && !autofilter && renderer == "none" ) {
			return false;
		}
		if ( rel == "one-to-many" ) {
			return false;
		}

		return true;
	}

	private struct function _quickFilterForProperty( required string objectName, required struct propertyDefinition ) {
		var prop         = arguments.propertyDefinition;
		var propName     = prop.name ?: "";
		var autofilter   = IsBoolean( prop.autofilter ?: "" ) ? prop.autofilter : true;
		var renderer     = prop.renderer ?: "";
		var relationship = prop.relationship ?: "";
		var propType     = prop.type ?: "string";
		var formula      = Len( Trim( prop.formula ?: "" ) ) > 0;

		if ( !Len( propName ) || !autofilter || renderer == "none" || renderer == "encrypted" || relationship == "select-data-view" ) {
			return {};
		}
		if ( IsBoolean( prop.secret ?: "" ) && prop.secret ) {
			return {};
		}
		if ( ListFindNoCase( "many-to-many,one-to-many", relationship ) ) {
			return {};
		}

		var label = $translatePropertyName( arguments.objectName, propName, "listing" );
		var base  = {
			  field    = propName
			, label    = label
			, type     = propType
		};

		if ( Len( Trim( prop.enum ?: "" ) ) ) {
			base.type         = "enum";
			base.expressionId = "presideobject_enumMatches_#arguments.objectName#.#propName#";
			base.enum         = prop.enum;
			base.options      = _enumOptions( prop.enum );
			return base;
		}

		if ( relationship == "many-to-one" ) {
			base.type         = "object";
			base.expressionId = "presideobject_manytoonematch_#arguments.objectName#.#propName#";
			base.relatedTo    = prop.relatedTo ?: "";
			return base;
		}

		if ( formula ) {
			return {};
		}

		switch( propType ) {
			case "boolean":
				base.type         = "boolean";
				base.expressionId = "presideobject_booleanistrue_#arguments.objectName#.#propName#";
				return base;
			case "date":
				base.type         = "date";
				base.expressionId = "presideobject_dateinrange_#arguments.objectName#.#propName#";
				base.isDate       = ( prop.dbtype ?: "" ) == "date";
				return base;
			case "numeric":
				base.type         = "numeric";
				base.expressionId = "presideobject_numbercompares_#arguments.objectName#.#propName#";
				return base;
			default:
				base.type         = "text";
				base.expressionId = "presideobject_stringmatches_#arguments.objectName#.#propName#";
				return base;
		}
	}

	private array function _enumOptions( required string enum ) {
		var items   = _getEnumService().listItems( arguments.enum );
		var options = [];

		for( var item in items ) {
			ArrayAppend( options, {
				  id    = item.id    ?: ( item.value ?: "" )
				, label = item.label ?: ( item.id ?: "" )
			} );
		}

		return options;
	}

	private array function _serializeSavedFilters( required string objectName ) {
		var filterService = _getRulesEngineFilterService();
		if ( IsNull( filterService ) ) {
			return [];
		}

		var favourites    = filterService.getFavourites( arguments.objectName );
		var others        = filterService.getNonFavouriteFilters( arguments.objectName );
		var items         = [];

		for( var row in favourites ) {
			ArrayAppend( items, {
				  id        = row.id
				, name      = row.condition_name
				, favourite = true
				, folder    = ""
				, type      = "saved"
			} );
		}
		for( var row in others ) {
			ArrayAppend( items, {
				  id        = row.id
				, name      = row.condition_name
				, favourite = false
				, folder    = row.folder ?: ""
				, type      = "saved"
			} );
		}

		return items;
	}

	private array function _serializeSegmentationFilters( required string objectName ) {
		var filterService = _getRulesEngineFilterService();
		if ( IsNull( filterService ) || !filterService.objectSupportsSegmentationFilters( arguments.objectName ) ) {
			return [];
		}

		var filters = filterService.getSegmentationFiltersForFavourites( arguments.objectName );
		var items   = [];

		for( var filter in filters ) {
			ArrayAppend( items, {
				  id    = filter.id
				, name  = _plainFilterLabel( filter.condition_name ?: "" )
				, count = Val( filter.segmentation_last_count ?: 0 )
				, type  = "segmentation"
			} );
		}

		return items;
	}

	private string function _plainFilterLabel( required string value ) {
		var name = arguments.value;

		name = ReplaceNoCase( name, "&nbsp;", " ", "all" );
		name = ReplaceNoCase( name, "&rarr;", "→", "all" );
		name = ReReplaceNoCase( name, "<[^>]+>", "", "all" );

		return Trim( ReReplace( name, "\s+", " ", "all" ) );
	}

	private array function _uniqueFields( required array fields ) {
		var seen   = {};
		var unique = [];

		for( var fieldName in arguments.fields ) {
			if ( !Len( Trim( fieldName ) ) || StructKeyExists( seen, LCase( fieldName ) ) ) {
				continue;
			}
			seen[ LCase( fieldName ) ] = true;
			ArrayAppend( unique, fieldName );
		}

		return unique;
	}

	private any function _getDataManagerService() {
		return _dataManagerService;
	}
	private void function _setDataManagerService( required any dataManagerService ) {
		_dataManagerService = arguments.dataManagerService;
	}

	private any function _getCustomizationService() {
		return _customizationService;
	}
	private void function _setCustomizationService( required any customizationService ) {
		_customizationService = arguments.customizationService;
	}

	private any function _getEnumService() {
		return _enumService;
	}
	private void function _setEnumService( required any enumService ) {
		_enumService = arguments.enumService;
	}

	private any function _getRulesEngineFilterService() {
		return _rulesEngineFilterService;
	}
	private void function _setRulesEngineFilterService( any rulesEngineFilterService ) {
		_rulesEngineFilterService = arguments.rulesEngineFilterService ?: NullValue();
	}

}
