<!---@feature admin and apiManager--->
<cfset id = rc.id ?: ""/>
<cfoutput>
	#outputView( view="/admin/datamanager/_objectVersionHistoryTable", args={
		  objectName    = "rest_user"
		, datasourceUrl = event.buildAdminLink( linkTo="apiUserManager.getHistoryForAjaxDatatables", queryString="id=#id#" )
	} )#
</cfoutput>