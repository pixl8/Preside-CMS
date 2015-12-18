component extends="testbox.system.BaseSpec"{

	function run(){
		describe( "getForm()", function(){
			it( "should return result of selectData() call on the form dao, filtering by the passed id", function(){
				var formBuilderService = getService();
				var id                 = CreateUUId();
				var dummyResult        = QueryNew( 'id,label', 'varchar,varchar', [[CreateUUId(), "label"]] );

				mockFormDao.$( "selectData").$args( id=id ).$results( dummyResult );

				expect( formBuilderService.getForm( id ) ).toBe( dummyResult );
			} );

			it( "should return an empty query object when ID passed has no length", function(){
				var formBuilderService = getService();
				var id                 = "";
				var dummyResult        = QueryNew( 'id,label', 'varchar,varchar', [[CreateUUId(), "label"]] );

				mockFormDao.$( "selectData").$args( id=id ).$results( dummyResult );

				expect( formBuilderService.getForm( id ) ).toBe( QueryNew( '' ) );
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