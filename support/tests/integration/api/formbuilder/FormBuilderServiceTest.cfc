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
	}

	private function getService() {
		var service = CreateMock( object=new preside.system.services.formbuilder.FormBuilderService() );

		variables.mockFormDao = CreateStub();

		service.$( "$getPresideObject" ).$args( "formbuilder_form" ).$results( mockFormDao );

		return service;
	}

}