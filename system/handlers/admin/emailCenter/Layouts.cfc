component extends="preside.system.base.AdminHandler" {

	property name="emailLayoutService" inject="emailLayoutService";

	public void function preHandler( event, action, eventArguments ) {
		super.preHandler( argumentCollection=arguments );

		if ( !hasCmsPermission( "emailcenter.layouts.navigate" ) ) {
			event.adminAccessDenied();
		}

		event.addAdminBreadCrumb(
			  title = translateResource( "cms:emailcenter.layouts.breadcrumb.title" )
			, link  = event.buildAdminLink( linkTo="emailcenter.layouts" )
		);

		event.setValue( "pageIcon", "envelope", true );
	}

	public void function index( event, rc, prc ) {
		prc.pageTitle    = translateResource( "cms:emailcenter.layouts.page.title"    );
		prc.pageSubTitle = translateResource( "cms:emailcenter.layouts.page.subTitle" );

		prc.layouts = emailLayoutService.listLayouts();
	}

	public void function layout( event, rc, prc ) {
		var layoutId = rc.layout ?: "";
		prc.layout = emailLayoutService.getLayout( layoutId );
		if ( !prc.layout.count() ) {
			event.adminNotFound();
		}

		prc.pageTitle    = translateResource( uri="cms:emailcenter.layouts.layout.page.title"   , data=[ prc.layout.title ] );
		prc.pageSubTitle = translateResource( uri="cms:emailcenter.layouts.layout.page.subTitle", data=[ prc.layout.title ] );

		event.addAdminBreadCrumb(
			  title = translateResource( uri="cms:emailcenter.layouts.layout.breadcrumb.title"  , data=[ prc.layout.title ] )
			, link  = event.buildAdminLink( linkTo="emailcenter.layouts.layout", queryString="layout=" & layoutId )
		);




		// prc.preview = emailTemplateService.previewTemplate( template=templateId, allowDrafts=true, version=version );

		// prc.pageTitle    = translateResource( uri="cms:emailcenter.systemTemplates.template.page.title"   , data=[ prc.template.name ] );
		// prc.pageSubTitle = translateResource( uri="cms:emailcenter.systemTemplates.template.page.subTitle", data=[ prc.template.name ] );

		// event.addAdminBreadCrumb(
		// 	  title = translateResource( uri="cms:emailcenter.systemTemplates.template.breadcrumb.title"  , data=[ prc.template.name ] )
		// 	, link  = event.buildAdminLink( linkTo="emailcenter.systemTemplates.template", queryString="template=" & templateId )
		// );
	}

}