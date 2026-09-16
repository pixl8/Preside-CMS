/**
 * Listing toolbar helpers: per-user column and active-view preferences,
 * available column pools, and auto quick-filter definitions for column heading search.
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
	 * @dataManagerDefaults.inject         coldbox:setting:dataManager.defaults
	 */
	public any function init(
		  required any dataManagerService
		, required any customizationService
		, required any enumService
		, required any sessionStorage
		,          any rulesEngineFilterService
		,          any dataManagerDefaults
	) {
		_setDataManagerService( arguments.dataManagerService );
		_setCustomizationService( arguments.customizationService );
		_setEnumService( arguments.enumService );
		_setSessionStorage( arguments.sessionStorage );
		_setRulesEngineFilterService( arguments.rulesEngineFilterService ?: NullValue() );
		_setDataManagerDefaults( IsStruct( arguments.dataManagerDefaults ?: "" ) ? arguments.dataManagerDefaults : {} );

		return this;
	}

	public array function listDefaultColumns( required string objectName ) {
		return _getDataManagerService().listGridFields( arguments.objectName );
	}

	public array function listLockedColumns( required string objectName ) {
		return ListToArray( $getPresideObjectService().getObjectAttribute(
			  objectName    = arguments.objectName
			, attributeName = "datamanagerLockedGridFields"
			, defaultValue  = ""
		), ", " );
	}

	public boolean function listingAllowsSavedViews(
		  required string  objectName
		,          boolean allowColumnPicker = true
		,          boolean compact           = false
		,          any     allowSavedViews
	) {
		var annotated = "";

		if ( arguments.compact ) {
			return false;
		}
		if ( _hasExplicitSavedViewsFlag( argumentCollection=arguments ) ) {
			return $helpers.isTrue( arguments.allowSavedViews );
		}

		annotated = $getPresideObjectService().getObjectAttribute(
			  objectName    = arguments.objectName
			, attributeName = "datamanagerAllowSavedViews"
			, defaultValue  = ""
		);
		if ( IsBoolean( annotated ) ) {
			return $helpers.isTrue( annotated );
		}

		return arguments.allowColumnPicker;
	}

	/**
	 * Default pool is `@datamanagerGridFields` plus `@datamanagerHiddenGridFields`
	 * and optional `@datamanagerColumnPickerFields`. When the object omits that
	 * annotation, `dataManager.defaults.columnPickerFields` is used (`auto`
	 * unless the application sets e.g. `*` or `""`). Picker field lists accept
	 * `auto` (sensible columns), `*` wildcards and `!` exclusions, e.g.
	 * `auto,!sensitive_col`. Properties may opt in or out with
	 * `datamanagerUserColumn=true|false`. Locked columns come from
	 * `@datamanagerLockedGridFields` (none if unset). Handlers can replace
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
		if ( !Len( Trim( pickerAttr ) ) ) {
			pickerAttr = _defaultColumnPickerFields();
		}
		var pickerPatterns = ListToArray( ReReplace( pickerAttr, "\s+", "", "all" ), "," );
		var pickerSpec     = _resolveColumnPickerFields(
			  objectName = arguments.objectName
			, patterns   = pickerPatterns
			, properties = properties
		);
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
		,          string contextKey    = ""
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
		var stored   = StructKeyExists( arguments, "storedFields" ) ? arguments.storedFields : _getStoredColumns(
			  objectName  = arguments.objectName
			, listingKey  = arguments.listingKey
			, contextKey  = arguments.contextKey
		);
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
		,          string contextKey       = ""
		,          array  grantedFields    = []
		,          string grantedFieldsSig = ""
	) {
		return saveUserPreference( argumentCollection=arguments );
	}

	public boolean function saveUserPreference(
		  required string objectName
		,          string listingKey       = arguments.objectName
		,          string contextKey       = ""
		,          array  grantedFields    = []
		,          string grantedFieldsSig = ""
	) {
		var userId     = $getAdminLoggedInUserId();
		var hasColumns = StructKeyExists( arguments, "columns" ) && IsArray( arguments.columns );
		var hasView    = StructKeyExists( arguments, "activeView" );
		var context    = _normalizeContextKey( arguments.contextKey );
		var dao        = "";
		var existing   = "";
		var data       = {};
		var available  = [];
		var cleaned    = [];

		if ( !Len( Trim( userId ) ) || ( !hasColumns && !hasView ) ) {
			return false;
		}

		dao      = $getPresideObject( "admin_datatable_user_preference" );
		existing = dao.selectData(
			  filter       = _userPreferenceFilter(
				  userId     = userId
				, objectName = arguments.objectName
				, listingKey = arguments.listingKey
				, contextKey = context
			  )
			, selectFields = [ "id" ]
		);

		if ( hasColumns ) {
			if ( ArrayLen( arguments.columns ) ) {
				available = getGrantedListingColumns(
					  objectName       = arguments.objectName
					, listingKey       = arguments.listingKey
					, grantedFields    = arguments.grantedFields
					, grantedFieldsSig = arguments.grantedFieldsSig
				);
				cleaned = applyUserColumns(
					  objectName    = arguments.objectName
					, listingKey    = arguments.listingKey
					, contextKey    = context
					, defaultFields = listDefaultColumns( arguments.objectName )
					, available     = available
					, storedFields  = arguments.columns
				);
				data.columns = ArrayToList( cleaned );
			} else {
				data.columns = "";
			}
		}

		if ( hasView ) {
			data.active_view = _normalizeActiveViewId( arguments.activeView );
		}

		if ( existing.recordCount ) {
			return dao.updateData( id=existing.id, data=data );
		}

		data.security_user = userId;
		data.object_name   = arguments.objectName;
		data.listing_key   = arguments.listingKey;
		data.context_key   = context;

		return Len( dao.insertData( data=data ) ) > 0;
	}

	public struct function getUserPreference(
		  required string objectName
		,          string listingKey = arguments.objectName
		,          string contextKey = ""
	) {
		var record = _getUserPreferenceRecord(
			  objectName  = arguments.objectName
			, listingKey  = arguments.listingKey
			, contextKey  = arguments.contextKey
		);
		var pref   = { columns=[], activeView="default" };

		if ( StructIsEmpty( record ) ) {
			return pref;
		}

		if ( Len( Trim( record.columns ?: "" ) ) ) {
			pref.columns = ListToArray( record.columns );
		}
		pref.activeView = _normalizeActiveViewId( record.active_view ?: "" );

		return pref;
	}

	public struct function resolveListingContext(
		  string listingContextKey   = ""
		, string listingContextLabel = ""
		, string datasourceUrl       = ""
	) {
		var named = Len( Trim( arguments.listingContextKey ) ) > 0;
		var key   = "";
		var label = Trim( arguments.listingContextLabel );

		if ( named ) {
			key = _normalizeContextKey( arguments.listingContextKey );
		} else {
			key = _contextKeyFromDatasourceUrl( arguments.datasourceUrl );
		}

		if ( named && Len( label ) && Find( ":", label ) ) {
			label = $translateResource( uri=label, defaultValue=label );
		} else if ( !named ) {
			label = "";
		}

		return {
			  key   = key
			, label = label
			, named = named
		};
	}

	public array function listQuickFilters( required string objectName, array extraFields=[] ) {
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
			fieldNames = listAvailableColumns( objectName=arguments.objectName, extraFields=arguments.extraFields );
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

	/**
	 * Extra everything-bar actions from `getEverythingBarActions` (object or global
	 * customization). Each action may include `endpoint`; the bar POSTs `object`,
	 * `listingKey`, `query`, and `currentFilters` (JSON of search, savedFilterIds,
	 * extraFilters, columnSearch, advancedFilter). A successful JSON body (`ok` or
	 * `success`) may apply any combination of: `search`, `savedFilterIds`,
	 * `columnSearch`, `extraFilters` (or legacy `expression` + `label`),
	 * `advancedFilter`, and `openAdvancedFilter`.
	 */
	public array function listEverythingBarActions(
		  required string  objectName
		,          string  listingKey  = arguments.objectName
		,          boolean allowFilter = true
		,          boolean allowSearch = true
	) {
		var actions = _getCustomizationService().runCustomization(
			  objectName    = arguments.objectName
			, action        = "getEverythingBarActions"
			, args          = {
				  listingKey  = arguments.listingKey
				, allowFilter = arguments.allowFilter
				, allowSearch = arguments.allowSearch
			  }
			, defaultResult = []
		);

		return _normalizeEverythingBarActions( actions );
	}

	public struct function getToolbarConfig(
		  required string  objectName
		,          string  listingKey        = arguments.objectName
		,          string  contextKey        = ""
		,          string  contextLabel      = ""
		,          boolean namedContext      = false
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
		var pref      = getUserPreference(
			  objectName  = arguments.objectName
			, listingKey  = arguments.listingKey
			, contextKey  = arguments.contextKey
		);
		var current   = applyUserColumns(
			  objectName    = arguments.objectName
			, listingKey    = arguments.listingKey
			, contextKey    = arguments.contextKey
			, defaultFields = arguments.gridFields
			, available     = available
			, storedFields  = pref.columns
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
			, quickFilters         = ( arguments.allowFilter && arguments.allowColumnFilter ) ? listQuickFilters( objectName=arguments.objectName, extraFields=extraFields ) : []
			, columns              = columns
			, currentColumns       = current
			, defaultColumns       = defaultColumns
			, lockedColumns        = locked
			, listingKey           = arguments.listingKey
			, listingContextKey    = _normalizeContextKey( arguments.contextKey )
			, listingContextLabel  = arguments.contextLabel
			, namedListingContext  = arguments.namedContext
			, activeView           = arguments.allowSavedViews ? pref.activeView : "default"
			, grantedColumns       = available
			, grantedColumnsSig    = signGrantedColumns( arguments.objectName, arguments.listingKey, available )
			, allowFilter          = arguments.allowFilter
			, allowSearch          = arguments.allowSearch
			, everythingBarActions = listEverythingBarActions(
				  objectName   = arguments.objectName
				, listingKey   = arguments.listingKey
				, allowFilter  = arguments.allowFilter
				, allowSearch  = arguments.allowSearch
			  )
			, allowManageFilter    = arguments.allowManageFilter
			, manageFilterLink     = arguments.manageFilterLink
			, allowSavedViews      = arguments.allowSavedViews
			, canShareViews        = arguments.allowSavedViews && arguments.canShareViews
			, savedViews           = arguments.allowSavedViews ? listSavedViews( arguments.objectName, arguments.listingKey, arguments.contextKey ) : []
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
		,          string contextKey = ""
	) {
		var userId       = $getAdminLoggedInUserId();
		var context      = _normalizeContextKey( arguments.contextKey );
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
			, extraFilters = [
				  _savedViewPermissionFilter( userId )
				, _savedViewContextFilter( context )
			  ]
			, distinct     = true
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
		,          boolean isShared         = false
		,          boolean canShare         = false
		,          string  sharingScope     = ""
		,          string  userGroups       = ""
		,          boolean allowGroupEdit   = false
		,          array   grantedFields    = []
		,          string  grantedFieldsSig = ""
		,          string  contextKey       = ""
		,          boolean namedContext     = false
		,          string  contextScope     = "this"
	) {
		var userId          = $getAdminLoggedInUserId();
		var viewLabel       = Trim( arguments.label );
		var granted         = [];
		var viewColumns     = [];
		var viewFilterState = {};
		var viewId          = "";
		var sharing         = {};
		var storedContext   = "";

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
		sharing         = _normalizeSharing(
			  sharingScope   = arguments.sharingScope
			, userGroups     = arguments.userGroups
			, allowGroupEdit = arguments.allowGroupEdit
			, isShared       = arguments.isShared
			, canShare       = arguments.canShare
		);
		storedContext   = _storedViewContextKey(
			  contextKey   = arguments.contextKey
			, namedContext = arguments.namedContext
			, contextScope = arguments.contextScope
		);
		viewId          = $getPresideObject( "admin_datatable_saved_view" ).insertData(
			  data = {
				  label            = Left( viewLabel, 100 )
				, owner            = userId
				, object_name      = arguments.objectName
				, listing_key      = arguments.listingKey
				, context_key      = storedContext
				, is_shared        = sharing.isShared
				, sharing_scope    = sharing.sharingScope
				, allow_group_edit = sharing.allowGroupEdit
				, user_groups      = sharing.userGroups
				, columns          = ArrayToList( viewColumns )
				, filter_state     = SerializeJSON( viewFilterState )
			  }
			, insertManyToManyRecords = true
		);

		if ( !Len( viewId ) ) {
			return { success=false };
		}

		return {
			  success = true
			, view    = {
				  id          = viewId
				, label       = Left( viewLabel, 100 )
				, owner       = true
				, shared      = sharing.isShared
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
		,          array   columns
		,          any     filterState
		,          boolean isShared
		,          boolean canShare         = false
		,          string  sharingScope
		,          string  userGroups
		,          boolean allowGroupEdit
		,          array   grantedFields    = []
		,          string  grantedFieldsSig = ""
		,          string  contextKey       = ""
		,          boolean namedContext     = false
		,          string  contextScope
	) {
		var record  = _getOwnedSavedView( arguments.viewId, arguments.objectName, arguments.listingKey );
		var granted = [];
		var data    = {};
		var views   = [];
		var view    = {};
		var item    = {};
		var sharing = {};

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
		if ( StructKeyExists( arguments, "columns" ) ) {
			data.columns = ArrayToList( sanitizeViewColumns( arguments.columns, granted, arguments.objectName ) );
		}
		if ( StructKeyExists( arguments, "filterState" ) ) {
			data.filter_state = SerializeJSON( sanitizeFilterState( arguments.filterState, _permittedFilterIds( arguments.objectName ), granted ) );
		}
		if ( StructKeyExists( arguments, "sharingScope" ) ) {
			sharing = _normalizeSharing(
				  sharingScope   = arguments.sharingScope
				, userGroups     = arguments.userGroups ?: ""
				, allowGroupEdit = $helpers.isTrue( arguments.allowGroupEdit ?: false )
				, isShared       = $helpers.isTrue( arguments.isShared ?: false )
				, canShare       = arguments.canShare
			);
			data.is_shared        = sharing.isShared;
			data.sharing_scope    = sharing.sharingScope;
			data.allow_group_edit = sharing.allowGroupEdit;
			data.user_groups      = sharing.userGroups;
		} else if ( StructKeyExists( arguments, "isShared" ) && arguments.canShare ) {
			data.is_shared     = arguments.isShared;
			data.sharing_scope = arguments.isShared ? "global" : "individual";
		}

		if ( StructKeyExists( arguments, "contextScope" ) ) {
			data.context_key = _storedViewContextKey(
				  contextKey   = arguments.contextKey
				, namedContext = arguments.namedContext
				, contextScope = arguments.contextScope
			);
		}

		if ( StructCount( data ) && !$getPresideObject( "admin_datatable_saved_view" ).updateData(
			  id                      = arguments.viewId
			, data                    = data
			, updateManyToManyRecords = StructKeyExists( data, "user_groups" )
		) ) {
			return { success=false };
		}

		views = listSavedViews( arguments.objectName, arguments.listingKey, arguments.contextKey );
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

		if ( $getPresideObject( "admin_datatable_saved_view" ).deleteData( id=arguments.viewId ) <= 0 ) {
			return false;
		}

		$getPresideObject( "admin_datatable_user_preference" ).updateData(
			  filter = { active_view=arguments.viewId }
			, data   = { active_view="default" }
		);

		return true;
	}

	public struct function getSavedViewFormData(
		  required string viewId
		, required string objectName
		,          string listingKey = arguments.objectName
	) {
		var record = _getOwnedSavedView( arguments.viewId, arguments.objectName, arguments.listingKey );
		var groups = "";
		var groupQry;

		if ( StructIsEmpty( record ) ) {
			return {};
		}

		groupQry = $getPresideObject( "admin_datatable_saved_view_user_group" ).selectData(
			  filter       = { admin_datatable_saved_view=arguments.viewId }
			, selectFields = [ "security_group" ]
		);
		if ( groupQry.recordCount ) {
			groups = ValueList( groupQry.security_group );
		}

		return {
			  label            = record.label ?: ""
			, sharing_scope    = _legacySharingScope( record )
			, allow_group_edit = $helpers.IsTrue( record.allow_group_edit ?: false )
			, user_groups      = groups
			, context_scope    = Len( Trim( record.context_key ?: "" ) ) ? "this" : "global"
		};
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

	private struct function _savedViewPermissionFilter( required string userId ) {
		var userGroups = $getAdminPermissionService().listUserGroups( arguments.userId );
		var filter     = "owner = :owner or sharing_scope = 'global' or ( sharing_scope is null and is_shared = :is_shared )";
		var params     = {
			  owner     = arguments.userId
			, is_shared = true
		};

		if ( ArrayLen( userGroups ) ) {
			filter &= " or ( sharing_scope = 'group' and user_groups.id in ( :user_groups.id ) )";
			params[ "user_groups.id" ] = userGroups;
		}

		return { filter=filter, filterParams=params };
	}

	private struct function _normalizeSharing(
		  string  sharingScope   = ""
		, string  userGroups     = ""
		, boolean allowGroupEdit = false
		, boolean isShared       = false
		, boolean canShare       = true
	) {
		var scope  = LCase( Trim( arguments.sharingScope ) );
		var groups = Trim( arguments.userGroups );

		if ( !Len( scope ) ) {
			scope = ( arguments.canShare && arguments.isShared ) ? "global" : "individual";
		}
		if ( !ArrayFindNoCase( [ "global", "group", "individual" ], scope ) ) {
			scope = "individual";
		}
		if ( !arguments.canShare && scope != "individual" ) {
			scope  = "individual";
			groups = "";
		}
		if ( scope != "group" ) {
			groups = "";
		}

		return {
			  sharingScope   = scope
			, isShared       = scope != "individual"
			, userGroups     = groups
			, allowGroupEdit = scope == "group" && arguments.allowGroupEdit
		};
	}

	private string function _legacySharingScope( required struct record ) {
		var scope  = LCase( Trim( arguments.record.sharing_scope ?: "" ) );
		var shared = arguments.record.is_shared ?: false;

		if ( ArrayFindNoCase( [ "global", "group", "individual" ], scope ) ) {
			return scope;
		}

		return ( IsBoolean( shared ) && shared ) ? "global" : "individual";
	}

	private struct function _savedViewToStruct(
		  required struct record
		, required string userId
		, required array  granted
		, required array  permittedIds
		, required string objectName
	) {
		var ownerId  = arguments.record.owner ?: "";
		var isShared = _legacySharingScope( arguments.record ) != "individual";

		return {
			  id          = arguments.record.id
			, label       = arguments.record.label ?: ""
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
			, selectFields = [ "id", "label", "owner", "is_shared", "sharing_scope", "allow_group_edit", "columns", "filter_state", "context_key" ]
		);

		if ( !record.recordCount ) {
			return {};
		}

		for( row in record ) {
			return row;
		}

		return {};
	}

	private array function _getStoredColumns(
		  required string objectName
		, required string listingKey
		,          string contextKey = ""
	) {
		return getUserPreference(
			  objectName  = arguments.objectName
			, listingKey  = arguments.listingKey
			, contextKey  = arguments.contextKey
		).columns;
	}

	private struct function _getUserPreferenceRecord(
		  required string objectName
		, required string listingKey
		,          string contextKey = ""
	) {
		var userId   = $getAdminLoggedInUserId();
		var dao      = "";
		var context  = _normalizeContextKey( arguments.contextKey );
		var record   = "";
		var fallback = "";
		var row      = {};

		if ( !Len( Trim( userId ) ) ) {
			return {};
		}

		dao    = $getPresideObject( "admin_datatable_user_preference" );
		record = dao.selectData(
			  filter       = _userPreferenceFilter(
				  userId     = userId
				, objectName = arguments.objectName
				, listingKey = arguments.listingKey
				, contextKey = context
			  )
			, selectFields = [ "id", "columns", "active_view" ]
		);

		if ( !record.recordCount && context != "" ) {
			fallback = dao.selectData(
				  filter       = _userPreferenceFilter(
					  userId     = userId
					, objectName = arguments.objectName
					, listingKey = arguments.listingKey
					, contextKey = ""
				  )
				, selectFields = [ "id", "columns", "active_view" ]
			);
			if ( fallback.recordCount ) {
				record = fallback;
			}
		}

		if ( !record.recordCount ) {
			return {};
		}

		for( row in record ) {
			return row;
		}

		return {};
	}

	private struct function _userPreferenceFilter(
		  required string userId
		, required string objectName
		, required string listingKey
		,          string contextKey = ""
	) {
		return {
			  security_user = arguments.userId
			, object_name   = arguments.objectName
			, listing_key   = arguments.listingKey
			, context_key   = arguments.contextKey
		};
	}

	private struct function _savedViewContextFilter( string contextKey = "" ) {
		return {
			  filter       = "context_key = :savedViewContextEmpty or context_key = :savedViewContextCurrent"
			, filterParams = {
				  savedViewContextEmpty   = { type="cf_sql_varchar", value="" }
				, savedViewContextCurrent = { type="cf_sql_varchar", value=arguments.contextKey }
			  }
		};
	}

	private string function _storedViewContextKey(
		  string  contextKey   = ""
		, boolean namedContext = false
		, string  contextScope = "this"
	) {
		if ( arguments.namedContext && LCase( Trim( arguments.contextScope ) ) == "global" ) {
			return "";
		}

		return _normalizeContextKey( arguments.contextKey );
	}

	private string function _normalizeContextKey( string contextKey = "" ) {
		var key = Trim( arguments.contextKey );

		if ( Len( key ) > 100 ) {
			return LCase( Hash( key ) );
		}

		return key;
	}

	private string function _contextKeyFromDatasourceUrl( string datasourceUrl = "" ) {
		var raw      = Trim( ListFirst( arguments.datasourceUrl, "##" ) );
		var queryPos = Find( "?", raw );
		var qs       = queryPos ? Mid( raw, queryPos + 1, Len( raw ) ) : "";
		var pairs    = [];
		var pair     = "";
		var key      = "";

		for( pair in ListToArray( qs, "&" ) ) {
			key = Trim( UrlDecode( ListFirst( pair, "=" ) ) );
			if ( !Len( key ) || _isCacheBusterParam( key ) ) {
				continue;
			}
			ArrayAppend( pairs, pair );
		}

		if ( ArrayLen( pairs ) ) {
			ArraySort( pairs, "textnocase" );
		}

		return _normalizeContextKey( ArrayToList( pairs, "&" ) );
	}

	private boolean function _isCacheBusterParam( required string paramName ) {
		return ArrayFindNoCase( [ "cachebuster", "prefetchCacheBuster", "_" ], arguments.paramName ) > 0;
	}

	private string function _normalizeActiveViewId( string activeView = "" ) {
		var viewId = Trim( arguments.activeView );

		if ( !Len( viewId ) || viewId == "default" ) {
			return "default";
		}

		return viewId;
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

	private boolean function _isAutoPickerColumn(
		  required string fieldName
		, required struct propertyDefinition
		,          string idField = "id"
	) {
		var prop          = arguments.propertyDefinition;
		var relationship  = LCase( Trim( prop.relationship  ?: "" ) );
		var renderer      = LCase( Trim( prop.renderer      ?: "" ) );
		var adminRenderer = LCase( Trim( prop.adminRenderer ?: "" ) );
		var dbtype        = LCase( Trim( prop.dbtype        ?: "" ) );
		var propType      = LCase( Trim( prop.type          ?: "" ) );

		if ( CompareNoCase( arguments.fieldName, "id" ) == 0 || ( Len( arguments.idField ) && CompareNoCase( arguments.fieldName, arguments.idField ) == 0 ) ) {
			return false;
		}
		if ( Left( arguments.fieldName, 1 ) == "_" ) {
			return false;
		}
		if ( ListFindNoCase( "one-to-many,many-to-many,select-data-view", relationship ) ) {
			return false;
		}
		if ( ListFindNoCase( "none,encrypted,password", renderer ) || adminRenderer == "none" ) {
			return false;
		}
		if ( $helpers.isTrue( prop.secret ?: "" ) || $helpers.isTrue( prop.excludeDataExport ?: "" ) ) {
			return false;
		}
		if ( IsBoolean( prop.autofilter ?: "" ) && !$helpers.isTrue( prop.autofilter ) ) {
			return false;
		}
		if ( ListFindNoCase( "text,longtext,mediumtext,tinytext", dbtype ) || propType == "text" ) {
			return false;
		}
		if ( ListFindNoCase( "blob,mediumblob,longblob,tinyblob,binary", dbtype ) || propType == "binary" ) {
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
		if ( formula ) {
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
			var relatedTo = Trim( prop.relatedTo ?: "" );
			if ( !Len( relatedTo ) ) {
				return {};
			}

			base.type                = "object";
			base.expressionId        = "presideobject_manytoonematch_#arguments.objectName#.#propName#";
			base.filterExpressionId  = "presideobject_manytoonefilter_#arguments.objectName#.#propName#";
			base.relatedTo           = relatedTo;
			base.relatedToLabel      = _relatedObjectTitle( relatedTo );
			return base;
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

	private string function _relatedObjectTitle( required string objectName ) {
		if ( !Len( Trim( arguments.objectName ) ) ) {
			return "";
		}

		return $translateResource(
			  uri          = $getPresideObjectService().getResourceBundleUriRoot( arguments.objectName ) & "title"
			, defaultValue = arguments.objectName
		);
	}

	private array function _normalizeEverythingBarActions( required any actions ) {
		var normalized = [];
		var action     = {};
		var item       = {};
		var icon       = "";
		var chipIcon   = "";

		if ( !IsArray( arguments.actions ) ) {
			return [];
		}

		for( action in arguments.actions ) {
			if ( !IsStruct( action ) || !Len( Trim( action.id ?: "" ) ) ) {
				continue;
			}

			icon = _fontAwesomeIconName( action.icon ?: "magic" );
			item = {
				  id           = Trim( action.id )
				, icon         = Len( icon ) ? icon : "magic"
				, requireQuery = true
			};

			if ( StructKeyExists( action, "requireQuery" ) && IsBoolean( action.requireQuery ) ) {
				item.requireQuery = action.requireQuery;
			}
			if ( Len( Trim( action.labelUri ?: "" ) ) ) {
				item.labelUri = Trim( action.labelUri );
			}
			if ( Len( Trim( action.label ?: "" ) ) ) {
				item.label = action.label;
			}
			if ( Len( Trim( action.endpoint ?: "" ) ) ) {
				item.endpoint = Trim( action.endpoint );
			}

			chipIcon = _fontAwesomeIconName( action.chipIcon ?: "" );
			if ( Len( chipIcon ) ) {
				item.chipIcon = chipIcon;
			}

			ArrayAppend( normalized, item );
		}

		return normalized;
	}

	private string function _fontAwesomeIconName( required string icon ) {
		var name = Trim( arguments.icon );

		if ( Left( name, 3 ) == "fa-" ) {
			return Mid( name, 4, Len( name ) );
		}

		return name;
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
		  required string objectName
		, required array  patterns
		, required struct properties
	) {
		var included = [];
		var excluded = {};
		var names    = StructKeyArray( arguments.properties );
		var idField  = "";

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
			if ( !isExclude && CompareNoCase( pattern, "auto" ) == 0 ) {
				if ( !Len( idField ) ) {
					idField = $getPresideObjectService().getIdField( arguments.objectName );
				}
				for( var propName in names ) {
					if ( _isAutoPickerColumn( fieldName=propName, propertyDefinition=arguments.properties[ propName ], idField=idField ) ) {
						ArrayAppend( included, propName );
					}
				}
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

	private boolean function _hasExplicitSavedViewsFlag() {
		if ( !StructKeyExists( arguments, "allowSavedViews" ) || IsNull( arguments.allowSavedViews ) ) {
			return false;
		}

		return IsBoolean( arguments.allowSavedViews ) || Len( Trim( arguments.allowSavedViews ) );
	}

	private string function _defaultColumnPickerFields() {
		var defaults = _getDataManagerDefaults();

		if ( !IsStruct( defaults ) ) {
			return "auto";
		}

		return Trim( defaults.columnPickerFields ?: "auto" );
	}

	private any function _getDataManagerService() {
		return _dataManagerService;
	}
	private void function _setDataManagerService( required any dataManagerService ) {
		_dataManagerService = arguments.dataManagerService;
	}

	private any function _getDataManagerDefaults() {
		return _dataManagerDefaults ?: {};
	}
	private void function _setDataManagerDefaults( required any dataManagerDefaults ) {
		_dataManagerDefaults = arguments.dataManagerDefaults;
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
