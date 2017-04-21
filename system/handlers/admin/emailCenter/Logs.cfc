component extends="preside.system.base.AdminHandler" {

	property name="emailLoggingService" inject="emailLoggingService";

	function prehandler( event, rc, prc ) {
		super.preHandler( argumentCollection = arguments );

		if ( !isFeatureEnabled( "emailcenter" ) ) {
			event.notFound();
		}

		if ( !hasCmsPermission( "emailCenter.logs.view" ) ) {
			event.adminAccessDenied();
		}

		event.addAdminBreadCrumb(
			  title = translateResource( uri="cms:emailcenter.logs.page.breadcrumb" )
			, link  = event.buildAdminLink( linkTo="emailCenter.logs" )
		);
		prc.pageIcon = "envelope";
	}

	public void function index( event, rc, prc ) {
		prc.pageTitle    = translateResource( uri="cms:emailcenter.logs.page.title" );
		prc.pageSubtitle = translateResource( uri="cms:emailcenter.logs.page.subtitle" );
	}

	public void function log( event, rc, prc ) {
		var logId = rc.id ?: "";

		prc.log = emailLoggingService.getLog( logId );
		if ( prc.log.isEmpty() ) {
			event.notFound();
		}
		prc.activity = emailLoggingService.getActivity( logId );

		event.noLayout();
	}

	public void function getLogsForAjaxDataTables( event, rc, prc ) {
		runEvent(
			  event          = "admin.DataManager._getObjectRecordsForAjaxDataTables"
			, prePostExempt  = true
			, private        = true
			, eventArguments = {
				  object        = "email_template_send_log"
				, gridFields    = "email_template,recipient,subject,datecreated,sent,delivered,failed,opened,click_count"
				, actionsView   = "admin.emailCenter.logs._logGridActions"
			}
		);
	}

	private string function _logGridActions( event, rc, prc, args={} ) {
		var logId = args.id ?: "";

		args.viewlink = event.buildAdminLink(
			  linkTo      = "emailcenter.logs.log"
			, queryString = "id=#logId#"
		);
		args.viewLogTitle = translateResource( "cms:emailcenter.logs.view.log.modal.title" );

		return renderView( view="/admin/emailcenter/logs/_logGridActions", args=args );
	}
}