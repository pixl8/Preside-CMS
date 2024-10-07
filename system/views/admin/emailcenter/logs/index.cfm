<!---@feature admin and emailCenter--->
<cfscript>
	templateId = rc.id ?: "";
	ajaxUrl    = event.buildAdminLink( linkTo="emailCenter.logs.getLogsForAjaxDataTables" );
	gridFields = [ "email_template", "recipient", "subject", "datecreated", "sent", "delivered", "failed", "opened", "click_count" ];

	if ( !IsFeatureEnabled( "emailDeliveryStats" ) ) {
		ArrayDelete( gridFields, "delivered" );
	}

	event.include( "/js/admin/specific/emailcenter/logs/viewlog/" );
	event.include( "/css/admin/specific/htmliframepreview/" );
</cfscript>
<cfoutput>
	#renderView( view="/admin/datamanager/_objectDataTable", args={
		  objectName      = "email_template_send_log"
		, useMultiActions = false
		, datasourceUrl   = ajaxUrl
		, gridFields      = gridFields
		, allowDataExport = true
		, dataExportUrl   = event.buildAdminLink( linkTo="emailcenter.logs.exportAction" )
	} )#
</cfoutput>