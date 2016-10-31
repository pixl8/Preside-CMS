component extends="resources.HelperObjects.PresideBddTestCase" {

	function run() {

		describe( "listLayouts", function(){
			it( "should return an array of layouts derived from view and handler directories (base on convention, 'email.layout.(layoutid).html/text') including transated titles and descriptions based on i18n convention", function(){
				var service          = _getService();
				var expectedLayouts  = [ {
					  id          = "layout1"
					, title       = "Layout 1 title"
					, description = "Layout 1 description"
				},{
					  id          = "layout2"
					, title       = "Layout 2 title here"
					, description = "Layout 2 description here"
				},{
					  id          = "layout3"
					, title       = "Layout 3"
					, description = "Layout 3 is cool"
				} ]

				for( var layout in expectedLayouts ) {
					service.$( "$translateResource" ).$args( uri="email.layout:#layout.id#.title"      , defaultValue=layout.id ).$results( layout.title       );
					service.$( "$translateResource" ).$args( uri="email.layout:#layout.id#.description", defaultValue=""        ).$results( layout.description );
				}

				expect( service.listLayouts() ).toBe( expectedLayouts );
			} );
		} );

	}

	private any function _getService(
		array layoutViewlets=_getDefaultLayoutViewlets()
	){
		variables.mockViewletsService = createEmptyMock( "preside.system.services.viewlets.ViewletsService" );

		mockViewletsService.$( "listPossibleViewlets" ).$args( filter="email\.layout\.(.*?)\.(html|text)" ).$results( layoutViewlets );

		var service = createMock( object=new preside.system.services.email.EmailLayoutService(
			viewletsService = mockViewletsService
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