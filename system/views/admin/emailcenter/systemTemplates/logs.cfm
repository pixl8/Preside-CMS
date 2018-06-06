<cfscript>
	templateId = rc.template ?: "";
	ajaxUrl    = event.buildAdminLink( linkTo="emailCenter.systemTemplates.getLogsForAjaxDataTables", querystring="template=" & templateid );
	showClicks = IsTrue( prc.showClicks ?: "" );
	gridFields = [ "recipient", "subject", "datecreated", "sent", "delivered", "failed", "opened" ];

	if ( showClicks ) {
		gridFields.append( "click_count" );
	}

	event.include( "/js/admin/specific/emailcenter/logs/viewlog/" );
	event.include( "/css/admin/specific/htmliframepreview/" );
</cfscript>
<cfoutput>
	<cfsavecontent variable="body">
		#renderView( view="/admin/datamanager/_objectDataTable", args={
			  objectName          = "email_template_send_log"
			, useMultiActions     = false
			, datasourceUrl       = ajaxUrl
			, gridFields          = gridFields
			, noRecordMessage     = translateResource( uri="cms:datatables.emailTemplate.emptyTable" )
		} )#
	</cfsavecontent>

	#renderViewlet( event="admin.emailcenter.systemtemplates._templateTabs", args={ body=body, tab="log" } )#
</cfoutput>