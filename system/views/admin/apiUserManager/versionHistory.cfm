<cfset id = rc.id ?: ""/>
<cfoutput>
	#renderView( view="/admin/datamanager/_objectVersionHistoryTable", args={
		  objectName    = "rest_user"
		, datasourceUrl = event.buildAdminLink( linkTo="apiUserManager.getHistoryForAjaxDatatables", queryString="id=#id#" )
	} )#
</cfoutput>