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

			it( "should return an empty 'types' array for a category when it has no types configured", function(){
				var service = getService( {
					  categoryX = {}
					, categoryZ = {}
					, categoryY = {}
				} );

				service.$( "$translateResource", "meh" );

				var categoriesAndTypes = service.getCategoriesAndItemTypes();

				expect( categoriesAndTypes.len()  ).toBe( 3 );
				expect( categoriesAndTypes[1].types ).toBe( [] );
				expect( categoriesAndTypes[2].types ).toBe( [] );
				expect( categoriesAndTypes[3].types ).toBe( [] );
			} );

			it( "should return item types within a category ordered by their translated label", function(){
				var service = getService( {
					standard = {
						  textinput = { someConfig=true }
						, textarea  = { moreConfig="test" }
						, test      = { test=CreateUUId() }
					}
				} );

				service.$( "$translateResource" ).$args( uri="formbuilder.item-categories:standard.title", defaultValue="standard" ).$results( "Standard" );
				service.$( "$translateResource" ).$args( uri="formbuilder.item-types.textinput:title", defaultValue="textinput" ).$results( "Text input" );
				service.$( "$translateResource" ).$args( uri="formbuilder.item-types.textarea:title", defaultValue="textarea" ).$results( "Text area" );
				service.$( "$translateResource" ).$args( uri="formbuilder.item-types.test:title", defaultValue="test" ).$results( "Zzzzz" );

				var categoriesAndTypes = service.getCategoriesAndItemTypes();

				expect( categoriesAndTypes.len()  ).toBe( 1 );
				expect( categoriesAndTypes[1].types.len() ).toBe( 3 );
				expect( categoriesAndTypes[1].types[1].id    ).toBe( "textarea"   );
				expect( categoriesAndTypes[1].types[1].title ).toBe( "Text area"  );
				expect( categoriesAndTypes[1].types[2].id    ).toBe( "textinput"  );
				expect( categoriesAndTypes[1].types[2].title ).toBe( "Text input" );
				expect( categoriesAndTypes[1].types[3].id    ).toBe( "test"       );
				expect( categoriesAndTypes[1].types[3].title ).toBe( "Zzzzz"      );
			} );

			it( "should include any defined configuration for each type in the returned type structure", function(){
				var config  = {
					standard = {
						  textinput = { someConfig=true }
						, textarea  = { moreConfig="test" }
						, test      = { test=CreateUUId() }
					}
				};
				var service = getService( config );

				service.$( "$translateResource" ).$args( uri="formbuilder.item-categories:standard.title", defaultValue="standard" ).$results( "Standard" );
				service.$( "$translateResource" ).$args( uri="formbuilder.item-types.textinput:title", defaultValue="textinput" ).$results( "Text input" );
				service.$( "$translateResource" ).$args( uri="formbuilder.item-types.textarea:title", defaultValue="textarea" ).$results( "Text area" );
				service.$( "$translateResource" ).$args( uri="formbuilder.item-types.test:title", defaultValue="test" ).$results( "Zzzzz" );

				var categoriesAndTypes = service.getCategoriesAndItemTypes();

				expect( categoriesAndTypes.len()  ).toBe( 1 );
				expect( categoriesAndTypes[1].types.len() ).toBe( 3 );
				expect( categoriesAndTypes[1].types[1].moreConfig ?: "" ).toBe( config.standard.textarea.moreConfig  );
				expect( categoriesAndTypes[1].types[2].someConfig ?: "" ).toBe( config.standard.textinput.someConfig );
				expect( categoriesAndTypes[1].types[3].test       ?: "" ).toBe( config.standard.test.test            );
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