component extends="tests.resources.HelperObjects.PresideBddTestCase"{

	function run(){

		describe( "rendererExistsFor()", function(){

			it( "should return true if handler exists with required methods", function(){
				var service         = _getService();
				var objectName      = "dummy_object";
				var selectHandler   = service.getSelectFieldsHandler( objectName );
				var renderHandler   = service.getRenderLabelHandler(  objectName );

				mockColdboxController.$( "handlerExists" ).$args( selectHandler ).$results( true );
				mockColdboxController.$( "handlerExists" ).$args( renderHandler ).$results( true );
				
				expect( service.rendererExistsFor( objectName ) ).toBeTrue();
			} );

			it( "should return false if handler does not exist with required methods", function(){
				var service         = _getService();
				var objectName      = "dummy_object";
				var selectHandler   = service.getSelectFieldsHandler( objectName );
				var renderHandler   = service.getRenderLabelHandler(  objectName );

				mockColdboxController.$( "handlerExists" ).$args( selectHandler ).$results( true  );
				mockColdboxController.$( "handlerExists" ).$args( renderHandler ).$results( false );
				expect( service.rendererExistsFor( objectName ) ).toBeFalse();

				mockColdboxController.$( "handlerExists" ).$args( selectHandler ).$results( false );
				mockColdboxController.$( "handlerExists" ).$args( renderHandler ).$results( true  );
				expect( service.rendererExistsFor( objectName ) ).toBeFalse();

				mockColdboxController.$( "handlerExists" ).$args( selectHandler ).$results( false );
				mockColdboxController.$( "handlerExists" ).$args( renderHandler ).$results( false );
				expect( service.rendererExistsFor( objectName ) ).toBeFalse();
			} );

		} );

		describe( "getSelectFieldsForLabel()", function(){

			it( "should return custom selectFields if label renderer exists", function(){
				var service         = _getService();
				var objectName      = "dummy_object";
				var selectHandler   = service.getSelectFieldsHandler( objectName );
				var expectedFields  = [ "column_one", "column_two" ];

				mockColdboxController.$( "handlerExists" ).$args( selectHandler ).$results( true );
				mockColdboxController.$( "runEvent"      ).$args(
					  event          = selectHandler
					, prePostExempt  = true
					, private        = true ).$results( expectedFields );
				
				expect( service.getSelectFieldsForLabel( objectName) ).toBe( expectedFields );
			} );

			it( "should return default selectFields if label renderer does not exist", function(){
				var service         = _getService();
				var objectName      = "dummy_object";
				var selectHandler   = service.getSelectFieldsHandler( objectName );
				var expectedFields  = [ "${labelfield} as label" ];

				mockColdboxController.$( "handlerExists" ).$args( selectHandler ).$results( false );
				
				expect( service.getSelectFieldsForLabel( objectName) ).toBe( expectedFields );
			} );

		} );


		describe( "renderLabel()", function(){

			it( "should return custom label if label renderer exists", function(){
				var service         = _getService();
				var objectName      = "dummy_object";
				var selectHandler   = service.getSelectFieldsHandler( objectName );
				var renderHandler   = service.getRenderLabelHandler(  objectName );
				var selectFields    = [ "column_one", "column_two" ];
				var args            = { column_one="First", column_two="Second" };
				var expectedLabel   = "Custom label text";

				mockColdboxController.$( "handlerExists" ).$args( selectHandler ).$results( true );
				mockColdboxController.$( "handlerExists" ).$args( renderHandler ).$results( true );
				mockColdboxController.$( "runEvent"      ).$args(
					  event          = selectHandler
					, prePostExempt  = true
					, private        = true ).$results( selectFields );
				mockColdboxController.$( "runEvent"      ).$args(
					  event          = renderHandler
					, eventArguments = args
					, prePostExempt  = true
					, private        = true ).$results( expectedLabel );
				
				expect( service.renderLabel( objectName, args ) ).toBe( expectedLabel );
			} );

			it( "should return default label if label renderer does not exist", function(){
				var service         = _getService();
				var objectName      = "dummy_object";
				var selectHandler   = service.getSelectFieldsHandler( objectName );
				var renderHandler   = service.getRenderLabelHandler(  objectName );
				var selectFields    = [ "${labelfield} as label" ];
				var expectedLabel   = "Default label text";

				mockColdboxController.$( "handlerExists" ).$args( selectHandler ).$results( false );
				mockColdboxController.$( "handlerExists" ).$args( renderHandler ).$results( false );
				
				expect( service.renderLabel( objectName, { label=expectedLabel } ) ).toBe( expectedLabel );
			} );

		} );

	}

// PRIVATE HELPERS
	private any function _getService() {
		var service = createMock( object=CreateObject( "preside.system.services.rendering.LabelRendererService" ) );

		mockColdboxController = createStub();
		service.$( "$getColdbox", mockColdboxController );

		makePublic( service, "_getSelectFieldsHandler", "getSelectFieldsHandler" );
		makePublic( service, "_getRenderLabelHandler" , "getRenderLabelHandler"  );

		return service;
	}

}