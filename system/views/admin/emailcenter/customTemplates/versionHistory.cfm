<cfset id = rc.id ?: ""/>
<cfoutput>
	#renderView( view="/admin/datamanager/_objectVersionHistoryTable", args={
		  objectName    = "email_template"
		, datasourceUrl = event.buildAdminLink( linkTo="emailCenter.customTemplates.getHistoryForAjaxDatatables", queryString="id=#id#" )
	} )#
</cfoutput>