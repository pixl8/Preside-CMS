<cfscript>
	templateId = rc.id ?: "";
	ajaxUrl    = event.buildAdminLink( linkTo="emailCenter.customTemplates.getLogsForAjaxDataTables", querystring="id=" & templateid );
	showClicks = IsTrue( prc.showClicks ?: "" );
	gridFields = [ "recipient", "subject", "datecreated", "sent", "delivered", "failed", "opened" ];

	if ( showClicks ) {
		gridFields.append( "click_count" );
	}
</cfscript>
<cfoutput>
	<cfsavecontent variable="body">
		#renderView( view="/admin/datamanager/_objectDataTable", args={
			  objectName          = "email_template_send_log"
			, useMultiActions     = false
			, datasourceUrl       = ajaxUrl
			, gridFields          = gridFields
		} )#
	</cfsavecontent>

	#renderViewlet( event="admin.emailcenter.customtemplates._customTemplateTabs", args={ body=body, tab="log" } )#
</cfoutput>