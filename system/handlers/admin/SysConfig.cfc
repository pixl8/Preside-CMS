component extends="preside.system.base.AdminHandler" {

	property name="systemConfigurationService" inject="systemConfigurationService";
	property name="siteService"                inject="siteService";
	property name="messageBox"                 inject="coldbox:plugin:messageBox";


// LIFECYCLE EVENTS
	function preHandler( event, rc, prc ) {
		super.preHandler( argumentCollection = arguments );

		if ( !isFeatureEnabled( "systemConfiguration" ) ) {
			event.notFound();
		}

		if ( !hasCmsPermission( permissionKey="systemConfiguration.manage" ) ) {
			event.adminAccessDenied();
		}

		event.addAdminBreadCrumb(
			  title = translateResource( "cms:sysConfig" )
			, link  = event.buildAdminLink( linkTo="sysConfig" )
		);
	}

// FIRST CLASS EVENTS
	public any function index( event, rc, prc ) {
		prc.categories = systemConfigurationService.listConfigCategories();

		prc.pageTitle    = translateResource( uri="cms:sysconfig" );
		prc.pageSubtitle = translateResource( uri="cms:sysconfig.subtitle" );
		prc.pageIcon     = "cogs";
	}

	public any function category( event, rc, prc ) {
		var categoryId = Trim( rc.id   ?: "" );
		var siteId     = Trim( rc.site ?: "" );

		try {
			prc.category = systemConfigurationService.getConfigCategory( id = categoryId );
		} catch( "SystemConfigurationService.category.notFound" e ) {
			event.notFound();
		}
		prc.sites = siteService.listSites();

		var isSiteConfig = prc.sites.recordCount > 1 && siteId.len();
		if ( isSiteConfig ) {
			prc.savedData = systemConfigurationService.getCategorySettings(
				  category        = categoryId
				, includeDefaults = false
				, siteId          = siteId
			);
		} else {
			prc.savedData = systemConfigurationService.getCategorySettings(
				  category           = categoryId
				, globalDefaultsOnly = true
			);
		}

		prc.categoryName        = translateResource( uri=prc.category.getName(), defaultValue=prc.category.getId() );
		prc.categoryDescription = translateResource( uri=prc.category.getDescription(), defaultValue="" );
		prc.formName            = isSiteConfig ? prc.category.getSiteForm() : prc.category.getForm();

		event.addAdminBreadCrumb(
			  title = prc.categoryName
			, link  = ""
		);

		prc.pageTitle    = translateResource( uri="cms:sysconfig.editCategory.title", data=[ prc.categoryName ] )
		prc.pageSubtitle = prc.categoryDescription
		prc.pageIcon     = translateResource( uri=prc.category.getIcon(), defaultValue="" );

		if ( !Len( Trim( prc.pageIcon ) ) ) {
			prc.pageIcon = "cogs";
		}
	}

	public any function saveCategoryAction( event, rc, prc ) {
		var categoryId = rc.id ?: "";
		var siteId     = rc.site ?: "";

		try {
			prc.category = systemConfigurationService.getConfigCategory( id = categoryId );
		} catch( "SystemConfigurationService.category.notFound" e ) {
			event.notFound();
		}

		var formName = Len( Trim( siteId ) ) ? prc.category.getSiteForm() : prc.category.getForm();
		var formData = event.getCollectionForForm( formName );

		if ( Len( Trim( siteId ) ) ) {
			for( var setting in formData ){
				if ( IsFalse( rc[ "_override_" & setting ] ?: "" ) ) {
					formData.delete( setting );
					systemConfigurationService.deleteSetting(
						  category = categoryId
						, setting  = setting
						, siteId   = siteId
					);
				}
			}
		}

		var validationResult = validateForm(
			  formName      = formName
			, formData      = formData
			, ignoreMissing = Len( Trim( siteId ) )
		);

		announceInterception( "preSaveSystemConfig", {
			  category         = categoryId
			, configuration    = formData
			, validationResult = validationResult
		} );

		if ( !validationResult.validated() ) {
			messageBox.error( translateResource( uri="cms:sysconfig.validation.failed" ) );
			var persist = formData;
			persist.validationResult = validationResult;

			setNextEvent(
				  url           = event.buildAdminLink(linkTo="sysconfig.category", queryString="id=#categoryId#" )
				, persistStruct = persist
			);
		}

		for( var setting in formData ){
			systemConfigurationService.saveSetting(
				  category = categoryId
				, setting  = setting
				, value    = formData[ setting ]
				, siteId   = siteId
			);
		}

		event.audit(
			  action   = "save_sysconfig_category"
			, type     = "sysconfig"
			, recordId = categoryId
			, detail   = formData
		);

		announceInterception( "postSaveSystemConfig", {
			  category         = categoryId
			, configuration    = formData
		} );

		messageBox.info( translateResource( uri="cms:sysconfig.saved" ) );
		setNextEvent( url=event.buildAdminLink( linkTo="sysconfig.category", queryString="id=#categoryId#" ) );
	}

// VIEWLETS
	private string function categoryMenu( event, rc, prc, args ) {
		args.categories = systemConfigurationService.listConfigCategories();

		return renderView( view="admin/sysconfig/categoryMenu", args=args );
	}

}