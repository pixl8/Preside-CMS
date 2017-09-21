component extends="preside.system.base.AdminHandler" {

	property name="emailLoggingService"       inject="emailLoggingService";
	property name="emailService"              inject="emailService";
	property name="emailRecipientTypeService" inject="emailRecipientTypeService";
	property name="presideObjectService"      inject="presideObjectService";

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

	public void function resendEmail( event, rc, prc ) {

		_checkPermissions( event=event, key="resend" );

		var logId = rc.id ?: "";

		var log = emailLoggingService.getLog( logId );
		if ( log.isEmpty() ) {
			event.notFound();
		}

		var recipeintId            = "";
		var recipientIdLogProperty = emailRecipientTypeService.getRecipientIdLogPropertyForRecipientType( log.recipient_type );
		if( !isEmpty( recipientIdLogProperty ) ) {
			recipeintId = presideObjectService.selectData( objectName="email_template_send_log", selectFields=["#recipientIdLogProperty#"], id=log.id )['#recipientIdLogProperty#'];
		}

		emailService.send(
			  templateId  = log.email_template
			, recipientId = recipeintId
			, to          = [ log.recipient ]
			, from        = log.sender
			, subject     = log.subject
			, htmlBody    = log.email_content_html ?: ""
			, textBody    = log.email_content_text ?: ""
			, args        = deserializeJson( log.send_args ?: "" )
		);

		messageBox.info( translateResource( uri="cms:emailcenter.logs.resend.success", data=[ log.recipient ] ) );
		setNextEvent( url=cgi.http_referer );
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

	private void function _checkPermissions( required any event, required string key ) {
		if ( !hasCmsPermission( "emailCenter.email." & arguments.key ) ) {
			event.adminAccessDenied();
		}
	}

}