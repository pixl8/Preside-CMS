/**
 * @singleton
 * @presideservice
 *
 */
component {

// CONSTRUCTOR

	/**
	 * @presideObjectService.inject PresideObjectService
	 * @contentRenderer.inject      ContentRendererService
	 * @i18nPlugin.inject           coldbox:plugin:i18n
	 * @permissionService.inject    PermissionService
	 * @siteService.inject          SiteService
	 */
	public any function init( required any presideObjectService, required any contentRenderer, required any i18nPlugin, required any permissionService, required any siteService ) {
		_setPresideObjectService( arguments.presideObjectService );
		_setContentRenderer( arguments.contentRenderer );
		_setI18nPlugin( arguments.i18nPlugin );
		_setPermissionService( arguments.permissionService );
		_setSiteService( arguments.siteService );

		return this;
	}

// PUBLIC METHODS
	public array function getGroupedObjects() {
		var poService          = _getPresideObjectService();
		var permsService       = _getPermissionService();
		var activeSiteTemplate = _getSiteService().getActiveSiteTemplate();
		var i18nPlugin         = _getI18nPlugin();
		var objectNames        = poService.listObjects();
		var groups             = {};
		var groupedObjects     = [];

		for( var objectName in objectNames ){
			var groupId            = poService.getObjectAttribute( objectName=objectName, attributeName="datamanagerGroup", defaultValue="" );
			var siteTemplates      = poService.getObjectAttribute( objectName=objectName, attributeName="siteTemplates"   , defaultValue="*" );
			var isInActiveTemplate = siteTemplates == "*" || ListFindNoCase( siteTemplates, activeSiteTemplate );

			if ( isInActiveTemplate && Len( Trim( groupId ) ) && permsService.hasPermission( permissionKey="datamanager.navigate", context="datamanager", contextKeys=[ objectName ] ) ) {
				if ( !StructKeyExists( groups, groupId ) ) {
					groups[ groupId ] = {
						  title       = i18nPlugin.translateResource( uri="preside-objects.groups.#groupId#:title" )
						, description = i18nPlugin.translateResource( uri="preside-objects.groups.#groupId#:description" )
						, icon        = i18nPlugin.translateResource( uri="preside-objects.groups.#groupId#:iconclass" )
						, objects     = []
					};
				}
				groups[ groupId ].objects.append( {
					  id    = objectName
					, title = i18nPlugin.translateResource( uri="preside-objects.#objectName#:title" )
				} );
			}
		}

		for( var group in groups ) {
			groups[ group ].objects.sort( function( obj1, obj2 ){
				return obj1.title > obj2.title ? 1 : -1;
			} );
			ArrayAppend( groupedObjects, groups[ group ] );
		}

		groupedObjects.sort( function( group1, group2 ){
			return group1.title > group2.title ? 1 : -1;
		} );

		return groupedObjects;

	}

	public boolean function isObjectAvailableInDataManager( required string objectName ) {
		var groupId = _getPresideObjectService().getObjectAttribute( objectName=arguments.objectName, attributeName="datamanagerGroup", defaultValue="" );

		return Len( Trim( groupId ) );
	}

	public array function listGridFields( required string objectName ) {
		var labelfield = _getPresideObjectService().getObjectAttribute(
			  objectName    = arguments.objectName
			, attributeName = "labelfield"
			, defaultValue  = "label"
		);
		var fields = _getPresideObjectService().getObjectAttribute(
			  objectName    = arguments.objectName
			, attributeName = "datamanagerGridFields"
			, defaultValue  = "#labelfield#,datecreated,datemodified"
		);

		return ListToArray( fields );
	}

	public array function listBatchEditableFields( required string objectName ) {
		var fields               = [];
		var objectAttributes     = _getPresideObjectService().getObjectProperties( objectName );
		var forbiddenFields      = [ "id", "datecreated", "datemodified", _getPresideObjectService().getObjectAttribute( arguments.objectName, "labelfield", "label" ) ];
		var isFieldBatchEditable = function( propertyName, attributes ) {
			if ( forbiddenFields.findNoCase( propertyName ) ) {
				return false
			}
			if ( attributes.relationship == "one-to-many" ) {
				return false;
			}
			if ( Len( Trim( attributes.uniqueindexes ?: "" ) ) ) {
				return false;
			}
			if ( propertyName.startsWith( "_" ) ) {
				return false;
			}
			if ( IsBoolean( attributes.batcheditable ?: "" ) && !attributes.batcheditable ) {
				return false;
			}

			return true;
		}

		for( var property in objectAttributes ) {
			if ( isFieldBatchEditable( property, objectAttributes[ property ] ) ) {
       		 	ArrayAppend( fields, property );
			}
		}

		return fields;
	}

	public boolean function isOperationAllowed( required string objectName, required string operation ) {
		var operations = _getPresideObjectService().getObjectAttribute(
			  objectName    = arguments.objectName
			, attributeName = "datamanagerAllowedOperations"
			, defaultValue  = "add,edit,delete,viewversions"
		);

		return operations != "none" && ListFindNoCase( operations, arguments.operation );
	}

	public boolean function isSortable( required string objectName ) {
		var sortable = _getPresideObjectService().getObjectAttribute(
			  objectName    = arguments.objectName
			, attributeName = "datamanagerSortable"
		);

		return IsBoolean( sortable ) && sortable;
	}

	public string function getSortField( required string objectName ) {
		return _getPresideObjectService().getObjectAttribute(
			  objectName    = arguments.objectName
			, attributeName = "datamanagerSortField"
			, defaultValue  = "sortorder"
		);
	}

	public string function getDefaultSortOrderForDataGrid( required string objectName ) output=false {
		return _getPresideObjectService().getObjectAttribute(
			  objectName    = arguments.objectName
			, attributeName = "datamanagerDefaultSortOrder"
			, defaultValue  = ""
		);
	}

	public query function getRecordsForSorting( required string objectName ) {
		var sortField = getSortField( arguments.objectName );
		return _getPresideObjectService().selectData(
			  objectName   = arguments.objectName
			, selectFields = [ "id", "${labelfield} as label", sortField ]
			, orderby      = sortField
		);
	}

	public void function saveSortedRecords( required string objectName, required array sortedIds ) {
		var object    = _getPresideObjectService().getObject( arguments.objectName );
		var sortField = getSortField( arguments.objectName );

		for( var i=1; i <= arguments.sortedIds.len(); i++ ) {
			object.updateData(
				  id   = arguments.sortedIds[ i ]
				, data = { "#sortField#" = i }
			);
		}
	}

	public struct function getRecordsForGridListing(
		  required string  objectName
		, required array   gridFields
		,          numeric startRow     = 1
		,          numeric maxRows      = 10
		,          string  orderBy      = ""
		,          string  searchQuery  = ""
		,          any     filter       = {}
		,          struct  filterParams = {}

	) {

		var result = { totalRecords = 0, records = "" };
		var args   = {
			  objectName         = arguments.objectName
			, selectFields       = _prepareGridFieldsForSqlSelect( arguments.gridFields, arguments.objectName )
			, startRow           = arguments.startRow
			, maxRows            = arguments.maxRows
			, orderBy            = arguments.orderBy
			, filter             = arguments.filter
			, filterParams       = arguments.filterParams
			, allowDraftVersions = true
			, extraFilters       = []
		};

		if ( Len( Trim( arguments.searchQuery ) ) ) {
			args.extraFilters.append({
				  filter       = _buildSearchFilter( arguments.searchQuery, arguments.objectName, arguments.gridFields )
				, filterParams = { q = { type="varchar", value="%" & arguments.searchQuery & "%" } }
			});
		}

		result.records = _getPresideObjectService().selectData( argumentCollection = args );

		if ( arguments.startRow eq 1 and result.records.recordCount lt arguments.maxRows ) {
			result.totalRecords = result.records.recordCount;
		} else {
			result.totalRecords = _getPresideObjectService().selectData(
				  objectName         = arguments.objectName
				, selectFields       = [ "count( * ) as nRows" ]
				, filter             = arguments.filter
				, filterParams       = arguments.filterParams
				, allowDraftVersions = true
			).nRows;
		}

		return result;
	}

	public struct function getRecordHistoryForGridListing(
		  required string  objectName
		, required string  recordId
		,          string  property     = ""
		,          numeric startRow     = 1
		,          numeric maxRows      = 10
		,          string  orderBy      = ""
		,          any     filter       = ""
		,          any     filterParams = {}
	) {
		var result = { totalRecords = 0, records = "" };
		var args   = {
			  objectName       = arguments.objectName
			, id               = arguments.recordId
			, selectFields     = [ "id", "_version_is_draft as published", "datemodified", "_version_author", "_version_changed_fields", "_version_number" ]
			, startRow         = arguments.startRow
			, maxRows          = arguments.maxRows
			, orderBy          = arguments.orderBy
			, filter           = arguments.filter
			, filterParams     = arguments.filterParams
		};

		if ( Len( Trim( arguments.property ) ) ) {
			args.fieldName = arguments.property;
		}
		result.records = Duplicate( _getPresideObjectService().getRecordVersions( argumentCollection = args ) );

		// odd looking, just a reversal of the _version_is_draft field that we're aliasing as 'published'
		for( var i=1; i<=result.records.recordCount; i++ ) {
			result.records.published[ i ] = !IsBoolean( result.records.published[ i ] ) || !result.records.published[ i ];
		}

		if ( arguments.startRow == 1 && result.records.recordCount < arguments.maxRows ) {
			result.totalRecords = result.records.recordCount;
		} else {
			args = {
				  objectName   = arguments.objectName
				, id           = arguments.recordId
				, selectFields = [ "count( * ) as nRows" ]
			};
			if ( Len( Trim( arguments.property ) ) ) {
				args.fieldName = arguments.property;
			}

			result.totalRecords = _getPresideObjectService().getRecordVersions( argumentCollection = args ).nRows;
		}

		return result;
	}

	public boolean function batchEditField(
		  required string objectName
		, required string fieldName
		, required array  sourceIds
		, required string value
		,          string multiEditBehaviour = "append"
	) {
		var pobjService  = _getPresideObjectService();
		var isMultiValue = pobjService.isManyToManyProperty( arguments.objectName, arguments.fieldName );

		transaction {
			for( var sourceId in sourceIds ) {
				if ( !isMultiValue ) {
					pobjService.updateData(
						  objectName = objectName
						, data       = { "#arguments.fieldName#" = value }
						, filter     = { id=sourceId }
					);
				} else {
					var existingIds  = [];
					var targetIdList = [];
					var newChoices   = ListToArray( arguments.value );

					if ( arguments.multiEditBehaviour != "overwrite" ) {
						var previousData = pobjService.getDeNormalizedManyToManyData(
							  objectName   = objectName
							, id           = sourceId
							, selectFields = [ arguments.fieldName ]
						);
						existingIds = ListToArray( previousData[ arguments.fieldName ] ?: "" );
					}

					switch( arguments.multiEditBehaviour ) {
						case "overwrite":
							targetIdList = newChoices;
							break;
						case "delete":
							targetIdList = existingIds;
							for( var id in newChoices ) {
								targetIdList.delete( id )
							}
							break;
						default:
							targetIdList = existingIds;
							targetIdList.append( newChoices, true );
					}

					targetIdList = targetIdList.toList();
					targetIdList = ListRemoveDuplicates( targetIdList );

					pobjService.syncManyToManyData(
						  sourceObject   = objectName
						, sourceProperty = updateField
						, sourceId       = sourceId
						, targetIdList   = targetIdList
					);
				}

				$audit(
					  action   = "datamanager_batch_edit_record"
					, type     = "datamanager"
					, recordId = sourceid
					, detail   = Duplicate( arguments )
				);
			}
		}

		return true;
	}


	public array function getRecordsForAjaxSelect(
		  required string  objectName
		,          array   ids          = []
		,          array   selectFields = []
		,          array   savedFilters = []
		,          array   extraFilters = []
		,          string  searchQuery  = ""
		,          numeric maxRows      = 1000
		,          string  orderBy      = "label asc"
	) {
		var result = [];
		var records = "";
		var args   = {
			  objectName   = arguments.objectName
			, selectFields = arguments.selectFields
			, savedFilters = arguments.savedFilters
			, extraFilters = arguments.extraFilters
			, maxRows      = arguments.maxRows
			, orderBy      = arguments.orderBy
		};
		var transormResult = function( required struct result ) {
			result.text = result.label;
			result.value = result.id;
			result.delete( "label" );
			result.delete( "id" );

			return result;
		};
		var labelField         = _getPresideOBjectService().getObjectAttribute( arguments.objectName, "labelField", "label" );
		var replacedLabelField = !Find( ".", labelField ) ? "#arguments.objectName#.${labelfield} as label" : "${labelfield} as label";

		args.selectFields.delete( labelField );
		args.selectFields.append( replacedLabelField );
		args.selectFields.delete( "id" );
		args.selectFields.append( "#arguments.objectName#.id" );


		if ( arguments.ids.len() ) {
			args.filter = { id = arguments.ids };
		} elseif ( Len( Trim( arguments.searchQuery ) ) ) {
			args.filter       = _buildSearchFilter( arguments.searchQuery, arguments.objectName, arguments.selectFields );
			args.filterParams = { q = { type="varchar", value="%" & arguments.searchQuery & "%" } };
		}

		records = _getPresideObjectService().selectData( argumentCollection = args );
		if ( arguments.ids.len() ) {
			var tmp = {};
			for( var r in records ) { tmp[ r.id ] = transormResult( r ) };
			for( var id in arguments.ids ){
				if ( tmp.keyExists( id ) ) {
					result.append( tmp[id] );
				}
			}
		} else {
			for( var r in records ) { result.append( transormResult( r ) ); }
		}

		return result;
	}

	public string function getPrefetchCachebusterForAjaxSelect( required string  objectName ) {
		var records = _getPresideObjectService().getObject( arguments.objectName ).selectData(
			selectFields = [ "Max( datemodified ) as lastmodified" ]
		);

		return IsDate( records.lastmodified ) ? Hash( records.lastmodified ) : Hash( Now() );
	}

	public boolean function areDraftsEnabledForObject( required string objectName ) {
		var poService = _getPresideObjectService();

		if ( !poService.objectIsVersioned( arguments.objectName ) ) {
			return false;
		}

		var draftsEnabled = poService.getObjectAttribute(
			  objectName    = arguments.objectName
			, attributeName = "datamanagerAllowDrafts"
			, defaultValue  = ""
		);

		return IsBoolean( draftsEnabled ) && draftsEnabled;
	}

// PRIVATE HELPERS
	private array function _prepareGridFieldsForSqlSelect( required array gridFields, required string objectName, boolean versionTable=false ) {
		var sqlFields                = Duplicate( arguments.gridFields );
		var field                    = "";
		var i                        = "";
		var props                    = _getPresideObjectService().getObjectProperties( arguments.objectName );
		var prop                     = "";
		var objName                  = arguments.versionTable ? "vrsn_" & arguments.objectName : arguments.objectName;
		var labelField               = _getPresideObjectService().getObjectAttribute( objName, "labelField", "label" );
		var labelFieldIsRelationship = ( props[ labelField ].relationship ?: "" ) contains "-to-";
		var replacedLabelField       = !Find( ".", labelField ) ? "#objName#.${labelfield} as #ListLast( labelField, '.' )#" : "${labelfield} as #labelField#";

		sqlFields.delete( "id" );
		sqlFields.append( "#objName#.id" );
		if ( !labelFieldIsRelationship && sqlFields.find( labelField ) ) {
			sqlFields.delete( labelField );
			sqlFields.append( replacedLabelField );
		}

		if ( areDraftsEnabledForObject( arguments.objectName ) ) {
			sqlFields.append( "_version_has_drafts" );
			sqlFields.append( "_version_is_draft"   );
		}

		// ensure all fields are valid + get labels from join tables
		for( i=ArrayLen( sqlFields ); i gt 0; i-- ){
			field = sqlFields[i];
			if ( field == "#objName#.id" || field == replacedLabelField ) {
				continue;
			}
			if ( not StructKeyExists( props, field ) ) {
				if ( arguments.versiontable && field.startsWith( "_version_" ) ) {
					sqlFields[i] = objName & "." & field;
				} else {
					sqlFields[i] = "'' as " & field;
				}
				continue;
			}

			prop = props[ field ];

			switch( prop.relationship ?: "none" ) {
				case "one-to-many":
				case "many-to-many":
					sqlFields[i] = "'' as " & field;
				break;

				case "many-to-one":
					sqlFields[i] = ( prop.name ?: "" ) & ".${labelfield} as " & field;
				break;

				default:
					sqlFields[i] = objName & "." & field;
			}

			if ( arguments.versionTable ) {
				sqlFields.append( objName & "._version_number" );
			}
		}
		return sqlFields;
	}

	private string function _buildSearchFilter( required string q, required string objectName, required array gridFields ) {
		var field  = "";
		var filter = "";
		var delim  = "";

		for( field in arguments.gridFields ){
			field = ListFirst( field, " " );
			var objName = arguments.objectName;
			if ( ListLen( field, "." ) == 2 ) {
				objName = ListFirst( field, "." );
				field = ListLast( field, "." );
			}
			if ( _propertyIsSearchable( field, objName ) ) {
				filter &= delim & _getFullFieldName( field, objName ) & " like :q";
				delim = " or ";
			}
		}

		return filter;
	}

	private string function _getFullFieldName( required string field, required string objectName ) {
		var poService = "";
		var fieldName = arguments.field;
		var objName   = arguments.objectName;

		if ( fieldName contains "${labelfield}" ) {
			fieldName = _getPresideObjectService().getObjectAttribute( arguments.objectName, "labelfield", "label" );
			if ( ListLen( fieldName, "." ) == 2 ) {
				objName = ListFirst( fieldName, "." );
				fieldName = ListLast( fieldName, "." );
			}

			return objName & "." & fieldName;
		}

		var prop = _getPresideObjectService().getObjectProperty( objectName=objName, propertyName=fieldName );
		var relatedTo = prop.relatedTo ?: "none";

		if(  Len( Trim( relatedTo ) ) and relatedTo neq "none" ) {
			var objectLabelField = _getPresideObjectService().getObjectAttribute( relatedTo, "labelfield", "label" );

			if( Find( ".", objectLabelField ) ){
				return arguments.field & "$" & objectLabelField;
			} else{
				return arguments.field & "." & objectLabelField;
			}
		}

		return objName & "." & fieldName;
	}

	private string function _propertyIsSearchable( required string field, required string objectName ) {
		if ( ListFindNoCase( "#arguments.objectName#.id,datecreated,datemodified", field ) ){
			return false;
		}

		if ( FindNoCase( "${labelfield}", arguments.field ) ) {
			return true;
		}

		var prop = _getPresideObjectService().getObjectProperty( objectName=arguments.objectName, propertyName=arguments.field );

		return ( prop.type ?: "" ) == "string";
	}

// GETTERS AND SETTERS
	private any function _getPresideObjectService() {
		return _presideObjectService;
	}
	private void function _setPresideObjectService( required any presideObjectService ) {
		_presideObjectService = arguments.presideObjectService;
	}

	private any function _getContentRenderer() {
		return _contentRenderer;
	}
	private void function _setContentRenderer( required any contentRenderer ) {
		_contentRenderer = arguments.contentRenderer;
	}

	private any function _getI18nPlugin() {
		return _i18nPlugin;
	}
	private void function _setI18nPlugin( required any i18nPlugin ) {
		_i18nPlugin = arguments.i18nPlugin;
	}

	private any function _getPermissionService() {
		return _permissionService;
	}
	private void function _setPermissionService( required any permissionService ) {
		_permissionService = arguments.permissionService;
	}

	private any function _getSiteService() {
		return _siteService;
	}
	private void function _setSiteService( required any siteService ) {
		_siteService = arguments.siteService;
	}

}