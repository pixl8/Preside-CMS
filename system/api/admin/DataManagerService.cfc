component output="false" extends="preside.system.base.Service" {

// CONSTRUCTOR
	public any function init( required any contentRenderer, required any i18nPlugin, required any permissionService ) output=false {
		super.init( argumentCollection = arguments );

		_setContentRenderer( arguments.contentRenderer );
		_setI18nPlugin( arguments.i18nPlugin );
		_setPermissionService( arguments.permissionService );

		return this;
	}

// PUBLIC METHODS
	public array function getGroupedObjects() output=false {
		var poService      = _getPresideObjectService();
		var permsService   = _getPermissionService();
		var i18nPlugin     = _getI18nPlugin();
		var objectNames    = poService.listObjects();
		var groups         = {};
		var groupedObjects = [];

		for( var objectName in objectNames ){
			var groupId = poService.getObjectAttribute( objectName=objectName, attributeName="datamanagerGroup", defaultValue="" );
			if ( Len( Trim( groupId ) ) && permsService.hasPermission( permissionKey="datamanager.navigate", context="datamanager", contextKeys=[ objectName ] ) ) {
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
				, fromVersionTable = true
			).nRows;
		}

		return result;
	}

	public array function getRecordsForAjaxSelect(
		  required string  objectName
		,          array   ids          = []
		,          array   selectFields = [ "id", "label" ]
		,          string  searchQuery  = ""
		,          numeric maxRows      = 1000
		,          string  orderBy      = "label asc"
	) output=false {
		var result = [];
		var records = "";
		var args   = {
			  objectName       = arguments.objectName
			, selectFields     = arguments.selectFields
			, maxRows          = arguments.maxRows
			, orderBy          = arguments.orderBy
		};
		var transormResult = function( required struct result ) output=false {
			result.text = result.label;
			result.value = result.id;
			result.delete( "label" );
			result.delete( "id" );

			return result;
		};

		if ( !args.selectFields.findNoCase( "id" ) ) {
			args.selectFields.append( "id" );
		}
		if ( !args.selectFields.findNoCase( "label" ) ) {
			args.selectFields.append( "label" );
		}

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
		var records = getPresideObject( arguments.objectName ).selectData(
			selectFields = [ "Max( datemodified ) as lastmodified" ]
		);

		return records.recordCount ? Hash( records.lastmodified ) : Hash( Now() );
	}

// PRIVATE HELPERS
	private array function _prepareGridFieldsForSqlSelect( required array gridFields, required string objectName ) output=false {
		var sqlFields    = Duplicate( arguments.gridFields );
		var field        = "";
		var i            = "";
		var props        = _getPresideObjectService().getObjectProperties( arguments.objectName );
		var prop         = "";

		if ( not sqlFields.find( "id" ) ) {
			sqlFields.append( "id" );
		}
		if ( not sqlFields.find( "label" ) ) {
			sqlFields.append( "label" );
		}

		// ensure all fields are valid + get labels from join tables
		for( i=ArrayLen( sqlFields ); i gt 0; i-- ){
			field = sqlFields[i];
			if ( not StructKeyExists( props, field ) ) {
				sqlFields[i] = "'' as " & field;
				continue;
			}

			prop = props[ field ];

			switch( prop.getAttribute( "relationship", "none" ) ) {
				case "one-to-many":
				case "many-to-many":
					sqlFields[i] = "'' as " & field;
				break;

				case "many-to-one":
					sqlFields[i] = prop.getAttribute( "relatedTo", "" ) & ".label as " & field;
				break;

				default:
					sqlFields[i] = arguments.objectName & "." & field;
			}
		}

		return sqlFields;
	}

	private string function _buildSearchFilter( required string q, required string objectName, required array gridFields ) output=false {
		var field  = "";
		var filter = "";
		var delim  = "";

		for( field in arguments.gridFields ){
			if ( _propertyIsSearchable( field, arguments.objectName ) ) {
				filter &= delim & _getFullFieldName( field, arguments.objectName ) & " like :q";
				delim = " or ";
			}
		}

		return filter;
	}

	private string function _getFullFieldName( required string field, required string objectName ) output=false {
		var prop = _getPresideObjectService().getObjectProperty( objectName=arguments.objectName, propertyName=arguments.field );
		var relatedTo = prop.getAttribute( "relatedTo", "none" );

		if(  Len( Trim( relatedTo ) ) and relatedTo neq "none" ) {
			return relatedTo & ".label";
		}

		return arguments.objectName & "." & arguments.field;
	}

	private string function _propertyIsSearchable( required string field, required string objectName ) output=false {
		if ( ListFindNoCase( "id,datecreated,datemodified", field ) ){
			return false;
		}

		var prop      = _getPresideObjectService().getObjectProperty( objectName=arguments.objectName, propertyName=arguments.field );
		var type      = prop.getAttribute( "type", "" );
		var maxLength = Val( prop.getAttribute( "maxLength", "" ) );

		return type eq "string" and maxLength and maxLength lt 4000; // 4000, really?
	}

// GETTERS AND SETTERS
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

}