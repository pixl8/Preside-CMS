component extends="preside.system.base.AdminHandler" output=false {

	property name="systemConfigurationService" inject="systemConfigurationService";

// LIFECYCLE EVENTS
	function preHandler( event, rc, prc ) output=false {
		super.preHandler( argumentCollection = arguments );

		event.addAdminBreadCrumb(
			  title = translateResource( "cms:sysConfig" )
			, link  = event.buildAdminLink( linkTo="sysConfig" )
		);
	}

// FIRST CLASS EVENTS
	public any function category( event, rc, prc ) output=false {
		try {
			prc.category            = systemConfigurationService.getConfigCategory( id = rc.id ?: "" );
		} catch( "SystemConfigurationService.category.notFound" e ) {
			event.notFound();
		}
		prc.savedData           = systemConfigurationService.getCategorySettings( category = rc.id ?: "" );
		prc.categoryName        = translateResource( uri=prc.category.getName(), defaultValue=prc.category.getId() );
		prc.categoryDescription = translateResource( uri=prc.category.getDescription(), defaultValue="" );

		event.addAdminBreadCrumb(
			  title = prc.categoryName
			, link  = ""
		);

		prc.pageTitle = translateResource( uri="cms:sysconfig.editCategory.title", data=[ prc.categoryName ] )
		prc.pageSubtitle = prc.categoryDescription
	}

// VIEWLETS
	private string function categoryMenu( event, rc, prc, viewletArgs ) output=false {
		viewletArgs.categories = systemConfigurationService.listConfigCategories();

		return renderView( view="admin/sysconfig/categoryMenu", args=viewletArgs );
	}

}