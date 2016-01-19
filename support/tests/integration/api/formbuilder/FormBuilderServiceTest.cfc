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

				mockFormItemDao.$( "selectData" ).$args(
					  filter       = { form=formId }
					, orderBy      = "sort_order"
					, selectFields = [
						  "id"
						, "item_type"
						, "configuration"
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
				var types = {
					  a = { test=true, something=CreateUUId() }
					, b = { test=true, something=CreateUUId() }
				};
				var expectedResult = [
					  { id="item1", type=types.a, configuration={} }
					, { id="item2", type=types.b, configuration={} }
					, { id="item3", type=types.b, configuration={} }
					, { id="item4", type=types.b, configuration={} }
					, { id="item5", type=types.a, configuration={} }
					, { id="item6", type=types.a, configuration={} }
					, { id="item7", type=types.b, configuration={} }
				];

				mockItemTypesService.$( "getItemTypeConfig" ).$args( "typea" ).$results( types.a );
				mockItemTypesService.$( "getItemTypeConfig" ).$args( "typeb" ).$results( types.b );

				mockFormItemDao.$( "selectData" ).$args(
					  filter       = { form=formId }
					, orderBy      = "sort_order"
					, selectFields = [
						  "id"
						, "item_type"
						, "configuration"
					  ]
				).$results( dummyData );

				expect( service.getFormItems( formId ) ).toBe( expectedResult );
			} );

			it( "should deserialize configuration that has een saved in the database", function(){
				var service        = getService();
				var formId         = CreateUUId();
				var dummyData      = QueryNew( 'id,item_type,configuration', 'varchar,varchar,varchar', [
					  [ "item1", "typea", '{ "cat":"dog", "test":true }' ]
				] );
				var expectedResult = { cat="dog", test=true };

				mockItemTypesService.$( "getItemTypeConfig", {} );
				mockFormItemDao.$( "selectData" ).$args(
					  filter       = { form=formId }
					, orderBy      = "sort_order"
					, selectFields = [
						  "id"
						, "item_type"
						, "configuration"
					  ]
				).$results( dummyData );

				var formItems = service.getFormItems( formId );
				expect( formItems.len() ).toBe( 1 );
				expect( formItems[ 1 ].configuration ).toBe( expectedResult );
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
				service.$( "isFormLocked", false );

				expect( service.addItem(
					  formId        = formId
					, itemType      = itemType
					, configuration = configuration
				) ).toBe( newId );
			} );

			it( "should do nothing when the form is locked", function(){
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
				service.$( "isFormLocked", true );

				expect( service.addItem(
					  formId        = formId
					, itemType      = itemType
					, configuration = configuration
				) ).toBe( "" );

				expect( mockFormItemDao.$callLog().selectData.len() ).toBe( 0 );
				expect( mockFormItemDao.$callLog().insertData.len() ).toBe( 0 );
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

		describe( "deleteItem", function(){

			it( "should remove item from the database", function(){
				var service = getService();
				var itemId  = CreateUUId();

				mockFormItemDao.$( "deleteData" ).$args( id=itemId ).$results( 1 );
				service.$( "isFormLocked" ).$args( itemId=itemId ).$results( false );

				service.deleteItem( itemId );

				var callLog = mockFormItemDao.$callLog().deleteData;
				expect( callLog.len() ).toBe( 1 );

				expect( callLog[ 1 ] ).toBe( { id=itemId } );
			} );

			it( "should return true when an item was deleted from the database", function(){
				var service = getService();
				var itemId  = CreateUUId();

				mockFormItemDao.$( "deleteData" ).$args( id=itemId ).$results( 1 );
				service.$( "isFormLocked" ).$args( itemId=itemId ).$results( false );

				expect( service.deleteItem( itemId )  ).toBeTrue();


			} );

			it( "should return false when no records were deleted from the database", function(){
				var service = getService();
				var itemId  = CreateUUId();

				mockFormItemDao.$( "deleteData" ).$args( id=itemId ).$results( 0 );
				service.$( "isFormLocked" ).$args( itemId=itemId ).$results( false );

				expect( service.deleteItem( itemId )  ).toBeFalse();


			} );

			it( "should not attempt to delete anything and return false when an empty string is passed as the id", function(){
				var service = getService();
				var itemId  = "";

				mockFormItemDao.$( "deleteData" );
				service.$( "isFormLocked" ).$args( itemId=itemId ).$results( false );

				expect( service.deleteItem( itemId )  ).toBeFalse();
				var callLog = mockFormItemDao.$callLog().deleteData;
				expect( callLog.len() ).toBe( 0 );
			} );

			it( "should not attempt to delete anything and return false when form is locked", function(){
				var service = getService();
				var itemId  = CreateUUId();

				mockFormItemDao.$( "deleteData" );
				service.$( "isFormLocked" ).$args( itemId=itemId ).$results( true );

				expect( service.deleteItem( itemId )  ).toBeFalse();
				var callLog = mockFormItemDao.$callLog().deleteData;
				expect( callLog.len() ).toBe( 0 );
			} );

		} );

		describe( "setItemsSortOrder", function(){
			it( "should set the sort order of all items to their position in the passed array of item IDs", function(){
				var service = getService();
				var items   = [ CreateUUId(), CreateUUId(), CreateUUId(), CreateUUId(), CreateUUId() ];

				mockFormItemDao.$( "updateData", 1 );
				service.$( "isFormLocked", false );

				service.setItemsSortOrder( items );

				var callLog = mockFormItemDao.$callLog().updateData;
				expect( callLog.len() ).toBe( items.len() );
				for( var i=1; i <= items.len(); i++ ){
					expect( callLog[ i ] ).toBe( { id=items[i], data={ sort_order=i } } );
				}
			} );

			it( "should return the number of records updated", function(){
				var service = getService();
				var items   = [ CreateUUId(), CreateUUId(), CreateUUId(), CreateUUId(), CreateUUId(), CreateUUId() ];

				mockFormItemDao.$( "updateData", 1 );
				service.$( "isFormLocked", false );

				expect( service.setItemsSortOrder( items ) ).toBe( items.len() );
			} );

			it( "should do nothing when the form is locked", function(){
				var service = getService();
				var items   = [ CreateUUId(), CreateUUId(), CreateUUId(), CreateUUId(), CreateUUId() ];

				mockFormItemDao.$( "updateData", 1 );
				service.$( "isFormLocked", true );

				service.setItemsSortOrder( items );

				var callLog = mockFormItemDao.$callLog().updateData;
				expect( callLog.len() ).toBe( 0 );
			} );
		} );

		describe( "activateForm", function(){
			it( "should set the given's form active status to true", function(){
				var service = getService();
				var formId  = CreateUUId();

				mockFormDao.$( "updateData", 1 );
				service.$( "isFormLocked", false );

				expect( service.activateForm( formId ) ).toBe( 1 );

				var callLog = mockFormDao.$callLog().updateData;
				expect( callLog.len() ).toBe( 1 );
				expect( callLog[ 1 ] ).toBe( { id=formId, data={ active=true } } );
			} );

			it( "should do nothing when the passed ID is an empty string", function(){
				var service = getService();
				var formId  = "";

				mockFormDao.$( "updateData", 1 );
				service.$( "isFormLocked", false );

				expect( service.activateForm( formId ) ).toBe( 0 );

				var callLog = mockFormDao.$callLog().updateData;
				expect( callLog.len() ).toBe( 0 );
			} );

			it( "should do nothing when the form is locked", function(){
				var service = getService();
				var formId  = CreateUUId();

				mockFormDao.$( "updateData", 1 );
				service.$( "isFormLocked", true );

				expect( service.activateForm( formId ) ).toBe( 0 );

				var callLog = mockFormDao.$callLog().updateData;
				expect( callLog.len() ).toBe( 0 );
			} );
		} );

		describe( "deactivateForm", function(){
			it( "should set the given's form active status to false", function(){
				var service = getService();
				var formId  = CreateUUId();

				mockFormDao.$( "updateData", 1 );
				service.$( "isFormLocked", false );

				expect( service.deactivateForm( formId ) ).toBe( 1 );

				var callLog = mockFormDao.$callLog().updateData;
				expect( callLog.len() ).toBe( 1 );
				expect( callLog[ 1 ] ).toBe( { id=formId, data={ active=false } } );
			} );

			it( "should do nothing when the passed ID is an empty string", function(){
				var service = getService();
				var formId  = "";

				mockFormDao.$( "updateData", 1 );
				service.$( "isFormLocked", false );

				expect( service.deactivateForm( formId ) ).toBe( 0 );

				var callLog = mockFormDao.$callLog().updateData;
				expect( callLog.len() ).toBe( 0 );
			} );

			it( "should do nothing when the form is locked", function(){
				var service = getService();
				var formId  = CreateUUId();

				mockFormDao.$( "updateData", 1 );
				service.$( "isFormLocked", true );

				expect( service.deactivateForm( formId ) ).toBe( 0 );

				var callLog = mockFormDao.$callLog().updateData;
				expect( callLog.len() ).toBe( 0 );
			} );
		} );

		describe( "lockForm", function(){
			it( "should set the given's form locked status to true", function(){
				var service = getService();
				var formId  = CreateUUId();

				mockFormDao.$( "updateData", 1 );

				expect( service.lockForm( formId ) ).toBe( 1 );

				var callLog = mockFormDao.$callLog().updateData;
				expect( callLog.len() ).toBe( 1 );
				expect( callLog[ 1 ] ).toBe( { id=formId, data={ locked=true } } );
			} );

			it( "should do nothing when the passed ID is an empty string", function(){
				var service = getService();
				var formId  = "";

				mockFormDao.$( "updateData", 1 );

				expect( service.lockForm( formId ) ).toBe( 0 );

				var callLog = mockFormDao.$callLog().updateData;
				expect( callLog.len() ).toBe( 0 );
			} );
		} );

		describe( "unlockForm", function(){
			it( "should set the given's form locked status to false", function(){
				var service = getService();
				var formId  = CreateUUId();

				mockFormDao.$( "updateData", 1 );

				expect( service.unlockForm( formId ) ).toBe( 1 );

				var callLog = mockFormDao.$callLog().updateData;
				expect( callLog.len() ).toBe( 1 );
				expect( callLog[ 1 ] ).toBe( { id=formId, data={ locked=false } } );
			} );

			it( "should do nothing when the passed ID is an empty string", function(){
				var service = getService();
				var formId  = "";

				mockFormDao.$( "updateData", 1 );

				expect( service.unlockForm( formId ) ).toBe( 0 );

				var callLog = mockFormDao.$callLog().updateData;
				expect( callLog.len() ).toBe( 0 );
			} );
		} );

		describe( "isFormLocked", function(){

			it( "should return true when the form for the passed form id has its locked status set to true in the database", function(){
				var service = getService();
				var formId  = CreateUUId();

				mockFormDao.$( "dataExists" ).$args( filter={ id=formId, locked=true } ).$results( true );

				expect( service.isFormLocked( formId ) ).toBeTrue();
			} );

			it( "should return false when the form for the passed form id has its locked status set to false in the database", function(){
				var service = getService();
				var formId  = CreateUUId();

				mockFormDao.$( "dataExists" ).$args( filter={ id=formId, locked=true } ).$results( false );

				expect( service.isFormLocked( formId ) ).toBeFalse();
			} );

			it( "should get the form ID from the passed form item id if an item id is passed and no form id is passed", function(){
				var service = getService();
				var formId  = CreateUUId();
				var itemId  = CreateUUId();

				mockFormItemDao.$( "selectData" ).$args( id=itemId, selectFields=[ "form" ] ).$results( QueryNew( 'form', 'varchar', [[formId]] ) );
				mockFormDao.$( "dataExists" ).$args( filter={ id=formId, locked=true } ).$results( true );

				expect( service.isFormLocked( itemId=itemId ) ).toBeTrue();
			} );

		} );

		describe( "isFormActive", function(){

			it( "should return false when the given form is set to inactive", function(){
				var service    = getService();
				var formId     = CreateUUId();
				var formRecord = QueryNew( 'active,active_from,active_to', 'boolean,date,date', [[false,NullValue(),NullValue()]]);

				service.$( "getForm" ).$args( id=formId ).$results( formRecord );

				expect( service.isFormActive( formId ) ).toBe( false );
			} );

			it( "should return true when the given form is set to active and no active_from / active_to dates are set", function(){
				var service    = getService();
				var formId     = CreateUUId();
				var formRecord = QueryNew( 'active,active_from,active_to', 'boolean,date,date', [[true,NullValue(),NullValue()]]);

				service.$( "getForm" ).$args( id=formId ).$results( formRecord );

				expect( service.isFormActive( formId ) ).toBe( true );
			} );

			it( "should return false when the given form is set to active but the active_from date is in the future", function(){
				var service    = getService();
				var formId     = CreateUUId();
				var activeFrom = DateAdd( 'd', 1, Now() );
				var formRecord = QueryNew( 'active,active_from,active_to', 'boolean,date,date', [[true,activeFrom,NullValue()]]);

				service.$( "getForm" ).$args( id=formId ).$results( formRecord );

				expect( service.isFormActive( formId ) ).toBe( false );
			} );

			it( "should return false when the given form is set to active but the active_to date is in the past", function(){
				var service    = getService();
				var formId     = CreateUUId();
				var activeTo   = DateAdd( 'd', -1, Now() );
				var formRecord = QueryNew( 'active,active_from,active_to', 'boolean,date,date', [[true,NullValue(),activeTo]]);

				service.$( "getForm" ).$args( id=formId ).$results( formRecord );

				expect( service.isFormActive( formId ) ).toBe( false );
			} );

			it( "should return true when the given form is set to active and the current date falls between the active_from and active_to dates (when set)", function(){
				var service    = getService();
				var formId     = CreateUUId();
				var activeTo   = DateAdd( 'd', 1, Now() );
				var activeFrom = DateAdd( 'd', -1, Now() );
				var formRecord = QueryNew( 'active,active_from,active_to', 'boolean,date,date', [[true,activeFrom,activeTo]]);

				service.$( "getForm" ).$args( id=formId ).$results( formRecord );

				expect( service.isFormActive( formId ) ).toBe( true );
			} );

		} );

		describe( "renderFormItem", function(){
			it( "should render the given item's type viewlet with the supplied data args", function(){
				var service         = getService();
				var itemType        = "anItemType";
				var itemTypeViewlet = "some.viewlet." & CreateUUId();
				var rendered        = CreateUUId();
				var configuration   = { test="true", maxSomething=10 };

				mockRenderingService.$( "getItemTypeViewlet" ).$args( itemType=itemType ).$results( itemTypeViewlet );
				service.$( "$renderViewlet" ).$args( event=itemTypeViewlet, args=configuration ).$results( rendered );

				expect( service.renderFormItem( itemType=itemType, configuration=configuration ) ).toBe( rendered );
			} );

			it( "should return a rendered form item layout that is passed item configuration along with rendered item as 'body' argument, when configuration specifies a 'layout'", function(){
				var service            = getService();
				var itemType           = "anItemType";
				var itemTypeViewlet    = "some.viewlet." & CreateUUId();
				var layoutViewlet      = "some.layout." & CreateUUId();
				var renderedItem       = CreateUUId();
				var renderedLayout     = CreateUUId();
				var configuration      = { test="true", maxSomething=10, layout="somelayout" };
				var expectedLayoutArgs = Duplicate( configuration );

				expectedLayoutArgs.renderedItem = renderedItem;

				mockRenderingService.$( "getItemTypeViewlet" ).$args( itemType=itemType ).$results( itemTypeViewlet );
				mockRenderingService.$( "getFormFieldLayoutViewlet" ).$args( itemType=itemType, layout="somelayout" ).$results( layoutViewlet );
				service.$( "$renderViewlet" ).$args( event=itemTypeViewlet, args=configuration      ).$results( renderedItem );
				service.$( "$renderViewlet" ).$args( event=layoutViewlet, args=expectedLayoutArgs ).$results( renderedLayout );

				expect( service.renderFormItem( itemType=itemType, configuration=configuration ) ).toBe( renderedLayout );
			} );
		} );

		describe( "renderForm", function(){
			it( "should compile a form from rendering its saved items in order and rendering them within a core form layout and and finally the specified form layout", function(){
				var service            = getService();
				var formId             = CreateUUId();
				var formLayout         = "test";
				var formArgs           = { some="test", configuration=CreateUUId() };
				var formViewlet        = "formbuilder.layouts.form.test";
				var coreViewlet        = "formbuilder.layouts.core.form";
				var renderedCoreLayout = CreateUUId();
				var renderedFormLayout = CreateUUId();
				var renderedItems      = [ CreateUUId(), CreateUUId(), CreateUUId() ];
				var idPrefix           = "fb_" & CreateUUId() & "_";
				var formItems          = [{
					  id            = CreateUUId()
					, type          = { id="textinput" }
					, configuration = { test=true, something=CreateUUId(), name="test" }
				},{
					  id            = CreateUUId()
					, type          = { id="content" }
					, configuration = { body=CreateUUId(), name="blah" }
				},{
					  id            = CreateUUId()
					, type          = { id="textarea" }
					, configuration = { label="test", defaultvalue=CreateUUId(), name="blah2" }
				}];
				var formLayoutArgs = Duplicate( formArgs );
				var coreLayoutArgs = Duplicate( formArgs );

				coreLayoutArgs.renderedItems = renderedItems.toList( "" );
				coreLayoutArgs.id            = idPrefix;
				formLayoutArgs.renderedForm  = renderedCoreLayout;

				mockRenderingService.$( "getFormLayoutViewlet" ).$args( layout=formLayout ).$results( formViewlet );


				service.$( "_createIdPrefix", idPrefix );
				service.$( "getFormItems" ).$args( id=formId ).$results( formItems );
				for( var i=1; i<=formItems.len(); i++ ) {
					var item = formItems[ i ];
					var config = Duplicate( item.configuration );

					config.id = idPrefix & ( config.name ?: "" );
					service.$( "renderFormItem" ).$args(
						  itemType      = item.type.id
						, configuration = config
					).$results( renderedItems[ i ] );
				}
				service.$( "$renderViewlet" ).$args( event=coreViewlet, args=coreLayoutArgs ).$results( renderedCoreLayout );
				service.$( "$renderViewlet" ).$args( event=formViewlet, args=formLayoutArgs ).$results( renderedFormLayout );

				expect(
					service.renderForm(
						  formId        = formId
						, layout        = formLayout
						, configuration = formArgs
					)
				).toBe( renderedFormLayout );
			} );
		} );
	}

	private function getService() {
		variables.mockFormDao          = CreateStub();
		variables.mockFormItemDao      = CreateStub();
		variables.mockItemTypesService = CreateEmptyMock( "preside.system.services.formbuilder.FormBuilderItemTypesService" );
		variables.mockRenderingService = CreateEmptyMock( "preside.system.services.formbuilder.FormBuilderRenderingService" );
		variables.mockFormsService     = CreateEmptyMock( "preside.system.services.forms.FormsService" );
		variables.mockValidationEngine = CreateEmptyMock( "preside.system.services.validation.ValidationEngine" );

		var service = CreateMock( object=new preside.system.services.formbuilder.FormBuilderService(
			  itemTypesService            = mockItemTypesService
			, formBuilderRenderingService = mockRenderingService
			, formsService                = mockFormsService
			, validationEngine            = mockValidationEngine
		) );

		service.$( "$getPresideObject" ).$args( "formbuilder_form" ).$results( mockFormDao );
		service.$( "$getPresideObject" ).$args( "formbuilder_formitem" ).$results( mockFormItemDao );

		return service;
	}

}