/**
 * Service to provide business logic for the [[datamanager]].
 *
 * @singleton
 * @presideservice
 * @autodoc
 */
component {

	variables._operationsCache = {};

// CONSTRUCTOR

	/**
	 * @presideObjectService.inject PresideObjectService
	 * @contentRenderer.inject      ContentRendererService
	 * @labelRendererService.inject LabelRendererService
	 * @i18nPlugin.inject           i18n
	 * @permissionService.inject    PermissionService
	 * @siteService.inject          SiteService
	 * @relationshipGuidance.inject relationshipGuidance
	 * @customizationService.inject datamanagerCustomizationService
	 * @cloningService.inject       presideObjectCloningService
	 * @multilingualService.inject  multilingualPresideObjectService
	 */
	public any function init(
		  required any presideObjectService
		, required any contentRenderer
		, required any labelRendererService
		, required any i18nPlugin
		, required any permissionService
		, required any siteService
		, required any relationshipGuidance
		, required any customizationService
		, required any cloningService
		, required any multilingualService
	) {
		_setPresideObjectService( arguments.presideObjectService );
		_setContentRenderer( arguments.contentRenderer );
		_setLabelRendererService( arguments.labelRendererService );
		_setI18nPlugin( arguments.i18nPlugin );
		_setPermissionService( arguments.permissionService );
		_setSiteService( arguments.siteService );
		_setRelationshipGuidance( arguments.relationshipGuidance );
		_setCustomizationService( arguments.customizationService );
		_setCloningService( arguments.cloningService );
		_setMultilingualService( arguments.multilingualService );

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
					  id        = objectName
					, title     = i18nPlugin.translateResource( uri="preside-objects.#objectName#:title" )
					, iconClass = i18nPlugin.translateResource( uri="preside-objects.#objectName#:iconClass", defaultValue="fa-database" )
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
		if ( objectIsIndexedInDatamanagerUi( arguments.objectName ) ) {
			return true;
		}

		var datamanagerEnabled = _getPresideObjectService().getObjectAttribute( objectName=arguments.objectName, attributeName="datamanagerEnabled", defaultValue="" );

		return IsBoolean( datamanagerEnabled ) && datamanagerEnabled;
	}

	public boolean function objectIsIndexedInDatamanagerUi( required string objectName ) {
		var groupId = _getPresideObjectService().getObjectAttribute( objectName=arguments.objectName, attributeName="datamanagerGroup", defaultValue="" );

		return Len( Trim( groupId ) ) > 0;
	}

	public array function listGridFields( required string objectName ) {
		var fields = _getPresideObjectService().getObjectAttribute(
			  objectName    = arguments.objectName
			, attributeName = "datamanagerGridFields"
			, defaultValue  = arrayToList( defaultGridFields( arguments.objectName ) )
		);

		return ListToArray( fields, ", " );
	}

	public array function defaultGridFields( required string objectName ) {
		var labelfield     = _getPresideObjectService().getObjectAttribute(
			  objectName    = arguments.objectName
			, attributeName = "labelfield"
			, defaultValue  = "label"
		);
		var noDateCreated  = _getPresideObjectService().getObjectAttribute(
			  objectName    = arguments.objectName
			, attributeName = "noDateCreated"
		);
		var noDateModified = _getPresideObjectService().getObjectAttribute(
			  objectName    = arguments.objectName
			, attributeName = "noDateModified"
		);
		var fields     = [ labelfield ];

		if ( !noDateCreated ) {
			fields.append( "datecreated" );
		}
		if ( !noDateModified ) {
			fields.append( "datemodified" );
		}

		return fields;
	}

	public array function listHiddenGridFields( required string objectName ) {
		var fields = _getPresideObjectService().getObjectAttribute(
			  objectName    = arguments.objectName
			, attributeName = "datamanagerHiddenGridFields"
		);

		return ListToArray( fields );
	}

	public array function listSearchFields( required string objectName ) {
		var fields = _getPresideObjectService().getObjectAttribute(
			  objectName    = arguments.objectName
			, attributeName = "datamanagerSearchFields"
		);

		return ListToArray( fields );
	}

	public array function listBatchEditableFields( required string objectName ) {
		if ( !isOperationAllowed( arguments.objectName, "edit" ) ) {
			return [];
		}

		var fields               = [];
		var propertyNames        = _getPresideObjectService().getObjectAttribute( objectName=objectName, attributeName="propertyNames" );
		var props                = _getPresideObjectService().getObjectProperties( objectName );
		var dao                  = _getPresideObjectService().getObject( objectName );
		var forbiddenFields      = [ dao.getIdField(), dao.getLabelField(), dao.getDateCreatedField(), dao.getDateModifiedField() ];
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
			if ( Len( Trim( attributes.formula ?: "" ) ) ) {
				return false;
			}
			if ( propertyName.reFind( "^_" ) ) {
				return false;
			}
			if ( IsBoolean( attributes.batcheditable ?: "" ) && !attributes.batcheditable ) {
				return false;
			}

			return true;
		}

		for( var propertyName in propertyNames ) {
			if ( isFieldBatchEditable( propertyName, props[ propertyName ] ) ) {
       		 	ArrayAppend( fields, propertyName );
			}
		}

		return fields;
	}

	public boolean function isOperationAllowed( required string objectName, required string operation ) {
		if ( _getCustomizationService().objectHasCustomization( arguments.objectName, "isOperationAllowed" ) ) {
			var result = _getCustomizationService().runCustomization(
				  objectName = arguments.objectName
				, action     = "isOperationAllowed"
				, args       = arguments
			);

			return IsBoolean( result ?: "" ) && result;
		}

		return getAllowedOperationsForObject( arguments.objectName ).findNoCase( arguments.operation );
	}

	public array function getAllowedOperationsForObject( required string objectName ) {
		if ( !StructKeyExists( _operationsCache, arguments.objectName ) ) {
			var operations           = _getPresideObjectService().getObjectAttribute( attributeName="datamanagerAllowedOperations"   , objectName=arguments.objectName, defaultValue=getDefaultOperationsForObject( arguments.objectName ) );
			var disallowedOperations = _getPresideObjectService().getObjectAttribute( attributeName="datamanagerDisallowedOperations", objectName=arguments.objectName, defaultValue=""                                                    );

			operations           = ListToArray( operations.reReplaceNoCase( "\bview\b", "read" ) );
			disallowedOperations = ListToArray( disallowedOperations );

			for( var disallowedOp in disallowedOperations ) {
				var index = operations.findNoCase( disallowedOp );
				if ( index ) { operations.deleteAt( index ); }
			}

			_operationsCache[ arguments.objectName ] = operations;
		}

		return _operationsCache[ arguments.objectName ];
	}

	public string function getDefaultOperationsForObject( required string objectName ) {
		var defaults = [ "read", "add", "edit", "delete" ];

		if ( _getPresideObjectService().objectIsVersioned( arguments.objectName ) ) {
			defaults.append( "viewversions" );
		}
		if ( _getCloningService().isCloneable( arguments.objectName ) ) {
			defaults.append( "clone" );
		}
		if ( _getMultilingualService().isMultilingual( arguments.objectName ) ) {
			defaults.append( "translate" );
		}

		return defaults.toList();
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

	public boolean function usesTreeView( required string objectName ) {
		var treeView = _getPresideObjectService().getObjectAttribute(
			  objectName    = arguments.objectName
			, attributeName = "datamanagerTreeView"
		);

		return IsBoolean( treeView ) && treeView;
	}

	public string function getTreeParentProperty( required string objectName ) {
		return _getPresideObjectService().getObjectAttribute(
			  objectName    = arguments.objectName
			, attributeName = "datamanagerTreeParentProperty"
			, defaultValue  = "parent"
		);
	}

	public string function getTreeFirstLevelParentProperty( required string objectName ) {
		return _getPresideObjectService().getObjectAttribute(
			  objectName    = arguments.objectName
			, attributeName = "datamanagerTreeFirstLevelParentProperty"
			, defaultValue  = ""
		);
	}

	public string function getTreeSortOrder( required string objectName ) {
		return _getPresideObjectService().getObjectAttribute(
			  objectName    = arguments.objectName
			, attributeName = "datamanagerTreeSortOrder"
			, defaultValue  = _getPresideObjectService().getLabelField( arguments.objectName )
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
		var idField        = _getPresideObjectService().getIdField( arguments.objectName );
		var selectDataArgs = StructCopy( arguments );

		selectDataArgs.orderBy      = getSortField( arguments.objectName );
		selectDataArgs.selectFields = [ "#arguments.objectName#.#idField# as id", "${labelfield} as label", selectDataArgs.orderBy ];

		return _getPresideObjectService().selectData( argumentCollection=selectDataArgs );
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

	/**
	 * Gets raw results from the database for the data manager
	 * grid listing. Results are returned as a struct with keys:
	 * `records` (query) and `totalRecords` (numeric count).
	 * \n
	 * Note: any additional arguments passed will be passed on to
	 * the [[presideobjectservice-selectdata]] call.
	 *
	 * @autodoc       true
	 * @objectName    Name of the object whose records we are to get
	 * @gridFields    Array of "grid fields", these will be converted to a selectFields array for the [[presideobjectservice-selectdata]] call
	 * @startRow      For pagination, first row number to fetch
	 * @maxRows       For pagination, maximum number of rows to fetch
	 * @orderBy       Order by string for sorting records
	 * @searchQuery   Optional search query
	 * @filter        Optional filter for the [[presideobjectservice-selectdata]] call
	 * @filterParams  Optional params for the `filter`
	 * @draftsEnabled Whether or not drafts are enabled (if so, the method will additionally fetch the draft status of each record)
	 * @extraFilters  Optional array of extraFilters to send to the [[presideobjectservice-selectdata]] call
	 * @searchFields  Optional array of fields that will be used to search against with the `searchQuery` argument
	 */
	public struct function getRecordsForGridListing(
		  required string  objectName
		, required array   gridFields
		,          numeric startRow       = 1
		,          numeric maxRows        = 10
		,          string  orderBy        = ""
		,          string  searchQuery    = ""
		,          any     filter         = {}
		,          struct  filterParams   = {}
		,          boolean draftsEnabled  = areDraftsEnabledForObject( arguments.objectName )
		,          array   extraFilters   = []
		,          array   searchFields   = listSearchFields( arguments.objectName )
		,          boolean treeView       = false
		,          string  treeViewParent = ""
	) {

		var result = { totalRecords = 0, records = "" };
		var args   = Duplicate( arguments );

		args.selectFields       = _prepareGridFieldsForSqlSelect( gridFields=arguments.gridFields, objectName=arguments.objectName, draftsEnabled=arguments.draftsEnabled );
		args.orderBy            = _prepareOrderByForObject( arguments.objectName, arguments.orderBy );
		args.autoGroupBy        = true;
		args.allowDraftVersions = true;

		args.delete( "gridFields"   );
		args.delete( "searchQuery"  );
		args.delete( "searchFields" );

		if ( Len( Trim( arguments.searchQuery ) ) ) {
			args.extraFilters.append({
				  filter       = buildSearchFilter(
					  q            = arguments.searchQuery
					, objectName   = arguments.objectName
					, gridFields   = arguments.gridFields
					, searchFields = arguments.searchFields
				  )
				, filterParams = { q = { type="varchar", value="%" & arguments.searchQuery & "%" } }
			});
		}

		if ( arguments.treeView ) {
			var parentField  = getTreeParentProperty( arguments.objectName );
			var treeSubQuery = _getPresideObjectService().selectData(
				  objectName          = arguments.objectName
				, selectFields        = [ parentField ]
				, filter              = "#parentField# is not null"
				, getSqlAndParamsOnly = true
			);
			args.extraJoins = args.extraJoins ?: [];
			args.extraJoins.append( {
				  type           = "left"
				, subQuery       = treeSubQuery.sql
				, subQueryAlias  = "childRecords"
				, subQueryColumn = parentField
				, joinToTable    = arguments.objectName
				, joinToColumn   = _getPresideObjectService().getIdField( arguments.objectName )
			} );
			args.extraFilters.append( { filter={ "#parentField#"=arguments.treeViewParent } } );
			args.selectFields.append( "Count( childRecords.#parentField# ) as child_count" );

			args.filterParams = args.filterParams ?: {};
			for( var param in treeSubQuery.params ) {
				args.filterParams[ param.name ] = args.filterParams[ param.name ] ?: param;
			}
		}

		result.records = _getPresideObjectService().selectData( argumentCollection=args );

		if ( arguments.startRow == 1 && result.records.recordCount < arguments.maxRows ) {
			result.totalRecords = result.records.recordCount;
		} else {
			result.totalRecords = _getPresideObjectService().selectData( argumentCollection=args, recordCountOnly=true, maxRows=0 );
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
		var result            = { totalRecords = 0, records = "" };
		var idField           = _getPresideOBjectService().getIdField( arguments.objectName );
		var dateModifiedField = _getPresideOBjectService().getDateModifiedField( arguments.objectName );
		var args    = {
			  objectName       = arguments.objectName
			, id               = arguments.recordId
			, selectFields     = [ "#idField# as id", "_version_is_draft as published", "#dateModifiedField# as datemodified", "_version_author", "_version_changed_fields", "_version_number" ]
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
				  objectName      = arguments.objectName
				, id              = arguments.recordId
				, recordCountOnly = true
			};
			if ( Len( Trim( arguments.property ) ) ) {
				args.fieldName = arguments.property;
			}

			result.totalRecords = _getPresideObjectService().getRecordVersions( argumentCollection = args );
		}

		return result;
	}

	public boolean function batchEditField(
		  required string objectName
		, required string fieldName
		, required array  sourceIds
		, required string value
		,          string multiEditBehaviour = "append"
		,          string auditAction        = "datamanager_batch_edit_record"
		,          string auditCategory      = "datamanager"
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

					pobjService.updateData(
						  objectName              = objectName
						, id                      = sourceId
						, data                    = { "#updateField#" = targetIdList }
						, updateManyToManyRecords = true
					);
				}

				$audit(
					  action   = arguments.auditAction
					, type     = arguments.auditCategory
					, recordId = sourceid
					, detail   = Duplicate( arguments )
				);
			}
		}

		return true;
	}


	public array function getRecordsForAjaxSelect(
		  required string  objectName
		,          array   ids           = []
		,          array   selectFields  = []
		,          array   savedFilters  = []
		,          array   extraFilters  = []
		,          string  searchQuery   = ""
		,          numeric maxRows       = 1000
		,          string  orderBy       = "label"
		,          string  labelRenderer = ""
		,          array   bypassTenants = []
		,          boolean useCache      = false
	) {
		var result = [];
		var records = "";
		var args   = {
			  objectName    = arguments.objectName
			, selectFields  = arguments.selectFields
			, savedFilters  = arguments.savedFilters
			, extraFilters  = arguments.extraFilters
			, bypassTenants = arguments.bypassTenants
			, maxRows       = arguments.maxRows
			, orderBy       = arguments.orderBy
			, autoGroupBy   = true
			, useCache      = arguments.useCache
		};
		var transformResult = function( required struct result, required string labelRenderer ) {
			result.text = replaceList(_getLabelRendererService().renderLabel( labelRenderer, result ), "&lt;,&gt;,&amp;,&quot;", '<,>,&,"');
			result.value = result.id;
			result.delete( "label" );
			result.delete( "id" );

			return result;
		};
		var labelField         = _getPresideOBjectService().getLabelField( arguments.objectName );
		if (args.orderBy is 'label') {
			args.orderBy = labelField;
		}
		var idField            = _getPresideOBjectService().getIdField( arguments.objectName );
		var replacedLabelField = !Find( ".", labelField ) ? "#arguments.objectName#.${labelfield} as label" : "${labelfield} as label";
		if ( len( arguments.labelRenderer ) ) {
			args.selectFields = _getLabelRendererService().getSelectFieldsForLabel( arguments.labelRenderer );
			args.orderBy      = _getLabelRendererService().getOrderByForLabels( arguments.labelRenderer, { orderBy=args.orderBy } );
		} else {
			args.selectFields.delete( labelField );
			args.selectFields.append( replacedLabelField );
			args.selectFields.delete( "id" );
		}
		args.selectFields.append( "#arguments.objectName#.#idField# as id" );

		if ( arguments.ids.len() ) {
			args.filter = { "#idField#" = arguments.ids };
		} else if ( Len( Trim( arguments.searchQuery ) ) ) {
			var searchFields = [ labelField ];
			if ( len( arguments.labelRenderer ) ) {
				searchFields = _getLabelRendererService().getSelectFieldsForLabel( labelRenderer=arguments.labelRenderer, includeAlias=false );
			}
			args.filter       = buildSearchFilter(
				  q            = arguments.searchQuery
				, objectName   = arguments.objectName
				, gridFields   = args.selectFields
				, labelfield   = labelfield
				, searchFields = searchFields
			);
			args.filterParams = { q = { type="varchar", value="%" & arguments.searchQuery & "%" } };
		}

		records = _getPresideObjectService().selectData( argumentCollection = args );

		if ( arguments.ids.len() ) {
			var tmp = {};
			for( var r in records ) { tmp[ r.id ] = transformResult( r, arguments.labelRenderer ) };
			for( var id in arguments.ids ){
				if ( StructKeyExists( tmp, id ) ) {
					result.append( tmp[id] );
				}
			}
		} else {
			for( var r in records ) { result.append( transformResult( r, arguments.labelRenderer ) ); }
		}

		return result;
	}

	public string function getPrefetchCachebusterForAjaxSelect( required string objectName, string labelRenderer="" ) {
		var obj               = _getPresideObjectService().getObject( arguments.objectName );
		var dmField           = obj.getDateModifiedField();
		var lastModified      = Now();
		var rendererCacheDate = _getLabelRendererService().getRendererCacheDate( labelRenderer );

		if ( StructKeyExists( _getPresideObjectService().getObjectProperties( arguments.objectName ), dmField ) ) {
			var records = obj.selectData(
				selectFields = [ "Max( #dmField# ) as lastmodified" ]
			);

			if ( IsDate( records.lastmodified ) ) {
				lastModified = records.lastmodified;
			}
		}

		return Hash( max( lastModified, rendererCacheDate ) );
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

	public struct function superQuickAdd( required string objectName, required string value ) {
		var dao        = _getPresideObjectService().getObject( arguments.objectName );
		var labelField = _getPresideObjectService().getLabelField( arguments.objectName );
		var labelValue = Trim( arguments.value );
		var existing   = dao.selectData(
			  selectFields = [ "id", labelField ]
			, filter       = { "#labelField#"=labelValue }
		);

		if ( existing.recordCount ) {
			return {
				  value = existing.id
				, text  = labelValue
			};
		}

		return {
			  value = dao.insertData( { "#labelField#"=labelValue } )
			, text  = labelValue
		};
	}

	public string function buildSearchFilter(
		  required string q
		, required string objectName
		, required array  gridFields
		,          string labelfield   = _getPresideObjectService().getLabelField( arguments.objectName )
		,          array  searchFields = []
	) {
		var field                = "";
		var fullFieldName        = "";
		var objName              = "";
		var filter               = "";
		var delim                = "";
		var poService            = _getPresideObjectService();
		var relationshipGuidance = _getRelationshipGuidance();

		if ( arguments.searchFields.len() ) {
			var parsedFields = poService.parseSelectFields(
				  objectName   = arguments.objectName
				, selectFields = arguments.searchFields
				, includeAlias = false
			);
			for( field in parsedFields ){
				if ( StructKeyExists( poService.getObjectProperties( arguments.objectName ), field ) ) {
					field = _getFullFieldName( field,  arguments.objectName );
				}
				filter &= delim & field & " like :q";
				delim = " or ";
			}
		} else {
			for( field in arguments.gridFields ){
				field = fullFieldName = ListFirst( field, " " ).replace( "${labelfield}", arguments.labelField, "all" );
				objName = arguments.objectName;

				if ( ListLen( field, "." ) == 2 ) {
					objName = relationshipGuidance.resolveRelationshipPathToTargetObject(
						  sourceObject     = arguments.objectName
						, relationshipPath = ListFirst( field, "." )
					);
					field = ListLast( field, "." );
				}

				if ( poService.objectExists( objName ) && poService.getObjectProperties( objName ).keyExists( field ) ) {
					if ( ListLen( fullFieldName, "." ) < 2 ) {
						fullFieldName = _getFullFieldName( field, objName );
					}

					if ( _propertyIsSearchable( field, objName ) ) {
						filter &= delim & fullFieldName & " like :q";
						delim = " or ";
					}
				}
			}
		}

		return filter;
	}
	
	public boolean function isDataExportEnabled( required string objectName ) {
	
		if ( !$isFeatureEnabled( "dataexport" ) ) {
			return false;
		}

		var exportEnabled = _getPresideObjectService().getObjectAttribute( objectName=arguments.objectName, attributeName="dataManagerExportEnabled", defaultValue=true );

		return IsBoolean( exportEnabled ) && exportEnabled;
	}
	
	public string function getDataExportPermissionKey( required string objectName ) {
		return _getPresideObjectService().getObjectAttribute( objectName=arguments.objectName, attributeName="dataManagerExportPermissionKey", defaultValue="read" );
	}

// PRIVATE HELPERS
	private array function _prepareGridFieldsForSqlSelect( required array gridFields, required string objectName, boolean versionTable=false, boolean draftsEnabled=areDraftsEnabledForObject( arguments.objectName ) ) {
		var sqlFields                = Duplicate( arguments.gridFields );
		var field                    = "";
		var i                        = "";
		var props                    = _getPresideObjectService().getObjectProperties( arguments.objectName );
		var prop                     = "";
		var obj                      = _getPresideObjectService().getObject( arguments.objectName );
		var objName                  = arguments.versionTable ? "vrsn_" & arguments.objectName : arguments.objectName;
		var labelField               = obj.getLabelField();
		var idField                  = obj.getIdField();
		var dateCreatedField         = obj.getDateCreatedField();
		var dateModifiedField        = obj.getDateModifiedField();
		var labelFieldIsRelationship = ( props[ labelField ].relationship ?: "" ) contains "-to-";
		var replacedLabelField       = !Find( ".", labelField ) ? "#objName#.${labelfield} as #ListLast( labelField, '.' )#" : "${labelfield} as #labelField#";

		sqlFields.delete( "id" );
		sqlFields.append( "#objName#.#idField# as id" );
		if ( !labelFieldIsRelationship && ListLen( labelField, "." ) < 2 && sqlFields.find( labelField ) ) {
			sqlFields.delete( labelField );
			sqlFields.append( replacedLabelField );
		}

		if ( dateCreatedField != "datecreated" && sqlFields.findNoCase( "dateCreated" ) ) {
			sqlFields.deleteAt( sqlFields.findNoCase( "datecreated" ) );
			sqlFields.append( "#objName#.#dateCreatedField# as datecreated" );
		}

		if ( dateModifiedField != "dateModified" && sqlFields.findNoCase( "dateModified" ) ) {
			sqlFields.deleteAt( sqlFields.findNoCase( "datemodified" ) );
			sqlFields.append( "#objName#.#dateModifiedField# as datemodified" );
		}

		if ( arguments.draftsEnabled ) {
			sqlFields.append( "_version_has_drafts" );
			sqlFields.append( "_version_is_draft"   );
		}

		// ensure all fields are valid + get labels from join tables
		var ignore = [
			  "#objName#.#idField# as id"
			, "#objName#.#dateCreatedField# as datecreated"
			, "#objName#.#dateModifiedField# as datemodified"
			, replacedLabelField
		];
		for( i=ArrayLen( sqlFields ); i gt 0; i-- ){
			field = sqlFields[i];
			if ( ignore.findNoCase( field ) ) {
				continue;
			}
			if ( !StructKeyExists( props, field ) ) {
				if ( arguments.versiontable && field.reFind( "^_version_" ) ) {
					sqlFields[i] = objName & "." & field;
				} else if ( field != labelField ) {
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

	private string function _prepareOrderByForObject( required string objectName, required string orderBy ) {
		var orderByItems = ListToArray( Trim( arguments.orderBy ) );
		var newOrderBy   = [];

		for( var item in orderByItems ) {
			var orderByField      = ListFirst( item, " " );
			var orderDirection    = ListRest( item, " " );
			var objectProps       = _getPresideObjectService().getObjectProperties( arguments.objectName );
			var fieldRelationship = objectProps[ orderByField ].relationship ?: "";

			if ( fieldRelationship == "many-to-one" ) {
				var relatedLabelField       = _getFullFieldName( "${labelfield}", _getPresideObjectService().getObjectProperties( arguments.objectName )["#orderByField#"].relatedTo );
				var foreignObject           = _getPresideObjectService().getObjectProperties( objectProps[ orderByField ].relatedTo );
				var foreignObjectLabelField = _getPresideObjectService().getLabelField(       objectProps[ orderByField ].relatedTo );

				if ( !structKeyExists( foreignObject[ foreignObjectLabelField ], "formula" ) ) {
					var delim = relatedLabelField.find( "$" ) ? "$" : ".";

					relatedLabelField = orderByField & delim & ListRest( relatedLabelField, delim );
				}

				newOrderBy.append( relatedLabelField & " " & orderDirection );
			} else {
				newOrderBy.append( item );
			}
		}

		return newOrderBy.toList();
	}

	private string function _getFullFieldName( required string field, required string objectName ) {
		var poService = _getPresideObjectService();
		var fieldName = arguments.field;
		var objName   = arguments.objectName;
		var fullName  = "";

		if ( fieldName contains "${labelfield}" ) {
			fieldName = poService.getObjectAttribute( arguments.objectName, "labelfield", "label" );
			if ( ListLen( fieldName, "." ) == 2 ) {
				objName = ListFirst( fieldName, "." );
				fieldName = ListLast( fieldName, "." );
			}

			fullName = objName & "." & fieldName;
		} else {
			var prop = poService.getObjectProperty( objectName=objName, propertyName=fieldName );
			var relatedTo = prop.relatedTo ?: "none";

			if(  Len( Trim( relatedTo ) ) && relatedTo != "none" ) {
				var objectLabelField = poService.getObjectAttribute( relatedTo, "labelfield", "label" );

				if( Find( ".", objectLabelField ) ){
					fullName = arguments.field & "$" & objectLabelField;
				} else{
					fullName = arguments.field & "." & objectLabelField;
				}
			} else {
				fullName = objName & "." & fieldName;
			}
		}

		return poService.expandFormulaFields(
			  objectName   = objName
			, expression   = fullName
			, includeAlias = false
		);
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

	private any function _getLabelRendererService() {
		return _labelRendererService;
	}
	private void function _setLabelRendererService( required any labelRendererService ) {
		_labelRendererService = arguments.labelRendererService;
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

	private any function _getRelationshipGuidance() {
		return _RelationshipGuidance;
	}
	private void function _setRelationshipGuidance( required any RelationshipGuidance ) {
		_RelationshipGuidance = arguments.RelationshipGuidance;
	}

	private any function _getCustomizationService() {
		return _customizationService;
	}
	private void function _setCustomizationService( required any customizationService ) {
		_customizationService = arguments.customizationService;
	}

	private any function _getCloningService() {
		return _cloningService;
	}
	private void function _setCloningService( required any cloningService ) {
		_cloningService = arguments.cloningService;
	}

	private any function _getMultilingualService() {
		return _multilingualService;
	}
	private void function _setMultilingualService( required any multilingualService ) {
		_multilingualService = arguments.multilingualService;
	}

}
