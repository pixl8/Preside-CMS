component extends="preside.system.base.AdminHandler" {


	function preHandler() {
		super.preHandler( argumentCollection=arguments );
	}

	public void function index( event, rc, prc ) {
		prc.pageIcon     = translateResource( "cms:rulesEngine.iconClass" );
		prc.pageTitle    = translateResource( "cms:rulesEngine.page.title" );
		prc.pageSubTitle = translateResource( "cms:rulesEngine.page.subtitle" );
	}

}