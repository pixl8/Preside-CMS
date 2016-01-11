component extends="testbox.system.BaseSpec"{

	function run(){
		describe( "getForm()", function(){
			it( "should return result of selectData() call on the form dao, filtering by the passed id", function(){
				var service     = getService();
				var id          = CreateUUId();
				var dummyResult = QueryNew( 'id,label', 'varchar,varchar', [[CreateUUId(), "label"]] );

				mockFormDao.$( "selectData").$args( id=id ).$results( dummyResult );

				expect( service.getForm( id ) ).toBe( dummyResult );
			} );

			it( "should return an empty query object when ID passed has no length", function(){
				var service     = getService();
				var id          = "";
				var dummyResult = QueryNew( 'id,label', 'varchar,varchar', [[CreateUUId(), "label"]] );

				mockFormDao.$( "selectData").$args( id=id ).$results( dummyResult );

				expect( service.getForm( id ) ).toBe( QueryNew( '' ) );
			} );
		} );

		describe( "getFormItems", function(){

			it( "should return an empty array when form has no sections", function(){
				var service = getService();
				var formId  = CreateUUId();

				mockFormDao.$( "selectData" ).$args(
					  id           = formId
					, sortOrder    = "items.sort_order"
					, forceJoins   = "inner"
					, selectFields = [
						  "items.id"
						, "items.item_type"
						, "items.configuration"
					  ]
				).$results( QueryNew( '' ) );

				expect( service.getFormItems( formId ) ).toBe( [] );
			} );

			it( "should return a nested array representation of returned database query", function(){
				var service        = getService();
				var formId         = CreateUUId();
				var dummyData      = QueryNew( 'id,item_type,configuration', 'varchar,varchar,varchar', [
					  [ "item1", "typea", "{}" ]
					, [ "item2", "typeb", "{}" ]
					, [ "item3", "typeb", "{}" ]
					, [ "item4", "typeb", "{}" ]
					, [ "item5", "typea", "{}" ]
					, [ "item6", "typea", "{}" ]
					, [ "item7", "typeb", "{}" ]
				] );
				var expectedResult = [
					  { id="item1", type="typea", configuration={} }
					, { id="item2", type="typeb", configuration={} }
					, { id="item3", type="typeb", configuration={} }
					, { id="item4", type="typeb", configuration={} }
					, { id="item5", type="typea", configuration={} }
					, { id="item6", type="typea", configuration={} }
					, { id="item7", type="typeb", configuration={} }
				];

				mockFormDao.$( "selectData" ).$args(
					  id           = formId
					, sortOrder    = "items.sort_order"
					, forceJoins   = "inner"
					, selectFields = [
						  "items.id"
						, "items.item_type"
						, "items.configuration"
					  ]
				).$results( dummyData );

				expect( service.getFormItems( formId ) ).toBe( expectedResult );
			} );

			it( "should deserialize configuration that has neen saved in the database", function(){
				var service        = getService();
				var formId         = CreateUUId();
				var dummyData      = QueryNew( 'id,item_type,configuration', 'varchar,varchar,varchar', [
					  [ "item1", "typea", '{ "cat":"dog", "test":true }' ]
				] );
				var expectedResult = [
					{ id="item1", type="typea", configuration={ cat="dog", test=true } }
				];


				mockFormDao.$( "selectData" ).$args(
					  id           = formId
					, sortOrder    = "items.sort_order"
					, forceJoins   = "inner"
					, selectFields = [
						  "items.id"
						, "items.item_type"
						, "items.configuration"
					  ]
				).$results( dummyData );

				expect( service.getFormItems( formId ) ).toBe( expectedResult );
			} );

		} );

		describe( "addItem", function(){

			it( "should save passed item data to the given form with next available sort order value", function(){
				var service       = getService();
				var formId        = CreateUUId();
				var itemtype      = "sometype";
				var configuration = { test=true, configuration="nice" };
				var newId         = CreateUUId();
				var topSortOrder  = 5;

				mockFormItemDao.$( "selectData" ).$args( filter={ form=formId }, selectFields=[ "Max( sort_order ) as max_sort_order" ] ).$results( QueryNew( "max_sort_order", "int", [[ topSortOrder ]]) );
				mockFormItemDao.$( "insertData" ).$args( data={
					  form          = formId
					, item_type     = itemType
					, configuration = SerializeJson( configuration )
					, sort_order    = topSortOrder+1
				} ).$results( newId );

				expect( service.addItem(
					  formId        = formId
					, itemType      = itemType
					, configuration = configuration
				) ).toBe( newId );
			} );

		} );

		describe( "validateItemConfig", function(){

			it( "should do a standard preside validation based on the configuration form for the item type", function(){
 				var service              = getService();
 				var itemType             = "textarea";
 				var formName             = "someform" & CreateUUId();
 				var itemTypeConfig       = { isFormField=false, configFormName=formName, requiresConfiguration=true };
 				var config               = { name="something", test=true };
 				var mockValidationResult = CreateEmptyMock( "preside.system.services.validation.ValidationResult" );

 				mockItemTypesService.$( "getItemTypeConfig" ).$args( itemType ).$results( itemTypeConfig );
 				mockValidationEngine.$( "newValidationResult", mockValidationResult );
 				mockFormsService.$( "validateForm" ).$args( formName=formName, formData=config, validationResult=mockValidationResult ).$results( mockValidationResult );

 				expect( service.validateItemConfig(
 					  formId   = CreateUUId()
 					, itemId   = CreateUUId()
 					, itemType = itemType
 					, config   = config
 				) ).toBe( mockValidationResult );

			} );

			it( "should return fresh validation result when the item type has no configuration", function(){
				var service              = getService();
 				var itemType             = "textarea";
 				var itemTypeConfig       = { isFormField=false, configFormName="", requiresConfiguration=false };
 				var config               = {};
 				var mockValidationResult = CreateEmptyMock( "preside.system.services.validation.ValidationResult" );

 				mockItemTypesService.$( "getItemTypeConfig" ).$args( itemType ).$results( itemTypeConfig );
 				mockValidationEngine.$( "newValidationResult", mockValidationResult );

 				expect( service.validateItemConfig(
 					  formId   = CreateUUId()
 					, itemId   = CreateUUId()
 					, itemType = itemType
 					, config   = config
 				) ).toBe( mockValidationResult );
			} );

			it( "it should fail validation on the uniqueness of the 'name' config field when the item is a form field and an item with that name alread exists", function(){
				var service              = getService();
 				var itemType             = "textarea";
 				var formName             = "someform" & CreateUUId();
 				var itemTypeConfig       = { isFormField=true, configFormName=formName, requiresConfiguration=true };
 				var config               = { name="something", test=true };
 				var mockValidationResult = CreateEmptyMock( "preside.system.services.validation.ValidationResult" );
 				var formId               = CreateUUId();
				var itemId               = CreateUUId();
 				var dummyExistingResults = QueryNew( "configuration", "varchar", [[SerializeJson({ name="test" })],[SerializeJson({ name="something" })]]);

 				mockValidationResult.$( "addError" );
 				mockItemTypesService.$( "getItemTypeConfig" ).$args( itemType ).$results( itemTypeConfig );
 				mockValidationEngine.$( "newValidationResult", mockValidationResult );
 				mockFormsService.$( "validateForm" ).$args( formName=formName, formData=config, validationResult=mockValidationResult ).$results( mockValidationResult );
 				mockFormItemDao.$( "selectData" ).$args(
 					  filter       = "form = :form and id != :id"
 					, filterParams = { form=formId, id=itemId }
 					, selectFields = [ "configuration" ]
 				).$results( dummyExistingResults );

 				expect( service.validateItemConfig(
 					  formId   = formId
 					, itemId   = itemId
 					, itemType = itemType
 					, config   = config
 				) ).toBe( mockValidationResult );

 				var callLog = mockValidationResult.$callLog().addError;
 				expect( callLog.len() ).toBe( 1 );
 				expect( callLog[ 1 ] ).toBe( { fieldName="name", message="formbuilder:validation.non.unique.field.name" } );
			} );

		} );
	}

	private function getService() {
		variables.mockFormDao          = CreateStub();
		variables.mockFormItemDao      = CreateStub();
		variables.mockItemTypesService = CreateEmptyMock( "preside.system.services.formbuilder.FormBuilderItemTypesService" );
		variables.mockFormsService     = CreateEmptyMock( "preside.system.services.forms.FormsService" );
		variables.mockValidationEngine = CreateEmptyMock( "preside.system.services.validation.ValidationEngine" );

		var service = CreateMock( object=new preside.system.services.formbuilder.FormBuilderService(
			  itemTypesService = mockItemTypesService
			, formsService     = mockFormsService
			, validationEngine = mockValidationEngine
		) );

		service.$( "$getPresideObject" ).$args( "formbuilder_form" ).$results( mockFormDao );
		service.$( "$getPresideObject" ).$args( "formbuilder_formitem" ).$results( mockFormItemDao );

		return service;
	}

}