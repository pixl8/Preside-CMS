component extends="tests.resources.HelperObjects.PresideBddTestCase" {

	function run() {
		describe( "buildFormula()", function(){
			it( "should generate an EAV subquery for static fields against the host value table", function(){
				var injector = _getInjector();
				var formula  = injector.buildFormula(
					  field      = { id=12, kind="static", data_type="text", key="nickname" }
					, objectName = "elf_test_object"
				);

				expect( formula ).toInclude( "select shorttext_value from _cfv_pobj_elf_test_object" );
				expect( formula ).toInclude( "field = 12" );
				expect( formula ).toInclude( "record = ${prefix}id" );
			} );

			it( "should generate a count formula for aggregate fields", function(){
				var injector = _getInjector();
				var formula  = injector.buildFormula(
					  field      = { id="fld-2", kind="aggregate", aggregate_property="gallery", aggregate_function="count", key="gallery_count" }
					, objectName = "elf_test_object"
				);

				expect( formula ).toBe( "count( distinct ${prefix}gallery.id )" );
			} );

			it( "should generate an agg formula for sum", function(){
				var injector = _getInjector();
				var formula  = injector.buildFormula(
					  field      = { id="fld-3", kind="aggregate", aggregate_property="orders", aggregate_function="sum", aggregate_value_property="amount", key="order_total" }
					, objectName = "elf_test_object"
				);

				expect( formula ).toBe( "agg:sum{ ${prefix}orders.amount }" );
			} );

			it( "should bake a related-record filter into a one-to-many count formula", function(){
				var injector      = _getInjector();
				var mockFilterSvc = createStub();

				variables.mockPoService.$( "getObjectPropertyAttribute" ).$args(
					  objectName    = "elf_test_object"
					, propertyName  = "addresses"
					, attributeName = "relatedTo"
					, defaultValue  = ""
				).$results( "address" );
				variables.mockPoService.$( "getIdField" ).$args( "address" ).$results( "id" );
				variables.mockPoService.$( "objectExists" ).$args( "address" ).$results( true );
				variables.mockPoService.$( "getObjectPropertyAttribute" ).$args(
					  objectName    = "elf_test_object"
					, propertyName  = "addresses"
					, attributeName = "relationship"
					, defaultValue  = ""
				).$results( "one-to-many" );
				variables.mockPoService.$( "getObjectPropertyAttribute" ).$args(
					  objectName    = "elf_test_object"
					, propertyName  = "addresses"
					, attributeName = "relationshipKey"
					, defaultValue  = "elf_test_object"
				).$results( "contact" );
				mockFilterSvc.$( "prepareFilter" ).$results( { filter="address.city = :city" } );
				variables.mockPoService.$( "selectData" ).$results( {
					  sql    = "select count( address.id ) as agg_value from pobj_address address where address.city = :city and address.contact = '__cf_parent_id__'"
					, params = { city={ value="London", type="varchar" } }
				} );
				injector.$property( propertyName="rulesEngineFilterService", mock=mockFilterSvc );

				var formula = injector.buildFormula(
					  field      = { id="fld-4", kind="aggregate", aggregate_property="addresses", aggregate_function="count", aggregate_filter="flt-1", key="london_addresses" }
					, objectName = "elf_test_object"
				);

				expect( formula ).toInclude( "ifnull(" );
				expect( formula ).toInclude( "${prefix}id" );
				expect( formula ).toInclude( "London" );
				expect( formula ).notToInclude( "__cf_parent_id__" );
				expect( formula ).notToInclude( ":city" );
			} );
		} );

		describe( "buildPropertyDefinition()", function(){
			it( "should mark static fields as batch editable and exportable by default", function(){
				var injector   = _getInjector();
				var definition = injector.buildPropertyDefinition(
					  field      = { id=12, kind="static", data_type="text", key="nickname", label="Nickname" }
					, objectName = "elf_test_object"
				);

				expect( definition.batchEditable     ).toBeTrue();
				expect( definition.excludeDataExport ).toBeFalse();
				expect( definition.control           ).toBe( "textinput" );
				expect( definition.customField       ).toBeTrue();
			} );

			it( "should honour data_exportable and batch_editable flags on static fields", function(){
				var injector   = _getInjector();
				var definition = injector.buildPropertyDefinition(
					  field      = { id=12, kind="static", data_type="text", key="nickname", label="Nickname", data_exportable=false, batch_editable=false }
					, objectName = "elf_test_object"
				);

				expect( definition.batchEditable     ).toBeFalse();
				expect( definition.excludeDataExport ).toBeTrue();
			} );

			it( "should never mark aggregate fields as batch editable", function(){
				var injector   = _getInjector();
				var definition = injector.buildPropertyDefinition(
					  field      = { id=13, kind="aggregate", aggregate_property="gallery", aggregate_function="count", key="gallery_count", label="Gallery count", batch_editable=true }
					, objectName = "elf_test_object"
				);

				expect( definition.batchEditable     ).toBeFalse();
				expect( definition.control           ).toBe( "none" );
				expect( definition.excludeDataExport ).toBeFalse();
			} );
		} );
	}

	private any function _getInjector() {
		var injector = CreateMock( object=new preside.system.services.customFields.CustomFieldsPropertyInjector() );
		var helpers  = createStub();

		variables.mockPoService              = createStub();
		variables.mockCustomFieldsService    = createStub();
		variables.mockValueTables            = createStub();
		variables.mockTypesService           = createStub();
		variables.mockAdminDataViewsService  = createStub();
		variables.mockExpressionService      = createStub();

		helpers.$( method="isTrue", callback=function( val ){
			return IsBoolean( arguments.val ?: "" ) && arguments.val;
		} );

		variables.mockValueTables.$( "getValueObjectName" ).$args( "elf_test_object" ).$results( "_cfv_elf_test_object" );
		variables.mockPoService.$( "getObjectAttribute" ).$args( "_cfv_elf_test_object", "tableName" ).$results( "_cfv_pobj_elf_test_object" );
		variables.mockPoService.$( "getIdField" ).$args( "elf_test_object" ).$results( "id" );
		variables.mockPoService.$( "getIdField", "id" );
		variables.mockPoService.$( "getObjectPropertyAttribute" ).$args(
			  objectName    = "elf_test_object"
			, propertyName  = "gallery"
			, attributeName = "relatedTo"
			, defaultValue  = ""
		).$results( "asset" );
		variables.mockPoService.$( "getObjectPropertyAttribute" ).$args(
			  objectName    = "elf_test_object"
			, propertyName  = "orders"
			, attributeName = "relatedTo"
			, defaultValue  = ""
		).$results( "order" );
		variables.mockPoService.$( "getIdField" ).$args( "asset" ).$results( "id" );
		variables.mockPoService.$( "getIdField" ).$args( "order" ).$results( "id" );

		variables.mockTypesService.$( "getTypedColumn" ).$args( "text" ).$results( "shorttext_value" );
		variables.mockTypesService.$( "getType" ).$args( "text" ).$results( { type="string", control="textinput" } );
		variables.mockTypesService.$( "getControl" ).$args( "text" ).$results( "textinput" );
		variables.mockTypesService.$( "getRenderer", "plaintext" );

		variables.mockCustomFieldsService.$( "getFieldListingLabel", "Nickname" );
		variables.mockCustomFieldsService.$( "getSlotViewGroup", "customFields" );

		injector.$property( propertyName="presideObjectService"            , mock=variables.mockPoService );
		injector.$property( propertyName="customFieldsService"             , mock=variables.mockCustomFieldsService );
		injector.$property( propertyName="customFieldsValueTableService"   , mock=variables.mockValueTables );
		injector.$property( propertyName="customFieldTypesService"         , mock=variables.mockTypesService );
		injector.$property( propertyName="adminDataViewsService"           , mock=variables.mockAdminDataViewsService );
		injector.$property( propertyName="rulesEngineExpressionService"    , mock=variables.mockExpressionService );
		injector.$property( propertyName="rulesEngineFilterService"        , mock=createStub() );
		injector.$property( propertyName="$helpers"                        , mock=helpers );
		injector.$( "$isFeatureEnabled", true );

		return injector;
	}

}
