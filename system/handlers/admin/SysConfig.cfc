component extends="preside.system.base.AdminHandler" {

	property name="systemConfigurationService" inject="systemConfigurationService";
	property name="siteService"                inject="siteService";
	property name="presideObjectService"       inject="presideObjectService";
	property name="messageBox"                 inject="messagebox@cbmessagebox";
	property name="tenancyConfig"              inject="coldbox:setting:tenancy";


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
		var categoryId      = Trim( rc.id   ?: "" );
		var tenantId        = Trim( rc.tenantId ?: "" );
		var dataLoaded      = false;
		var isTenancyConfig = false;

		try {
			prc.category = systemConfigurationService.getConfigCategory( id=categoryId );
		} catch( "SystemConfigurationService.category.notFound" e ) {
			event.notFound();
		}

		prc.tenancy = systemConfigurationService.getConfigCategoryTenancy( id=categoryId );

		if ( Len( prc.tenancy ) ) {
			prc.tenancyObject = tenancyConfig[ prc.tenancy ].object ?: prc.tenancy;
			prc.tenancyRecords = presideObjectService.selectData(
				  objectName   = prc.tenancyObject
				, selectFields = [ "id" ]
			);

			isTenancyConfig = prc.tenancyRecords.recordCount > 1 && tenantId.len();
			if ( isTenancyConfig ) {
				prc.savedData = systemConfigurationService.getCategorySettings(
					  category        = categoryId
					, includeDefaults = false
					, tenantId        = tenantId
				);
				dataLoaded = true;
			}
		}

		if ( !dataLoaded ) {
			prc.savedData = systemConfigurationService.getCategorySettings(
				  category           = categoryId
				, globalDefaultsOnly = true
			);
		}

		prc.categoryName        = translateResource( uri=prc.category.getName(), defaultValue=prc.category.getId() );
		prc.categoryDescription = translateResource( uri=prc.category.getDescription(), defaultValue="" );
		prc.formName            = isTenancyConfig ? prc.category.getSiteForm() : prc.category.getForm();

		event.addAdminBreadCrumb(
			  title = prc.categoryName
			, link  = ""
		);

		prc.pageTitle    = translateResource( uri="cms:sysconfig.editCategory.title", data=[ prc.categoryName ] );
		prc.pageSubtitle = prc.categoryDescription;
		prc.pageIcon     = translateResource( uri=prc.category.getIcon(), defaultValue="" );

		if ( !Len( Trim( prc.pageIcon ) ) ) {
			prc.pageIcon = "cogs";
		}
	}

	public any function saveCategoryAction( event, rc, prc ) {
		var categoryId = rc.id ?: "";
		var tenantId   = rc.tenantId ?: "";

		try {
			prc.category = systemConfigurationService.getConfigCategory( id=categoryId );
		} catch( "SystemConfigurationService.category.notFound" e ) {
			event.notFound();
		}

		var formName = Len( Trim( tenantId ) ) ? prc.category.getSiteForm() : prc.category.getForm();
		var formData = event.getCollectionForForm( formName );

		if ( Len( Trim( tenantId ) ) ) {
			for( var setting in formData ){
				if ( IsFalse( rc[ "_override_" & setting ] ?: "" ) ) {
					formData.delete( setting );
					systemConfigurationService.deleteSetting(
						  category = categoryId
						, setting  = setting
						, tenantId = tenantId
					);
				}
			}
		}

		var validationResult = validateForm(
			  formName      = formName
			, formData      = formData
			, ignoreMissing = Len( Trim( tenantId ) )
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
				  url           = event.buildAdminLink(linkTo="sysconfig.category", queryString="id=#categoryId#&tenantId=#tenantId#" )
				, persistStruct = persist
			);
		}

		for( var setting in formData ){
			systemConfigurationService.saveSetting(
				  category = categoryId
				, setting  = setting
				, value    = formData[ setting ]
				, tenantId = tenantId
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