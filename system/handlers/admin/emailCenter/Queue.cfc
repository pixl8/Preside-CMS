component extends="preside.system.base.AdminHandler" {

	property name="emailTemplateService" inject="emailTemplateService";
	property name="messagebox"           inject="coldbox:plugin:messagebox";

	function prehandler( event, rc, prc ) {
		super.preHandler( argumentCollection = arguments );

		if ( !isFeatureEnabled( "emailcenter" ) || !isFeatureEnabled( "customEmailTemplates" ) ) {
			event.notFound();
		}


		if ( !hasCmsPermission( "emailCenter.queue.view" ) ) {
			event.adminAccessDenied();
		}

		event.addAdminBreadCrumb(
			  title = translateResource( uri="cms:emailcenter.queue.page.breadcrumb" )
			, link  = event.buildAdminLink( linkTo="emailCenter.queue" )
		);
		prc.pageIcon = "hourglass-start";
	}

	public void function index( event, rc, prc ) {
		prc.pageTitle    = translateResource( uri="cms:emailcenter.queue.page.title" );
		prc.pageSubtitle = translateResource( uri="cms:emailcenter.queue.page.subtitle" );

		prc.queueSummary = emailTemplateService.getQueueStats();
		prc.hasClearPerms = hasCmsPermission( "emailCenter.queue.clear" );
	}

	public void function clear( event, rc, prc ) {
		if ( !hasCmsPermission( "emailCenter.queue.clear" ) ) {
			event.adminAccessDenied();
		}

		var templateId  = rc.template ?: "";
		var queuedCount = emailTemplateService.getQueueCount( templateId );

		if ( !queuedCount ) {
			messagebox.warn( translateResource( "cms:emailcenter.queue.nothing.to.clear" ) );
			setNextEvent( url=event.buildAdminLink( "emailcenter.queue" ) );
		}

		if ( templateId.len() ) {
			prc.template = emailTemplateService.getTemplate( templateId );

			if ( !prc.template.count() ) {
				event.notFound();
			}

			prc.promptMessage = translateResource( uri="cms:emailcenter.queue.clear.prompt", data=[ NumberFormat( queuedCount ), prc.template.name ] );
			prc.pageTitle     = translateResource( uri="cms:emailcenter.queue.clear.page.title" );
			prc.pageSubtitle  = translateResource( uri="cms:emailcenter.queue.clear.page.subtitle", data=[ prc.template.name ] );
		} else {
			prc.promptMessage = translateResource( uri="cms:emailcenter.queue.clear.all.prompt", data=[ NumberFormat( queuedCount ) ] );
			prc.pageTitle     = translateResource( uri="cms:emailcenter.queue.clear.all.page.title"    );
			prc.pageSubtitle  = translateResource( uri="cms:emailcenter.queue.clear.all.page.subtitle" );
		}

		event.addAdminBreadCrumb(
			  title = translateResource( uri="cms:emailcenter.queue.clear.page.breadcrumb" )
			, link  = ""
		);
	}



	public void function clearAction( event, rc, prc ) {
		if ( !hasCmsPermission( "emailCenter.queue.clear" ) ) {
			event.adminAccessDenied();
		}

		var templateId  = rc.template ?: "";

		emailTemplateService.clearQueue( templateId );

		if ( templateId.len() ) {
			var template = emailTemplateService.getTemplate( templateId );
			messagebox.info( translateResource( uri="cms:emailcenter.queue.cleared", data=[ template.name ] ) );


		} else {
			messagebox.info( translateResource( uri="cms:emailcenter.queue.cleared.all" ) );
		}

		setNextEvent( url=event.buildAdminLink( "emailcenter.queue" ) );
	}
}