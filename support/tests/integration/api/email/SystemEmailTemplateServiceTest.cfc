component extends="resources.HelperObjects.PresideBddTestCase" {

	function run() {

		describe( "listTemplates()", function(){
			it( "should return an array of templates based on system email templates config (settings.email.templates) decorated with title and description and sorted by title", function(){
				var service   = _getService();
				var templates = _getDefaultConfiguredTemplates().keyArray();
				var expected  = [];

				for( var templateId in templates ) {
					var template = {
						  id          = templateId
						, title       = "Template #templateId#"
						, description = "This is the template: #templateId#"
					};

					service.$( "$translateResource" ).$args( uri="email.template.#templateId#:title"      , defaultValue=templateId ).$results( template.title );
					service.$( "$translateResource" ).$args( uri="email.template.#templateId#:description", defaultValue=""         ).$results( template.description );

					expected.append( template );
				}

				expected.sort( function( a, b ){
					return a.title > b.title ? 1 : -1;
				} );

				expect( service.listTemplates() ).toBe( expected );
			} );
		} );

		describe( "listTemplateParameters()", function(){
			it( "should return configured parameters for the given template with translated titles and descriptions", function(){
				var service  = _getService();
				var template = "adminResetPassword"
				var expected = [{
					  id          = "resetLink"
					, title       = "Reset link"
					, description = "Blah blah blah test"
					, required    = true
				},{
					  id          = "testParam"
					, title       = "Test param"
					, description = "Blah blah blah test"
					, required    = false
				}];

				for( var param in expected ) {
					service.$( "$translateResource" ).$args( uri="email.template.#template#:param.#param.id#.title"      , defaultValue=param.id ).$results( param.title );
					service.$( "$translateResource" ).$args( uri="email.template.#template#:param.#param.id#.description", defaultValue=""       ).$results( param.description );
				}

				expect( service.listTemplateParameters( template ) ).toBe( expected );
			} );

			it( "should return an empty array when the template does not have any defined parameters", function(){
				expect( _getService().listTemplateParameters( "adminWelcome" )  ).toBe( [] );
			} );

			it( "should return an empty array when the template does not exist", function(){
				expect( _getService().listTemplateParameters( CreateUUId() )  ).toBe( [] );
			} );
		} );

		describe( "templateExists()", function(){
			it( "should return true if the provided template is configured in the system", function(){
				expect( _getService().templateExists( "websiteResetPassword" ) ).toBe( true );
			} );

			it( "should return false if the provided template is not configured in the system", function(){
				expect( _getService().templateExists( CreateUUId() ) ).toBe( false );
			} );
		} );

	}

	private any function _getService( struct configuredTemplates=_getDefaultConfiguredTemplates() ){
		var service = createMock( object=new preside.system.services.email.SystemEmailTemplateService(
			configuredTemplates = arguments.configuredTemplates
		) );

		return service;
	}


	private struct function _getDefaultConfiguredTemplates() {
		return {
			  adminResetPassword   = { parameters=[ { id="resetLink", required=true }, "testParam" ] }
			, adminWelcome         = {}
			, websiteResetPassword = {}
			, websiteWelcome       = {}
		};
	}

}