<cfscript>
	templateId = rc.id ?: "";
	ajaxUrl    = event.buildAdminLink( linkTo="emailCenter.logs.getLogsForAjaxDataTables" );
	gridFields = [ "email_template", "sender", "recipient", "subject", "sent_date", "sent", "delivered", "opened" ];
</cfscript>
<cfoutput>
	#renderView( view="/admin/datamanager/_objectDataTable", args={
		  objectName      = "email_template_send_log"
		, useMultiActions = false
		, datasourceUrl   = ajaxUrl
		, gridFields      = gridFields
	} )#
</cfoutput>