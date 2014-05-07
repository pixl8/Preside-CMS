component output="false" extends="tests.resources.HelperObjects.PresideTestCase" {

// SETUP, TEARDOWN, ETC.
	function setup() {
		mockPresideObjectService = getMockbox().createEmptyMock( "preside.system.api.presideObjects.PresideObjectService" );
		mockLogger               = _getTestLogger();

		sampleConfiguredTemplates = [{
			  id            = "events"
			, name          = "templates:events.title"
			, handler       = "templates.events"
			, defaultAction = "allevents"
			, configForm    = "events.pagetemplate.extension"
		},{
			  id            = "standard"
			, name          = "templates:standard.title"
			, handler       = "templates.standard"
			, defaultAction = "standard"
			, configForm    = "standard.config.form"
		}];
	}

// TESTS
	function test01_listTemplates_shouldReturnEmptyArray_whenNoTemplatesRegistered() {
		var templatesSvc = _getTemplateSvc();
		super.assertEquals( [], templatesSvc.listTemplates() );
	}

	function test02_listTemplates_shouldReturnAnArrayOfTemplatesRegisteredThroughConfiguration() {
		var templatesSvc = _getTemplateSvc( configuredTemplates = sampleConfiguredTemplates );
		var template  = "";
		var result    = "";
		var i = 0;
		var expected = "";

		result = templatesSvc.listTemplates();

		super.assertEquals( ArrayLen( sampleConfiguredTemplates ), ArrayLen( result ) );
		for( i=1; i lte ArrayLen( result ); i++ ){
			super.assertEquals( sampleConfiguredTemplates[i], result[i].getMemento() );
		}
	}

	function test03_templateExists_shouldReturnFalse_whenTemplateDoesNotExist() {
		var templatesSvc = _getTemplateSvc( configuredTemplates = sampleConfiguredTemplates );
		super.assertFalse( templatesSvc.templateExists( id="someTemplate" ) );
	}

	function test04_templateExists_shouldReturnTrue_whenTemplateExists() {
		var templatesSvc = _getTemplateSvc( configuredTemplates = sampleConfiguredTemplates );
		var template  = "";

		super.assert( templatesSvc.templateExists( id="standard" ) );
		super.assert( templatesSvc.templateExists( id="events" ) );
	}

	function test05_getTemplate_shouldReturnTheTemplateThatMatchesTheProvidedId(){
		var templatesSvc = "";
		var templates    = Duplicate( sampleConfiguredTemplates );
		var template     = "";
		var expected     = templates[2];

		StructDelete( templates[2], "configForm" );
		expected.configForm = "page-templates.standard";
		templatesSvc = _getTemplateSvc( configuredTemplates = templates );

		template = templatesSvc.getTemplate( id="standard" );

		super.assertEquals( expected, template.getMemento() );
	}

	function test06_getTemplate_shouldThrowInformativeError_whenTemplateDoesNotExist(){
		var templatesSvc = _getTemplateSvc();
		var errorThrown = false;

		try {
			templatesSvc.getTemplate( id="meh" );

		} catch ( "PageTemplatesService.missingTemplate" e ) {
			super.assertEquals( "The template, [meh], was not registered with the Preside page templates system", e.message );
			errorThrown = true;
		}

		super.assert( errorThrown, "No informative error was thrown" );
	}

	function test07_serviceShouldAutoDiscoverTemplatesByConvention() output=false {
		var templatesSvc      = _getTemplateSvc( autoDiscoverDirectories=[ "/tests/resources/pageTemplates/testDir1", "/tests/resources/pageTemplates/testDir2", "/tests/resources/pageTemplates/testDir3"] );
		var templates         = templatesSvc.listTemplates();
		var template          = "";
		var ids               = [];
		var expectedTemplates = [ "anotherTestTemplate", "cfmOnlyTemplate", "cfmOnlyTemplate2", "cfmOnlyTemplate3", "testTemplate", "testTemplate2", "testTemplate3", "testTemplate4" ];

		for( template in templates ){
			template = template.getMemento();
			ids.append( template.id );

			super.assertEquals( "templates.#template.id#:name", template.name );
			super.assertEquals( "templates.#template.id#", template.handler );
			super.assertEquals( "", template.defaultAction );
			super.assertEquals( "page-templates.#template.id#", template.configForm );
		}

		ids.sort( "textnocase" );
		super.assertEquals( expectedTemplates, ids );
	}

// private helpers
	private any function _getTemplateSvc( array configuredTemplates=[], array autoDiscoverDirectories=[] ) output=false {
		return new preside.system.api.pageTemplates.PageTemplatesService(
			  presideObjectService    = mockPresideObjectService
			, logger                  = mockLogger
			, configuredTemplates     = arguments.configuredTemplates
			, autoDiscoverDirectories = arguments.autoDiscoverDirectories
		);
	}


}