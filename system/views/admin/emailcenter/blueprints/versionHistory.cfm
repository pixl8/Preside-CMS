<!---@feature admin and emailCenter--->
<cfset id = rc.id ?: ""/>
<cfoutput>
	#outputView( view="/admin/datamanager/_objectVersionHistoryTable", args={
		  objectName    = "email_blueprint"
		, datasourceUrl = event.buildAdminLink( linkTo="emailCenter.Blueprints.getHistoryForAjaxDatatables", queryString="id=#id#" )
	} )#
</cfoutput>