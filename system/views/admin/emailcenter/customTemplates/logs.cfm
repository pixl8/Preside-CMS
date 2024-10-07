<!---@feature admin and customEmailTemplates--->
<cfscript>
	templateId = rc.id ?: "";
	ajaxUrl    = event.buildAdminLink( linkTo="emailCenter.customTemplates.getLogsForAjaxDataTables", querystring="id=" & templateid );
	showClicks = IsTrue( prc.showClicks ?: "" );
	gridFields = [ "recipient", "subject", "datecreated", "sent", "delivered", "failed", "opened" ];

	if ( showClicks ) {
		gridFields.append( "click_count" );
	}

	if ( !IsFeatureEnabled( "emailDeliveryStats" ) ) {
		ArrayDelete( gridFields, "delivered" );
	}

	event.include( "/js/admin/specific/emailcenter/logs/viewlog/" );
	event.include( "/css/admin/specific/htmliframepreview/" );
</cfscript>
<cfoutput>
	<cfsavecontent variable="body">
		#renderView( view="/admin/datamanager/_objectDataTable", args={
			  objectName      = "email_template_send_log"
			, useMultiActions = false
			, datasourceUrl   = ajaxUrl
			, gridFields      = gridFields
			, allowDataExport = true
			, dataExportUrl   = event.buildAdminLink( linkTo="emailcenter.customTemplates.exportAction", queryString="id=" & templateId )
		} )#
	</cfsavecontent>

	#renderViewlet( event="admin.emailcenter.customtemplates._customTemplateTabs", args={ body=body, tab="log" } )#
</cfoutput>