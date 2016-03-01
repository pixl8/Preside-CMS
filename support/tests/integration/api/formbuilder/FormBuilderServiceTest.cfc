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

				mockRenderingService.$( "getItemTypeViewlet" ).$args( itemType=itemType, context="input" ).$results( itemTypeViewlet );
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

				mockRenderingService.$( "getItemTypeViewlet" ).$args( itemType=itemType, context="input" ).$results( itemTypeViewlet );
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
				var coreViewlet        = "formbuilder.core.formLayout";
				var renderedCoreLayout = CreateUUId();
				var renderedFormLayout = CreateUUId();
				var renderedItems      = [ CreateUUId(), CreateUUId(), CreateUUId() ];
				var idPrefix           = "fb_" & CreateUUId() & "_";
				var formConfiguration  = QueryNew('test', 'varchar', [[CreateUUId()]] );
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
				coreLayoutArgs.formItems     = formItems;
				coreLayoutArgs.configuration = { test=formConfiguration.test };
				formLayoutArgs.renderedForm  = renderedCoreLayout;

				mockRenderingService.$( "getFormLayoutViewlet" ).$args( layout=formLayout ).$results( formViewlet );


				service.$( "_createIdPrefix", idPrefix );
				service.$( "getFormItems" ).$args( id=formId ).$results( formItems );
				service.$( "getForm" ).$args( id=formId ).$results( formConfiguration );
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

		describe( "getSubmissionSuccessMessage", function(){
			it( "should return the 'form_submitted_message' for the given form ID", function(){
				var service        = getService();
				var formId         = CreateUUId();
				var successMessage = "Test success message" & CreateUUId();
				var dbRecord       = QueryNew( 'form_submitted_message', 'varchar', [ [ successMessage ] ] );

				mockFormDao.$( "selectData" ).$args(
					  id           = formId
					, selectFields = [ "form_submitted_message" ]
				).$results( dbRecord );

				expect( service.getSubmissionSuccessMessage( formId ) ).toBe( successMessage );
			} );

			it( "should return an empty string when no db records found for the given ID", function(){
				var service        = getService();
				var formId         = CreateUUId();
				var dbRecord       = QueryNew( 'form_submitted_message' );

				mockFormDao.$( "selectData" ).$args(
					  id           = formId
					, selectFields = [ "form_submitted_message" ]
				).$results( dbRecord );

				expect( service.getSubmissionSuccessMessage( formId ) ).toBe( "" );
			} );

			it( "should return an empty string and not attempt DB lookup when passed formId is empty string", function(){
				var service        = getService();
				var formId         = "";
				var dbRecord       = QueryNew( 'form_submitted_message' );

				mockFormDao.$( "selectData" );

				expect( service.getSubmissionSuccessMessage( formId ) ).toBe( "" );
				expect( mockFormDao.$callLog().selectData.len() ).toBe( 0 );
			} );
		} );

		describe( "getRequestDataForForm", function(){
			it(  "should return a structure of data that contains only the relevent fields for the given form, given a struct containing an entire requests request params", function(){
				var service        = getService();
				var formId         = CreateUUId();
				var items          = [{
					  type          = { isFormField=false, id="type1" }
					, configuration = { name="test1" }
				},{
					  type          = { isFormField=true , id="type2" }
					, configuration = { name="test2" }
				},{
					  type          = { isFormField=true , id="type3" }
					, configuration = { name="test3" }
				},{
					  type          = { isFormField=true , id="type4" }
					, configuration = { name="test4" }
				}];
				var input          = { yes=false, no=true, test1=CreateUUId(), test2="nice", test4=CreateUUId() };
				var processed      = { test2=CreateUUId(), test4={ complex=true, test=CreateUUId() } }
				var expectedOutput = { test2=processed.test2, test4=processed.test4 };

				service.$( "getFormItems" ).$args( id=formId ).$results( items );
				service.$( "getItemDataFromRequest" ).$args( itemType="type2", inputName="test2", requestData=input, itemConfiguration=items[2].configuration ).$results( processed.test2 );
				service.$( "getItemDataFromRequest" ).$args( itemType="type3", inputName="test3", requestData=input, itemConfiguration=items[3].configuration ).$results( NullValue() );
				service.$( "getItemDataFromRequest" ).$args( itemType="type4", inputName="test4", requestData=input, itemConfiguration=items[4].configuration ).$results( processed.test4 );

				expect(
					service.getRequestDataForForm(
						  formId      = formId
						, requestData = input
					)
				).toBe( expectedOutput );
			} );
		} );

		describe( "saveFormSubmission", function(){
			it( "should return validation result without taking any action when validation failed", function(){
				var service            = getService();
				var formId             = CreateUUId();
				var requestData        = { some="data" };
				var formSubmissionData = { some="data", tests=CreateUUId() };
				var formItems          = [ "just", "test", "data" ];
				var formConfiguration  = QueryNew( 'use_captcha', "boolean", [ [ true ] ] );
				var validationResult   = CreateEmptyMock( "preside.system.services.validation.ValidationResult" );

				service.$( "getRequestDataForForm" ).$args(
					  formId      = formId
					, requestData = requestData
				).$results( formSubmissionData );
				service.$( "getFormItems" ).$args( id = formId ).$results( formItems );
				service.$( "getForm" ).$args( id = formId ).$results( formConfiguration );
				service.$( "getSubmission", QueryNew('') );
				mockFormBuilderValidationService.$( "validateFormSubmission" ).$args(
					  formItems      = formItems
					, submissionData = formSubmissionData
				).$results( validationResult );
				validationResult.$( "validated", false );
				mockFormSubmissionDao.$( "insertData", "" );
				mockActionsService.$( "triggerSubmissionActions" );

				expect( service.saveFormSubmission(
					  formId      = formId
					, requestData = requestData
				) ).toBe( validationResult );

				expect( mockFormSubmissionDao.$callLog().insertData.len() ).toBe( 0 );
			} );

			it( "should save submission data to a form builder submission object when validation passes", function(){
				var service            = getService();
				var formId             = CreateUUId();
				var requestData        = { some="data" };
				var formSubmissionData = { some="data", tests=CreateUUId() };
				var formConfiguration  = QueryNew( 'use_captcha', "boolean", [ [ true ] ] );
				var formItems          = [ "just", "test", "data" ];
				var validationResult   = CreateEmptyMock( "preside.system.services.validation.ValidationResult" );
				var userAgent          = CreateUUId();
				var ipAddress          = "219.349.93.4";
				var instanceId         = "TEST" & CreateUUId();
				var userid             = CreateUUId();

				service.$( "renderResponsesForSaving", formSubmissionData );
				service.$( "getRequestDataForForm" ).$args(
					  formId      = formId
					, requestData = requestData
				).$results( formSubmissionData );
				service.$( "getForm" ).$args( id = formId ).$results( formConfiguration );
				service.$( "getFormItems" ).$args( id = formId ).$results( formItems );
				service.$( "getSubmission", QueryNew('') );
				mockFormBuilderValidationService.$( "validateFormSubmission" ).$args(
					  formItems      = formItems
					, submissionData = formSubmissionData
				).$results( validationResult );
				validationResult.$( "validated", true );
				mockFormSubmissionDao.$( "insertData", CreateUUId() );
				service.$( "$getWebsiteLoggedInUserId", userId );
				mockActionsService.$( "triggerSubmissionActions" );

				expect( service.saveFormSubmission(
					  formId      = formId
					, requestData = requestData
					, instanceId  = instanceId
					, ipAddress   = ipAddress
					, userAgent   = userAgent
				) ).toBe( validationResult );

				expect( mockFormSubmissionDao.$callLog().insertData.len() ).toBe( 1 );
				expect( mockFormSubmissionDao.$callLog().insertData[1] ).toBe( { data={
					  form           = formId
					, submitted_by   = userId
					, form_instance  = instanceId
					, ip_address     = ipAddress
					, user_agent     = userAgent
					, submitted_data = SerializeJson( formSubmissionData )
				} } );
			} );

			it( "should call triggerSubmissionActions() on the actions service", function(){
				var service            = getService();
				var formId             = CreateUUId();
				var requestData        = { some="data" };
				var formSubmissionData = { some="data", tests=CreateUUId() };
				var formConfiguration  = QueryNew( 'use_captcha', "boolean", [ [ true ] ] );
				var formItems          = [ "just", "test", "data" ];
				var validationResult   = CreateEmptyMock( "preside.system.services.validation.ValidationResult" );
				var userAgent          = CreateUUId();
				var ipAddress          = "219.349.93.4";
				var instanceId         = "TEST" & CreateUUId();
				var userid             = CreateUUId();
				var newSubmissionId    = CreateUUId();
				var savedSubmission    = QueryNew( 'test,me', 'varchar,varchar', [[CreateUUId(),CreateUUId()]] );

				service.$( "getRequestDataForForm" ).$args(
					  formId      = formId
					, requestData = requestData
				).$results( formSubmissionData );
				service.$( "renderResponsesForSaving", formSubmissionData );
				service.$( "getForm" ).$args( id = formId ).$results( formConfiguration );
				service.$( "getFormItems" ).$args( id = formId ).$results( formItems );
				service.$( "getSubmission" ).$args( newSubmissionId ).$results( savedSubmission );
				mockFormBuilderValidationService.$( "validateFormSubmission" ).$args(
					  formItems      = formItems
					, submissionData = formSubmissionData
				).$results( validationResult );
				validationResult.$( "validated", true );
				mockFormSubmissionDao.$( "insertData", newSubmissionId );
				service.$( "$getWebsiteLoggedInUserId", userId );
				mockActionsService.$( "triggerSubmissionActions" );

				service.saveFormSubmission(
					  formId      = formId
					, requestData = requestData
					, instanceId  = instanceId
					, ipAddress   = ipAddress
					, userAgent   = userAgent
				);

				expect( mockActionsService.$callLog().triggerSubmissionActions.len() ).toBe( 1 );
				expect( mockActionsService.$callLog().triggerSubmissionActions[1] ).toBe({
					  formId         = formId
					, submissionData = { test=savedSubmission.test, me=savedSubmission.me }
				});
			} );
		} );

		describe( "getSubmissionCount", function(){
			it( "should return the number of submissions for the given form", function(){
				var service       = getService();
				var formId        = CreateUUId();
				var responseCount = 453;
				var queryResult   = QueryNew( "submission_count", "int", [ [ responseCount ] ] );

				mockFormSubmissionDao.$( "selectData" ).$args(
					  filter       = { form=formId }
					, selectFields = [ "Count( id ) as submission_count" ]
				).$results( queryResult );

				expect( service.getSubmissionCount( formId=formId ) ).toBe( responseCount );
			} );
		} );

		describe( "getItemByInputName", function(){
			it( "should return the form item that matches on input name", function(){
				var service = getService();
				var formId  = CreateUUId();
				var names   = [ CreateUUId(), CreateUUId(),CreateUUId(),CreateUUId(),CreateUUId() ];
				var name    = names[4];
				var items   = [
					  { type={ isFormField=true }, configuration={ name=names[ 1 ] } }
					, { type={ isFormField=true }, configuration={ name=names[ 2 ] } }
					, { type={ isFormField=true }, configuration={ name=names[ 3 ] } }
					, { type={ isFormField=true }, configuration={ name=names[ 4 ] } }
					, { type={ isFormField=true }, configuration={ name=names[ 5 ] } }
				];

				service.$( "getFormItems" ).$args( formId ).$results( items );
				expect( service.getItemByInputName( formId, name ) ).toBe( items[ 4 ] );
			} );

			it( "should return and empty struct when no item found", function(){
				var service = getService();
				var formId  = CreateUUId();
				var names   = [ CreateUUId(), CreateUUId(),CreateUUId(),CreateUUId(),CreateUUId() ];
				var name    = CreateUUId();
				var items   = [
					  { type={ isFormField=true }, configuration={ name=names[ 1 ] } }
					, { type={ isFormField=true }, configuration={ name=names[ 2 ] } }
					, { type={ isFormField=true }, configuration={ name=names[ 3 ] } }
					, { type={ isFormField=true }, configuration={ name=names[ 4 ] } }
					, { type={ isFormField=true }, configuration={ name=names[ 5 ] } }
				];

				service.$( "getFormItems" ).$args( formId ).$results( items );
				expect( service.getItemByInputName( formId, name ) ).toBe( {} );
			} );
		} );

		describe( "renderResponse", function(){

			it( "should render the given item's type response viewlet with the supplied data args", function(){
				var service         = getService();
				var formId          = CreateUUId();
				var inputName       = CreateUUId();
				var inputValue      = CreateUUId();
				var matchingItem    = { type={ id="someType", isFormField=true }, configuration={ name=inputName, label="hello", test=CreateUUId() } };
				var itemTypeViewlet = "some.viewlet." & CreateUUId();
				var expectedResult  = CreateUUId();
				var renderArgs      = { response=inputValue, itemConfiguration=matchingItem.configuration };

				mockRenderingService.$( "getItemTypeViewlet" ).$args( itemType=matchingItem.type.id, context="response" ).$results( itemTypeViewlet );
				service.$( "getItemByInputName" ).$args( formId=formId, inputName=inputName ).$results( matchingItem );
				service.$( "$renderViewlet" ).$args( event=itemTypeViewlet, args=renderArgs ).$results( expectedResult );

				var rendered = service.renderResponse(
					  formId     = formId
					, inputName  = inputName
					, inputValue = inputValue
				);

				expect( rendered ).toBe( expectedResult );
			} );

			it( "should return the inputValue unadulterated when a corresponding item could not be found", function(){
				var service         = getService();
				var formId          = CreateUUId();
				var inputName       = CreateUUId();
				var inputValue      = CreateUUId();
				var matchingItem    = {};

				service.$( "getItemByInputName" ).$args( formId=formId, inputName=inputName ).$results( matchingItem );

				var rendered = service.renderResponse(
					  formId     = formId
					, inputName  = inputName
					, inputValue = inputValue
				);

				expect( rendered ).toBe( inputValue );
			} );

		} );

		describe( "deleteSubmissions", function(){
			it( "should delete the passed submissions from the database", function(){
				var service = getService();
				var submissionIds = [ CreateUUId(), CreateUUId(), CreateUUId() ];

				mockFormSubmissionDao.$( "deleteData" ).$args( filter={ id=submissionIds } ).$results( 3 );

				expect( service.deleteSubmissions( submissionIds ) ).toBe( 3 );
				expect( mockFormSubmissionDao.$callLog().deleteData.len() ).toBe( 1 );
				expect( mockFormSubmissionDao.$callLog().deleteData[ 1 ] ).toBe( { filter={ id=submissionIds } } );
			} );
		} );

		describe( "getItemDataFromRequest", function(){

			it( "it should return result of preprocessing handler, when a preprocessing handler exists for the given item type", function(){
				var service     = getService();
				var itemType    = "test";
				var inputName   = "stuffs";
				var requestData = { test=CreateUUId(), something=false };
				var handlerName = "formbuilder.item-types.#itemType#.getItemDataFromRequest";
				var config      = { test=CreateUUId() };
				var result      = CreateUUId();

				mockColdbox.$( "handlerExists" ).$args( handlerName ).$results( true );
				mockColdbox.$( "runEvent"      ).$args(
					  event          = handlerName
					, private        = true
					, prepostExempt  = true
					, eventArguments = { args={ inputName=inputName, requestData=requestData, itemConfiguration=config } }
				).$results( result );

				expect(
					service.getItemDataFromRequest(
						  itemType          = itemType
						, inputName         = inputName
						, requestData       = requestData
						, itemConfiguration = config
					)
				).toBe( result );
			} );

			it( "should return the value of the matching key in the request data for the given input name when there is no preprocessing handler for the item type", function(){
				var service     = getService();
				var itemType    = "test";
				var inputName   = "test";
				var requestData = { test=CreateUUId(), something=false };
				var config      = { test=CreateUUId() };
				var handlerName = "formbuilder.item-types.#itemType#.getItemDataFromRequest";

				mockColdbox.$( "handlerExists" ).$args( handlerName ).$results( false );

				expect(
					service.getItemDataFromRequest(
						  itemType    = itemType
						, inputName   = inputName
						, requestData = requestData
						, itemConfiguration = config
					)
				).toBe( requestData[ inputName ] );
			} );

			it( "should return NULL when the item does not exist in the request data and there is no preprocessing handler for the item either	", function(){
				var service     = getService();
				var itemType    = "test";
				var inputName   = "whateverthisisatest";
				var requestData = { test=CreateUUId(), something=false };
				var config      = { test=CreateUUId() };
				var handlerName = "formbuilder.item-types.#itemType#.getItemDataFromRequest";

				mockColdbox.$( "handlerExists" ).$args( handlerName ).$results( false );

				expect(
					service.getItemDataFromRequest(
						  itemType    = itemType
						, inputName   = inputName
						, requestData = requestData
						, itemConfiguration = config
					)
				).toBeNull();
			} );

		} );
	}

	private function getService() {
		variables.mockFormDao                      = CreateStub();
		variables.mockFormItemDao                  = CreateStub();
		variables.mockFormSubmissionDao            = CreateStub();
		variables.mockColdbox                      = CreateStub();
		variables.mockSpreadsheetLib               = CreateStub();
		variables.mockActionsService               = CreateEmptyMock( "preside.system.services.formbuilder.FormBuilderActionsService" );
		variables.mockItemTypesService             = CreateEmptyMock( "preside.system.services.formbuilder.FormBuilderItemTypesService" );
		variables.mockRenderingService             = CreateEmptyMock( "preside.system.services.formbuilder.FormBuilderRenderingService" );
		variables.mockFormsService                 = CreateEmptyMock( "preside.system.services.forms.FormsService" );
		variables.mockValidationEngine             = CreateEmptyMock( "preside.system.services.validation.ValidationEngine" );
		variables.mockFormBuilderValidationService = CreateEmptyMock( "preside.system.services.formbuilder.FormBuilderValidationService" );
		variables.mockRecaptchaService             = CreateEmptyMock( "preside.system.services.formbuilder.RecaptchaService" );

		var service = CreateMock( object=new preside.system.services.formbuilder.FormBuilderService(
			  itemTypesService             = mockItemTypesService
			, actionsService               = mockActionsService
			, formBuilderRenderingService  = mockRenderingService
			, formsService                 = mockFormsService
			, formBuilderValidationService = mockFormBuilderValidationService
			, validationEngine             = mockValidationEngine
			, spreadsheetLib               = mockSpreadsheetLib
			, recaptchaService             = mockRecaptchaService
		) );

		service.$( "$getPresideObject" ).$args( "formbuilder_form" ).$results( mockFormDao );
		service.$( "$getPresideObject" ).$args( "formbuilder_formitem" ).$results( mockFormItemDao );
		service.$( "$getPresideObject" ).$args( "formbuilder_formsubmission" ).$results( mockFormSubmissionDao );
		service.$( "$getColdbox", mockColdbox );
		service.$( "$announceInterception" );

		mockRecaptchaService.$( "validate", true );

		return service;
	}

}