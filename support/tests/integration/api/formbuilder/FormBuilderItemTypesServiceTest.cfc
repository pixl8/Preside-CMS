component extends="testbox.system.BaseSpec"{

	function run(){
		describe( "getCategoriesAndItemTypes", function(){

			it( "should return an empty array when there are no configured types", function(){
				var service = getService();

				expect( service.getCategoriesAndItemTypes() ).toBe( [] );
			} );

			it( "should return an array of configured categories, ordered by their translated label", function(){
				var service = getService( {
					  categoryX = {}
					, categoryZ = {}
					, categoryY = {}
				} );

				service.$( "$translateResource" ).$args( uri="formbuilder.item-categories:categoryX.title", defaultValue="categoryX" ).$results( "Category X" );
				service.$( "$translateResource" ).$args( uri="formbuilder.item-categories:categoryY.title", defaultValue="categoryY" ).$results( "Category Y" );
				service.$( "$translateResource" ).$args( uri="formbuilder.item-categories:categoryZ.title", defaultValue="categoryZ" ).$results( "Category Z" );

				var categoriesAndTypes = service.getCategoriesAndItemTypes();

				expect( categoriesAndTypes.len()  ).toBe( 3 );
				expect( categoriesAndTypes[1].id    ).toBe( "categoryX"  );
				expect( categoriesAndTypes[1].title ).toBe( "Category X" );
				expect( categoriesAndTypes[2].id    ).toBe( "categoryY"  );
				expect( categoriesAndTypes[2].title ).toBe( "Category Y" );
				expect( categoriesAndTypes[3].id    ).toBe( "categoryZ"  );
				expect( categoriesAndTypes[3].title ).toBe( "Category Z" );
			} );
		} );
	}

	private function getService( struct configuration={} ) {
		var service = CreateMock( object=new preside.system.services.formbuilder.FormBuilderItemTypesService(
			  configuredTypesAndCategories = arguments.configuration
		) );

		return service;
	}

}