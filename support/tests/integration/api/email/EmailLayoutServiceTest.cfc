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
			it( "should call the layout's HTML viewlet (by convention), passing in supplied arguments", function(){
				var service       = _getService();
				var args          = { subject="Blah #CreateUUId()#", body=CreateUUId(), unsubscribeLink=CreateUUId(), viewOnlineLink=CreateUUId() };
				var dummyRendered = CreateUUId();

				service.$( "$renderViewlet" ).$args(
					  event = "email.layout.layout2.html"
					, args  = args
				).$results( dummyRendered );


				var rendered = service.renderLayout(
					  argumentCollection = args
					, layout             = "layout2"
					, type               = "html"
				);

				expect( rendered ).toBe( dummyRendered );
			} );

			it( "should call the layout's text viewlet (by convention), passing in supplied arguments", function(){
				var service       = _getService();
				var args          = { subject="Blah #CreateUUId()#", body=CreateUUId(), unsubscribeLink=CreateUUId(), viewOnlineLink=CreateUUId() };
				var dummyRendered = CreateUUId();

				service.$( "$renderViewlet" ).$args(
					  event = "email.layout.layout2.text"
					, args  = args
				).$results( dummyRendered );


				var rendered = service.renderLayout(
					  argumentCollection = args
					, layout             = "layout2"
					, type               = "text"
				);

				expect( rendered ).toBe( dummyRendered );
			} );

			it( "should pass arbitrary arguments to the layout viewlet's args", function(){
				var service       = _getService();
				var args          = { subject="Blah #CreateUUId()#", body=CreateUUId(), unsubscribeLink=CreateUUId(), viewOnlineLink=CreateUUId(), test=CreateUUId() };
				var dummyRendered = CreateUUId();

				service.$( "$renderViewlet" ).$args(
					  event = "email.layout.layout2.text"
					, args  = args
				).$results( dummyRendered );


				var rendered = service.renderLayout(
					  argumentCollection = args
					, layout             = "layout2"
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

	}

	private any function _getService(
		array layoutViewlets=_getDefaultLayoutViewlets()
	){
		variables.mockViewletsService = createEmptyMock( "preside.system.services.viewlets.ViewletsService" );
		variables.mockFormsService    = createEmptyMock( "preside.system.services.forms.FormsService" );

		mockViewletsService.$( "listPossibleViewlets" ).$args( filter="email\.layout\.(.*?)\.(html|text)" ).$results( layoutViewlets );

		var service = createMock( object=new preside.system.services.email.EmailLayoutService(
			  viewletsService = mockViewletsService
			, formsService    = mockFormsService
		) );

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