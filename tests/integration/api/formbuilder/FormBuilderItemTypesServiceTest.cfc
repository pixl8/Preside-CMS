component extends="testbox.system.BaseSpec"{

	function run(){
		describe( "getItemTypeConfig", function(){
			it( "should include any configuration defined in the configuration struct for the given type", function(){
				var serviceConfig = {
					standard = { sortOrder=10, types={
						  textinput = { someConfig=true, morenonStandardConfig=CreateUUId() }
						, textarea  = { moreConfig="test" }
						, test      = { test=CreateUUId() }
					} }
				};
				var service        = getService( serviceConfig );
				var itemTypeConfig = service.getItemTypeConfig( "textinput" );


				expect( itemTypeConfig.someConfig            ?: "" ).toBe( serviceConfig.standard.types.textinput.someConfig );
				expect( itemTypeConfig.morenonStandardConfig ?: "" ).toBe( serviceConfig.standard.types.textinput.morenonStandardConfig );
			} );

			it( "should default a 'isFormField' setting to true when it doesn't already exist", function(){
				var serviceConfig = {
					standard = { sortOrder=10, types={
						  textinput = { someConfig=true, morenonStandardConfig=CreateUUId() }
						, textarea  = { moreConfig="test" }
						, test      = { test=CreateUUId() }
					} }
				};
				var service        = getService( serviceConfig );
				var itemTypeConfig = service.getItemTypeConfig( "test" );

				expect( itemTypeConfig.isFormField ?: "" ).toBe( true );
			} );

			it( "should return a 'adminPlaceholderViewlet' setting derived by convention when the viewlet exists", function(){
				var serviceConfig = {
					standard = { sortOrder=10, types={
						  textinput = { someConfig=true, morenonStandardConfig=CreateUUId() }
						, textarea  = { moreConfig="test" }
						, test      = { test=CreateUUId() }
					} }
				};
				var expectedViewlet = "formbuilder.item-types.test.adminPlaceholder";
				var service         = getService( serviceConfig );

				mockColdbox.$( "viewletExists" ).$args( expectedViewlet ).$results( true );


				var itemTypeConfig = service.getItemTypeConfig( "test" );

				expect( itemTypeConfig.adminPlaceholderViewlet ?: "" ).toBe( expectedViewlet );
			} );

			it( "should return a 'adminPlaceholderViewlet' setting that is empty the convention based viewlet does not exist", function(){
				var serviceConfig = {
					standard = { sortOrder=10, types={
						  textinput = { someConfig=true, morenonStandardConfig=CreateUUId() }
						, textarea  = { moreConfig="test" }
						, test      = { test=CreateUUId() }
					} }
				};
				var expectedViewlet = "formbuilder.item-types.test.adminPlaceholder";
				var service         = getService( serviceConfig );

				mockColdbox.$( "viewletExists" ).$args( expectedViewlet ).$results( false );


				var itemTypeConfig = service.getItemTypeConfig( "test" );

				expect( itemTypeConfig.adminPlaceholderViewlet ?: "" ).toBe( "" );
			} );
		} );

		describe( "getItemTypesByCategory", function(){

			it( "should return an empty array when there are no configured types", function(){
				var service = getService();

				expect( service.getItemTypesByCategory() ).toBe( [] );
			} );

			it( "should return an array of configured categories, ordered by their defined sort order", function(){
				var service = getService( {
					  categoryX = { sortOrder=20  }
					, categoryZ = { sortOrder=100 }
					, categoryY = { sortOrder=5   }
				} );

				service.$( "$translateResource", "test" );

				var categoriesAndTypes = service.getItemTypesByCategory();

				expect( categoriesAndTypes.len()  ).toBe( 3 );
				expect( categoriesAndTypes[1].id    ).toBe( "categoryY"  );
				expect( categoriesAndTypes[2].id    ).toBe( "categoryX"  );
				expect( categoriesAndTypes[3].id    ).toBe( "categoryZ"  );
			} );

			it( "should provide translated titles for each category", function(){
				var service = getService( {
					  categoryX = { sortOrder=20  }
					, categoryZ = { sortOrder=100 }
					, categoryY = { sortOrder=5   }
				} );

				service.$( "$translateResource" ).$args( uri="formbuilder.item-categories:categoryX.title", defaultValue="categoryX" ).$results( "Category X" );
				service.$( "$translateResource" ).$args( uri="formbuilder.item-categories:categoryZ.title", defaultValue="categoryZ" ).$results( "Category Z" );
				service.$( "$translateResource" ).$args( uri="formbuilder.item-categories:categoryY.title", defaultValue="categoryY" ).$results( "Category Y" );

				var categoriesAndTypes = service.getItemTypesByCategory();

				expect( categoriesAndTypes.len()  ).toBe( 3 );
				expect( categoriesAndTypes[1].title ).toBe( "Category Y"  );
				expect( categoriesAndTypes[2].title ).toBe( "Category X"  );
				expect( categoriesAndTypes[3].title ).toBe( "Category Z"  );
			} );

			it( "should return an empty 'types' array for a category when it has no types configured", function(){
				var service = getService( {
					  categoryX = {}
					, categoryZ = {}
					, categoryY = {}
				} );

				service.$( "$translateResource", "meh" );

				var categoriesAndTypes = service.getItemTypesByCategory();

				expect( categoriesAndTypes.len()  ).toBe( 3 );
				expect( categoriesAndTypes[1].types ).toBe( [] );
				expect( categoriesAndTypes[2].types ).toBe( [] );
				expect( categoriesAndTypes[3].types ).toBe( [] );
			} );

			it( "should return item types within a category ordered by their translated label", function(){
				var service = getService( {
					standard = { sortOrder=10, types={
						  textinput = { someConfig=true }
						, textarea  = { moreConfig="test" }
						, test      = { test=CreateUUId() }
					} }
				} );

				service.$( "$translateResource" ).$args( uri="formbuilder.item-categories:standard.title", defaultValue="standard" ).$results( "Standard" );
				service.$( "$translateResource" ).$args( uri="formbuilder.item-types.textinput:title", defaultValue="textinput" ).$results( "Text input" );
				service.$( "$translateResource" ).$args( uri="formbuilder.item-types.textarea:title", defaultValue="textarea" ).$results( "Text area" );
				service.$( "$translateResource" ).$args( uri="formbuilder.item-types.test:title", defaultValue="test" ).$results( "Zzzzz" );

				var categoriesAndTypes = service.getItemTypesByCategory();

				expect( categoriesAndTypes.len()  ).toBe( 1 );
				expect( categoriesAndTypes[1].types.len() ).toBe( 3 );
				expect( categoriesAndTypes[1].types[1].id    ).toBe( "textarea"   );
				expect( categoriesAndTypes[1].types[1].title ).toBe( "Text area"  );
				expect( categoriesAndTypes[1].types[2].id    ).toBe( "textinput"  );
				expect( categoriesAndTypes[1].types[2].title ).toBe( "Text input" );
				expect( categoriesAndTypes[1].types[3].id    ).toBe( "test"       );
				expect( categoriesAndTypes[1].types[3].title ).toBe( "Zzzzz"      );
			} );
		} );

		describe( "getConfigFormNameForItemType", function(){
			it( "should return form name based on convention when item type is not a form control", function(){
				var config  = {
					standard = { sortOrder=10, types={
						  textinput = { someConfig=true }
						, textarea  = { moreConfig="test", isFormField=false }
						, content   = { isFormField=false }
					} }
				};
				var service = getService( config );
				var itemType = "content";
				var expectedFormName = "formbuilder.item-types." & itemType;

				service.$( "$translateResource", "" );
				mockFormsService.$( "formExists" ).$args( expectedFormName ).$results( true );

				expect( service.getConfigFormNameForItemType( itemType) ).toBe( expectedFormName );
			} );

			it( "should return 'formbuilder.item-types.formfield' when the type has no individual configuration but is a form field", function(){
				var config  = {
					standard = { sortOrder=10, types={
						  textinput = { someConfig=true }
						, textarea  = { moreConfig="test", isFormField=false }
						, content   = { isFormField=false }
					} }
				};
				var service          = getService( config );
				var itemType         = "textinput";
				var itemTypeFormName = "formbuilder.item-types." & itemType;
				var expectedFormName = "formbuilder.item-types.formfield";

				service.$( "$translateResource", "" );
				mockFormsService.$( "formExists" ).$args( itemTypeFormName ).$results( false );

				expect( service.getConfigFormNameForItemType( itemType) ).toBe( expectedFormName );
			} );

			it( "should return merged formname when itemtype is both a form field and has its own custom config form", function(){
				var config  = {
					standard = { sortOrder=10, types={
						  textinput = { someConfig=true }
						, textarea  = { moreConfig="test", isFormField=false }
						, content   = { isFormField=false }
					} }
				};
				var service          = getService( config );
				var itemType         = "textinput";
				var itemTypeFormName = "formbuilder.item-types." & itemType;
				var fieldFormName    = "formbuilder.item-types.formfield";
				var expectedFormName = CreateUUId();

				service.$( "$translateResource", "" );
				mockFormsService.$( "formExists" ).$args( itemTypeFormName ).$results( true );
				mockFormsService.$( "getMergedFormName" ).$args( formName=fieldFormName, mergeWithFormName=itemTypeFormName ).$results( expectedFormName );

				expect( service.getConfigFormNameForItemType( itemType) ).toBe( expectedFormName );
			} );

			it( "should return an empty string when the item type has no configuration", function(){
				var config  = {
					standard = { sortOrder=10, types={
						  textinput = { someConfig=true }
						, textarea  = { moreConfig="test", isFormField=false }
						, spacer   = { isFormField=false }
					} }
				};
				var service = getService( config );
				var itemType = "spacer";
				var expectedFormName = "formbuilder.item-types." & itemType;

				service.$( "$translateResource", "" );
				mockFormsService.$( "formExists" ).$args( expectedFormName ).$results( false );

				expect( service.getConfigFormNameForItemType( itemType) ).toBe( "" );
			} );

			it( "should return an empty string when the item type does not exist", function(){
				var config  = {
					standard = { sortOrder=10, types={
						  textinput = { someConfig=true }
						, textarea  = { moreConfig="test", isFormField=false }
						, spacer   = { isFormField=false }
					} }
				};
				var service = getService( config );
				var itemType = "nonexistant";

				expect( service.getConfigFormNameForItemType( itemType) ).toBe( "" );
			} );
		} );
	}

	private function getService( struct configuration={} ) {
		mockFormsService = CreateEmptyMock( "preside.system.services.forms.FormsService" );
		mockColdbox = CreateStub();
		mockFormsService.$( "formExists", false );

		var service = CreateMock( object=new preside.system.services.formbuilder.FormBuilderItemTypesService(
			  configuredTypesAndCategories = arguments.configuration
			, formsService                 = mockFormsService
		) );

		service.$( "$translateResource", "" );
		service.$( "$getColdbox", mockColdbox );
		mockColdbox.$( "viewletExists", false );

		return service;
	}

}