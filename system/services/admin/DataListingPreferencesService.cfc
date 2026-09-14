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
	 * @sessionStorage.inject              sessionStorage
	 * @rulesEngineFilterService.inject    featureInjector:rulesEngine:rulesEngineFilterService
	 */
	public any function init(
		  required any dataManagerService
		, required any customizationService
		, required any enumService
		, required any sessionStorage
		,          any rulesEngineFilterService
	) {
		_setDataManagerService( arguments.dataManagerService );
		_setCustomizationService( arguments.customizationService );
		_setEnumService( arguments.enumService );
		_setSessionStorage( arguments.sessionStorage );
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
	 * and optional `@datamanagerColumnPickerFields`. Picker field lists accept `*`
	 * wildcards and `!` exclusions, e.g. `*,!sensitive_col`. Properties may opt in
	 * or out with `datamanagerUserColumn=true|false`. Locked columns come from
	 * `@datamanagerLockedGridFields` (label field if unset). Handlers can replace
	 * the pool with `getAvailableListingColumns` / `getDefaultListingColumns`.
	 * Explicit listing `gridFields` / `hiddenGridFields` are merged into the pool
	 * so caller-supplied columns remain available alongside annotations.
	 */
	public array function listAvailableColumns(
		  required string objectName
		,          array  extraFields = []
	) {
		var customized = _getCustomizationService().runCustomization(
			  objectName    = arguments.objectName
			, action        = "getAvailableListingColumns"
			, args          = { extraFields=arguments.extraFields }
			, defaultResult = ""
		);

		if ( IsArray( customized ) && ArrayLen( customized ) ) {
			var merged = Duplicate( customized );
			ArrayAppend( merged, arguments.extraFields, true );
			return _uniqueFields( merged );
		}

		var fields         = Duplicate( _getDataManagerService().listGridFields( arguments.objectName ) );
		var hiddenFields   = _getDataManagerService().listHiddenGridFields( arguments.objectName );
		var properties     = $getPresideObjectService().getObjectProperties( arguments.objectName );
		var pickerAttr     = $getPresideObjectService().getObjectAttribute(
			  objectName    = arguments.objectName
			, attributeName = "datamanagerColumnPickerFields"
			, defaultValue  = ""
		);
		var pickerPatterns = ListToArray( ReReplace( pickerAttr, "\s+", "", "all" ), "," );
		var pickerSpec     = _resolveColumnPickerFields( patterns=pickerPatterns, properties=properties );
		var excluded       = Duplicate( pickerSpec.excluded );

		ArrayAppend( fields, hiddenFields, true );
		ArrayAppend( fields, pickerSpec.expanded, true );
		ArrayAppend( fields, _getDataManagerService().listSearchFields( arguments.objectName ), true );

		for( var propName in properties ) {
			var prop = properties[ propName ];
			if ( IsBoolean( prop.datamanagerUserColumn ?: "" ) ) {
				if ( prop.datamanagerUserColumn ) {
					ArrayAppend( fields, propName );
				} else {
					excluded[ LCase( propName ) ] = true;
				}
			}
		}

		var allowed = [];
		for( var fieldName in _uniqueFields( fields ) ) {
			if ( _isExcludedField( excluded, fieldName ) || !_isListableColumn( arguments.objectName, fieldName, properties ) ) {
				continue;
			}
			ArrayAppend( allowed, fieldName );
		}

		for( var fieldName in arguments.extraFields ) {
			if ( !Len( Trim( fieldName ) ) || ArrayFindNoCase( allowed, fieldName ) || _isExcludedField( excluded, fieldName ) ) {
				continue;
			}
			if ( !_isListableColumn( arguments.objectName, fieldName, properties ) ) {
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
		,          string listingKey       = arguments.objectName
		,          array  grantedFields    = []
		,          string grantedFieldsSig = ""
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

		var available = getGrantedListingColumns(
			  objectName        = arguments.objectName
			, listingKey        = arguments.listingKey
			, grantedFields     = arguments.grantedFields
			, grantedFieldsSig  = arguments.grantedFieldsSig
		);
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
		,          boolean allowColumnFilter = true
		,          boolean allowSearch       = true
		,          boolean allowManageFilter = false
		,          string  manageFilterLink  = ""
		,          boolean allowSavedViews   = false
		,          boolean canShareViews     = false
	) {
		var extraFields = Duplicate( arguments.gridFields );
		ArrayAppend( extraFields, arguments.hiddenGridFields, true );

		var available = listAvailableColumns( objectName=arguments.objectName, extraFields=extraFields );
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
			  savedFilters         = _serializeSavedFilters( arguments.objectName )
			, segmentationFilters  = _serializeSegmentationFilters( arguments.objectName )
			, quickFilters         = ( arguments.allowFilter && arguments.allowColumnFilter ) ? listQuickFilters( arguments.objectName ) : []
			, columns              = columns
			, currentColumns       = current
			, defaultColumns       = defaultColumns
			, lockedColumns        = locked
			, listingKey           = arguments.listingKey
			, grantedColumns       = available
			, grantedColumnsSig    = signGrantedColumns( arguments.objectName, arguments.listingKey, available )
			, allowFilter          = arguments.allowFilter
			, allowSearch          = arguments.allowSearch
			, allowManageFilter    = arguments.allowManageFilter
			, manageFilterLink     = arguments.manageFilterLink
			, allowSavedViews      = arguments.allowSavedViews
			, canShareViews        = arguments.allowSavedViews && arguments.canShareViews
			, savedViews           = arguments.allowSavedViews ? listSavedViews( arguments.objectName, arguments.listingKey ) : []
		};
	}

	public struct function emptyFilterState() {
		return {
			  savedFilterIds  = []
			, advancedFilter  = []
			, columnSearch    = {}
		};
	}

	public struct function defaultViewState( required array columns ) {
		return {
			  columns     = Duplicate( arguments.columns )
			, filterState = emptyFilterState()
		};
	}

	public array function sanitizeViewColumns(
		  required array  columns
		, required array  grantedColumns
		,          string objectName     = ""
	) {
		var selected = [];
		var seen     = {};
		var fieldName;
		var locked   = [];
		var result   = [];

		for( fieldName in arguments.columns ) {
			fieldName = Trim( fieldName );
			if ( !Len( fieldName ) || StructKeyExists( seen, LCase( fieldName ) ) ) {
				continue;
			}
			if ( ArrayFindNoCase( arguments.grantedColumns, fieldName ) ) {
				ArrayAppend( selected, fieldName );
				seen[ LCase( fieldName ) ] = true;
			}
		}

		if ( !Len( Trim( arguments.objectName ) ) ) {
			return selected;
		}

		locked = listLockedColumns( arguments.objectName );
		seen   = {};

		for( fieldName in locked ) {
			if ( ArrayFindNoCase( arguments.grantedColumns, fieldName ) && !StructKeyExists( seen, LCase( fieldName ) ) ) {
				ArrayAppend( result, fieldName );
				seen[ LCase( fieldName ) ] = true;
			}
		}
		for( fieldName in selected ) {
			if ( !StructKeyExists( seen, LCase( fieldName ) ) ) {
				ArrayAppend( result, fieldName );
				seen[ LCase( fieldName ) ] = true;
			}
		}

		return result;
	}

	public struct function sanitizeFilterState(
		  required any   filterState
		,          array permittedFilterIds = []
		,          array grantedColumns     = []
	) {
		var source          = _deserializeFilterState( arguments.filterState );
		var savedFilterIds  = [];
		var seen            = {};
		var advancedFilter  = [];
		var columnSearch    = {};
		var rawIds          = [];
		var rawAdvanced     = [];
		var rawColumnSearch = {};
		var filterId        = "";
		var fieldName       = "";

		rawIds          = source.savedFilterIds ?: ( source.savedfilterids ?: [] );
		rawAdvanced     = source.advancedFilter ?: ( source.advancedfilter ?: [] );
		rawColumnSearch = source.columnSearch   ?: ( source.columnsearch   ?: {} );

		if ( !IsArray( rawIds ) ) {
			rawIds = ListToArray( rawIds );
		}
		for( filterId in rawIds ) {
			filterId = Trim( filterId );
			if ( !Len( filterId ) || StructKeyExists( seen, filterId ) ) {
				continue;
			}
			if ( ArrayFindNoCase( arguments.permittedFilterIds, filterId ) ) {
				ArrayAppend( savedFilterIds, filterId );
				seen[ filterId ] = true;
			}
		}

		if ( IsArray( rawAdvanced ) ) {
			advancedFilter = Duplicate( rawAdvanced );
		}

		if ( IsStruct( rawColumnSearch ) ) {
			for( fieldName in rawColumnSearch ) {
				if ( ArrayLen( arguments.grantedColumns ) && !ArrayFindNoCase( arguments.grantedColumns, fieldName ) ) {
					continue;
				}
				if ( IsStruct( rawColumnSearch[ fieldName ] ) ) {
					columnSearch[ fieldName ] = Duplicate( rawColumnSearch[ fieldName ] );
				}
			}
		}

		return {
			  savedFilterIds = savedFilterIds
			, advancedFilter = advancedFilter
			, columnSearch   = columnSearch
		};
	}

	public boolean function viewStatesEqual( required struct left, required struct right ) {
		return _viewStateFingerprint( arguments.left ) == _viewStateFingerprint( arguments.right );
	}

	public array function listSavedViews(
		  required string objectName
		,          string listingKey = arguments.objectName
	) {
		var userId       = $getAdminLoggedInUserId();
		var records      = "";
		var granted      = [];
		var permittedIds = [];
		var views        = [];
		var row          = {};

		if ( !Len( Trim( userId ) ) ) {
			return [];
		}

		records = $getPresideObject( "admin_datatable_saved_view" ).selectData(
			  filter       = { object_name=arguments.objectName, listing_key=arguments.listingKey }
			, extraFilters = [ {
				  filter       = "owner = :owner or is_shared = :is_shared"
				, filterParams = { owner=userId, is_shared=true }
			  } ]
			, orderBy      = "label"
		);
		granted      = getGrantedListingColumns( arguments.objectName, arguments.listingKey );
		permittedIds = _permittedFilterIds( arguments.objectName );

		for( row in records ) {
			ArrayAppend( views, _savedViewToStruct(
				  record       = row
				, userId       = userId
				, granted      = granted
				, permittedIds = permittedIds
				, objectName   = arguments.objectName
			) );
		}

		return views;
	}

	public struct function saveSavedView(
		  required string  objectName
		, required string  label
		, required array   columns
		, required any     filterState
		,          string  listingKey       = arguments.objectName
		,          string  description      = ""
		,          boolean isShared         = false
		,          boolean canShare         = false
		,          array   grantedFields    = []
		,          string  grantedFieldsSig = ""
	) {
		var userId          = $getAdminLoggedInUserId();
		var viewLabel       = Trim( arguments.label );
		var granted         = [];
		var viewColumns     = [];
		var viewFilterState = {};
		var viewId          = "";

		if ( !Len( userId ) || !Len( viewLabel ) ) {
			return { success=false };
		}

		granted         = getGrantedListingColumns(
			  objectName       = arguments.objectName
			, listingKey       = arguments.listingKey
			, grantedFields    = arguments.grantedFields
			, grantedFieldsSig = arguments.grantedFieldsSig
		);
		viewColumns     = sanitizeViewColumns( arguments.columns, granted, arguments.objectName );
		viewFilterState = sanitizeFilterState( arguments.filterState, _permittedFilterIds( arguments.objectName ), granted );
		viewId          = $getPresideObject( "admin_datatable_saved_view" ).insertData( data={
			  label        = Left( viewLabel, 100 )
			, description  = Left( Trim( arguments.description ), 500 )
			, owner        = userId
			, object_name  = arguments.objectName
			, listing_key  = arguments.listingKey
			, is_shared    = arguments.canShare && arguments.isShared
			, columns      = ArrayToList( viewColumns )
			, filter_state = SerializeJSON( viewFilterState )
		} );

		if ( !Len( viewId ) ) {
			return { success=false };
		}

		return {
			  success = true
			, view    = {
				  id          = viewId
				, label       = Left( viewLabel, 100 )
				, description = Left( Trim( arguments.description ), 500 )
				, owner       = true
				, shared      = arguments.canShare && arguments.isShared
				, columns     = viewColumns
				, filterState = viewFilterState
			  }
		};
	}

	public struct function updateSavedView(
		  required string  viewId
		, required string  objectName
		,          string  listingKey       = arguments.objectName
		,          string  label            = ""
		,          string  description
		,          array   columns
		,          any     filterState
		,          boolean isShared
		,          boolean canShare         = false
		,          array   grantedFields    = []
		,          string  grantedFieldsSig = ""
	) {
		var record  = _getOwnedSavedView( arguments.viewId, arguments.objectName, arguments.listingKey );
		var granted = [];
		var data    = {};
		var views   = [];
		var view    = {};
		var item    = {};

		if ( StructIsEmpty( record ) ) {
			return { success=false };
		}

		granted = getGrantedListingColumns(
			  objectName       = arguments.objectName
			, listingKey       = arguments.listingKey
			, grantedFields    = arguments.grantedFields
			, grantedFieldsSig = arguments.grantedFieldsSig
		);

		if ( Len( Trim( arguments.label ) ) ) {
			data.label = Left( Trim( arguments.label ), 100 );
		}
		if ( StructKeyExists( arguments, "description" ) ) {
			data.description = Left( Trim( arguments.description ), 500 );
		}
		if ( StructKeyExists( arguments, "columns" ) ) {
			data.columns = ArrayToList( sanitizeViewColumns( arguments.columns, granted, arguments.objectName ) );
		}
		if ( StructKeyExists( arguments, "filterState" ) ) {
			data.filter_state = SerializeJSON( sanitizeFilterState( arguments.filterState, _permittedFilterIds( arguments.objectName ), granted ) );
		}
		if ( StructKeyExists( arguments, "isShared" ) && arguments.canShare ) {
			data.is_shared = arguments.isShared;
		}

		if ( StructCount( data ) && !$getPresideObject( "admin_datatable_saved_view" ).updateData( id=arguments.viewId, data=data ) ) {
			return { success=false };
		}

		views = listSavedViews( arguments.objectName, arguments.listingKey );
		for( item in views ) {
			if ( item.id == arguments.viewId ) {
				view = item;
				break;
			}
		}

		return { success=!StructIsEmpty( view ), view=view };
	}

	public boolean function deleteSavedView(
		  required string viewId
		, required string objectName
		,          string listingKey = arguments.objectName
	) {
		var record = _getOwnedSavedView( arguments.viewId, arguments.objectName, arguments.listingKey );
		if ( StructIsEmpty( record ) ) {
			return false;
		}

		return $getPresideObject( "admin_datatable_saved_view" ).deleteData( id=arguments.viewId ) > 0;
	}

	public array function getGrantedListingColumns(
		  required string objectName
		,          string listingKey       = arguments.objectName
		,          array  grantedFields    = []
		,          string grantedFieldsSig = ""
	) {
		if ( ArrayLen( arguments.grantedFields ) && verifyGrantedColumns(
			  objectName = arguments.objectName
			, listingKey = arguments.listingKey
			, columns    = arguments.grantedFields
			, signature  = arguments.grantedFieldsSig
		) ) {
			return listAvailableColumns( objectName=arguments.objectName, extraFields=arguments.grantedFields );
		}

		return listAvailableColumns( objectName=arguments.objectName );
	}

	public array function filterRequestedGridFields(
		  required array requestedFields
		, required array grantedColumns
		,          array defaultFields = []
	) {
		var selected = [];
		var seen     = {};
		var fieldName;

		for( fieldName in arguments.requestedFields ) {
			fieldName = Trim( fieldName );
			if ( !Len( fieldName ) || StructKeyExists( seen, LCase( fieldName ) ) ) {
				continue;
			}
			if ( ArrayFindNoCase( arguments.grantedColumns, fieldName ) ) {
				ArrayAppend( selected, fieldName );
				seen[ LCase( fieldName ) ] = true;
			}
		}

		if ( ArrayLen( selected ) ) {
			return selected;
		}

		for( fieldName in arguments.defaultFields ) {
			if ( ArrayFindNoCase( arguments.grantedColumns, fieldName ) && !StructKeyExists( seen, LCase( fieldName ) ) ) {
				ArrayAppend( selected, fieldName );
				seen[ LCase( fieldName ) ] = true;
			}
		}

		return selected;
	}

	public string function signGrantedColumns(
		  required string objectName
		, required string listingKey
		, required array  columns
	) {
		return LCase( Hmac( _grantedColumnsMessage( arguments.objectName, arguments.listingKey, arguments.columns ), _getHmacKey(), "HMACSHA256" ) );
	}

	public boolean function verifyGrantedColumns(
		  required string objectName
		, required string listingKey
		, required array  columns
		, required string signature
	) {
		if ( !Len( Trim( arguments.signature ) ) || !ArrayLen( arguments.columns ) ) {
			return false;
		}

		return CompareNoCase(
			  arguments.signature
			, signGrantedColumns( arguments.objectName, arguments.listingKey, arguments.columns )
		) == 0;
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
	private struct function _deserializeFilterState( required any filterState ) {
		var parsed = {};

		if ( IsStruct( arguments.filterState ) ) {
			return Duplicate( arguments.filterState );
		}
		if ( IsSimpleValue( arguments.filterState ) && IsJSON( arguments.filterState ) ) {
			parsed = DeserializeJSON( arguments.filterState );
			if ( IsStruct( parsed ) ) {
				return parsed;
			}
		}

		return emptyFilterState();
	}

	private string function _viewStateFingerprint( required struct state ) {
		var columns     = arguments.state.columns ?: [];
		var rawState    = arguments.state.filterState ?: ( arguments.state.filter_state ?: {} );
		var rawIds      = [];
		var filterState = {};
		var ids         = [];

		if ( !IsStruct( rawState ) ) {
			rawState = _deserializeFilterState( rawState );
		}
		rawIds = rawState.savedFilterIds ?: ( rawState.savedfilterids ?: [] );
		if ( !IsArray( rawIds ) ) {
			rawIds = ListToArray( rawIds );
		}

		filterState = sanitizeFilterState(
			  filterState        = rawState
			, permittedFilterIds = rawIds
		);
		ids = Duplicate( filterState.savedFilterIds );
		ArraySort( ids, "textnocase" );

		return LCase( ArrayToList( columns ) & "|" & ArrayToList( ids ) & "|" & SerializeJSON( filterState.advancedFilter ) & "|" & SerializeJSON( filterState.columnSearch ) );
	}

	private array function _permittedFilterIds( required string objectName ) {
		var ids   = [];
		var items = _serializeSavedFilters( arguments.objectName );
		var item  = {};

		ArrayAppend( items, _serializeSegmentationFilters( arguments.objectName ), true );

		for( item in items ) {
			if ( Len( Trim( item.id ?: "" ) ) ) {
				ArrayAppend( ids, item.id );
			}
		}

		return ids;
	}

	private struct function _savedViewToStruct(
		  required struct record
		, required string userId
		, required array  granted
		, required array  permittedIds
		, required string objectName
	) {
		var ownerId  = arguments.record.owner ?: "";
		var shared   = arguments.record.is_shared ?: false;
		var isShared = IsBoolean( shared ) && shared;

		return {
			  id          = arguments.record.id
			, label       = arguments.record.label ?: ""
			, description = arguments.record.description ?: ""
			, owner       = ownerId == arguments.userId
			, shared      = isShared
			, columns     = sanitizeViewColumns( ListToArray( arguments.record.columns ?: "" ), arguments.granted, arguments.objectName )
			, filterState = sanitizeFilterState( arguments.record.filter_state ?: "", arguments.permittedIds, arguments.granted )
		};
	}

	private struct function _getOwnedSavedView(
		  required string viewId
		, required string objectName
		, required string listingKey
	) {
		var userId = $getAdminLoggedInUserId();
		var record = "";
		var row    = {};

		if ( !Len( Trim( userId ) ) || !Len( Trim( arguments.viewId ) ) ) {
			return {};
		}

		record = $getPresideObject( "admin_datatable_saved_view" ).selectData(
			  filter       = {
				  id          = arguments.viewId
				, object_name = arguments.objectName
				, listing_key = arguments.listingKey
				, owner       = userId
			  }
			, selectFields = [ "id", "label", "description", "owner", "is_shared", "columns", "filter_state" ]
		);

		if ( !record.recordCount ) {
			return {};
		}

		for( row in record ) {
			return row;
		}

		return {};
	}

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

	private struct function _resolveColumnPickerFields(
		  required array  patterns
		, required struct properties
	) {
		var included = [];
		var excluded = {};
		var names    = StructKeyArray( arguments.properties );

		for( var rawPattern in arguments.patterns ) {
			var pattern   = Trim( rawPattern );
			var isExclude = false;

			if ( !Len( pattern ) ) {
				continue;
			}
			if ( Left( pattern, 1 ) == "!" ) {
				isExclude = true;
				pattern   = Trim( Mid( pattern, 2, Len( pattern ) ) );
			}
			if ( !Len( pattern ) ) {
				continue;
			}

			for( var propName in names ) {
				if ( !_matchesColumnPickerPattern( fieldName=propName, pattern=pattern ) ) {
					continue;
				}
				if ( isExclude ) {
					excluded[ LCase( propName ) ] = true;
				} else {
					ArrayAppend( included, propName );
				}
			}
		}

		var expanded = [];
		for( var fieldName in included ) {
			if ( StructKeyExists( excluded, LCase( fieldName ) ) ) {
				continue;
			}
			ArrayAppend( expanded, fieldName );
		}

		return { expanded=expanded, excluded=excluded };
	}

	private boolean function _matchesColumnPickerPattern(
		  required string fieldName
		, required string pattern
	) {
		var regex = "";

		if ( arguments.pattern == "*" ) {
			return true;
		}
		if ( !Find( "*", arguments.pattern ) ) {
			return CompareNoCase( arguments.fieldName, arguments.pattern ) == 0;
		}

		regex = ReReplace( arguments.pattern, "([\\.\+\?\^\$\{\}\(\)\|\[\]])", "\\\1", "all" );
		regex = Replace( regex, "*", ".*", "all" );

		return ReFindNoCase( "^" & regex & "$", arguments.fieldName ) > 0;
	}

	private boolean function _isExcludedField(
		  required struct excluded
		, required string fieldName
	) {
		return StructKeyExists( arguments.excluded, arguments.fieldName )
			|| StructKeyExists( arguments.excluded, LCase( arguments.fieldName ) );
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
		if ( !StructKeyExists( variables, "_rulesEngineFilterService" ) ) {
			return NullValue();
		}

		return variables._rulesEngineFilterService;
	}
	private void function _setRulesEngineFilterService( any rulesEngineFilterService ) {
		variables._rulesEngineFilterService = arguments.rulesEngineFilterService ?: NullValue();
	}

	private string function _grantedColumnsMessage(
		  required string objectName
		, required string listingKey
		, required array  columns
	) {
		var fields = _uniqueFields( arguments.columns );
		ArraySort( fields, "textnocase" );

		return LCase( arguments.objectName & "|" & arguments.listingKey & "|" & ArrayToList( fields ) );
	}

	private string function _getHmacKey() {
		var key = _getSessionStorage().getVar( name="_listingGridFieldsHmacKey", default="" );

		if ( !Len( Trim( key ) ) ) {
			key = CreateUUId();
			_getSessionStorage().setVar( "_listingGridFieldsHmacKey", key );
		}

		return key;
	}

	private any function _getSessionStorage() {
		return _sessionStorage;
	}
	private void function _setSessionStorage( required any sessionStorage ) {
		_sessionStorage = arguments.sessionStorage;
	}

}
