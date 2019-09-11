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

	public void function viewLog( event, rc, prc ) {
		var logId         = rc.id ?: "";
		var resendEnabled = isFeatureEnabled( "emailCenterResend" );

		prc.log = emailLoggingService.getLog( logId );
		if ( prc.log.isEmpty() ) {
			event.notFound();
		}
		prc.activity         = emailLoggingService.getActivity( logId );
		prc.canResendEmails  = resendEnabled && hasCmsPermission( "emailCenter.settings.resend" );
		prc.hasSavedHtmlBody = resendEnabled && len( prc.log.html_body ?: "" ) > 0;
		prc.hasSavedTextBody = resendEnabled && len( prc.log.text_body ?: "" ) > 0;
		prc.hasSavedContent  = prc.hasSavedHtmlBody || prc.hasSavedTextBody;

		event.noLayout();
	}

	public void function getLogsForAjaxDataTables( event, rc, prc ) {
		var useDistinct = len( rc.sFilterExpression ?: "" ) || len( rc.sSavedFilterExpression ?: "" );

		runEvent(
			  event          = "admin.DataManager._getObjectRecordsForAjaxDataTables"
			, prePostExempt  = true
			, private        = true
			, eventArguments = {
				  object        = "email_template_send_log"
				, gridFields    = "email_template,recipient,subject,datecreated,sent,delivered,failed,opened,click_count"
				, actionsView   = "admin.emailCenter.logs._logGridActions"
				, distinct      = useDistinct
			}
		);
	}

	public string function resendEmailAction( event, rc, prc ) {
		var logId   = rc.id ?: "";
		var rebuild = isTrue( rc.rebuild ?: "" );

		if ( rebuild ) {
			emailLoggingService.rebuildAndResendEmail( logId );
		} else {
			emailLoggingService.resendOriginalEmail( logId );
		}

		prc.log = emailLoggingService.getLog( logId );
		if ( prc.log.isEmpty() ) {
			event.notFound();
		}
		prc.activity = emailLoggingService.getActivity( logId );

		event.noLayout();

		return renderView( view="/admin/emailcenter/logs/viewLog" );
	}

	private string function _logGridActions( event, rc, prc, args={} ) {
		var logId = args.id ?: "";

		args.viewlink = event.buildAdminLink(
			  linkTo      = "emailcenter.logs.viewLog"
			, queryString = "id=#logId#"
		);
		args.viewLogTitle = translateResource( "cms:emailcenter.logs.view.log.modal.title" );

		return renderView( view="/admin/emailcenter/logs/_logGridActions", args=args );
	}

	public void function exportAction( event, rc, prc ) {
		if ( !isFeatureEnabled( "dataexport" ) ) {
			event.notFound();
		}

		runEvent(
			  event         = "admin.DataManager._exportDataAction"
			, prePostExempt = true
			, private       = true
		);
	}
}