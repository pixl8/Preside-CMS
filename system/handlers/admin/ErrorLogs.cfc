component extends="preside.system.base.AdminHandler" output=false {

	property name="messagebox"      inject="coldbox:plugin:messagebox";
	property name="errorLogService" inject="errorLogService";

	public void function preHandler( event ) output=false {
		super.preHandler( argumentCollection=arguments );

		prc.pageIcon = "fa-exclamation-circle";
		event.addAdminBreadCrumb(
			  title = translateResource( "cms:errorLogs.breadcrumbTitle" )
			, link  = event.buildAdminLink( linkTo="errorLogs" )
		);
	}

	public void function index( event, rc, prc ) output=false {
		prc.logs  = errorLogService.listErrors();

		prc.pageTitle    = translateResource( "cms:errorLogs.page.title" );
		prc.pageSubTitle = translateResource( "cms:errorLogs.page.subtitle" );
	}

	public void function view( event, rc, prc ) output=false {
		var log = errorLogService.readError( rc.log ?: "" );

		if ( Len( Trim( log ) ) ) {
			event.renderData( data=log, type="HTML" );
		}
	}

	public void function deleteLogAction( event, rc, prc ) output=false {
		errorLogService.deleteError( rc.log ?: "" );
		messagebox.info( translateResource( "cms:errorLogs.log.deleted.confirmation" ) );
		setNextEvent( url=event.buildAdminLink( "errorLogs" ) );
	}

	public void function deleteAllAction( event, rc, prc ) output=false {
		errorLogService.deleteAllErrors();
		messagebox.info( translateResource( "cms:errorLogs.all.logs.deleted.confirmation" ) );
		setNextEvent( url=event.buildAdminLink( "errorLogs" ) );
	}

}