component extends="preside.system.base.AdminHandler" {

	function prehandler( event, rc, prc ) {
		super.preHandler( argumentCollection = arguments );

		if ( !hasCmsPermission( "emailCenter.logs.view" ) ) {
			event.adminAccessDenied();
		}
	}

	public void function index( event, rc, prc ) {
		prc.pageTitle    = translateResource( uri="cms:emailcenter.logs.page.title" );
		prc.pageSubtitle = translateResource( uri="cms:emailcenter.logs.page.subtitle" );
		prc.pageIcon = "envelope";

		event.addAdminBreadCrumb(
			  title = translateResource( uri="cms:emailcenter.logs.page.breadcrumb" )
			, link  = event.buildAdminLink( linkTo="emailCenter.logs" )
		);
	}

	public void function getLogsForAjaxDataTables( event, rc, prc ) {
		runEvent(
			  event          = "admin.DataManager._getObjectRecordsForAjaxDataTables"
			, prePostExempt  = true
			, private        = true
			, eventArguments = {
				  object        = "email_template_send_log"
				, gridFields    = "email_template,recipient,sender,subject,sent_date,sent,delivered,opened"
				, actionsView   = "admin.emailCenter.customTemplates._logGridActions"
			}
		);
	}
}