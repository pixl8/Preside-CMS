component extends="tests.resources.HelperObjects.PresideBddTestCase" {

	function run() {
		describe( "buildVirtualObjectMeta()", function(){
			it( "should clone the shared record table and keep the label when records have one", function(){
				var meta = _getService().buildVirtualObjectMeta( _definition(), _prototype() );

				expect( meta.dbsync ).toBeFalse();
				expect( meta.tableName ).toBe( "psys_custom_object_record" );
				expect( meta.customFieldsEnabled ).toBeTrue();
				expect( meta.datamanagerEnabled ).toBeTrue();
				expect( meta.versioned ).toBeFalse();
				expect( meta.feature ).toBe( "customObjects" );
				expect( meta.customObject ).toBe( "definition-1" );
				expect( meta.customObjectKey ).toBe( "widget" );
				expect( meta.name ).toBe( "cobj_widget" );
				expect( meta.labelfield ).toBe( "label" );
				expect( meta.noLabel ).toBeFalse();
				expect( StructKeyExists( meta.properties, "label" ) ).toBeTrue();
				expect( meta.properties.label.required ).toBeTrue();
				expect( meta.properties.custom_object.control ).toBe( "none" );
				expect( meta.properties.custom_object.excludeDataExport ).toBeTrue();
				expect( meta.properties.custom_object.autofilter ).toBeFalse();
				expect( meta.datamanagerGroup ).toBe( "cobj_stores" );
			} );

			it( "should drop the label when the definition says records have none", function(){
				var definition = _definition();
				definition.has_label_field = false;

				var meta = _getService().buildVirtualObjectMeta( definition, _prototype() );

				expect( meta.noLabel ).toBeTrue();
				expect( meta.labelfield ).toBe( "" );
				expect( StructKeyExists( meta.properties, "label" ) ).toBeFalse();
				expect( ArrayFindNoCase( meta.propertyNames, "label" ) ).toBe( 0 );
				expect( ListFindNoCase( meta.dbFieldList, "label" ) ).toBe( 0 );
				expect( ListFindNoCase( meta.dbFieldList, "custom_object" ) ).toBeGT( 0 );
			} );

			it( "should use a chosen custom field as the label field", function(){
				var definition = _definition();
				definition.label_field = "store_note";

				var meta = _getService().buildVirtualObjectMeta( definition, _prototype() );

				expect( meta.labelfield ).toBe( "store_note" );
				expect( meta.noLabel ).toBeFalse();
				expect( StructKeyExists( meta.properties, "label" ) ).toBeTrue();
				expect( meta.properties.label.required ).toBeTrue();
			} );

			it( "should keep a custom field as the label when records have no built-in label", function(){
				var definition = _definition();
				definition.has_label_field = false;
				definition.label_field     = "store_note";

				var meta = _getService().buildVirtualObjectMeta( definition, _prototype() );

				expect( meta.labelfield ).toBe( "store_note" );
				expect( meta.noLabel ).toBeFalse();
				expect( StructKeyExists( meta.properties, "label" ) ).toBeFalse();
			} );
		} );

		describe( "getLabelFieldValidationError()", function(){
			it( "should accept the built-in label when records have one", function(){
				var svc = _getService();

				variables.mockFields.$( "listFields", [] );

				expect( svc.getLabelFieldValidationError( "cobj_widget", "label", true ) ).toBe( "" );
			} );

			it( "should reject the built-in label when records do not have one", function(){
				var svc = _getService();

				variables.mockFields.$( "listFields", [] );

				expect( svc.getLabelFieldValidationError( "cobj_widget", "label", false ) ).toBe( "preside-objects.custom_object:field.label_field.validation.unknown" );
			} );

			it( "should accept a custom field that exists on the object", function(){
				var svc = _getService();

				variables.mockFields.$( "listFields", [ { key="store_note" } ] );

				expect( svc.getLabelFieldValidationError( "cobj_widget", "store_note", false ) ).toBe( "" );
			} );
		} );

		describe( "shared value object mapping", function(){
			it( "should point every custom object at the one shared value object", function(){
				var valueTables = new preside.system.services.customFields.CustomFieldsValueTableService();

				expect( _getService().getSharedValueObjectName() ).toBe( "_cfv_custom_object_record" );
				expect( valueTables.getValueObjectName( "cobj_widget" ) ).toBe( "_cfv_custom_object_record" );
				expect( valueTables.getValueObjectName( "my_table" ) ).toBe( "_cfv_my_table" );
			} );
		} );

		describe( "addVirtualObjects()", function(){
			it( "should register active definitions and the shared value table", function(){
				var svc     = _getService();
				var objects = {
					custom_object_record = { meta=_prototype() }
				};

				variables.mockPoService.$( method="selectData", callback=function(){
					return [ _definition() ];
				} );

				svc.addVirtualObjects( objects );

				expect( StructKeyExists( objects, "_cfv_custom_object_record" ) ).toBeTrue();
				expect( objects[ "_cfv_custom_object_record" ].meta.tableName ).toBe( "_cfv_custom_object_record" );
				expect( objects[ "_cfv_custom_object_record" ].instance ).toBe( "auto_created" );
				expect( StructKeyExists( objects, "cobj_widget" ) ).toBeTrue();
				expect( IsSimpleValue( objects.cobj_widget.instance ) ).toBeFalse();
				expect( objects.cobj_widget.meta.dbsync ).toBeFalse();
			} );

			it( "should still register the shared value table when the definition table is not ready", function(){
				var svc     = _getService();
				var objects = {
					custom_object_record = { meta=_prototype() }
				};

				variables.mockPoService.$( method="selectData", callback=function(){
					throw( type="database", message="table missing" );
				} );

				svc.addVirtualObjects( objects );

				expect( StructKeyExists( objects, "_cfv_custom_object_record" ) ).toBeTrue();
				expect( StructKeyExists( objects, "cobj_widget" ) ).toBeFalse();
			} );
		} );

		describe( "refreshDefinition()", function(){
			it( "should register an active definition and unregister an inactive one", function(){
				var svc        = _getService();
				var registered = "";
				var removed    = "";

				variables.mockPoService.$( method="selectData", callback=function(){
					return _definition();
				} );
				variables.mockPoService.$( method="registerRuntimeObject", callback=function(){
					registered = arguments[ 1 ] ?: "";
				} );
				variables.mockPoService.$( method="unregisterRuntimeObject", callback=function(){
					removed = arguments[ 1 ] ?: "";
				} );
				variables.mockPoService.$( "objectExists", true );
				variables.mockInjector.$( "refreshObject" );
				variables.mockBundles.$( "registerDynamicResources" );
				variables.mockForms.$( "clearDynamicFormsForObject" );
				variables.mockViews.$( "clearCache" );

				svc.refreshDefinition( "definition-1" );

				expect( registered ).toBe( "cobj_widget" );

				var inactive = _definition();
				inactive.active = false;
				variables.mockPoService.$( method="selectData", callback=function(){
					return inactive;
				} );

				svc.refreshDefinition( "definition-1" );

				expect( removed ).toBe( "cobj_widget" );
			} );
		} );

		describe( "resolveGroupId()", function(){
			it( "should reuse a built-in group when the category matches its title", function(){
				var svc = _getService();

				variables.mockPoService.$( "listObjects", [ "crm_contact", "cobj_widget" ] );
				variables.mockPoService.$( method="getObjectAttribute", callback=function(){
					var objectName    = arguments[ 1 ] ?: "";
					var attributeName = arguments[ 2 ] ?: "";

					if ( attributeName == "customObject" ) {
						return objectName == "cobj_widget" ? "definition-1" : "";
					}
					if ( attributeName == "datamanagerGroup" ) {
						return objectName == "crm_contact" ? "crm" : "";
					}

					return arguments[ 3 ] ?: "";
				} );
				variables.mockBundles.$( method="getResource", callback=function(){
					if ( ( arguments[ 1 ] ?: "" ) == "preside-objects.groups.crm:title" ) {
						return "CRM";
					}

					return "";
				} );

				expect( svc.resolveGroupId( "crm" ) ).toBe( "crm" );
				expect( svc.resolveGroupId( "  Field stores  " ) ).toBe( "cobj_field_stores" );
				expect( svc.resolveGroupId( "" ) ).toBe( "cobj_uncategorised" );
			} );
		} );

		describe( "registerI18nForDefinition()", function(){
			it( "should publish the object title and a category group bundle", function(){
				var svc     = _getService();
				var bundles = {};

				variables.mockPoService.$( "listObjects", [] );
				variables.mockBundles.$( method="registerDynamicResources", callback=function(){
					bundles[ arguments[ 1 ] ] = Duplicate( arguments[ 2 ] );
				} );

				svc.registerI18nForDefinition( _definition() );

				expect( bundles[ "preside-objects.cobj_widget" ].title ).toBe( "Widgets" );
				expect( bundles[ "preside-objects.cobj_widget" ][ "title.singular" ] ).toBe( "Widget" );
				expect( bundles[ "preside-objects.cobj_widget" ].iconClass ).toBe( "fa-cube" );
				expect( bundles[ "preside-objects.groups.cobj_stores" ].title ).toBe( "Stores" );
			} );

			it( "should prefix a bare icon picker value so view groups can render it", function(){
				var svc     = _getService();
				var bundles = {};
				var definition = _definition();

				definition.icon_class = "500px";
				variables.mockPoService.$( "listObjects", [] );
				variables.mockBundles.$( method="registerDynamicResources", callback=function(){
					bundles[ arguments[ 1 ] ] = Duplicate( arguments[ 2 ] );
				} );

				svc.registerI18nForDefinition( definition );

				expect( bundles[ "preside-objects.cobj_widget" ].iconClass ).toBe( "fa-500px" );
			} );
		} );

		describe( "userCan()", function(){
			it( "should treat manage membership as read access", function(){
				expect( _userCan( "read", [ "manage-group" ], [], [ "manage-group" ] ) ).toBeTrue();
			} );

			it( "should deny everyone when no groups are selected", function(){
				expect( _userCan( "read", [], [], [ "some-group" ] ) ).toBeFalse();
				expect( _userCan( "edit", [], [], [ "some-group" ] ) ).toBeFalse();
			} );

			it( "should allow a read group to read and deny it from writing", function(){
				expect( _userCan( "navigate", [], [ "read-group" ], [ "read-group" ] ) ).toBeTrue();
				expect( _userCan( "add", [], [ "read-group" ], [ "read-group" ] ) ).toBeFalse();
			} );

			it( "should allow a system user without consulting groups", function(){
				var svc = _getService();

				variables.mockLogin.$( "getLoggedInUserId", "sysadmin-id" );
				variables.mockLogin.$( "isSystemUser", true );

				expect( svc.userCan( "cobj_widget", "delete" ) ).toBeTrue();
			} );
		} );

		describe( "deletionConfirmationMatches()", function(){
			it( "should require the typed name to match the label exactly", function(){
				var svc = _getService();

				expect( svc.deletionConfirmationMatches( _definition(), "Widgets" ) ).toBeTrue();
				expect( svc.deletionConfirmationMatches( _definition(), "widgets" ) ).toBeFalse();
			} );
		} );
	}

	private boolean function _userCan( required string operation, required array manageGroups, required array readGroups, required array userGroups ) {
		var svc = _getService();

		variables._manageGroups = arguments.manageGroups;
		variables._readGroups   = arguments.readGroups;
		variables.mockLogin.$( "getLoggedInUserId", "user-1" );
		variables.mockLogin.$( "isSystemUser", false );
		variables.mockPerms.$( "listUserGroups", arguments.userGroups );
		variables.mockPoService.$( method="getObjectAttribute", callback=function(){
			return "definition-1";
		} );
		variables.mockPoService.$( method="selectData", callback=function(){
			var objectName = arguments.objectName ?: "";
			var ids        = objectName == "custom_object_manage_group" ? variables._manageGroups : variables._readGroups;
			var rows       = [];

			if ( !Len( objectName ) && IsStruct( arguments[ 1 ] ?: "" ) ) {
				objectName = arguments[ 1 ].objectName ?: "";
				ids        = objectName == "custom_object_manage_group" ? variables._manageGroups : variables._readGroups;
			}

			for( var id in ids ) {
				ArrayAppend( rows, { security_group=id } );
			}

			return rows;
		} );

		return svc.userCan( "cobj_widget", arguments.operation, "user-1" );
	}

	private struct function _definition() {
		return {
			  id              = "definition-1"
			, key             = "widget"
			, label           = "Widgets"
			, label_singular  = "Widget"
			, description     = "Stored widgets"
			, icon_class      = "fa-cube"
			, has_label_field = true
			, category        = "Stores"
			, active          = true
		};
	}

	private struct function _prototype() {
		return {
			  tableName      = "psys_custom_object_record"
			, tablePrefix    = "psys_"
			, dsn            = "preside"
			, properties     = {
				  id            = { name="id" }
				, label         = { name="label" }
				, custom_object = { name="custom_object", relationship="many-to-one" }
				, datecreated   = { name="datecreated" }
				, datemodified  = { name="datemodified" }
			  }
			, propertyNames  = [ "id", "label", "custom_object", "datecreated", "datemodified" ]
			, dbFieldList    = "id,label,custom_object,datecreated,datemodified"
			, labelfield     = "label"
		};
	}

	private any function _getService() {
		var svc = createMock( object=new preside.system.services.customObjects.CustomObjectsService() );

		variables.mockPoService = createStub();
		variables.mockBundles   = createStub();
		variables.mockForms     = createStub();
		variables.mockViews     = createStub();
		variables.mockInjector  = createStub();
		variables.mockFields    = createStub();
		variables.mockLogin     = createStub();
		variables.mockPerms     = createStub();
		variables.mockValueTables = new preside.system.services.customFields.CustomFieldsValueTableService();

		variables.mockPoService.$( "listObjects", [] );
		variables.mockPoService.$( method="getObjectAttribute", callback=function(){
			return arguments[ 3 ] ?: "";
		} );
		variables.mockBundles.$( "getResource", "" );

		svc.$property( propertyName="presideObjectService"         , mock=variables.mockPoService );
		svc.$property( propertyName="customFieldsValueTableService", mock=variables.mockValueTables );
		svc.$property( propertyName="customFieldsService"          , mock=variables.mockFields );
		svc.$property( propertyName="customFieldsPropertyInjector" , mock=variables.mockInjector );
		svc.$property( propertyName="resourceBundleService"        , mock=variables.mockBundles );
		svc.$property( propertyName="formsService"                 , mock=variables.mockForms );
		svc.$property( propertyName="adminDataViewsService"        , mock=variables.mockViews );
		svc.$property( propertyName="loginService"                 , mock=variables.mockLogin );
		svc.$property( propertyName="permissionService"            , mock=variables.mockPerms );

		return svc;
	}

}
