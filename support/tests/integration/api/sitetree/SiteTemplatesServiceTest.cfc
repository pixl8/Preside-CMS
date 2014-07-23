component output="false" extends="tests.resources.HelperObjects.PresideTestCase" {

	function test01_listTemplates_shouldReturnEmptyArrayWhenNoSiteTemplatesFound(){
		var templatesService = new preside.system.services.sitetree.SiteTemplatesService();

		super.assertEquals( [], templatesService.listTemplates() );
	}

}