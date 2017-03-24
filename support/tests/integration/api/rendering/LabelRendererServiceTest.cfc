component extends="tests.resources.HelperObjects.PresideBddTestCase"{

	function run(){

		describe( "getSelectFieldsForLabel()", function(){

			it( "should return custom selectFields if label renderer exists", function(){
				var service         = _getService();
				var labelRenderer   = "custom_label_renderer";
				var selectHandler   = service.getSelectFieldsHandler( labelRenderer );
				var expectedFields  = [ "column_one", "column_two" ];

				mockColdboxController.$( "handlerExists" ).$args( selectHandler ).$results( true );
				mockColdboxController.$( "runEvent"      ).$args(
					  event          = selectHandler
					, prePostExempt  = true
					, private        = true ).$results( expectedFields );
				
				expect( service.getSelectFieldsForLabel( labelRenderer ) ).toBe( expectedFields );
			} );

			it( "should return default selectFields if label renderer does not exist", function(){
				var service         = _getService();
				var labelRenderer   = "custom_label_renderer";
				var selectHandler   = service.getSelectFieldsHandler( labelRenderer );
				var expectedFields  = [ "${labelfield} as label" ];

				mockColdboxController.$( "handlerExists" ).$args( selectHandler ).$results( false );
				
				expect( service.getSelectFieldsForLabel( labelRenderer ) ).toBe( expectedFields );
			} );

		} );


		describe( "getGroupByForLabels()", function(){

			it( "should return custom groupby if label renderer exists and groupby method defined", function(){
				var service         = _getService();
				var labelRenderer   = "custom_label_renderer";
				var groupByHandler  = service.getGroupByHandler( labelRenderer );
				var expectedGroupBy = "group_by_column";

				mockColdboxController.$( "handlerExists" ).$args( groupByHandler ).$results( true );
				mockColdboxController.$( "runEvent"      ).$args(
					  event          = groupByHandler
					, prePostExempt  = true
					, private        = true ).$results( expectedGroupBy );
				
				expect( service.getGroupByForLabels( labelRenderer ) ).toBe( expectedGroupBy );
			} );

			it( "should return empty string if label renderer does not exist or groupby method not defined", function(){
				var service         = _getService();
				var labelRenderer   = "custom_label_renderer";
				var groupByHandler  = service.getGroupByHandler( labelRenderer );
				var expectedGroupBy = "";

				mockColdboxController.$( "handlerExists" ).$args( groupByHandler ).$results( false );
				
				expect( service.getGroupByForLabels( labelRenderer ) ).toBe( expectedGroupBy );
			} );

		} );


		describe( "getOrderByForLabels()", function(){

			it( "should return custom orderby if label renderer exists and orderby method defined", function(){
				var service         = _getService();
				var labelRenderer   = "custom_label_renderer";
				var orderByHandler  = service.getOrderByHandler( labelRenderer );
				var defaultOrderBy  = "label";
				var expectedOrderBy = "column_one, column_two";

				mockColdboxController.$( "handlerExists" ).$args( orderByHandler ).$results( true );
				mockColdboxController.$( "runEvent"      ).$args(
					  event          = orderByHandler
					, prePostExempt  = true
					, private        = true ).$results( expectedOrderBy );
				
				expect( service.getOrderByForLabels( labelRenderer, { orderBy=defaultOrderBy } ) ).toBe( expectedOrderBy );
			} );

			it( "should return default orderby if label renderer does not exist or orderby method not defined", function(){
				var service         = _getService();
				var labelRenderer   = "custom_label_renderer";
				var orderByHandler  = service.getOrderByHandler( labelRenderer );
				var defaultOrderBy  = "label";
				var expectedOrderBy = "label";

				mockColdboxController.$( "handlerExists" ).$args( orderByHandler ).$results( false );
				
				expect( service.getOrderByForLabels( labelRenderer, { orderBy=defaultOrderBy } ) ).toBe( expectedOrderBy );
			} );

		} );


		describe( "renderLabel()", function(){

			it( "should return custom label if label renderer exists", function(){
				var service         = _getService();
				var labelRenderer   = "custom_label_renderer";
				var selectHandler   = service.getSelectFieldsHandler( labelRenderer );
				var renderHandler   = service.getRenderLabelHandler(  labelRenderer );
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
				
				expect( service.renderLabel( labelRenderer, args ) ).toBe( expectedLabel );
			} );

			it( "should return default label if label renderer does not exist", function(){
				var service         = _getService();
				var labelRenderer   = "custom_label_renderer";
				var selectHandler   = service.getSelectFieldsHandler( labelRenderer );
				var renderHandler   = service.getRenderLabelHandler(  labelRenderer );
				var selectFields    = [ "${labelfield} as label" ];
				var expectedLabel   = "Default label text";

				mockColdboxController.$( "handlerExists" ).$args( selectHandler ).$results( false );
				mockColdboxController.$( "handlerExists" ).$args( renderHandler ).$results( false );
				
				expect( service.renderLabel( labelRenderer, { label=expectedLabel } ) ).toBe( expectedLabel );
			} );

		} );


		describe( "getRendererCacheDate()", function(){

			it( "should return current datetime if label renderer exists but is not in cache", function(){
				var service         = _getService();
				var labelRenderer   = "custom_label_renderer";
				var selectHandler   = service.getSelectFieldsHandler( labelRenderer );
				var expectedDate    = Now();

				mockColdboxController.$( "handlerExists" ).$args( selectHandler ).$results( true );
				mockLabelRendererCache.$( "get" ).$args( labelRenderer ).$results( nullValue() );
				mockLabelRendererCache.$( "set" ).$args( labelRenderer, expectedDate ).$results( expectedDate );
				
				expect( service.getRendererCacheDate( labelRenderer ) ).toBeGTE( expectedDate );
			} );

			it( "should return cached datetime if label renderer exists and is in cache", function(){
				var service         = _getService();
				var labelRenderer   = "custom_label_renderer";
				var selectHandler   = service.getSelectFieldsHandler( labelRenderer );
				var expectedDate    = createDateTime( 2017, 1, 1, 10, 30, 0 );

				mockColdboxController.$( "handlerExists" ).$args( selectHandler ).$results( true );
				mockLabelRendererCache.$( "get" ).$args( labelRenderer ).$results( expectedDate );
				
				expect( service.getRendererCacheDate( labelRenderer ) ).toBe( expectedDate );
			} );

			it( "should return default datetime if label renderer does not exist", function(){
				var service         = _getService();
				var labelRenderer   = "custom_label_renderer";
				var selectHandler   = service.getSelectFieldsHandler( labelRenderer );
				var expectedDate    = createDateTime( 1970, 1, 1, 0, 0, 0 );

				mockColdboxController.$( "handlerExists" ).$args( selectHandler ).$results( false );
				
				expect( service.getRendererCacheDate( labelRenderer ) ).toBe( expectedDate );
			} );

		} );

	}

// PRIVATE HELPERS
	private any function _getService() {
		mockLabelRendererCache = createStub();
		mockColdboxController  = createStub();

		var service = createMock( object= new preside.system.services.rendering.LabelRendererService(
			labelRendererCache = mockLabelRendererCache
		) );

		service.$( "$getColdbox"           , mockColdboxController );

		makePublic( service, "_getSelectFieldsHandler", "getSelectFieldsHandler" );
		makePublic( service, "_getGroupByHandler"     , "getGroupByHandler"      );
		makePublic( service, "_getOrderByHandler"     , "getOrderByHandler"      );
		makePublic( service, "_getRenderLabelHandler" , "getRenderLabelHandler"  );

		return service;
	}

}