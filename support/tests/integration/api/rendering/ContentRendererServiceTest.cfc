component output="false" extends="tests.resources.HelperObjects.PresideTestCase" {

	function setup() output=false {
		_getCacheBox().clearAll();
	}

// TESTS
	function test01_listRenderers_shouldReturnEmptyArray_whenNoRenderersRegistered(){
		var expected = [];
		var result   = _getRendererService().listRenderers();

		super.assertEquals( expected, result );
	}

	function test02_listRenderers_shouldReturnListOfRegisteredRenderers(){
		var svc      = _getRendererService();
		var expected = [ "custom", "myRenderer", "plain" ];
		var result   = "";

		svc.registerRenderer( name="myRenderer", viewlet="some.viewlet" );
		svc.registerRenderer( name="myRenderer", viewlet="another.viewlet", context="admin" );
		svc.registerRenderer( name="plain", viewlet="plain.viewlet" );
		svc.registerRenderer( name="custom", chain=["plain","myRenderer"] );

		result = svc.listRenderers();
		super.assertEquals( expected, result );
	}

	function test03_rendererExists_shouldReturnFalse_whenRendererDoesNotExist(){
		var svc = _getRendererService();

		mockColdBox.$( "viewletExists", false );

		svc.registerRenderer( name="plain", viewlet="plain.viewlet" );
		svc.registerRenderer( name="custom", chain=["plain","myRenderer"] );

		super.assertFalse( svc.rendererExists( name="nonExistant" ) );
	}

	function test04_rendererExists_shouldReturnTrue_whenRendererHasBeenRegistered(){
		var svc = _getRendererService();

		svc.registerRenderer( name="plain", viewlet="plain.viewlet" );
		svc.registerRenderer( name="custom", chain=["plain","myRenderer"] );

		super.assert( svc.rendererExists( name="plain" ) );
	}

	function test05_rendererExists_shouldReturnFalse_whenRendererExists_butNotForTheSuppliedContext(){
		var svc = _getRendererService();

		mockColdBox.$( "viewletExists" ).$results( false );
		svc.registerRenderer( name="plain", viewlet="plain.viewlet", context="admin" );

		super.assertFalse( svc.rendererExists( name="plain", context="frontend" ) );
	}

	function test06_rendererExists_shouldReturnTrue_whenRendererExistsWithDefaultContext_butNotForTheSuppliedContext(){
		var svc = _getRendererService();

		svc.registerRenderer( name="plain", viewlet="plain.viewlet", context="default" );

		super.assert( svc.rendererExists( name="plain", context="frontend" ) );
	}

	function test06_01_rendererExists_shouldReturnTrue_whenRendererExistsForOneOfThePassedContexts(){
		var svc = _getRendererService();

		svc.registerRenderer( name="plain", viewlet="plain.viewlet", context="someContext" );

		super.assert( svc.rendererExists( name="plain", context=["frontend", "someContext", "anotherContext" ] ) );
	}

	function test07_render_shouldCallViewletOfRegisteredDefaultRenderer(){
		var svc            = _getRendererService();
		var rendered       = "";
		var expectedRender = "this is what would be rendered";

		// mocking the coldbox calls
		mockColdBox.$( method="renderViewlet", returns=expectedRender );
		svc.registerRenderer( name="plain", viewlet="plain.viewlet", context="default" );

		rendered = svc.render( renderer="plain", data="whatever" );
		super.assertEquals( expectedRender, rendered );
	}

	function test08_render_shouldCallViewletOfRegisteredDefaultRenderer_whenContextNotFoundButDefaultExists(){
		var svc            = _getRendererService();
		var rendered       = "";
		var expectedRender = "this is a test";

		// mocking the coldbox calls
		mockColdBox.$( "renderViewlet" ).$args( event="test.viewlet.here", args={ data="8334" } ).$results( expectedRender );
		mockColdBox.$( "viewletExists" ).$results( false );

		svc.registerRenderer( name="money", viewlet="test.viewlet.here", context="default" );

		rendered = svc.render( renderer="money", data="8334", context="admin" );
		super.assertEquals( expectedRender, rendered );
	}

	function test09_render_shouldCallViewletOfRegisteredRendererForTheGivenContext(){
		var svc            = _getRendererService();
		var rendered       = "";
		var expectedRender = "another testing rendering";

		// mocking the coldbox calls
		mockColdBox.$( "renderViewlet" )
			.$args( event="admin.viewlet.money", args={ data="8334" } ).$results( expectedRender );

		svc.registerRenderer( name="money", viewlet="admin.viewlet.money", context="admin" );
		svc.registerRenderer( name="money", viewlet="test.viewlet.here", context="default" );

		rendered = svc.render( renderer="money", data="8334", context="admin" );

		super.assertEquals( expectedRender, rendered );
	}

	function test09_01_render_shouldCallViewletOfRegisteredRendererForTheFirstMatchedContext_whenMultipleContextsArePassed(){
		var svc            = _getRendererService();
		var rendered       = "";
		var expectedRender = "another testing rendering";

		// mocking the coldbox calls
		mockColdBox.$( "viewletExists", false );
		mockColdBox.$( "renderViewlet" )
			.$args( event="admin.viewlet.money", args={ data="8334" } ).$results( expectedRender );

		svc.registerRenderer( name="money", viewlet="admin.viewlet.money", context="admin" );
		svc.registerRenderer( name="money", viewlet="test.viewlet.here", context="default" );

		rendered = svc.render( renderer="money", data="8334", context=[ "somecontext", "another", "admin", "blah" ] );

		super.assertEquals( expectedRender, rendered );
	}

	function test10_render_shouldThrowInformativeError_whenRendererDoesNotExist(){
		var errorThrown = false;
		var svc         = _getRendererService();

		mockColdBox.$( method="viewletExists", returns=false );

		try {
			svc.render( renderer="iDoNotExist", data="blah" );
		} catch ( "Renderer.missingRenderer" e ) {
			super.assertEquals( "The renderer, [iDoNotExist], is not registered with the Preside rendering service", e.message );
			errorThrown = true;
		}

		super.assert( errorThrown, "An informative error was not thrown" );
	}

	function test11_render_shouldThrowInformativeError_whenRendererDoesNotExistInSuppliedContext(){
		var errorThrown = false;
		var svc      = _getRendererService();

		mockColdBox.$( "viewletExists" ).$results( false );

		svc.registerRenderer( name="money", viewlet="admin.viewlet.money", context="admin" );

		try {
			svc.render( renderer="money", context="anotherContext", data="blah" );
		} catch ( "Renderer.missingDefaultContext" e ) {
			super.assertEquals( "The renderer, [money], does not have a default context", e.message );
			errorThrown = true;
		}

		super.assert( errorThrown, "An informative error was not thrown" );
	}

	function test12_render_shouldCallChainOfRenderers_whenRendererIsAChain(){
		var svc      = _getRendererService();
		var expectedRender = "Third render";
		var rendered       = ""

		svc.registerRenderer( name="myRenderer", viewlet="some.viewlet" );
		svc.registerRenderer( name="myRenderer", viewlet="another.viewlet", context="admin" );
		svc.registerRenderer( name="plain", viewlet="plain.viewlet" );
		svc.registerRenderer( name="another", viewlet="yetAnother.viewlet" );
		svc.registerRenderer( name="custom", chain=["plain","another","myRenderer"] );

		// mocking the coldbox calls
		mockColdBox.$( "renderViewlet" ).$args( event="plain.viewlet", args={ data="test data" } ).$results( "firstRenderResult" );
		mockColdBox.$( "renderViewlet" ).$args( event="yetAnother.viewlet", args={ data="firstRenderResult" } ).$results( "second" );
		mockColdBox.$( "renderViewlet" ).$args( event="another.viewlet", args={ data="second" } ).$results( expectedRender );
		mockColdBox.$( "viewletExists" ).$results( false );

		// run the test
		rendered = svc.render( renderer="custom", context="admin", data="test data" );

		super.assertEquals( expectedRender, rendered );
	}

	function test13_rendererExists_shouldReturnTrue_whenRendererIsNotRegisteredButConventionBasedColdboxViewletDoes(){
		var svc = _getRendererService();

		svc.registerRenderer( name="plain", viewlet="plain.viewlet" );
		svc.registerRenderer( name="custom", chain=["plain","myRenderer"] );

		mockColdBox.$( "viewletExists" ).$args( event="renderers.content.viewletOnly.mytest" ).$results( false );
		mockColdBox.$( "viewletExists" ).$args( event="renderers.content.viewletOnly.contexts" ).$results( true );
		mockColdBox.$( "viewletExists" ).$args( event="renderers.content.viewletOnly.here" ).$results( false );

		super.assert( svc.rendererExists( name="viewletOnly", context=[ "mytest", "contexts", "here" ] ) );
	}

	function test14_render_shouldCallConventionBasedColdboxViewlet_whenRendererNotRegisteredButConventionBasedViewletExists(){
		var svc = _getRendererService();
		var expectedRender = "thisIsARender";
		var rendered = "";

		svc.registerRenderer( name="plain", viewlet="plain.viewlet" );
		svc.registerRenderer( name="custom", chain=["plain","myRenderer"] );

		mockColdBox.$( "viewletExists" ).$args( event="renderers.content.viewletOnly.meh" ).$results( false );
		mockColdBox.$( "viewletExists" ).$args( event="renderers.content.viewletOnly.admin" ).$results( true );
		mockColdBox.$( "viewletExists" ).$args( event="renderers.content.viewletOnly.default" ).$results( false );
		mockColdBox.$( "renderViewlet" ).$args( event="renderers.content.viewletOnly.admin", args={ data="test" } ).$results( expectedRender );

		rendered = svc.render( renderer="viewletOnly", context=[ "meh", "admin" ], data="test" );
		super.assertEquals( expectedRender, rendered );
	}

	function test15_getRendererForField_shouldReturnRenderer_whenRendererExplicitlyDefinedInFieldAttributes(){
		var svc      = _getRendererService();
		var expected = "relativeDate";
		var result   = svc.getRendererForField( fieldAttributes={
			  name     = "test"
			, renderer = expected
		} );

		super.assertEquals( expected, result );
	}

	function test16_getRendererForField_shouldReturnEmptyString_whenRendererCannotBeDerivedFromFieldAttributes(){
		var svc      = _getRendererService();
		var expected = "";
		var result   = svc.getRendererForField( fieldAttributes={
			name = "test"
		} );

		super.assertEquals( expected, result );
	}

	function test17_getRendererForField_shouldReturnFieldType_whenFieldTypeExistsAndNoOtherRendererCanBeDerived(){
		var svc      = _getRendererService();
		var expected = "datetime";
		var result   = svc.getRendererForField( fieldAttributes={
			  name     = "test"
			, renderer = ""
			, type     = expected
		} );

		super.assertEquals( expected, result );
	}

	function test18_getRendererForField_shouldReturnDateTime_whenFieldTypeIsDateAndDbFieldTypeIsNotDate(){
		var svc      = _getRendererService();
		var expected = "datetime";
		var result   = svc.getRendererForField( fieldAttributes={
			  name     = "test"
			, renderer = ""
			, type     = "date"
			, dbtype   = "timestamp"
		} );

		super.assertEquals( expected, result );
	}

// PRIVATE HELPERS
	private any function _getRendererService() output=false {
		var presideObjectService = _getPresideObjectService();
		var logger               = _getTestLogger();
		var assetCache           = _getCacheBox().getCache( "renderedAssetCache" );

		mockColdBox = getMockBox().createEmptyMock( "preside.system.coldboxModifications.Controller" );

		return new preside.system.services.rendering.ContentRendererService(
			  logger               = logger
			, presideObjectService = presideObjectService
			, coldbox              = mockColdBox
			, renderedAssetCache   = assetCache
			, assetRendererService = getMockBox().createEmptyMock( "preside.system.services.assetManager.assetRendererService" )
			, widgetsService       = getMockBox().createEmptyMock( "preside.system.services.widgets.widgetsService" )
			, labelRendererService = getMockBox().createEmptyMock( "preside.system.services.rendering.LabelRendererService" )
		);
	}
}