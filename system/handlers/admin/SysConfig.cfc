component extends="preside.system.base.AdminHandler" output=false {

	property name="systemConfigurationService" inject="systemConfigurationService";
	property name="messageBox"                 inject="coldbox:plugin:messageBox";


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
		var categoryId = rc.id ?: "";

		try {
			prc.category = systemConfigurationService.getConfigCategory( id = categoryId );
		} catch( "SystemConfigurationService.category.notFound" e ) {
			event.notFound();
		}
		prc.savedData           = systemConfigurationService.getCategorySettings( category = categoryId );
		prc.categoryName        = translateResource( uri=prc.category.getName(), defaultValue=prc.category.getId() );
		prc.categoryDescription = translateResource( uri=prc.category.getDescription(), defaultValue="" );

		event.addAdminBreadCrumb(
			  title = prc.categoryName
			, link  = ""
		);

		prc.pageTitle = translateResource( uri="cms:sysconfig.editCategory.title", data=[ prc.categoryName ] )
		prc.pageSubtitle = prc.categoryDescription
	}

	public any function saveCategoryAction( event, rc, prc ) output=false {
		var categoryId = rc.id ?: "";

		try {
			prc.category = systemConfigurationService.getConfigCategory( id = categoryId );
		} catch( "SystemConfigurationService.category.notFound" e ) {
			event.notFound();
		}

		var formData = event.getCollectionForForm( prc.category.getForm() );

		for( var setting in formData ){
			systemConfigurationService.saveSetting(
				  category = categoryId
				, setting  = setting
				, value    = formData[ setting ]
			);
		}

		messageBox.info( translateResource( uri="cms:sysconfig.saved" ) );

		setNextEvent( url=event.buildAdminLink( linkTo="sysconfig.category", queryString="id=#categoryId#" ) );
	}

// VIEWLETS
	private string function categoryMenu( event, rc, prc, viewletArgs ) output=false {
		viewletArgs.categories = systemConfigurationService.listConfigCategories();

		return renderView( view="admin/sysconfig/categoryMenu", args=viewletArgs );
	}

}