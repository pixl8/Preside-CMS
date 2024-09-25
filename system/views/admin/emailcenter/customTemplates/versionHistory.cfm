<!---@feature admin and customEmailTemplates--->
<cfset id = rc.id ?: ""/>
<cfoutput>
	#outputView( view="/admin/datamanager/_objectVersionHistoryTable", args={
		  objectName    = "email_template"
		, datasourceUrl = event.buildAdminLink( linkTo="emailCenter.customTemplates.getHistoryForAjaxDatatables", queryString="id=#id#" )
	} )#
</cfoutput>