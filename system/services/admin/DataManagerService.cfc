component output="false" singleton=true {

// CONSTRUCTOR

	/**
	 * @presideObjectService.inject PresideObjectService
	 * @contentRenderer.inject      ContentRendererService
	 * @i18nPlugin.inject           coldbox:plugin:i18n
	 * @permissionService.inject    PermissionService
	 * @siteService.inject          SiteService
	 */
	public any function init( required any presideObjectService, required any contentRenderer, required any i18nPlugin, required any permissionService, required any siteService ) output=false {
		_setPresideObjectService( arguments.presideObjectService );
		_setContentRenderer( arguments.contentRenderer );
		_setI18nPlugin( arguments.i18nPlugin );
		_setPermissionService( arguments.permissionService );
		_setSiteService( arguments.siteService );

		return this;
	}

// PUBLIC METHODS
	public array function getGroupedObjects() output=false {
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

	public boolean function isObjectAvailableInDataManager( required string objectName ) output=false {
		var groupId = _getPresideObjectService().getObjectAttribute( objectName=arguments.objectName, attributeName="datamanagerGroup", defaultValue="" );

		return Len( Trim( groupId ) );
	}

	public array function listGridFields( required string objectName ) output=false {
		var fields = _getPresideObjectService().getObjectAttribute(
			  objectName    = arguments.objectName
			, attributeName = "datamanagerGridFields"
			, defaultValue  = "label,datecreated,datemodified"
		);

		return ListToArray( fields );
	}

	public boolean function isOperationAllowed( required string objectName, required string operation ) output=false {
		var operations = _getPresideObjectService().getObjectAttribute(
			  objectName    = arguments.objectName
			, attributeName = "datamanagerAllowedOperations"
			, defaultValue  = "add,edit,delete,viewversions"
		);

		return operations != "none" && ListFindNoCase( operations, arguments.operation );
	}

	public struct function getRecordsForGridListing(

		  required string  objectName
		, required array   gridFields
		,          numeric startRow    = 1
		,          numeric maxRows     = 10
		,          string  orderBy     = ""
		,          string  searchQuery = ""

	) output=false {

		var result = { totalRecords = 0, records = "" };
		var args   = {
			  objectName       = arguments.objectName
			, selectFields     = _prepareGridFieldsForSqlSelect( arguments.gridFields, arguments.objectName )
			, startRow         = arguments.startRow
			, maxRows          = arguments.maxRows
			, orderBy          = arguments.orderBy
		};

		if ( Len( Trim( arguments.searchQuery ) ) ) {
			args.filter       = _buildSearchFilter( arguments.searchQuery, arguments.objectName, arguments.gridFields );
			args.filterParams = { q = { type="varchar", value="%" & arguments.searchQuery & "%" } };
		}

		result.records = _getPresideObjectService().selectData( argumentCollection = args );

		if ( arguments.startRow eq 1 and result.records.recordCount lt arguments.maxRows ) {
			result.totalRecords = result.records.recordCount;
		} else {
			result.totalRecords = _getPresideObjectService().selectData(
				  objectName       = arguments.objectName
				, selectFields     = [ "count( * ) as nRows" ]
			).nRows;
		}

		return result;
	}

	public struct function getRecordHistoryForGridListing(
		  required string  objectName
		, required string  recordId
		, required array   gridFields
		,          string  property    = ""
		,          numeric startRow    = 1
		,          numeric maxRows     = 10
		,          string  orderBy     = ""
	) output=false {
		var result = { totalRecords = 0, records = "" };
		var args   = {
			  objectName       = arguments.objectName
			, id               = arguments.recordId
			, selectFields     = _prepareGridFieldsForSqlSelect( arguments.gridFields, arguments.objectName, true )
			, startRow         = arguments.startRow
			, maxRows          = arguments.maxRows
			, orderBy          = arguments.orderBy
		};

		if ( Len( Trim( arguments.property ) ) ) {
			args.fieldName = arguments.property;
		}

		result.records = _getPresideObjectService().getRecordVersions( argumentCollection = args );

		if ( arguments.startRow eq 1 and result.records.recordCount lt arguments.maxRows ) {
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

	public array function getRecordsForAjaxSelect(
		  required string  objectName
		,          array   ids          = []
		,          array   selectFields = [ "id", "label" ]
		,          array   savedFilters = []
		,          string  searchQuery  = ""
		,          numeric maxRows      = 1000
		,          string  orderBy      = "label asc"
	) output=false {
		var result = [];
		var records = "";
		var args   = {
			  objectName   = arguments.objectName
			, selectFields = arguments.selectFields
			, savedFilters = arguments.savedFilters
			, maxRows      = arguments.maxRows
			, orderBy      = arguments.orderBy
		};
		var transormResult = function( required struct result ) output=false {
			result.text = result.label;
			result.value = result.id;
			result.delete( "label" );
			result.delete( "id" );

			return result;
		};
		var labelField = _getPresideOBjectService().getObjectAttribute( arguments.objectName, "labelField", "label" );
		    labelField = !Find( ".", labelField ) ? "#arguments.objectName#.${labelfield} as label" : "${labelfield} as label";

		args.selectFields.delete( "label" );
		args.selectFields.append( labelField );
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

	public string function getPrefetchCachebusterForAjaxSelect( required string  objectName ) output=false {
		var records = _getPresideObjectService().getObject( arguments.objectName ).selectData(
			selectFields = [ "Max( datemodified ) as lastmodified" ]
		);

		return IsDate( records.lastmodified ) ? Hash( records.lastmodified ) : Hash( Now() );
	}

// PRIVATE HELPERS
	private array function _prepareGridFieldsForSqlSelect( required array gridFields, required string objectName, boolean versionTable=false ) output=false {
		var sqlFields    = Duplicate( arguments.gridFields );
		var field        = "";
		var i            = "";
		var props        = _getPresideObjectService().getObjectProperties( arguments.objectName );
		var prop         = "";
		var objName      = arguments.versionTable ? "vrsn_" & arguments.objectName : arguments.objectName;

		sqlFields.delete( "id" );
		sqlFields.delete( "label" );
		sqlFields.append( "#objName#.id" );
		sqlFields.append( "#objName#.${labelfield} as label" );

		// ensure all fields are valid + get labels from join tables
		for( i=ArrayLen( sqlFields ); i gt 0; i-- ){
			field = sqlFields[i];
			if ( field == "#objName#.id" || field == "#objName#.${labelfield} as label" ) {
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

			switch( prop.getAttribute( "relationship", "none" ) ) {
				case "one-to-many":
				case "many-to-many":
					sqlFields[i] = "'' as " & field;
				break;

				case "many-to-one":
					sqlFields[i] = prop.getAttribute( "name", "" ) & ".${labelfield} as " & field;
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

	private string function _buildSearchFilter( required string q, required string objectName, required array gridFields ) output=false {
		var field  = "";
		var filter = "";
		var delim  = "";

		for( field in arguments.gridFields ){
			field = ListFirst( field, " " );
			if ( _propertyIsSearchable( field, arguments.objectName ) ) {
				filter &= delim & _getFullFieldName( field, arguments.objectName ) & " like :q";
				delim = " or ";
			}
		}

		return filter;
	}

	private string function _getFullFieldName( required string field, required string objectName ) output=false {
		var poService = "";
		var fieldName = ( arguments.field == "#arguments.objectName#.${labelfield}" ) ? _getPresideObjectService().getObjectAttribute( arguments.objectName, "labelfield", "label" ) : arguments.field;
		var prop = _getPresideObjectService().getObjectProperty( objectName=arguments.objectName, propertyName=fieldName );
		var relatedTo = prop.getAttribute( "relatedTo", "none" );

		if(  Len( Trim( relatedTo ) ) and relatedTo neq "none" ) {
			return relatedTo & "." & _getPresideObjectService().getObjectAttribute( relatedTo, "labelfield", "label" );
		}

		return arguments.objectName & "." & fieldName;
	}

	private string function _propertyIsSearchable( required string field, required string objectName ) output=false {
		if ( ListFindNoCase( "#arguments.objectName#.id,datecreated,datemodified", field ) ){
			return false;
		}

		if ( FindNoCase( "${labelfield}", arguments.field ) ) {
			return true;
		}

		var prop      = _getPresideObjectService().getObjectProperty( objectName=arguments.objectName, propertyName=arguments.field );
		var type      = prop.getAttribute( "type", "" );
		var maxLength = Val( prop.getAttribute( "maxLength", "" ) );

		return type eq "string" and maxLength and maxLength lt 4000; // 4000, really?
	}

// GETTERS AND SETTERS
	private any function _getPresideObjectService() output=false {
		return _presideObjectService;
	}
	private void function _setPresideObjectService( required any presideObjectService ) output=false {
		_presideObjectService = arguments.presideObjectService;
	}

	private any function _getContentRenderer() output=false {
		return _contentRenderer;
	}
	private void function _setContentRenderer( required any contentRenderer ) output=false {
		_contentRenderer = arguments.contentRenderer;
	}

	private any function _getI18nPlugin() output=false {
		return _i18nPlugin;
	}
	private void function _setI18nPlugin( required any i18nPlugin ) output=false {
		_i18nPlugin = arguments.i18nPlugin;
	}

	private any function _getPermissionService() output=false {
		return _permissionService;
	}
	private void function _setPermissionService( required any permissionService ) output=false {
		_permissionService = arguments.permissionService;
	}

	private any function _getSiteService() output=false {
		return _siteService;
	}
	private void function _setSiteService( required any siteService ) output=false {
		_siteService = arguments.siteService;
	}

}