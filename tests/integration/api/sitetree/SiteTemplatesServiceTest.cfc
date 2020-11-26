component output="false" extends="tests.resources.HelperObjects.PresideTestCase" {

	function test01_listTemplates_shouldReturnEmptyArrayWhenNoSiteTemplatesFound(){
		var templatesService = new preside.system.services.sitetree.SiteTemplatesService( templateDirectories=[] );

		super.assertEquals( [], templatesService.listTemplates() );
	}

	function test02_listTemplates_shouldReturnArrayOfSiteTemplateBeansRepresentingAutoDiscoveredSiteTemplates(){
		var templatesService = new preside.system.services.sitetree.SiteTemplatesService( templateDirectories=[ "/tests/resources/siteTemplates/folder1", "/tests/resources/siteTemplates/folder2", "/tests/resources/siteTemplates/folder3" ] );
		var expected = [
			  { id="template1", title="site-templates.template1:title", description="site-templates.template1:description" }
			, { id="template2", title="site-templates.template2:title", description="site-templates.template2:description" }
			, { id="template3", title="site-templates.template3:title", description="site-templates.template3:description" }
		];
		var actual = templatesService.listTemplates();

		super.assertEquals( ArrayLen( expected ), ArrayLen( actual ) );

		actual.sort( function( a, b ){
			return a.getId() > b.getId() ? 1 : -1;
		} );

		for( var i=1; i <= expected.len(); i++ ){
			super.assertEquals( expected[i], actual[i].getMemento() );
		}

	}

}