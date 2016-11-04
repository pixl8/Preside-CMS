component extends="preside.system.base.AdminHandler" {

	property name="systemEmailTemplateService" inject="systemEmailTemplateService";
	property name="emailTemplateService"       inject="emailTemplateService";

	public void function preHandler( event, action, eventArguments ) {
		super.preHandler( argumentCollection=arguments );

		if ( !hasCmsPermission( "emailcenter.systemTemplates.navigate" ) ) {
			event.adminAccessDenied();
		}

		event.addAdminBreadCrumb(
			  title = translateResource( "cms:emailcenter.systemTemplates.breadcrumb.title" )
			, link  = event.buildAdminLink( linkTo="emailcenter.systemTemplates" )
		);

		event.setValue( "pageIcon", "envelope", true );
	}

	public void function index( event, rc, prc ) {
		prc.pageTitle    = translateResource( "cms:emailcenter.systemTemplates.page.title"    );
		prc.pageSubTitle = translateResource( "cms:emailcenter.systemTemplates.page.subTitle" );

		prc.templates = systemEmailTemplateService.listTemplates();
	}

	public void function template( event, rc, prc ) {
		var templateId = rc.template ?: "";

		prc.template = emailTemplateService.getTemplate( templateId );

		if ( !prc.template.count() || !systemEmailTemplateService.templateExists( templateId ) ) {
			event.adminNotFound();
		}

		prc.preview = emailTemplateService.previewTemplate( templateId );

		prc.pageTitle    = translateResource( uri="cms:emailcenter.systemTemplates.template.page.title"   , data=[ prc.template.name ] );
		prc.pageSubTitle = translateResource( uri="cms:emailcenter.systemTemplates.template.page.subTitle", data=[ prc.template.name ] );

		event.addAdminBreadCrumb(
			  title = translateResource( uri="cms:emailcenter.systemTemplates.template.breadcrumb.title"  , data=[ prc.template.name ] )
			, link  = event.buildAdminLink( linkTo="emailcenter.systemTemplates.template", queryString="template=" & templateId )
		);
	}

	public void function edit( event, rc, prc ) {
		var templateId = rc.template ?: "";

		prc.template = emailTemplateService.getTemplate( templateId );

		if ( !prc.template.count() || !systemEmailTemplateService.templateExists( templateId ) ) {
			event.adminNotFound();
		}

		prc.pageTitle    = translateResource( uri="cms:emailcenter.systemTemplates.edit.page.title"   , data=[ prc.template.name ] );
		prc.pageSubTitle = translateResource( uri="cms:emailcenter.systemTemplates.edit.page.subTitle", data=[ prc.template.name ] );
		prc.formName     = "preside-objects.email_template.system.admin.edit"

		event.addAdminBreadCrumb(
			  title = translateResource( uri="cms:emailcenter.systemTemplates.edit.breadcrumb.title"  , data=[ prc.template.name ] )
			, link  = event.buildAdminLink( linkTo="emailcenter.systemTemplates.edit", queryString="template=" & templateId )
		);
	}

}