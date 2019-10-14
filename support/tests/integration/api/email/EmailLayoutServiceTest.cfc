component extends="resources.HelperObjects.PresideBddTestCase" {

	function run() {

		describe( "listLayouts", function(){
			it( "should return an array of layouts derived from view and handler directories (base on convention, 'email.layout.(layoutid).html/text') including transated titles and descriptions based on i18n convention", function(){
				var service          = _getService();
				var expectedLayouts  = [ {
					  id           = "layout1"
					, title        = "Layout 1 title"
					, description  = "Layout 1 description"
					, configurable = false
				},{
					  id           = "layout2"
					, title        = "Layout 2 title here"
					, description  = "Layout 2 description here"
					, configurable = true
				},{
					  id           = "layout3"
					, title        = "Layout 3"
					, description  = "Layout 3 is cool"
					, configurable = false
				} ]

				for( var layout in expectedLayouts ) {
					service.$( "$translateResource" ).$args( uri="email.layout.#layout.id#:title"      , defaultValue=layout.id ).$results( layout.title       );
					service.$( "$translateResource" ).$args( uri="email.layout.#layout.id#:description", defaultValue=""        ).$results( layout.description );
					mockFormsService.$( "formExists" ).$args( "email.layout.#layout.id#" ).$results( layout.configurable );
				}

				expect( service.listLayouts() ).toBe( expectedLayouts );
			} );
		} );

		describe( "renderLayout", function() {
			it( "should call the layout's HTML viewlet (by convention), passing in supplied arguments combined with retrieved config for the layout/blueprint/email", function(){
				var service       = _getService();
				var layout        = "layout2";
				var emailTemplate = CreateUUId();
				var blueprint     = CreateUUId();
				var args          = { subject="Blah #CreateUUId()#", body=CreateUUId(), unsubscribeLink=CreateUUId(), viewOnlineLink=CreateUUId() };
				var dummyRendered = CreateUUId();
				var config        = { dummy=CreateUUId(), test=Now() };
				var argsPlusConfig = Duplicate( args );

				argsPlusConfig.append( config, false );

				service.$( "getLayoutConfig" ).$args( layout=layout, emailTemplate=emailTemplate, blueprint=blueprint, merged=true ).$results( config );
				service.$( "$renderViewlet" ).$args(
					  event = "email.layout.layout2.html"
					, args  = argsPlusConfig
				).$results( dummyRendered );

				var rendered = service.renderLayout(
					  argumentCollection = args
					, layout             = layout
					, emailTemplate      = emailTemplate
					, blueprint          = blueprint
					, type               = "html"
				);

				expect( rendered ).toBe( dummyRendered );
			} );

			it( "should call the layout's text viewlet (by convention), passing in supplied arguments", function(){
				var service       = _getService();
				var layout        = "layout2";
				var emailTemplate = CreateUUId();
				var blueprint     = CreateUUId();
				var args          = { subject="Blah #CreateUUId()#", body=CreateUUId(), unsubscribeLink=CreateUUId(), viewOnlineLink=CreateUUId() };
				var dummyRendered = CreateUUId();
				var config        = { dummy=CreateUUId(), test=Now() };
				var argsPlusConfig = Duplicate( args );

				argsPlusConfig.append( config, false );

				service.$( "getLayoutConfig" ).$args( layout=layout, emailTemplate=emailTemplate, blueprint=blueprint, merged=true ).$results( config );
				service.$( "$renderViewlet" ).$args(
					  event = "email.layout.layout2.text"
					, args  = argsPlusConfig
				).$results( dummyRendered );


				var rendered = service.renderLayout(
					  argumentCollection = args
					, layout             = layout
					, emailTemplate      = emailTemplate
					, blueprint          = blueprint
					, type               = "text"
				);

				expect( rendered ).toBe( dummyRendered );
			} );

			it( "should pass arbitrary arguments to the layout viewlet's args", function(){
				var service        = _getService();
				var layout         = "layout2";
				var emailTemplate  = CreateUUId();
				var blueprint      = CreateUUId();
				var dummyRendered  = CreateUUId();
				var args           = { subject="Blah #CreateUUId()#", body=CreateUUId(), unsubscribeLink=CreateUUId(), viewOnlineLink=CreateUUId(), test=CreateUUId() };
				var config         = { dummy=CreateUUId(), test=Now() };
				var argsPlusConfig = Duplicate( args );

				argsPlusConfig.append( config, false );

				service.$( "getLayoutConfig" ).$args( layout=layout, emailTemplate=emailTemplate, blueprint=blueprint, merged=true ).$results( config );
				service.$( "$renderViewlet" ).$args(
					  event = "email.layout.layout2.text"
					, args  = argsPlusConfig
				).$results( dummyRendered );


				var rendered = service.renderLayout(
					  argumentCollection = args
					, layout             = layout
					, emailTemplate      = emailTemplate
					, blueprint          = blueprint
					, type               = "text"
				);

				expect( rendered ).toBe( dummyRendered );
			} );

			it( "should pass keys from templateDetail argument into the layout viewlets args", function(){
				var service        = _getService();
				var layout         = "layout2";
				var emailTemplate  = CreateUUId();
				var blueprint      = CreateUUId();
				var dummyRendered  = CreateUUId();
				var templateDetail = { header_line=CreateUUid(), body=CreateUUId() }
				var args           = {
					  subject="Blah #CreateUUId()#"
					, body=CreateUUId()
					, unsubscribeLink=CreateUUId()
					, viewOnlineLink=CreateUUId()
					, test=CreateUUId()
				};
				var config         = { dummy=CreateUUId(), test=Now() };
				var argsPlusConfig = Duplicate( args );

				argsPlusConfig.append( config, false );
				argsPlusConfig.append( templateDetail, false );

				service.$( "getLayoutConfig" ).$args( layout=layout, emailTemplate=emailTemplate, blueprint=blueprint, merged=true ).$results( config );
				service.$( "$renderViewlet" ).$args(
					  event = "email.layout.layout2.text"
					, args  = argsPlusConfig
				).$results( dummyRendered );


				var rendered = service.renderLayout(
					  argumentCollection = args
					, layout             = layout
					, emailTemplate      = emailTemplate
					, templateDetail     = templateDetail
					, blueprint          = blueprint
					, type               = "text"
				);

				expect( rendered ).toBe( dummyRendered );
			} );
		} );

		describe( "getLayoutConfigFormName", function(){

			it( "should return the convention based form name when the form exists (i.e. 'email.layout.{layoutId}')", function(){
				var service  = _getService();
				var layout   = "layout1";
				var formName = "email.layout.layout1";

				mockFormsService.$( "formExists" ).$args( formName ).$results( true );

				expect( service.getLayoutConfigFormName( layout ) ).toBe( formName );
			} );

			it( "should return an empty string when the layout does not have a corresponding form", function(){
				var service  = _getService();
				var layout   = "layout1";
				var formName = "email.layout.layout1";

				mockFormsService.$( "formExists" ).$args( formName ).$results( false );

				expect( service.getLayoutConfigFormName( layout ) ).toBe( "" );
			} );

			it( "should return an empty string when the layout does not exist", function(){
				var service  = _getService();
				var layout   = CreateUUId();

				expect( service.getLayoutConfigFormName( layout ) ).toBe( "" );
			} );

		} );

		describe( "layoutExists", function(){
			it( "should return true when the layout is recognized by the system", function(){
				var service = _getService();

				expect( service.layoutExists( "layout1" ) ).toBe( true );
			} );

			it( "should return false when the layout is not recognized by the system", function(){
				var service = _getService();

				expect( service.layoutExists( CreateUUId() ) ).toBe( false );
			} );
		} );

		describe( "saveLayoutConfig", function(){

			it( "should insert a global (no email template ID) configuration record for each config item supplied after deleting any potential previously saved records", function(){
				var service = _getService();
				var layout  = "layout2";
				var config  = StructNew( "linked" );

				config.test   = CreateUUId();
				config.all    = "the";
				config.things = Now();

				mockConfigDao.$( "deleteData", 1 );
				mockConfigDao.$( "insertData", CreateUUId() );

				service.saveLayoutConfig(
					  layout = layout
					, config = config
				);

				expect( mockConfigDao.$callLog().deleteData.len() ).toBe( 1 );
				expect( mockConfigDao.$callLog().deleteData[1] ).toBe( { filter={ layout=layout, email_template="", email_blueprint="" } } );

				expect( mockConfigDao.$callLog().insertData.len() ).toBe( 3 );
				expect( mockConfigDao.$callLog().insertData[1] ).toBe( [ { layout=layout, email_template="", email_blueprint="", item="test"  , value=config.test   } ] );
				expect( mockConfigDao.$callLog().insertData[2] ).toBe( [ { layout=layout, email_template="", email_blueprint="", item="all"   , value=config.all    } ] );
				expect( mockConfigDao.$callLog().insertData[3] ).toBe( [ { layout=layout, email_template="", email_blueprint="", item="things", value=config.things } ] );
			} );

			it( "should insert an email specific configuration record for each config item supplied after deleting any potential previously saved records", function(){
				var service       = _getService();
				var layout        = "layout2";
				var emailTemplate = CreateUUId();
				var config        = StructNew( "linked" );

				config.test   = CreateUUId();
				config.all    = "the";
				config.things = Now();

				mockConfigDao.$( "deleteData", 1 );
				mockConfigDao.$( "insertData", CreateUUId() );

				service.saveLayoutConfig(
					  layout        = layout
					, emailTemplate = emailTemplate
					, config        = config
				);

				expect( mockConfigDao.$callLog().deleteData.len() ).toBe( 1 );
				expect( mockConfigDao.$callLog().deleteData[1] ).toBe( { filter={ layout=layout, email_template=emailTemplate, email_blueprint="" } } );

				expect( mockConfigDao.$callLog().insertData.len() ).toBe( 3 );
				expect( mockConfigDao.$callLog().insertData[1] ).toBe( [ { layout=layout, email_template=emailTemplate, email_blueprint="", item="test"  , value=config.test   } ] );
				expect( mockConfigDao.$callLog().insertData[2] ).toBe( [ { layout=layout, email_template=emailTemplate, email_blueprint="", item="all"   , value=config.all    } ] );
				expect( mockConfigDao.$callLog().insertData[3] ).toBe( [ { layout=layout, email_template=emailTemplate, email_blueprint="", item="things", value=config.things } ] );
			} );

			it( "should insert a blueprint specific configuration record for each config item supplied after deleting any potential previously saved records", function(){
				var service   = _getService();
				var layout    = "layout2";
				var blueprint = CreateUUId();
				var config    = StructNew( "linked" );

				config.test   = CreateUUId();
				config.all    = "the";
				config.things = Now();

				mockConfigDao.$( "deleteData", 1 );
				mockConfigDao.$( "insertData", CreateUUId() );

				service.saveLayoutConfig(
					  layout    = layout
					, blueprint = blueprint
					, config    = config
				);

				expect( mockConfigDao.$callLog().deleteData.len() ).toBe( 1 );
				expect( mockConfigDao.$callLog().deleteData[1] ).toBe( { filter={ layout=layout, email_blueprint=blueprint, email_template="" } } );

				expect( mockConfigDao.$callLog().insertData.len() ).toBe( 3 );
				expect( mockConfigDao.$callLog().insertData[1] ).toBe( [ { layout=layout, email_template="", email_blueprint=blueprint, item="test"  , value=config.test   } ] );
				expect( mockConfigDao.$callLog().insertData[2] ).toBe( [ { layout=layout, email_template="", email_blueprint=blueprint, item="all"   , value=config.all    } ] );
				expect( mockConfigDao.$callLog().insertData[3] ).toBe( [ { layout=layout, email_template="", email_blueprint=blueprint, item="things", value=config.things } ] );
			} );

		} );

		describe( "getLayoutConfig", function(){
			it( "should return all the globally saved configuration items for the layout in a struct, when no email template or blueprint supplied", function(){
				var service       = _getService();
				var layout        = "layout3";
				var mockDbRecords = QueryNew( 'item,value', 'varchar,varchar', [["test",CreateUUId()],["data",CreateUUId()],["fun",Now()]] );
				var expected      = {};

				for( var record in mockDbRecords ) {
					expected[ record.item ] = record.value;
				}

				mockConfigDao.$( "selectData" ).$args(
					  filter       = { layout=layout, email_template="", email_blueprint="" }
					, selectFields = [ "item", "value" ]
				).$results( mockDbRecords );

				expect( service.getLayoutConfig( layout ) ).toBe( expected );
			} );

			it( "should return email template specific configuration when email template ID supplied", function(){
				var service       = _getService();
				var layout        = "layout3";
				var emailTemplate = CreateUUId();
				var mockDbRecords = QueryNew( 'item,value', 'varchar,varchar', [["test",CreateUUId()],["data",CreateUUId()],["fun",Now()]] );
				var expected      = {};

				for( var record in mockDbRecords ) {
					expected[ record.item ] = record.value;
				}

				mockConfigDao.$( "selectData" ).$args(
					  filter       = { layout=layout, email_template=emailTemplate, email_blueprint="" }
					, selectFields = [ "item", "value" ]
				).$results( mockDbRecords );

				expect( service.getLayoutConfig( layout, emailTemplate ) ).toBe( expected );
			} );

			it( "should return email blueprint specific configuration when email blueprint ID supplied", function(){
				var service       = _getService();
				var layout        = "layout3";
				var blueprint     = CreateUUId();
				var mockDbRecords = QueryNew( 'item,value', 'varchar,varchar', [["test",CreateUUId()],["data",CreateUUId()],["fun",Now()]] );
				var expected      = {};

				for( var record in mockDbRecords ) {
					expected[ record.item ] = record.value;
				}

				mockConfigDao.$( "selectData" ).$args(
					  filter       = { layout=layout, email_template="", email_blueprint=blueprint }
					, selectFields = [ "item", "value" ]
				).$results( mockDbRecords );

				expect( service.getLayoutConfig( layout=layout, blueprint=blueprint ) ).toBe( expected );
			} );

			it( "should return a merged set of global, email template and blueprint specific configuration when email template ID supplied and merge set to true", function(){
				var service                = _getService();
				var layout                 = "layout3";
				var emailTemplate          = CreateUUId();
				var blueprint              = CreateUUId();
				var mockSpecificDbRecords  = QueryNew( 'item,value', 'varchar,varchar', [["test",CreateUUId()],["data",CreateUUId()],["fun",Now()]] );
				var mockBlueprintDbRecords = QueryNew( 'item,value', 'varchar,varchar', [["test",CreateUUId()],["data",CreateUUId()],["new",Now()],["interesting",CreateUUId()]] );
				var mockGlobalDbRecords    = QueryNew( 'item,value', 'varchar,varchar', [["test",CreateUUId()],["fun",Now()],["boo","hoo"],["interesting","stuff"]] );
				var expected               = {};

				for( var record in mockGlobalDbRecords ) {
					expected[ record.item ] = record.value;
				}
				for( var record in mockBlueprintDbRecords ) {
					expected[ record.item ] = record.value;
				}
				for( var record in mockSpecificDbRecords ) {
					expected[ record.item ] = record.value;
				}

				mockConfigDao.$( "selectData" ).$args(
					  filter       = { layout=layout, email_template=emailTemplate, email_blueprint="" }
					, selectFields = [ "item", "value" ]
				).$results( mockSpecificDbRecords );
				mockConfigDao.$( "selectData" ).$args(
					  filter       = { layout=layout, email_template="", email_blueprint=blueprint }
					, selectFields = [ "item", "value" ]
				).$results( mockBlueprintDbRecords );
				mockConfigDao.$( "selectData" ).$args(
					  filter       = { layout=layout, email_template="", email_blueprint="" }
					, selectFields = [ "item", "value" ]
				).$results( mockGlobalDbRecords );

				expect( service.getLayoutConfig( layout=layout, emailTemplate=emailTemplate, blueprint=blueprint, merged=true ) ).toBe( expected );
			} );
		} );

	}

	private any function _getService(
		array layoutViewlets=_getDefaultLayoutViewlets()
	){
		variables.mockViewletsService = createEmptyMock( "preside.system.services.viewlets.ViewletsService" );
		variables.mockFormsService    = createEmptyMock( "preside.system.services.forms.FormsService" );
		variables.mockConfigDao       = createStub();

		mockViewletsService.$( "listPossibleViewlets" ).$args( filter="email\.layout\.(.*?)\.(html|text)" ).$results( layoutViewlets );

		var service = createMock( object=new preside.system.services.email.EmailLayoutService(
			  viewletsService = mockViewletsService
			, formsService    = mockFormsService
		) );

		service.$( "$getPresideObject" ).$args( "email_layout_config_item" ).$results( mockConfigDao );
		service.$( "$announceInterception" );

		return service;
	}

	private array function _getDefaultLayoutViewlets() {
		return [
			  "email.layout.layout1.html"
			, "email.layout.layout1.text"
			, "email.layout.layout2.html"
			, "email.layout.layout2.text"
			, "email.layout.layout3.html"
			, "email.layout.layout3.text"
		];
	}
}