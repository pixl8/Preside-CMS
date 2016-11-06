<cfscript>
	templateId = rc.template ?: "";
</cfscript>

<cfoutput>
	#renderView( view="/admin/datamanager/_objectVersionHistoryTable", args={
		  objectName    = "email_template"
		, datasourceUrl = event.buildAdminLink( linkTo="emailCenter.systemTemplates.getHistoryForAjaxDatatables", queryString="template=#templateId#" )
	} )#
</cfoutput>