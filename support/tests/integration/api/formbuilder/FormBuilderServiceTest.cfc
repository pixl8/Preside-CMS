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

		describe( "getFormItemsBySection", function(){

			it( "should return an empty array when form has no sections", function(){
				var service = getService();
				var formId  = CreateUUId();

				mockFormDao.$( "selectData" ).$args(
					  id           = formId
					, sortOrder    = "sections.sort_order, sections$items.sort_order"
					, forceJoins   = "inner"
					, selectFields = [
						  "sections.id                  as section_id"
						, "sections$items.id            as item_id"
						, "sections$items.item_type     as item_type"
						, "sections$items.configuration as item_configuration"
					  ]
				).$results( QueryNew( '' ) );

				expect( service.getFormItemsBySection( formId ) ).toBe( [] );
			} );

			it( "should return a nested array representation of returned database query", function(){
				var service        = getService();
				var formId         = CreateUUId();
				var sections       = [ CreateUUId(), CreateUUId(), CreateUUId() ];
				var dummyData      = QueryNew( 'section_id,item_id,item_type,item_configuration', 'varchar,varchar,varchar,varchar', [
					  [ sections[1], "item1", "typea", "{}" ]
					, [ sections[1], "item2", "typeb", "{}" ]
					, [ sections[2], "item3", "typeb", "{}" ]
					, [ sections[2], "item4", "typeb", "{}" ]
					, [ sections[3], "item5", "typea", "{}" ]
					, [ sections[3], "item6", "typea", "{}" ]
					, [ sections[3], "item7", "typeb", "{}" ]
				] );
				var expectedResult = [
					  { id=sections[1], items=[{ id="item1", type="typea", configuration={} }, { id="item2", type="typeb", configuration={} } ] }
					, { id=sections[2], items=[{ id="item3", type="typeb", configuration={} }, { id="item4", type="typeb", configuration={} } ] }
					, { id=sections[3], items=[{ id="item5", type="typea", configuration={} }, { id="item6", type="typea", configuration={} }, { id="item7", type="typeb", configuration={} } ] }
				];

				mockFormDao.$( "selectData" ).$args(
					  id           = formId
					, sortOrder    = "sections.sort_order, sections$items.sort_order"
					, forceJoins   = "inner"
					, selectFields = [
						  "sections.id                  as section_id"
						, "sections$items.id            as item_id"
						, "sections$items.item_type     as item_type"
						, "sections$items.configuration as item_configuration"
					  ]
				).$results( dummyData );

				expect( service.getFormItemsBySection( formId ) ).toBe( expectedResult );
			} );

			it( "should deserialize configuration that has neen saved in the database", function(){
				var service        = getService();
				var formId         = CreateUUId();
				var sections       = [ CreateUUId(), CreateUUId(), CreateUUId() ];
				var dummyData      = QueryNew( 'section_id,item_id,item_type,item_configuration', 'varchar,varchar,varchar,varchar', [
					  [ sections[1], "item1", "typea", '{ "cat":"dog", "test":true }' ]
				] );
				var expectedResult = [
					{ id=sections[1], items=[{ id="item1", type="typea", configuration={ cat="dog", test=true } } ] }
				];


				mockFormDao.$( "selectData" ).$args(
					  id           = formId
					, sortOrder    = "sections.sort_order, sections$items.sort_order"
					, forceJoins   = "inner"
					, selectFields = [
						  "sections.id                  as section_id"
						, "sections$items.id            as item_id"
						, "sections$items.item_type     as item_type"
						, "sections$items.configuration as item_configuration"
					  ]
				).$results( dummyData );

				expect( service.getFormItemsBySection( formId ) ).toBe( expectedResult );
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