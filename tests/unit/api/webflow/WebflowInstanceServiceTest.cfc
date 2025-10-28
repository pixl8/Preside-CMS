component extends="testbox.system.BaseSpec" {

	function run() {
		describe( "Webflow instance service", function() {
			beforeEach( function(){
				_webflowLibrary    = CreateEmptyMock( "preside.system.services.webflow.spec.WebflowSpecLibrary" );
				_configService     = CreateEmptyMock( "preside.system.services.webflow.WebflowConfigurationService" );
				_presideStorage    = CreateStub();
				_visitorService    = CreateStub();
				_cookieService     = CreateStub();
				_mockColdbox       = CreateStub();
				_mockCfFlow        = CreateStub();
				_mockCfFlowFactory = CreateStub();

				_svc = CreateMock( object=new preside.system.services.webflow.WebflowInstanceService(
					  webflowLibrary        = _webflowLibrary
					, webflowConfigurator   = _configService
					, cookieService         = _cookieService
					, websiteVisitorService = _visitorService
					, cfflow                = _mockCfFlow
					, cfFlowFactory         = _mockCfFlowFactory
					, cfFlowPresideStorage  = _presideStorage
				) );

				_svc.$( "$getColdbox", _mockColdbox );
				_svc.$( "$runEvent" );
				_mockColdbox.$( "handlerExists", true );
			} );

			describe( "getDefaultOwner()", function(){
				it( "should return the logged in user ID if a user is logged in", function(){
					var userId = CreateUUId();
					_svc.$( "$getWebsiteLoggedInUserId", userId );
					_cookieService.$( "getVar" ).$args( name="vid", default="" ).$results( "" );

					expect( _svc.getDefaultOwner() ).toBe( userId );
				} );

				it( "should return value from vid cookie if user not logged in", function(){
					var vid = CreateUUId();

					_svc.$( "$getWebsiteLoggedInUserId", "" );
					_cookieService.$( "getVar" ).$args( name="vid", default="" ).$results( vid );

					expect( _svc.getDefaultOwner() ).toBe( vid );

				} );
			} );

			describe( "getInstanceArgs( webflowId, instanceRef, subReference, explicitArgs )", function(){
				beforeEach( function() {
					_webflowId    = CreateUUId();
					_instanceRef  = CreateUUId();
					_subReference = CreateUUId();
					_webflow      = CreateMock( object=new preside.system.services.webflow.spec.Webflow() );

					_webflow.setId( _webflowId );

					_webflowLibrary.$( "getWebflow" ).$args( _webflowId ).$results( _webflow );
				} );

				it( "should should combine explicitly passed args with args hard coded in the webflow definition and any args passed back by defined instanceArgs handler", function(){
					var explicit = { reference=CreateUUId(), unique=true };
					var eventBegottenArgs = { reference=CreateUUId(), subreference=false, owner=CreateUUId() };
					var flowConfig = { some="config" };
					var init = {
						instanceargs = {
							  args    = { reference=CreateUUId(), subreference=true }
							, handler = { event="test.handler" }
						}
					};

					_webflow.setInit( init );
					_configService.$( "getFlowConfig" ).$args( webflowId=_webflowId, instanceRef=_instanceRef ).$results( flowConfig );

					var instanceArgsForHandler = {};
					StructAppend( instanceArgsForHandler, init.instanceArgs.args );

					_svc.$( "$runEvent" ).$args(
						  event = init.instanceArgs.handler.event
						, private = true
						, prePostExempt = true
						, eventArguments = {
							  instanceArgs = instanceArgsForHandler
							, config       = flowConfig
							, webflowId    = _webflowId
							, instanceRef  = _instanceRef
							, args         = explicit
						  }
					).$results( eventBegottenArgs );


					expect( _svc.getInstanceArgs(
						  webflowId = _webflowId
						, instanceRef = _instanceRef
						, subReference = _subReference
						, explicitArgs = explicit
					) ).toBe( {
						  reference       = explicit.reference
						, unique          = true
						, subreference    = false
						, subSubreference = _subReference
						, owner           = eventBegottenArgs.owner
					} );
				} );

				it( "should default the owner, reference and subreference when all other approaches do not set them", function(){
					var explicit = {};
					var init = { instanceargs = {} };
					var owner = CreateUUId();

					_webflow.setInit( init );
					_configService.$( "getFlowConfig" ).$args( webflowId=_webflowId, instanceRef=_instanceRef ).$results( {} );
					_svc.$( "getDefaultOwner", owner );

					expect( _svc.getInstanceArgs(
						  webflowId = _webflowId
						, instanceRef = _instanceRef
						, subReference = _subReference
						, explicitArgs = explicit
					) ).toBe( {
						  reference       = _webflowId
						, subreference    = _instanceRef
						, subSubreference = _subReference
						, owner           = owner
					} );
				} );

			} );
		} );
	}

}