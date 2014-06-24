component extends="preside.system.base.AdminHandler" output=false {

	property name="systemConfigurationService" inject="systemConfigurationService";

// VIEWLETS
	private string function categoryMenu( event, rc, prc, viewletArgs ) output=false {
		viewletArgs.categories = systemConfigurationService.listConfigCategories();

		return renderView( view="admin/sysconfig/categoryMenu", args=viewletArgs );
	}

}