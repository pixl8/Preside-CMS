<cfset id = rc.id ?: ""/>
<cfoutput>
	#renderView( view="/admin/datamanager/_objectVersionHistoryTable", args={
		  objectName    = "email_blueprint"
		, datasourceUrl = event.buildAdminLink( linkTo="emailCenter.Blueprints.getHistoryForAjaxDatatables", queryString="id=#id#" )
	} )#
</cfoutput>