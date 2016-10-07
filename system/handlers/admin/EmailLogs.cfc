component extends="preside.system.base.AdminHandler" output=false {

	property name="emailLogService" inject="emailLogService";
	property name="messagebox"      inject="coldbox:plugin:messagebox";

	public void function preHandler( event ) output=false {
		super.preHandler( argumentCollection=arguments );

		prc.pageIcon = "fa-envelope";
		event.addAdminBreadCrumb(
			  title = translateResource( "cms:emailLogs.breadcrumbTitle" )
			, link  = event.buildAdminLink( linkTo="emailLogs" )
		);

		event.include( assetId="/js/admin/specific/emailLogs/" );
	}

	public void function index( event, rc, prc ) output=false {
		prc.logs         = emailLogService.getEmailLogs();
		prc.pageTitle    = translateResource( "cms:emailLogs.page.title" );
		prc.pageSubTitle = translateResource( "cms:emailLogs.page.subtitle" );
	}

	public void function viewEmailBody( event, rc, prc ) output=false {
		var id           = rc.id ?: "";
		prc.log          = emailLogService.getEmailLog( id=id );
		prc.pageTitle    = translateResource( "cms:viewEmailBody.page.title" );
		prc.pageSubTitle = translateResource( "cms:viewEmailBody.page.subtitle" );

		event.addAdminBreadCrumb(
			  title = translateResource( "cms:viewEmailBody.breadcrumbTitle" )
			, link  = event.buildAdminLink( linkTo="viewEmailBody" )
		);

		event.includeData( { htmlBody : prc.log.html_body, textBody : prc.log.text_body } );
	}

	public void function deleteLogAction( event, rc, prc ) output=false {
		emailLogService.deleteEmailLog( rc.id ?: "" );
		messagebox.info( translateResource( "cms:emailLogs.log.deleted.confirmation" ) );
		setNextEvent( url=event.buildAdminLink( "emailLogs" ) );
	}

	public void function deleteAllAction( event, rc, prc ) output=false {
		emailLogService.deleteAllEmails( forceDeleteAll=true );
		messagebox.info( translateResource( "cms:emailLogs.all.logs.deleted.confirmation" ) );
		setNextEvent( url=event.buildAdminLink( "emailLogs" ) );
	}
}